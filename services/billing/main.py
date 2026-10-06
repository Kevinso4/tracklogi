"""Billing Service — costo real de cada envío entregado y factura mensual por cliente.

Consume:  shipment.delivered   → registra el costo operativo y el precio al cliente del envío.
Publica:  invoice.issued       (vía outbox) al cerrar el mes.
UNIQUE(cliente, periodo) impide facturar dos veces el mismo mes.
"""
import enum
import logging
import math
import uuid
from datetime import date, datetime
from typing import Annotated

from fastapi import Depends, Query
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy import Boolean, Date, DateTime, Enum, ForeignKey, Integer, Numeric, String, UniqueConstraint, Uuid, func, select
from sqlalchemy.orm import Mapped, Session, mapped_column

from common.app import crear_app
from common.db import Base, ahora, get_db
from common.errores import error
from common.outbox import idempotente, registrar_evento
from common.seguridad import requiere_rol

log = logging.getLogger("billing")
Db = Annotated[Session, Depends(get_db)]

# Costos operativos de referencia (COP). ponytail: constantes fijas; pasarlas a una tabla si negocio las ajusta.
FACTOR_CARRETERA = 1.3          # la ruta por carretera es ~30 % más larga que la línea recta
COMBUSTIBLE_POR_KM = 950
PEAJES_POR_KM = 180
CONDUCTOR_POR_HORA = 18_000
VELOCIDAD_PROMEDIO_KMH = 55
TARIFA_POR_DEFECTO = ("por_km", 3_800)  # para clientes sin tarifa pactada


class ModeloTarifa(str, enum.Enum):
    por_km = "por_km"
    por_envio = "por_envio"


class TarifaCliente(Base):
    __tablename__ = "tarifas_cliente"
    cliente: Mapped[str] = mapped_column(String(120), primary_key=True)
    modelo: Mapped[ModeloTarifa] = mapped_column(Enum(ModeloTarifa, name="modelo_tarifa"))
    valor: Mapped[float] = mapped_column(Numeric(14, 2))


class Factura(Base):
    __tablename__ = "facturas"
    __table_args__ = (UniqueConstraint("cliente", "periodo", name="uq_factura_cliente_periodo"),)
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    numero: Mapped[int] = mapped_column(Integer, unique=True)
    cliente: Mapped[str] = mapped_column(String(120))
    periodo: Mapped[date] = mapped_column(Date)  # primer día del mes facturado
    envios: Mapped[int] = mapped_column(Integer)
    monto_total: Mapped[float] = mapped_column(Numeric(14, 2))
    emitida_en: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=ahora)


class CostoEnvio(Base):
    __tablename__ = "costos_envio"
    envio_id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True)  # externo (Shipment)
    codigo: Mapped[str] = mapped_column(String(12))
    cliente: Mapped[str] = mapped_column(String(120), index=True)
    ruta: Mapped[str] = mapped_column(String(200))
    distancia_km: Mapped[float] = mapped_column(Numeric(8, 1))
    costo_combustible: Mapped[float] = mapped_column(Numeric(14, 2))
    costo_peajes: Mapped[float] = mapped_column(Numeric(14, 2))
    costo_conductor: Mapped[float] = mapped_column(Numeric(14, 2))
    precio_cliente: Mapped[float] = mapped_column(Numeric(14, 2))
    a_tiempo: Mapped[bool] = mapped_column(Boolean)
    entregado_en: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=ahora)
    factura_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("facturas.id"), nullable=True, index=True)


