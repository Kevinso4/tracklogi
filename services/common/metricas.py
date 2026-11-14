"""Métricas Prometheus comunes a todos los servicios (endpoint /metrics).

- Disponibilidad: la da Prometheus con `up` al leer /metrics de cada servicio.
- Peticiones, tiempos de respuesta y errores: middleware HTTP, etiquetado por servicio, método,
  plantilla de ruta (/api/v1/envios/{envio_id}, no cada id) y código de estado.
- Negocio: eventos publicados y procesados por tipo (los cuenta el bus).
"""
import time

from fastapi import FastAPI, Request
from fastapi.responses import Response
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

PETICIONES = Counter("logitrack_http_peticiones_total", "Peticiones HTTP atendidas",
                     ["servicio", "metodo", "ruta", "estado"])
DURACION = Histogram("logitrack_http_duracion_segundos", "Tiempo de respuesta HTTP",
                     ["servicio", "metodo", "ruta"],
                     buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10))
EVENTOS_PUBLICADOS = Counter("logitrack_eventos_publicados_total", "Eventos publicados en RabbitMQ", ["servicio", "tipo"])
EVENTOS_PROCESADOS = Counter("logitrack_eventos_procesados_total", "Eventos consumidos de RabbitMQ",
                             ["servicio", "tipo", "resultado"])  # resultado: ok | dlq


def instrumentar(app: FastAPI, servicio: str) -> None:
    @app.middleware("http")
    async def medir(request: Request, call_next):
        if request.url.path == "/metrics":
            return await call_next(request)
        inicio = time.perf_counter()
        estado = 500
        try:
            respuesta = await call_next(request)
            estado = respuesta.status_code
            return respuesta
        finally:
            ruta = getattr(request.scope.get("route"), "path", "sin_ruta")  # plantilla: pocas series
            DURACION.labels(servicio, request.method, ruta).observe(time.perf_counter() - inicio)
            PETICIONES.labels(servicio, request.method, ruta, str(estado)).inc()

    @app.get("/metrics", include_in_schema=False)
    def metricas() -> Response:
        return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
