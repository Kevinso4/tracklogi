"""Integración: cliente → envío → asignación automática (Fleet simulado) → PostgreSQL y outbox."""
import os
import random
import uuid
from datetime import datetime, timedelta, timezone

import httpx

os.environ.setdefault("DATABASE_URL", "postgresql://ci:ci@localhost:5432/ci")
os.environ.setdefault("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/")

from sqlalchemy import select  # noqa: E402

import shipment.main as servicio  # noqa: E402
from common.db import SessionLocal  # noqa: E402
from common.outbox import OutboxEvento  # noqa: E402
from common.pruebas import cliente, preparar_bd  # noqa: E402

preparar_bd()
OPERADOR = {"X-User-Role": "operador"}


def test_el_envio_se_crea_y_se_asigna_al_vehiculo_que_ofrece_fleet(monkeypatch):
    vehiculo = {"id": str(uuid.uuid4()), "placa": "PRB-" + str(random.randint(100, 999))}
    monkeypatch.setattr(servicio.fleet, "get", lambda ruta, **_: httpx.Response(
        200, json=[vehiculo], request=httpx.Request("GET", "http://fleet" + ruta)))
    http = cliente(servicio.app)

    c = http.post("/api/v1/clientes", headers=OPERADOR,
                  json={"nombre": f"Cliente prueba {uuid.uuid4().hex[:8]}", "nit": str(random.randint(10**8, 10**9))})
    assert c.status_code == 201, c.text
    envio = dict(cliente_id=c.json()["id"], cliente_email="cliente@prueba.co", origen="Montería", destino="Cartagena",
                 origen_lat=8.75, origen_lon=-75.88, destino_lat=10.39, destino_lon=-75.48, peso_kg=1200,
                 volumen_m3=8, fecha_limite_sla=(datetime.now(timezone.utc) + timedelta(days=1)).isoformat())
    clave = {"Idempotency-Key": uuid.uuid4().hex, **OPERADOR}

    r = http.post("/api/v1/envios", json=envio, headers=clave)
    assert r.status_code == 201, r.text
    eid = r.json()["id"]
    # La tarea en segundo plano ya consultó a Fleet y asignó el vehículo
    detalle = http.get(f"/api/v1/envios/{eid}").json()
    assert detalle["estado"] == "en_transito" and detalle["vehiculo_placa"] == vehiculo["placa"]

    with SessionLocal() as db:
        tipos = set(db.scalars(select(OutboxEvento.tipo).where(OutboxEvento.agregado_id == eid)))
    assert tipos == {"shipment.created", "shipment.assigned"}

    repetido = http.post("/api/v1/envios", json=envio, headers=clave)  # reintento con la misma clave
    assert repetido.status_code == 200 and repetido.json()["id"] == eid
