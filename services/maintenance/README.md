# LogiTrack · Maintenance Service

[![CI-CD](https://github.com/Kevinso4/logitrack-maintenance/actions/workflows/deploy.yml/badge.svg)](https://github.com/Kevinso4/logitrack-maintenance/actions/workflows/deploy.yml)

Microservicio de **LogiTrack**, plataforma de gestión de flotas y envíos construida con arquitectura de microservicios (Universidad Cooperativa de Colombia – Arquitectura y Modelamiento de Software).

## Responsabilidad

Programa el mantenimiento preventivo y alerta sobre anomalías (temperatura del motor, códigos OBD2, combustible) antes de que se conviertan en averías en ruta. Trabaja solo con los eventos de telemetría: nunca lee la base de Tracking.

### Reglas de negocio

- Reglas configurables por métrica con umbral y severidad; no repite una alerta abierta del mismo tipo.
- Programa el siguiente mantenimiento por kilómetros o por días, lo que ocurra primero.
- Una alerta crítica saca el camión de servicio (Fleet); registrar la intervención lo devuelve.

## Lugar en la arquitectura

| | |
|---|---|
| **Publica** | `maintenance.alert`, `maintenance.scheduled`, `maintenance.completed` (patrón outbox) |
| **Consume** | `telemetry.aggregated` |
| **REST** | Servidor REST de consulta y registro |
| **Base de datos** | `maintenance_db` (PostgreSQL 16) |

Los eventos viajan por RabbitMQ (exchange `logitrack.events`, tipo topic) con reintentos y cola de mensajes fallidos (`.dlq`). Los publica el patrón *outbox* (en la misma transacción que el cambio) y los consumidores son idempotentes.

## Tecnologías

Python 3.12 · FastAPI · SQLAlchemy 2 · Pydantic v2 · PostgreSQL 16 · RabbitMQ (aio-pika) · Docker

## Base de datos

Tablas: `alertas`, `eventos_procesados`, `intervenciones`, `outbox_eventos`, `programas_mantenimiento`, `reglas`, `ultimas_lecturas`.

| Archivo | Contenido |
|---|---|
| [`db/schema.sql`](db/schema.sql) | Script de creación de tablas, índices y restricciones |
| [`db/datos_ejemplo.sql`](db/datos_ejemplo.sql) | Datos de ejemplo (respaldo de la base de demostración) |

El servicio también crea sus tablas al arrancar si no existen. Para restaurar la base a mano:

```bash
createdb maintenance_db
psql -d maintenance_db -f db/schema.sql
psql -d maintenance_db -f db/datos_ejemplo.sql
```

## Instalación y ejecución

### Solo este microservicio (Docker)

```bash
cd services/maintenance
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
PYTHONPATH=. uvicorn maintenance.main:app --port 8000
```

### Pruebas automáticas

```bash
cd services
pip install -r requirements.txt pytest
PYTHONPATH=. python -m pytest maintenance/tests
```

Son las mismas que ejecuta el pipeline de CI antes de publicar la imagen y desplegar.

## Endpoints principales

Todos pasan por el API Gateway (`/api/v1/...`) con un JWT; el rol viaja en `X-User-Role` y cada servicio vuelve a comprobar el permiso.

| Método | Ruta | Para qué |
|---|---|---|
| GET | `/api/v1/mantenimiento/alertas` | Alertas (`estado=abierta`) |
| POST | `/api/v1/mantenimiento/alertas/{id}/cerrar` | Cierra una alerta |
| GET | `/api/v1/mantenimiento/proximos` | Mantenimientos de los próximos `dias` (90 por defecto) |
| GET | `/api/v1/mantenimiento/vehiculo/{id}/programa` | Programa de un vehículo |
| POST | `/api/v1/mantenimiento/programas` | Crea un programa preventivo |
| GET · POST | `/api/v1/mantenimiento/intervenciones` | Historial y registro de intervenciones |
| GET · POST · PATCH | `/api/v1/mantenimiento/reglas` | Reglas de anomalía |

Además: `GET /health` (vivo) y `GET /ready` (base de datos y bus disponibles).

## Variables de entorno

Ver [`.env.example`](.env.example).

| Variable | Para qué |
|---|---|
| `DATABASE_URL` | Conexión a la base de datos propia del servicio |
| `RABBITMQ_URL` | Conexión a RabbitMQ (bus de eventos) |
| `DB_SCHEMA` | Opcional. Esquema propio cuando varios servicios comparten una instancia (Render) |
| `LOG_LEVEL` | Nivel de los logs JSON |

## Despliegue

- Producción (Render): https://tracklogi-maintenance.onrender.com — salud en `https://tracklogi-maintenance.onrender.com/ready`. En el plan gratuito el servicio se duerme tras 15 min; el primer acceso tarda unos 50 s.
- Las credenciales (`DATABASE_URL`, `RABBITMQ_URL`) se configuran como variables de entorno en Render, nunca en el código.
- Panel web: https://tracklogi.onrender.com- **CI/CD (GitHub Actions):** `.github/workflows/deploy.yml` invoca el pipeline reutilizable de [logitrack-pipelines](https://github.com/Kevinso4/logitrack-pipelines). En cada push a `main`: **test** (lint, pytest, pip-audit, gitleaks) → **docker** (imagen `ghcr.io/kevinso4/logitrack-maintenance` etiquetada con el SHA del commit) → **deploy** (deploy hook de Render, guardado en el secret `RENDER_DEPLOY_HOOK`). Si una prueba falla, no se publica ni se despliega nada; un pull request solo ejecuta las pruebas.

## Equipo

Kevin Ayaso · Keyner Madrid · Juan Vega · Luisa Alzate · Paula Fernández
