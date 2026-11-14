"""Integración: login → sesión en Redis → proxy autenticado al servicio → rotación del refresh token.

Redis es real; el microservicio de destino se simula para ver qué cabeceras le llegan.
"""
import os
from unittest.mock import AsyncMock

import httpx
import pytest
import redis
import redis.asyncio as aioredis

os.environ.setdefault("REDIS_URL", "redis://localhost:6379/0")
os.environ.setdefault("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/")
os.environ.setdefault("INTERNAL_TOKEN", "clave-de-prueba")

from fastapi.testclient import TestClient  # noqa: E402

import gateway.main as gw  # noqa: E402
from common.pruebas import exigir  # noqa: E402
from gateway.auth import decodificar  # noqa: E402

REDIS = redis.Redis.from_url(os.environ["REDIS_URL"], decode_responses=True)
try:
    exigir(REDIS.ping(), "Redis")
except redis.RedisError:
    exigir(False, "Redis")


@pytest.fixture
def http(monkeypatch):
    recibidas = []

    def servicio(peticion: httpx.Request) -> httpx.Response:
        recibidas.append(peticion)
        return httpx.Response(200, json=[{"codigo": "LT-00001"}])

    monkeypatch.setattr(gw, "redis", aioredis.from_url(os.environ["REDIS_URL"], decode_responses=True))
    monkeypatch.setattr(gw, "http", httpx.AsyncClient(transport=httpx.MockTransport(servicio)))
    for metodo in ("conectar", "suscribir_efimera", "cerrar"):  # sin RabbitMQ
        monkeypatch.setattr(gw.bus, metodo, AsyncMock())
    with TestClient(gw.app) as cliente:
        cliente.recibidas = recibidas
        yield cliente


def test_login_proxy_y_rotacion_de_sesion(http):
    assert http.post("/api/v1/auth/token", json={"usuario": "operador", "clave": "mala"}).status_code == 401
    r = http.post("/api/v1/auth/token", json={"usuario": "operador", "clave": "operador123"})
    assert r.status_code == 200
    refresh = decodificar(http.cookies["lt_refresh"], "refresh")
    assert REDIS.get(f"refresh:{refresh['jti']}") == refresh["familia"]  # la sesión vive en Redis

    assert http.get("/api/v1/envios").status_code == 401  # sin token no pasa
    envios = http.get("/api/v1/envios", headers={"Authorization": f"Bearer {r.json()['access_token']}"})
    assert envios.status_code == 200 and envios.json() == [{"codigo": "LT-00001"}]
    enviada = http.recibidas[-1]
    assert str(enviada.url).endswith("/api/v1/envios")
    assert enviada.headers["x-user-role"] == "operador"
    assert enviada.headers["x-internal-token"] == os.environ["INTERNAL_TOKEN"]

    viejo = http.cookies["lt_refresh"]
    assert http.post("/api/v1/auth/refresh").status_code == 200   # rota: el refresh anterior deja de valer
    assert not REDIS.exists(f"refresh:{refresh['jti']}")
    http.cookies.set("lt_refresh", viejo, path="/api/v1/auth")
    assert http.post("/api/v1/auth/refresh").json()["error"] == "sesion_revocada"  # reutilizarlo revoca la sesión
