"""Reglas de Shipment al recibir un envío o un cliente nuevo."""
import os
from datetime import datetime, timedelta, timezone

import pytest
from pydantic import ValidationError

os.environ.setdefault("DATABASE_URL", "postgresql://ci:ci@localhost:5432/ci")
os.environ.setdefault("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/")

from shipment.schemas import ClienteIn, EnvioIn  # noqa: E402

ENVIO = dict(cliente="Distribuidora del Sinú S.A.S.", origen="Montería", destino="Cartagena",
             origen_lat=8.75, origen_lon=-75.88, destino_lat=10.39, destino_lon=-75.48, peso_kg=1200, volumen_m3=8)


def manana():
    return datetime.now(timezone.utc) + timedelta(days=1)


def test_un_envio_valido_se_acepta():
    assert EnvioIn(**ENVIO, fecha_limite_sla=manana()).peso_kg == 1200


@pytest.mark.parametrize("cambio,mensaje", [
    ({"cliente": None}, "Selecciona el cliente"),
    ({"destino": "montería"}, "distintos"),
    ({"fecha_limite_sla": datetime.now(timezone.utc) - timedelta(hours=1)}, "futuro"),
    ({"peso_kg": 0}, None),
    ({"peso_kg": 50000}, None),
])
def test_rechaza_envios_que_rompen_las_reglas(cambio, mensaje):
    with pytest.raises(ValidationError) as e:
        EnvioIn(**{**ENVIO, "fecha_limite_sla": manana(), **cambio})
    assert mensaje is None or mensaje in str(e.value)


def test_el_cliente_exige_nit_valido_y_limpia_el_nombre():
    c = ClienteIn(nombre="  Lácteos   de la Costa  ", nit="800456789-1")
    assert c.nombre == "Lácteos de la Costa"
    for nit in ("abc", "12", "900123456-77"):
        with pytest.raises(ValidationError):
            ClienteIn(nombre="Cliente", nit=nit)
