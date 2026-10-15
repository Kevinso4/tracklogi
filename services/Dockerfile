# Plantilla única de Dockerfile para todos los microservicios (multi-etapa).
#   docker build --build-arg SERVICE=fleet -t logitrack-fleet ./services
ARG PYTHON_VERSION=3.12

FROM python:${PYTHON_VERSION}-slim AS builder
WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:${PYTHON_VERSION}-slim
ARG SERVICE
ENV SERVICE=${SERVICE} \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONPATH=/app
WORKDIR /app
COPY --from=builder /install /usr/local
# Todo el código de la carpeta (common, el servicio y, en Tracking, el simulador que puede embeber).
# Así la misma imagen se construye en el repositorio de integración y en el repositorio de cada servicio.
COPY . .
RUN useradd --create-home --uid 10001 app
USER app
EXPOSE 8000
CMD ["sh", "-c", "exec uvicorn ${SERVICE}.main:app --host 0.0.0.0 --port 8000 --no-access-log"]
