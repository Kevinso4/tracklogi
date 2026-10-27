# LogiTrack · Billing Service

[![CI-CD](https://github.com/Kevinso4/logitrack-billing/actions/workflows/deploy.yml/badge.svg)](https://github.com/Kevinso4/logitrack-billing/actions/workflows/deploy.yml)

Microservicio de **LogiTrack**, plataforma de gestión de flotas y envíos construida con arquitectura de microservicios (Universidad Cooperativa de Colombia – Arquitectura y Modelamiento de Software).

## Responsabilidad

Consolida el costo real de cada envío entregado (combustible, peajes y conductor sobre los km reales de Routing) y emite la factura mensual de cada cliente según su tarifa pactada.

### Reglas de negocio

- Tarifa por km o por envío pactada por cliente; los demás usan la tarifa general.
- UNIQUE(cliente, periodo): un mes no se factura dos veces; el cierre suma lo pendiente.
- Un mismo envío no genera dos costos (consumidor idempotente).
- La información financiera solo la ven el operador y el administrador.

## Lugar en la arquitectura

| | |
|---|---|
| **Publica** | `invoice.issued` (patrón outbox) |
| **Consume** | `shipment.delivered` |
| **REST** | Servidor REST de consulta y cierre mensual |
| **Base de datos** | `billing_db` (PostgreSQL 16) |

Los eventos viajan por RabbitMQ (exchange `logitrack.events`, tipo topic) con reintentos y cola de mensajes fallidos (`.dlq`). Los publica el patrón *outbox* (en la misma transacción que el cambio) y los consumidores son idempotentes.

## Tecnologías

Python 3.12 · FastAPI · SQLAlchemy 2 · Pydantic v2 · PostgreSQL 16 · RabbitMQ (aio-pika) · Docker

## Base de datos

Tablas: `costos_envio`, `eventos_procesados`, `facturas`, `outbox_eventos`, `tarifas_cliente`.

| Archivo | Contenido |
|---|---|
| [`db/schema.sql`](db/schema.sql) | Script de creación de tablas, índices y restricciones |
| [`db/datos_ejemplo.sql`](db/datos_ejemplo.sql) | Datos de ejemplo (respaldo de la base de demostración) |

El servicio también crea sus tablas al arrancar si no existen. Para restaurar la base a mano:

```bash
createdb billing_db
psql -d billing_db -f db/schema.sql
psql -d billing_db -f db/datos_ejemplo.sql
```

## Instalación y ejecución

### Solo este microservicio (Docker)

```bash
cd services/billing
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
PYTHONPATH=. uvicorn billing.main:app --port 8000
```

### Pruebas automáticas

```bash
cd services
pip install -r requirements.txt pytest
PYTHONPATH=. python -m pytest billing/tests
```

Son las mismas que ejecuta el pipeline de CI antes de publicar la imagen y desplegar.

## Endpoints principales

Todos pasan por el API Gateway (`/api/v1/...`) con un JWT; el rol viaja en `X-User-Role` y cada servicio vuelve a comprobar el permiso.

| Método | Ruta | Para qué |
|---|---|---|
| GET | `/api/v1/facturacion/costos` | Costo y precio de cada envío entregado |
| GET | `/api/v1/facturacion/facturas` | Facturas emitidas |
| POST | `/api/v1/facturacion/cierre` | Cierre del mes: una factura por cliente |
| GET | `/api/v1/facturacion/resumen` | Ingresos, costos, margen y costo por km |
| GET | `/api/v1/facturacion/tarifas` | Tarifa general y tarifas pactadas |
| PUT | `/api/v1/facturacion/tarifas/{cliente}` | Fija la tarifa de un cliente |

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

- Producción (Render): https://tracklogi-billing.onrender.com — salud en `https://tracklogi-billing.onrender.com/ready`. En el plan gratuito el servicio se duerme tras 15 min; el primer acceso tarda unos 50 s.
- Las credenciales (`DATABASE_URL`, `RABBITMQ_URL`) se configuran como variables de entorno en Render, nunca en el código.
- Panel web: https://tracklogi.onrender.com- **CI/CD (GitHub Actions):** `.github/workflows/deploy.yml` invoca el pipeline reutilizable de [logitrack-pipelines](https://github.com/Kevinso4/logitrack-pipelines). En cada push a `main`: **test** (lint, pytest, pip-audit, gitleaks) → **docker** (imagen `ghcr.io/kevinso4/logitrack-billing` etiquetada con el SHA del commit) → **deploy** (deploy hook de Render, guardado en el secret `RENDER_DEPLOY_HOOK`). Si una prueba falla, no se publica ni se despliega nada; un pull request solo ejecuta las pruebas.

## Equipo

Kevin Ayaso · Keyner Madrid · Juan Vega · Luisa Alzate · Paula Fernández
