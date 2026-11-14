"""Integración: evento shipment.delivered → plantilla → notificación en PostgreSQL → API (sin duplicados)."""
import asyncio
import os

os.environ.setdefault("DATABASE_URL", "postgresql://ci:ci@localhost:5432/ci")
os.environ.setdefault("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/")
os.environ.pop("SMTP_HOST", None)  # sin servidor de correo: la notificación queda «simulada»

import random  # noqa: E402

from common.pruebas import cliente, evento, preparar_bd  # noqa: E402
from notification.main import al_evento, app  # noqa: E402

preparar_bd()


def test_la_entrega_genera_un_correo_al_cliente_una_sola_vez():
    codigo = f"LT-{random.randint(10000, 99999)}"
    ev = evento("shipment.delivered", {"codigo": codigo, "cliente": "Lácteos de la Costa S.A.",
                                       "cliente_email": "despachos@lacteoscosta.co",
                                       "origen": "Montería", "destino": "Sincelejo"})
    asyncio.run(al_evento(ev))
    asyncio.run(al_evento(ev))  # RabbitMQ entrega el mismo evento dos veces

    enviadas = cliente(app).get("/api/v1/notificaciones", params={"envio": codigo}).json()
    assert len(enviadas) == 1
    n = enviadas[0]
    assert (n["destinatario"], n["estado"], n["tipo_evento"]) == ("despachos@lacteoscosta.co", "simulada",
                                                                  "shipment.delivered")
    assert codigo in n["asunto"] + n["cuerpo"]
