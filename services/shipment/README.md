# LogiTrack · Shipment Service

[![CI-CD](https://github.com/Kevinso4/logitrack-shipment/actions/workflows/deploy.yml/badge.svg)](https://github.com/Kevinso4/logitrack-shipment/actions/workflows/deploy.yml)

Microservicio de **LogiTrack**, plataforma de gestión de flotas y envíos construida con arquitectura de microservicios (Universidad Cooperativa de Colombia – Arquitectura y Modelamiento de Software).

## Responsabilidad

Núcleo transaccional: gobierna el ciclo de vida del envío (pendiente → en tránsito → entregado / devuelto) y su cadena de custodia inmutable. También gestiona los clientes que contratan los envíos.

### Reglas de negocio

- Responde 201 al instante y asigna el vehículo en segundo plano; `Idempotency-Key` evita envíos duplicados.
- Transiciones de estado controladas (p. ej. solo se entrega lo que está en tránsito o con incidencia).
- Saga: si el camión sale de servicio busca otro; si no hay, compensa dejando el envío retrasado. Reintenta cada 15 s.
- Cada envío pertenece a un cliente registrado y activo; NIT y nombre únicos; un cliente con envíos no se borra, se desactiva.
- El seguimiento público por código no muestra datos del cliente ni placas.

## Lugar en la arquitectura

| | |
|---|---|
| **Publica** | `shipment.created`, `shipment.assigned`, `shipment.reassigned`, `shipment.incident`, `shipment.delayed`, `shipment.delivered`, `shipment.returned` (patrón outbox) |
| **Consume** | `vehicle.status_changed` (saga de reasignación), `route.assigned`, `route.recalculated` (ETA y km reales) |
| **REST** | Cliente REST de Fleet (`/vehiculos/disponibles`) con reintentos y circuit breaker |
| **Base de datos** | `shipment_db` (PostgreSQL 16) |

Los eventos viajan por RabbitMQ (exchange `logitrack.events`, tipo topic) con reintentos y cola de mensajes fallidos (`.dlq`). Los publica el patrón *outbox* (en la misma transacción que el cambio) y los consumidores son idempotentes.

## Tecnologías

Python 3.12 · FastAPI · SQLAlchemy 2 · Pydantic v2 · PostgreSQL 16 · RabbitMQ (aio-pika) · Docker

## Base de datos

Tablas: `clientes`, `envios`, `eventos_envio`, `eventos_procesados`, `outbox_eventos`, `pruebas_entrega`.

| Archivo | Contenido |
|---|---|
| [`db/schema.sql`](db/schema.sql) | Script de creación de tablas, índices y restricciones |
| [`db/datos_ejemplo.sql`](db/datos_ejemplo.sql) | Datos de ejemplo (respaldo de la base de demostración) |

El servicio también crea sus tablas al arrancar si no existen. Para restaurar la base a mano:

```bash
createdb shipment_db
psql -d shipment_db -f db/schema.sql
psql -d shipment_db -f db/datos_ejemplo.sql
```

## Instalación y ejecución

### Solo este microservicio (Docker)

```bash
cd services/shipment
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
PYTHONPATH=. uvicorn shipment.main:app --port 8000
```

### Pruebas automáticas

```bash
cd services
pip install -r requirements.txt pytest
PYTHONPATH=. python -m pytest shipment/tests
```

Son las mismas que ejecuta el pipeline de CI antes de publicar la imagen y desplegar.

## Endpoints principales

Todos pasan por el API Gateway (`/api/v1/...`) con un JWT; el rol viaja en `X-User-Role` y cada servicio vuelve a comprobar el permiso.

| Método | Ruta | Para qué |
|---|---|---|
| POST | `/api/v1/envios` | Crea un envío (operador; admite `Idempotency-Key`) |
| GET | `/api/v1/envios` | Lista con filtros (`estado`, `q`) |
| GET | `/api/v1/envios/{id}` | Detalle con cadena de custodia y prueba de entrega |
| GET | `/api/v1/envios/{id}/historial` | Cadena de custodia |
| POST | `/api/v1/envios/{id}/incidencia` | Reporta una incidencia (inicia la saga si es avería) |
| POST | `/api/v1/envios/{id}/prueba-entrega` | Registra la entrega |
| POST | `/api/v1/envios/{id}/reanudar · /devolucion · /asignar` | Resto del ciclo de vida |
| GET | `/api/v1/envios/seguimiento/{codigo}` | Seguimiento público, sin sesión |
| GET · POST | `/api/v1/clientes` | Lista (`q`, `solo_activos`) y registro de clientes |
| PUT · DELETE | `/api/v1/clientes/{id}` | Edita o elimina un cliente (solo si no tiene envíos) |

Además: `GET /health` (vivo) y `GET /ready` (base de datos y bus disponibles).

## Variables de entorno

Ver [`.env.example`](.env.example).

| Variable | Para qué |
|---|---|
| `DATABASE_URL` | Conexión a la base de datos propia del servicio |
| `RABBITMQ_URL` | Conexión a RabbitMQ (bus de eventos) |
| `DB_SCHEMA` | Opcional. Esquema propio cuando varios servicios comparten una instancia (Render) |
| `LOG_LEVEL` | Nivel de los logs JSON |
| `FLEET_URL` | Dirección interna de Fleet |

## Despliegue

- Producción (Render): https://tracklogi-shipment.onrender.com — salud en `https://tracklogi-shipment.onrender.com/ready`. En el plan gratuito el servicio se duerme tras 15 min; el primer acceso tarda unos 50 s.
- Las credenciales (`DATABASE_URL`, `RABBITMQ_URL`) se configuran como variables de entorno en Render, nunca en el código.
- Panel web: https://tracklogi.onrender.com- **CI/CD (GitHub Actions):** `.github/workflows/deploy.yml` invoca el pipeline reutilizable de [logitrack-pipelines](https://github.com/Kevinso4/logitrack-pipelines). En cada push a `main`: **test** (lint, pytest, pip-audit, gitleaks) → **docker** (imagen `ghcr.io/kevinso4/logitrack-shipment` etiquetada con el SHA del commit) → **deploy** (deploy hook de Render, guardado en el secret `RENDER_DEPLOY_HOOK`). Si una prueba falla, no se publica ni se despliega nada; un pull request solo ejecuta las pruebas.

## Equipo

Kevin Ayaso · Keyner Madrid · Juan Vega · Luisa Alzate · Paula Fernández
