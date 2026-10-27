"""Ingesta de telemetría: validación de cada lectura GPS y agregación por vehículo."""
import os
import uuid
from datetime import datetime, timedelta, timezone

import pytest
from pydantic import ValidationError

os.environ.setdefault("DATABASE_URL", "postgresql://ci:ci@localhost:5432/ci")
os.environ.setdefault("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/")

from tracking.main import LecturaIn, _agregar, _hash  # noqa: E402

T0 = datetime(2026, 10, 1, 12, 0, tzinfo=timezone.utc)


def lectura(vehiculo, minuto, **extra):
    return LecturaIn(**{"vehiculo_id": vehiculo, "registrado_en": T0 + timedelta(minutes=minuto), "lat": 8.75,
                        "lon": -75.88, "velocidad_kmh": 60, "nivel_combustible": 80, "temperatura_motor_c": 90,
                        "odometro_km": 1000 + minuto, **extra})


@pytest.mark.parametrize("cambio", [{"lat": 95}, {"lon": -181}, {"velocidad_kmh": 300}, {"nivel_combustible": 120}])
def test_rechaza_lecturas_fuera_de_rango(cambio):
    valida = lectura(uuid.uuid4(), 0).model_dump()
    with pytest.raises(ValidationError):
        LecturaIn(**{**valida, **cambio})


def test_normaliza_el_codigo_obd2():
    assert lectura(uuid.uuid4(), 0, codigo_obd2=" p0217 ").codigo_obd2 == "P0217"
    assert lectura(uuid.uuid4(), 0, codigo_obd2="  ").codigo_obd2 is None


def test_agrega_un_resumen_por_vehiculo():
    a, b = uuid.uuid4(), uuid.uuid4()
    lote = [lectura(a, 2, velocidad_kmh=100, codigo_obd2="P0300"), lectura(a, 0, velocidad_kmh=50),
            lectura(b, 1, temperatura_c=5)]
    agregados = {x["vehiculo_id"]: x for x in _agregar(lote)}
    assert len(agregados) == 2
    va = agregados[str(a)]
    assert (va["lecturas"], va["velocidad_max"], va["velocidad_promedio"]) == (2, 100, 75.0)
    assert va["odometro_km"] == 1002 and va["codigos_obd2"] == ["P0300"]  # la última lectura manda
    assert agregados[str(b)]["temperatura_carga_max"] == 5


def test_la_clave_del_dispositivo_no_se_guarda_en_claro():
    assert _hash("clave-secreta") != "clave-secreta" and len(_hash("clave-secreta")) == 64
