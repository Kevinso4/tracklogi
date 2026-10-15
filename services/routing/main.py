"""Routing Service — ruta real por carretera y hora estimada de llegada (ETA) de cada envío.

Consume:  shipment.assigned / shipment.reassigned → calcula (o recalcula) la ruta.
          shipment.delivered / shipment.returned  → cierra la ruta.
Publica:  route.assigned, route.recalculated   (vía outbox)
Proveedor de mapas: OSRM (OpenStreetMap). Si no responde, el circuit breaker se abre y se usa una
estimación en línea recta marcada como «estimada»: el envío nunca se bloquea por el mapa.
"""
import asyncio
import logging
import math
import os
import uuid
from datetime import datetime, timedelta
from typing import Annotated

import httpx
from fastapi import Depends, Query
from pydantic import BaseModel, ConfigDict
from sqlalchemy import BigInteger, DateTime, ForeignKey, Integer, Numeric, String, Uuid, select
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, Session, mapped_column
from starlette.concurrency import run_in_threadpool

from common.app import crear_app
from common.cliente_http import CircuitBreaker, CircuitoAbierto
from common.db import Base, SessionLocal, ahora, get_db
from common.errores import error
from common.outbox import idempotente, registrar_evento
from common.seguridad import CABECERA_INTERNA

log = logging.getLogger("routing")
Db = Annotated[Session, Depends(get_db)]

OSRM_URL = os.getenv("OSRM_URL", "https://router.project-osrm.org")
FACTOR_CAMION = 1.35        # OSRM estima tiempos de automóvil; un camión cargado va más lento
MAX_PUNTOS = 300            # puntos de la geometría que se guardan y se envían al mapa
VELOCIDAD_ESTIMADA_KMH = 55
FACTOR_CARRETERA = 1.3      # para la estimación en línea recta

osrm = httpx.Client(timeout=5.0)  # 5 s para proveedores externos
shipment = httpx.Client(base_url=os.getenv("SHIPMENT_URL", "http://shipment:8000"), timeout=5.0)
circuito = CircuitBreaker("osrm")


class Ruta(Base):
    __tablename__ = "rutas"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    envio_id: Mapped[uuid.UUID] = mapped_column(Uuid, unique=True)  # externo (Shipment)
    codigo: Mapped[str] = mapped_column(String(12))
    vehiculo_id: Mapped[uuid.UUID | None] = mapped_column(Uuid, nullable=True)  # externo (Fleet)
    placa: Mapped[str | None] = mapped_column(String(10), nullable=True)
    origen: Mapped[str] = mapped_column(String(200))
    destino: Mapped[str] = mapped_column(String(200))
    geometria: Mapped[list] = mapped_column(JSONB)  # [[lon, lat], ...] en orden de recorrido
    distancia_km: Mapped[float] = mapped_column(Numeric(8, 1))
    duracion_min: Mapped[int] = mapped_column(Integer)
    eta: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    proveedor: Mapped[str] = mapped_column(String(12))  # osrm | estimada
    estado: Mapped[str] = mapped_column(String(12), default="activa", index=True)  # activa | completada
    recalculos: Mapped[int] = mapped_column(Integer, default=0)
    creada_en: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=ahora)


class HistorialRuta(Base):
    """Auditoría de recálculos: solo inserción."""

    __tablename__ = "historial_rutas"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    ruta_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("rutas.id"))
    motivo: Mapped[str] = mapped_column(String(120))
    eta_anterior: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    eta_nueva: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    registrado_en: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=ahora)


# ---------------------------------------------------------------- cálculo


