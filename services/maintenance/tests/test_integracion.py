"""Integración: evento telemetry.aggregated → motor de reglas → alerta en PostgreSQL → API de alertas."""
import asyncio
import os
import uuid

os.environ.setdefault("DATABASE_URL", "postgresql://ci:ci@localhost:5432/ci")
os.environ.setdefault("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/")

from sqlalchemy import select  # noqa: E402

from common.db import SessionLocal  # noqa: E402
from common.outbox import OutboxEvento  # noqa: E402
from common.pruebas import cliente, evento, preparar_bd  # noqa: E402
from maintenance.main import al_telemetria, app, sembrar_reglas  # noqa: E402

preparar_bd()
sembrar_reglas()


def test_un_motor_recalentado_abre_una_sola_alerta_y_programa_el_preventivo():
    vid = str(uuid.uuid4())
    datos = {"vehiculo_id": vid, "odometro_km": 12500, "temperatura_motor_max": 130, "nivel_combustible": 70,
             "velocidad_max": 60, "temperatura_carga_max": None, "codigos_obd2": []}
    ev = evento("telemetry.aggregated", datos)
    asyncio.run(al_telemetria(ev))
    asyncio.run(al_telemetria(ev))                                     # mismo evento repetido: se descarta
    asyncio.run(al_telemetria(evento("telemetry.aggregated", datos)))  # nueva lectura: la alerta sigue abierta

    alertas = cliente(app).get("/api/v1/mantenimiento/alertas", params={"vehiculo_id": vid}).json()
    assert len(alertas) == 1 and alertas[0]["metrica"] == "temperatura_motor"
    programas = cliente(app).get(f"/api/v1/mantenimiento/vehiculo/{vid}/programa").json()["programas"]
    assert [p["km_previsto"] for p in programas] == [20000]  # próximo múltiplo de 10 000 km

    with SessionLocal() as db:
        tipos = list(db.scalars(select(OutboxEvento.tipo).where(OutboxEvento.payload["vehiculo_id"].astext == vid)))
    assert sorted(tipos) == ["maintenance.alert", "maintenance.scheduled"]
