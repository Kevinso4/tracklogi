"""Integración: evento shipment.assigned → cálculo de ruta (OSRM simulado) → PostgreSQL → API de rutas."""
import asyncio
import os
import uuid

import httpx

os.environ.setdefault("DATABASE_URL", "postgresql://ci:ci@localhost:5432/ci")
os.environ.setdefault("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/")

import routing.main as servicio  # noqa: E402
from common.pruebas import cliente, evento, preparar_bd  # noqa: E402

preparar_bd()


def test_asignar_un_envio_traza_su_ruta_y_reasignarlo_la_recalcula(monkeypatch):
    osrm = {"code": "Ok", "routes": [{"distance": 245_000, "duration": 3 * 3600,
                                      "geometry": {"coordinates": [[-75.88, 8.75], [-75.6, 9.5], [-75.48, 10.39]]}}]}
    monkeypatch.setattr(servicio.osrm, "get", lambda url, **_: httpx.Response(
        200, json=osrm, request=httpx.Request("GET", url)))
    envio_id = str(uuid.uuid4())
    datos = {"envio_id": envio_id, "codigo": "LT-PRUEBA", "origen": "Montería", "destino": "Cartagena",
             "origen_lat": 8.75, "origen_lon": -75.88, "destino_lat": 10.39, "destino_lon": -75.48,
             "vehiculo_id": str(uuid.uuid4()), "placa": "ABC-123"}

    asyncio.run(servicio.al_asignar(evento("shipment.assigned", datos)))
    ruta = cliente(servicio.app).get(f"/api/v1/rutas/{envio_id}").json()
    assert (ruta["distancia_km"], ruta["proveedor"], ruta["placa"]) == (245.0, "osrm", "ABC-123")

    asyncio.run(servicio.al_asignar(evento("shipment.reassigned", {**datos, "placa": "XYZ-987"})))
    historial = cliente(servicio.app).get(f"/api/v1/rutas/{envio_id}/historial")
    assert historial.status_code == 200 and "Cambio de vehículo" in historial.text
    assert cliente(servicio.app).get(f"/api/v1/rutas/{envio_id}").json()["placa"] == "XYZ-987"