def _linea_recta_km(o_lat: float, o_lon: float, d_lat: float, d_lon: float) -> float:
    p1, p2 = math.radians(o_lat), math.radians(d_lat)
    h = math.sin((p2 - p1) / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(math.radians(d_lon - o_lon) / 2) ** 2
    return 2 * 6371 * math.asin(math.sqrt(h))


def _reducir(puntos: list) -> list:
    """Deja como máximo MAX_PUNTOS conservando el primero y el último (todos siguen sobre la carretera)."""
    if len(puntos) <= MAX_PUNTOS:
        return puntos
    paso = math.ceil(len(puntos) / (MAX_PUNTOS - 1))
    return puntos[::paso] + ([puntos[-1]] if (len(puntos) - 1) % paso else [])


def calcular(o_lat: float, o_lon: float, d_lat: float, d_lon: float) -> tuple[list, float, int, str]:
    """Devuelve (geometría, km, minutos, proveedor)."""
    try:
        circuito.antes()
        r = osrm.get(f"{OSRM_URL}/route/v1/driving/{o_lon},{o_lat};{d_lon},{d_lat}",
                     params={"overview": "full", "geometries": "geojson"})
        r.raise_for_status()
        datos = r.json()
        if datos.get("code") != "Ok" or not datos.get("routes"):
            raise ValueError(f"OSRM sin ruta: {datos.get('code')}")
        circuito.exito()
        ruta = datos["routes"][0]
        return (_reducir(ruta["geometry"]["coordinates"]), round(ruta["distance"] / 1000, 1),
                round(ruta["duration"] / 60 * FACTOR_CAMION), "osrm")
    except CircuitoAbierto:
        log.warning("Circuito de OSRM abierto: se usa la ruta estimada")
    except (httpx.HTTPError, ValueError, KeyError) as exc:
        circuito.fallo()
        log.warning("OSRM no respondió (%s): se usa la ruta estimada", exc)
    km = round(_linea_recta_km(o_lat, o_lon, d_lat, d_lon) * FACTOR_CARRETERA, 1)
    return [[o_lon, o_lat], [d_lon, d_lat]], km, round(km / VELOCIDAD_ESTIMADA_KMH * 60), "estimada"


def datos_evento(ruta: Ruta, d: dict) -> dict:
    return {
        "ruta_id": ruta.id, "envio_id": ruta.envio_id, "codigo": ruta.codigo,
        "cliente": d.get("cliente"), "cliente_email": d.get("cliente_email"),
        "origen": ruta.origen, "destino": ruta.destino, "vehiculo_id": ruta.vehiculo_id, "placa": ruta.placa,
        "distancia_km": float(ruta.distancia_km), "duracion_min": ruta.duracion_min, "eta": ruta.eta,
        "eta_estimado": ruta.proveedor != "osrm", "recalculos": ruta.recalculos,
    }


def trazar(db: Session, d: dict, motivo: str) -> Ruta:
    """Crea la ruta del envío o la recalcula si ya existía, y deja el evento en la outbox."""
    envio_id = uuid.UUID(d["envio_id"])
    geometria, km, minutos, proveedor = calcular(d["origen_lat"], d["origen_lon"], d["destino_lat"], d["destino_lon"])
    eta = ahora() + timedelta(minutes=minutos)
    ruta = db.scalar(select(Ruta).where(Ruta.envio_id == envio_id))
    if ruta:
        db.add(HistorialRuta(ruta_id=ruta.id, motivo=motivo[:120], eta_anterior=ruta.eta, eta_nueva=eta))
        ruta.recalculos += 1
        tipo = "route.recalculated"
    else:
        ruta = Ruta(envio_id=envio_id, codigo=d["codigo"], origen=d["origen"], destino=d["destino"])
        db.add(ruta)
        tipo = "route.assigned"
    ruta.vehiculo_id = uuid.UUID(d["vehiculo_id"]) if d.get("vehiculo_id") else None
    ruta.placa = d.get("placa")
    ruta.geometria, ruta.distancia_km, ruta.duracion_min = geometria, km, minutos
    ruta.eta, ruta.proveedor, ruta.estado = eta, proveedor, "activa"
    db.flush()
    registrar_evento(db, tipo, ruta.id, datos_evento(ruta, d))
    log.info("%s %s: %.1f km, %s min (%s)", tipo, ruta.codigo, km, minutos, proveedor,
             extra={"shipment_id": str(envio_id)})
    return ruta


@idempotente
def al_asignar(db: Session, evento: dict) -> None:
    motivo = "Cambio de vehículo" if evento["tipo"] == "shipment.reassigned" else "Asignación inicial"
    trazar(db, evento["datos"], motivo)


@idempotente
def al_finalizar(db: Session, evento: dict) -> None:
    ruta = db.scalar(select(Ruta).where(Ruta.envio_id == uuid.UUID(evento["datos"]["envio_id"])))
    if ruta:
        ruta.estado = "completada"


async def reconciliar(_bus, parar: asyncio.Event) -> None:
    """Cada 30 s calcula la ruta de los envíos en tránsito que no la tengan (p. ej. asignados
    antes de desplegar Routing, o si se perdió un evento). El sistema se repara solo."""
    while not parar.is_set():
        await asyncio.sleep(30)
        try:
            await run_in_threadpool(_reconciliar)
        except Exception as exc:
            log.warning("Reconciliación de rutas fallida: %s", exc)


def _reconciliar() -> None:
    envios = shipment.get("/api/v1/envios", params={"estado": "en_transito", "limite": 200},
                          headers={"X-User-Role": "servicio", **CABECERA_INTERNA}).json()
    with SessionLocal() as db:
        con_ruta = set(db.scalars(select(Ruta.envio_id)))
        for e in envios:
            reciente = datetime.fromisoformat(e["actualizado_en"]) > ahora() - timedelta(seconds=60)  # su evento viene en camino
            if e["vehiculo_id"] and not reciente and uuid.UUID(e["id"]) not in con_ruta:
                trazar(db, {**e, "envio_id": e["id"], "placa": e["vehiculo_placa"]}, "Reconciliación")
                db.commit()


app = crear_app(
    "routing",
    "LogiTrack · Routing Service",
    tareas=[reconciliar],
    suscripciones=[
        ("shipment-assigned", ["shipment.assigned", "shipment.reassigned"], al_asignar),
        ("shipment-finished", ["shipment.delivered", "shipment.returned"], al_finalizar),
    ],
)


# ---------------------------------------------------------------- API


class RutaOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    envio_id: uuid.UUID
    codigo: str
    vehiculo_id: uuid.UUID | None
    placa: str | None
    origen: str
    destino: str
    geometria: list[list[float]]
    distancia_km: float
    duracion_min: int
    eta: datetime
    proveedor: str
    estado: str
    recalculos: int


@app.get("/api/v1/rutas", response_model=list[RutaOut], tags=["rutas"])
def listar(db: Db, estado: str | None = "activa", limite: int = Query(default=100, ge=1, le=300)):
    consulta = select(Ruta).order_by(Ruta.creada_en.desc()).limit(limite)
    if estado:
        consulta = consulta.where(Ruta.estado == estado)
    return list(db.scalars(consulta))


@app.get("/api/v1/rutas/{envio_id}", response_model=RutaOut, tags=["rutas"])
def ver(envio_id: uuid.UUID, db: Db):
    ruta = db.scalar(select(Ruta).where(Ruta.envio_id == envio_id))
    if not ruta:
        raise error(404, "ruta_no_encontrada", "El envío aún no tiene una ruta calculada")
    return ruta


@app.get("/api/v1/rutas/{envio_id}/eta", tags=["rutas"])
def eta(envio_id: uuid.UUID, db: Db):
    ruta = ver(envio_id, db)
    return {"envio_id": envio_id, "eta": ruta.eta, "estimado": ruta.proveedor != "osrm",
            "distancia_km": float(ruta.distancia_km), "duracion_min": ruta.duracion_min}


@app.get("/api/v1/rutas/{envio_id}/historial", tags=["rutas"])
def historial(envio_id: uuid.UUID, db: Db):
    ruta = ver(envio_id, db)
    filas = db.scalars(select(HistorialRuta).where(HistorialRuta.ruta_id == ruta.id).order_by(HistorialRuta.id))
    return [{"motivo": h.motivo, "eta_anterior": h.eta_anterior, "eta_nueva": h.eta_nueva,
             "registrado_en": h.registrado_en} for h in filas]
