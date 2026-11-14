"""Integración: evento shipment.delivered → costo en PostgreSQL → cierre mensual → factura por cliente."""
import asyncio
import os
import uuid

os.environ.setdefault("DATABASE_URL", "postgresql://ci:ci@localhost:5432/ci")
os.environ.setdefault("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/")

from common.pruebas import cliente, evento, preparar_bd  # noqa: E402
from billing.main import al_entregado, app  # noqa: E402

preparar_bd()
OPERADOR = {"X-User-Role": "operador"}


def test_la_entrega_se_costea_y_el_cierre_la_factura():
    nombre = f"Cliente prueba {uuid.uuid4().hex[:8]}"
    http = cliente(app)
    assert http.put(f"/api/v1/facturacion/tarifas/{nombre}", json={"modelo": "por_km", "valor": 5000},
                    headers=OPERADOR).status_code == 200
    ev = evento("shipment.delivered", {"envio_id": str(uuid.uuid4()), "codigo": "LT-PRB01", "cliente": nombre,
                                       "origen": "Montería", "destino": "Cartagena", "distancia_km": 245.0,
                                       "origen_lat": 8.75, "origen_lon": -75.88, "destino_lat": 10.39,
                                       "destino_lon": -75.48, "a_tiempo": True})
    asyncio.run(al_entregado(ev))
    asyncio.run(al_entregado(ev))  # duplicado: no se cobra dos veces

    costos = http.get("/api/v1/facturacion/costos", params={"cliente": nombre}, headers=OPERADOR).json()
    assert len(costos) == 1 and costos[0]["precio_cliente"] == 245 * 5000
    assert http.get("/api/v1/facturacion/costos", headers={"X-User-Role": "conductor"}).status_code == 403

    facturas = http.post("/api/v1/facturacion/cierre", headers=OPERADOR).json()
    mia = next(f for f in facturas if f["cliente"] == nombre)
    assert (mia["envios"], mia["monto_total"]) == (1, 245 * 5000)
    assert http.get("/api/v1/facturacion/costos", params={"cliente": nombre},
                    headers=OPERADOR).json()[0]["factura_id"] == mia["id"]
