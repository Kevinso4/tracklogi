# LogiTrack · Routing Service

[![CI-CD](https://github.com/Kevinso4/logitrack-routing/actions/workflows/deploy.yml/badge.svg)](https://github.com/Kevinso4/logitrack-routing/actions/workflows/deploy.yml)

Microservicio de **LogiTrack**, plataforma de gestión de flotas y envíos construida con arquitectura de microservicios (Universidad Cooperativa de Colombia – Arquitectura y Modelamiento de Software).

## Responsabilidad

Calcula la ruta real por carretera de cada envío, su distancia y la hora estimada de llegada (ETA), y la recalcula al reasignar el envío. Concentra la dependencia del proveedor de mapas.

### Reglas de negocio

- Usa OSRM (OpenStreetMap) para trazar la ruta por carretera: los camiones no cruzan el mar.
- Si el proveedor falla, el circuit breaker se abre y se usa una ruta «estimada»: el envío nunca se bloquea.
- Cada 30 s reconcilia envíos en tránsito que aún no tienen ruta.
- Guarda el historial de recálculos de cada envío.

## Lugar en la arquitectura

| | |
|---|---|
| **Publica** | `route.assigned`, `route.recalculated` (patrón outbox) |
| **Consume** | `shipment.assigned`, `shipment.reassigned`, `shipment.delivered`, `shipment.returned` |
| **REST** | Cliente REST de OSRM (API externa de geolocalización) con circuit breaker; consulta a Shipment para reconciliar |
| **Base de datos** | `routing_db` (PostgreSQL 16) |

Los eventos viajan por RabbitMQ (exchange `logitrack.events`, tipo topic) con reintentos y cola de mensajes fallidos (`.dlq`). Los publica el patrón *outbox* (en la misma transacción que el cambio) y los consumidores son idempotentes.

## Tecnologías

Python 3.12 · FastAPI · SQLAlchemy 2 · Pydantic v2 · PostgreSQL 16 · RabbitMQ (aio-pika) · Docker

## Base de datos

Tablas: `eventos_procesados`, `historial_rutas`, `outbox_eventos`, `rutas`.

| Archivo | Contenido |
|---|---|
| [`db/schema.sql`](db/schema.sql) | Script de creación de tablas, índices y restricciones |
| [`db/datos_ejemplo.sql`](db/datos_ejemplo.sql) | Datos de ejemplo (respaldo de la base de demostración) |

El servicio también crea sus tablas al arrancar si no existen. Para restaurar la base a mano:

```bash
createdb routing_db
psql -d routing_db -f db/schema.sql
psql -d routing_db -f db/datos_ejemplo.sql
```

## Instalación y ejecución

### Solo este microservicio (Docker)

```bash
cd services/routing
docker compose up --build
```

Levanta su PostgreSQL ya restaurado con los datos de ejemplo, RabbitMQ y el servicio en http://localhost:8000 (documentación interactiva en `/docs`). Usa `PUERTO=8100 docker compose up` si el 8000 está ocupado.

> Este servicio colabora con otros por REST; solo, funciona pero esas llamadas fallan de forma controlada (circuit breaker). Para el flujo completo usa el sistema entero.

### Sistema completo

Desde la raíz del repositorio de integración [Kevinso4/tracklogi](https://github.com/Kevinso4/tracklogi):

```bash
docker compose up --build
```

### Sin Docker

```bash
cd services
pip install -r requirements.txt
# define las variables de .env.example apuntando a tu PostgreSQL y RabbitMQ
PYTHONPATH=. uvicorn routing.main:app --port 8000
```

### Pruebas automáticas

```bash
cd services
pip install -r requirements.txt pytest
PYTHONPATH=. python -m pytest routing/tests
```

Son las mismas que ejecuta el pipeline de CI antes de publicar la imagen y desplegar.

## Endpoints principales

Todos pasan por el API Gateway (`/api/v1/...`) con un JWT; el rol viaja en `X-User-Role` y cada servicio vuelve a comprobar el permiso.

| Método | Ruta | Para qué |
|---|---|---|
| GET | `/api/v1/rutas` | Rutas activas (geometría para el mapa) |
| GET | `/api/v1/rutas/{envio_id}` | Ruta de un envío |
| GET | `/api/v1/rutas/{envio_id}/eta` | Hora estimada de llegada |
| GET | `/api/v1/rutas/{envio_id}/historial` | Cálculos y recálculos de la ruta |

Además: `GET /health` (vivo) y `GET /ready` (base de datos y bus disponibles).

## Variables de entorno

Ver [`.env.example`](.env.example).

| Variable | Para qué |
|---|---|
| `DATABASE_URL` | Conexión a la base de datos propia del servicio |
| `RABBITMQ_URL` | Conexión a RabbitMQ (bus de eventos) |
| `DB_SCHEMA` | Opcional. Esquema propio cuando varios servicios comparten una instancia (Render) |
| `LOG_LEVEL` | Nivel de los logs JSON |
| `OSRM_URL` | Proveedor de rutas (API externa) |
| `SHIPMENT_URL` | Dirección interna de Shipment (reconciliación) |

## Despliegue

- Producción (Render): https://tracklogi-routing.onrender.com — salud en `https://tracklogi-routing.onrender.com/ready`. En el plan gratuito el servicio se duerme tras 15 min; el primer acceso tarda unos 50 s.
- Las credenciales (`DATABASE_URL`, `RABBITMQ_URL`) se configuran como variables de entorno en Render, nunca en el código.
- Panel web: https://tracklogi.onrender.com- **CI/CD (GitHub Actions):** `.github/workflows/deploy.yml` invoca el pipeline reutilizable de [logitrack-pipelines](https://github.com/Kevinso4/logitrack-pipelines). En cada push a `main`: **test** (lint, pytest, pip-audit, gitleaks) → **docker** (imagen `ghcr.io/kevinso4/logitrack-routing` etiquetada con el SHA del commit) → **deploy** (deploy hook de Render, guardado en el secret `RENDER_DEPLOY_HOOK`). Si una prueba falla, no se publica ni se despliega nada; un pull request solo ejecuta las pruebas.

## Equipo

Kevin Ayaso · Keyner Madrid · Juan Vega · Luisa Alzate · Paula Fernández
