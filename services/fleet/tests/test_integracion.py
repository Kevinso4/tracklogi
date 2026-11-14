"""Integración: POST /vehiculos → reglas → PostgreSQL (vehículo + evento en la outbox, misma transacción)."""
import os
import random
import string
import uuid

os.environ.setdefault("DATABASE_URL", "postgresql://ci:ci@localhost:5432/ci")
os.environ.setdefault("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/")
os.environ.setdefault("INTERNAL_TOKEN", "clave-de-prueba")

from sqlalchemy import select  # noqa: E402

from common.db import SessionLocal  # noqa: E402
from common.outbox import OutboxEvento  # noqa: E402
from common.pruebas import cliente, preparar_bd  # noqa: E402
from fleet.main import app  # noqa: E402
from fleet.models import Vehiculo  # noqa: E402

preparar_bd()
GESTOR = {"X-User-Role": "gestor_flota"}


def test_crear_vehiculo_lo_guarda_con_su_evento_y_rechaza_la_placa_repetida():
    placa = "".join(random.choices(string.ascii_lowercase, k=3)) + "-" + str(random.randint(100, 999))
    datos = dict(placa=placa, tipo="camion", marca="Hino 500", capacidad_kg=5000, capacidad_m3=25, anio=2023,
                 vencimiento_seguro="2027-06-30", zona="Montería")
    http = cliente(app)

    r = http.post("/api/v1/vehiculos", json=datos, headers=GESTOR)
    assert r.status_code == 201, r.text
    vid = r.json()["id"]
    assert r.json()["placa"] == placa.upper()

    with SessionLocal() as db:
        assert db.get(Vehiculo, uuid.UUID(vid)).estado.value == "activo"
        evento = db.scalar(select(OutboxEvento).where(OutboxEvento.agregado_id == vid))
        assert evento.tipo == "vehicle.status_changed" and evento.publicado_en is None

    assert http.get(f"/api/v1/vehiculos/{vid}").json()["placa"] == placa.upper()
    assert http.post("/api/v1/vehiculos", json=datos, headers=GESTOR).status_code == 409
    assert http.post("/api/v1/vehiculos", json=datos, headers={"X-User-Role": "conductor"}).status_code == 403
