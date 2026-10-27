"""Reglas de Fleet que no necesitan base de datos: validación del vehículo y acceso solo vía gateway."""
import os
from datetime import date

import pytest
from pydantic import ValidationError

os.environ.setdefault("DATABASE_URL", "postgresql://ci:ci@localhost:5432/ci")
os.environ.setdefault("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/")
os.environ.setdefault("INTERNAL_TOKEN", "clave-de-prueba")

from fastapi.testclient import TestClient  # noqa: E402

from fleet.main import app  # noqa: E402
from fleet.schemas import VehiculoIn  # noqa: E402

BASE = dict(placa="mtr-909", tipo="camion", marca="Hino 500", capacidad_kg=5000, capacidad_m3=25, anio=2023,
            vencimiento_seguro=date(2027, 6, 30), zona="Montería")


def test_placa_se_normaliza_en_mayusculas():
    assert VehiculoIn(**BASE).placa == "MTR-909"


@pytest.mark.parametrize("cambio", [
    {"placa": "MTR 909"},          # espacio
    {"placa": "MT#909"},           # símbolo
    {"capacidad_kg": 0},           # sin capacidad
    {"anio": 1980},                # demasiado antiguo
    {"zona": "Zona 5"},            # la zona es un nombre, sin números
    {"marca": "12345"},            # solo números
])
def test_rechaza_vehiculos_invalidos(cambio):
    with pytest.raises(ValidationError):
        VehiculoIn(**{**BASE, **cambio})


def test_sin_clave_interna_no_se_puede_saltar_el_gateway():
    cliente = TestClient(app)
    respuesta = cliente.get("/api/v1/vehiculos", headers={"X-User-Role": "admin"})
    assert respuesta.status_code == 401
    assert respuesta.json()["error"] == "no_autenticado"
    assert cliente.get("/health").status_code == 200  # la salud sí es pública
