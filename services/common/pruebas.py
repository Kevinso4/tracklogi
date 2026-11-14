"""Ayudas para las pruebas de integración: endpoint + lógica + PostgreSQL real (RabbitMQ se simula).

Sin base de datos la prueba se salta en local; en CI (variable CI=true) es obligatoria y falla.
"""
import os
import uuid
from datetime import datetime, timezone

import pytest
from fastapi.testclient import TestClient

from .db import Base, db_ok, engine, esperar_db
from .seguridad import CABECERA_INTERNA


def exigir(disponible: bool, que: str) -> None:
    if not disponible:
        if os.getenv("CI"):
            raise RuntimeError(f"En CI la prueba de integración necesita {que}")
        pytest.skip(f"Sin {que} de pruebas", allow_module_level=True)


def preparar_bd() -> None:
    exigir(db_ok(), "PostgreSQL")
    esperar_db(1)  # crea el esquema propio si se usa DB_SCHEMA
    Base.metadata.create_all(engine)


def cliente(app) -> TestClient:
    """Cliente HTTP contra la app real, sin ejecutar su arranque (no conecta a RabbitMQ)."""
    return TestClient(app, headers=CABECERA_INTERNA)


def evento(tipo: str, datos: dict) -> dict:
    return {"event_id": str(uuid.uuid4()), "tipo": tipo, "origen": "pruebas",
            "ocurrido_en": datetime.now(timezone.utc).isoformat(), "datos": datos}
