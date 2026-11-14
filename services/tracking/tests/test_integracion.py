"""Integración: alta de dispositivo → ingesta con su clave → posiciones en PostgreSQL → consulta."""
import os
import uuid
from datetime import datetime, timedelta, timezone
from unittest.mock import AsyncMock

os.environ.setdefault("DATABASE_URL", "postgresql://ci:ci@localhost:5432/ci")
os.environ.setdefault("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/")

from common.pruebas import cliente, preparar_bd  # noqa: E402
from tracking.main import app  # noqa: E402

preparar_bd()


def test_un_dispositivo_registrado_envia_telemetria_y_se_consulta():
    vid = str(uuid.uuid4())
    app.state.bus.publicar = AsyncMock()  # RabbitMQ simulado: se comprueba qué se publicaría
    http = cliente(app)

    clave = http.post("/api/v1/dispositivos", json={"vehiculo_id": vid}, headers={"X-User-Role": "gestor_flota"})
    assert clave.status_code == 201, clave.text
    t0 = datetime.now(timezone.utc) - timedelta(seconds=30)
    lote = {"lecturas": [{"vehiculo_id": vid, "registrado_en": (t0 + timedelta(seconds=i * 10)).isoformat(),
                          "lat": 8.75, "lon": -75.88, "velocidad_kmh": 50 + i, "nivel_combustible": 80,
                          "temperatura_motor_c": 90, "odometro_km": 1000 + i} for i in range(3)]}

    assert http.post("/api/v1/telemetria", json=lote, headers={"X-Device-Key": "clave-falsa"}).status_code == 401
    r = http.post("/api/v1/telemetria", json=lote, headers={"X-Device-Key": clave.json()["api_key"]})
    assert r.status_code == 202 and r.json() == {"aceptadas": 3}
    # Reenvío del mismo lote (modo offline): no duplica lecturas
    http.post("/api/v1/telemetria", json=lote, headers={"X-Device-Key": clave.json()["api_key"]})

    ultima = http.get(f"/api/v1/telemetria/{vid}/ultima").json()
    assert ultima["velocidad_kmh"] == 52 and ultima["odometro_km"] == 1002
    assert len(http.get(f"/api/v1/telemetria/{vid}/recorrido").json()) == 3
    tipos = [c.args[0] for c in app.state.bus.publicar.call_args_list]
    assert tipos.count("telemetry.aggregated") == 2