def distancia_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    p1, p2 = math.radians(lat1), math.radians(lat2)
    h = math.sin((p2 - p1) / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(math.radians(lon2 - lon1) / 2) ** 2
    return 2 * 6371 * math.asin(math.sqrt(h)) * FACTOR_CARRETERA


def calcular(km: float, modelo: str, valor: float) -> dict:
    return {
        "costo_combustible": round(km * COMBUSTIBLE_POR_KM, 2),
        "costo_peajes": round(km * PEAJES_POR_KM, 2),
        "costo_conductor": round(km / VELOCIDAD_PROMEDIO_KMH * CONDUCTOR_POR_HORA, 2),
        "precio_cliente": round(km * valor if modelo == "por_km" else valor, 2),
    }


@idempotente
def al_entregado(db: Session, evento: dict) -> None:
    d = evento["datos"]
    if db.get(CostoEnvio, uuid.UUID(d["envio_id"])):
        return
    km = round(distancia_km(d["origen_lat"], d["origen_lon"], d["destino_lat"], d["destino_lon"]), 1)
    tarifa = db.get(TarifaCliente, d["cliente"])
    modelo, valor = (tarifa.modelo.value, float(tarifa.valor)) if tarifa else TARIFA_POR_DEFECTO
    db.add(CostoEnvio(envio_id=uuid.UUID(d["envio_id"]), codigo=d["codigo"], cliente=d["cliente"],
                      ruta=f"{d['origen']} → {d['destino']}", distancia_km=km, a_tiempo=bool(d.get("a_tiempo")),
                      **calcular(km, modelo, valor)))
    log.info("Costo registrado para %s: %.1f km", d["codigo"], km, extra={"shipment_id": d["envio_id"]})


app = crear_app(
    "billing",
    "LogiTrack · Billing Service",
    suscripciones=[("shipment-delivered", ["shipment.delivered"], al_entregado)],
)


# ---------------------------------------------------------------- API


class CostoOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    envio_id: uuid.UUID
    codigo: str
    cliente: str
    ruta: str
    distancia_km: float
    costo_combustible: float
    costo_peajes: float
    costo_conductor: float
    precio_cliente: float
    a_tiempo: bool
    entregado_en: datetime
    factura_id: uuid.UUID | None


class FacturaOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    numero: int
    cliente: str
    periodo: date
    envios: int
    monto_total: float
    emitida_en: datetime


class TarifaIn(BaseModel):
    modelo: ModeloTarifa
    valor: float = Field(gt=0, le=1_000_000_000)


@app.get("/api/v1/facturacion/costos", response_model=list[CostoOut], tags=["facturación"])
def costos(db: Db, cliente: str | None = None, limite: int = Query(default=200, ge=1, le=1000)):
    consulta = select(CostoEnvio).order_by(CostoEnvio.entregado_en.desc()).limit(limite)
    if cliente:
        consulta = consulta.where(CostoEnvio.cliente == cliente)
    return list(db.scalars(consulta))


@app.get("/api/v1/facturacion/facturas", response_model=list[FacturaOut], tags=["facturación"])
def facturas(db: Db):
    return list(db.scalars(select(Factura).order_by(Factura.numero.desc())))


@app.get("/api/v1/facturacion/resumen", tags=["facturación"])
def resumen(db: Db):
    costo = CostoEnvio.costo_combustible + CostoEnvio.costo_peajes + CostoEnvio.costo_conductor
    fila = db.execute(select(func.count(), func.coalesce(func.sum(CostoEnvio.precio_cliente), 0),
                             func.coalesce(func.sum(costo), 0), func.coalesce(func.sum(CostoEnvio.distancia_km), 0))).one()
    pendientes = db.scalar(select(func.count()).where(CostoEnvio.factura_id.is_(None)))
    facturado = db.scalar(select(func.coalesce(func.sum(Factura.monto_total), 0)))
    ingresos, costos_total = float(fila[1]), float(fila[2])
    return {
        "envios": fila[0],
        "ingresos": ingresos,
        "costos": costos_total,
        "margen": ingresos - costos_total,
        "costo_por_km": round(costos_total / float(fila[3]), 0) if fila[3] else None,
        "pendientes_de_facturar": pendientes,
        "facturado": float(facturado),
    }


@app.post("/api/v1/facturacion/cierre", response_model=list[FacturaOut], tags=["facturación"])
def cierre_mensual(db: Db, _=requiere_rol("operador")):
    """Agrupa por cliente los envíos aún no facturados y emite una factura por cliente para el mes actual."""
    periodo = date.today().replace(day=1)
    pendientes = list(db.scalars(select(CostoEnvio).where(CostoEnvio.factura_id.is_(None)).with_for_update()))
    if not pendientes:
        raise error(409, "nada_que_facturar", "No hay envíos entregados pendientes de facturar")
    por_cliente: dict[str, list[CostoEnvio]] = {}
    for c in pendientes:
        por_cliente.setdefault(c.cliente, []).append(c)
    numero = (db.scalar(select(func.max(Factura.numero))) or 1000)
    emitidas = []
    for cliente, lista in por_cliente.items():
        factura = db.scalar(select(Factura).where(Factura.cliente == cliente, Factura.periodo == periodo))
        if factura:  # ya se facturó este mes: se suman los envíos nuevos a la misma factura
            factura.envios += len(lista)
            factura.monto_total = float(factura.monto_total) + sum(float(c.precio_cliente) for c in lista)
        else:
            numero += 1
            factura = Factura(numero=numero, cliente=cliente, periodo=periodo, envios=len(lista),
                              monto_total=sum(float(c.precio_cliente) for c in lista))
            db.add(factura)
        db.flush()
        for c in lista:
            c.factura_id = factura.id
        registrar_evento(db, "invoice.issued", factura.id, {
            "factura_id": factura.id, "numero": factura.numero, "cliente": cliente,
            "periodo": periodo, "envios": factura.envios, "monto_total": float(factura.monto_total),
        })
        emitidas.append(factura)
    db.commit()
    return emitidas


@app.get("/api/v1/facturacion/tarifas", tags=["facturación"])
def tarifas(db: Db):
    defecto = {"modelo": TARIFA_POR_DEFECTO[0], "valor": TARIFA_POR_DEFECTO[1]}
    return {"por_defecto": defecto,
            "clientes": [{"cliente": t.cliente, "modelo": t.modelo.value, "valor": float(t.valor)}
                         for t in db.scalars(select(TarifaCliente).order_by(TarifaCliente.cliente))]}


@app.put("/api/v1/facturacion/tarifas/{cliente}", tags=["facturación"])
def fijar_tarifa(cliente: str, datos: TarifaIn, db: Db, _=requiere_rol("operador")):
    db.merge(TarifaCliente(cliente=cliente, modelo=datos.modelo, valor=datos.valor))
    db.commit()
    return {"cliente": cliente, "modelo": datos.modelo.value, "valor": datos.valor}
