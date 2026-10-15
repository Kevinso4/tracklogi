# LogiTrack · Tracking Ingestion Service

Microservicio de **LogiTrack**, plataforma de gestión de flotas y envíos construida con arquitectura de microservicios (Universidad Cooperativa de Colombia – Arquitectura y Modelamiento de Software).

## Responsabilidad

Recibe, valida y normaliza la telemetría GPS de los dispositivos de los camiones y la publica en el bus sin analizarla. Es el servicio de mayor caudal; guarda las lecturas en una hypertable de TimescaleDB.

### Reglas de negocio

- Cada dispositivo envía con su API key; solo se guarda su huella SHA-256.
- Se rechazan coordenadas, velocidades, combustible o temperaturas fuera de rango.
- Lecturas repetidas (mismo vehículo e instante) no se duplican.
- Con `SIMULADOR=true` el contenedor también ejecuta el simulador GPS (camiones recorriendo la ruta real).

## Lugar en la arquitectura

| | |
|---|---|
| **Publica** | `telemetry.raw` (resumen de cada lote), `telemetry.aggregated` (un agregado por vehículo) |
| **Consume** | — |
| **REST** | Servidor REST de ingesta (los dispositivos se autentican con `X-Device-Key`) |
| **Base de datos** | `tracking_db` (PostgreSQL 16 + TimescaleDB) |

Los eventos viajan por RabbitMQ (exchange `logitrack.events`, tipo topic) con reintentos y cola de mensajes fallidos (`.dlq`). Los publica el patrón *outbox* (en la misma transacción que el cambio) y los consumidores son idempotentes.

## Tecnologías

Python 3.12 · FastAPI · SQLAlchemy 2 · Pydantic v2 · PostgreSQL 16 · RabbitMQ (aio-pika) · Docker

## Base de datos

Tablas: `posiciones`, `dispositivos`, `eventos_procesados`, `outbox_eventos`.

| Archivo | Contenido |
|---|---|
| [`db/schema.sql`](db/schema.sql) | Script de creación de tablas, índices y restricciones |
| [`db/datos_ejemplo.sql`](db/datos_ejemplo.sql) | Datos de ejemplo (respaldo de la base de demostración) |

El servicio también crea sus tablas al arrancar si no existen. Para restaurar la base a mano:

```bash
createdb tracking_db
psql -d tracking_db -f db/schema.sql
psql -d tracking_db -f db/datos_ejemplo.sql
```

## Instalación y ejecución

### Solo este microservicio (Docker)

```bash
cd services/tracking
docker compose up --build
```

Levanta su PostgreSQL ya restaurado con los datos de ejemplo, RabbitMQ y el servicio en http://localhost:8000 (documentación interactiva en `/docs`). Usa `PUERTO=8100 docker compose up` si el 8000 está ocupado.

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
PYTHONPATH=. uvicorn tracking.main:app --port 8000
```

## Endpoints principales

Todos pasan por el API Gateway (`/api/v1/...`) con un JWT; el rol viaja en `X-User-Role` y cada servicio vuelve a comprobar el permiso.

| Método | Ruta | Para qué |
|---|---|---|
| POST | `/api/v1/telemetria` | Lote de lecturas GPS de un dispositivo (`X-Device-Key`) |
| GET | `/api/v1/telemetria/ultimas` | Última posición de cada vehículo (mapa) |
| GET | `/api/v1/telemetria/{vehiculo_id}/ultima` | Última lectura de un vehículo |
| GET | `/api/v1/telemetria/{vehiculo_id}/recorrido` | Recorrido entre `desde` y `hasta` |
| GET | `/api/v1/telemetria/estadisticas` | Lecturas recibidas y vehículos reportando |
| POST | `/api/v1/dispositivos` | Registra un dispositivo y entrega su API key |

Además: `GET /health` (vivo) y `GET /ready` (base de datos y bus disponibles).

## Variables de entorno

Ver [`.env.example`](.env.example).

| Variable | Para qué |
|---|---|
| `DATABASE_URL` | Conexión a la base de datos propia del servicio |
| `RABBITMQ_URL` | Conexión a RabbitMQ (bus de eventos) |
| `DB_SCHEMA` | Opcional. Esquema propio cuando varios servicios comparten una instancia (Render) |
| `LOG_LEVEL` | Nivel de los logs JSON |
| `SIMULADOR` | true: ejecuta el simulador GPS dentro del mismo contenedor |
| `SIMULADOR_MINUTOS_ACTIVIDAD` | Minutos que el simulador sigue activo tras la última visita |

## Despliegue

- Producción (Render): https://tracklogi-tracking.onrender.com — salud en `https://tracklogi-tracking.onrender.com/ready`. En el plan gratuito el servicio se duerme tras 15 min; el primer acceso tarda unos 50 s.
- Las credenciales (`DATABASE_URL`, `RABBITMQ_URL`) se configuran como variables de entorno en Render, nunca en el código.
- Panel web: https://tracklogi.onrender.com

## Equipo

Kevin Ayaso · Keyner Madrid · Juan Vega · Luisa Alzate · Paula Fernández
