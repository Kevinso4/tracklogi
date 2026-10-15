# LogiTrack · Fleet Service

Microservicio de **LogiTrack**, plataforma de gestión de flotas y envíos construida con arquitectura de microservicios (Universidad Cooperativa de Colombia – Arquitectura y Modelamiento de Software).

## Responsabilidad

Maestro de vehículos y conductores: capacidades, certificaciones, seguros, zona y estado operativo. Es el catálogo que Shipment consulta para decidir qué camión puede llevar una carga.

### Reglas de negocio

- Un vehículo solo es candidato si está activo y cubre peso, volumen, refrigeración y certificado hazmat de la carga.
- Una alerta crítica de mantenimiento o una avería/accidente saca el vehículo de servicio y publica `vehicle.status_changed` (inicio de la saga de reasignación).
- Solo el gestor de flota cambia estados a mano; placa y número de licencia únicos.
- Al entregar, el camión queda ubicado en la ciudad de destino.

## Lugar en la arquitectura

| | |
|---|---|
| **Publica** | `vehicle.status_changed` |
| **Consume** | `maintenance.alert`, `maintenance.completed`, `shipment.incident`, `shipment.assigned`, `shipment.reassigned`, `shipment.delivered`, `shipment.returned` |
| **REST** | Servidor REST: Shipment le consulta `GET /vehiculos/disponibles` de forma síncrona |
| **Base de datos** | `fleet_db` (PostgreSQL 16) |

Los eventos viajan por RabbitMQ (exchange `logitrack.events`, tipo topic) con reintentos y cola de mensajes fallidos (`.dlq`). Los publica el patrón *outbox* (en la misma transacción que el cambio) y los consumidores son idempotentes.

## Tecnologías

Python 3.12 · FastAPI · SQLAlchemy 2 · Pydantic v2 · PostgreSQL 16 · RabbitMQ (aio-pika) · Docker

## Base de datos

Tablas: `asignaciones`, `conductor_categorias`, `conductores`, `eventos_procesados`, `outbox_eventos`, `vehiculos`.

| Archivo | Contenido |
|---|---|
| [`db/schema.sql`](db/schema.sql) | Script de creación de tablas, índices y restricciones |
| [`db/datos_ejemplo.sql`](db/datos_ejemplo.sql) | Datos de ejemplo (respaldo de la base de demostración) |

El servicio también crea sus tablas al arrancar si no existen. Para restaurar la base a mano:

```bash
createdb fleet_db
psql -d fleet_db -f db/schema.sql
psql -d fleet_db -f db/datos_ejemplo.sql
```

## Instalación y ejecución

### Solo este microservicio (Docker)

```bash
cd services/fleet
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
PYTHONPATH=. uvicorn fleet.main:app --port 8000
```

## Endpoints principales

Todos pasan por el API Gateway (`/api/v1/...`) con un JWT; el rol viaja en `X-User-Role` y cada servicio vuelve a comprobar el permiso.

| Método | Ruta | Para qué |
|---|---|---|
| GET | `/api/v1/vehiculos` | Lista de vehículos (filtros por estado, zona y texto) |
| GET | `/api/v1/vehiculos/disponibles` | Vehículos que cumplen una carga (`zona`, `peso_kg`, `volumen_m3`, `refrigerado`, `hazmat`) |
| GET | `/api/v1/vehiculos/{id}` | Detalle de un vehículo |
| POST | `/api/v1/vehiculos` | Registra un vehículo (gestor de flota) |
| PATCH | `/api/v1/vehiculos/{id}/estado` | Cambia el estado operativo (gestor de flota) |
| GET | `/api/v1/vehiculos/resumen` | Conteo por estado |
| GET | `/api/v1/conductores` | Lista de conductores |
| POST | `/api/v1/conductores` | Registra un conductor |
| GET | `/api/v1/conductores/{id}/disponibilidad` | Si el conductor puede tomar un vehículo |
| POST | `/api/v1/asignaciones` | Asigna un conductor a un vehículo |

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

- Producción (Render): https://tracklogi-fleet.onrender.com — salud en `https://tracklogi-fleet.onrender.com/ready`. En el plan gratuito el servicio se duerme tras 15 min; el primer acceso tarda unos 50 s.
- Las credenciales (`DATABASE_URL`, `RABBITMQ_URL`) se configuran como variables de entorno en Render, nunca en el código.
- Panel web: https://tracklogi.onrender.com

## Equipo

Kevin Ayaso · Keyner Madrid · Juan Vega · Luisa Alzate · Paula Fernández
