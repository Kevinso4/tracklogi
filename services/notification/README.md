# LogiTrack · Notification Service

Microservicio de **LogiTrack**, plataforma de gestión de flotas y envíos construida con arquitectura de microservicios (Universidad Cooperativa de Colombia – Arquitectura y Modelamiento de Software).

## Responsabilidad

Envía el mensaje correcto al destinatario correcto: avisa al cliente por correo de la salida, reasignaciones, incidencias, retrasos y entrega de su envío, y al gestor de flota de las alertas de mantenimiento.

### Reglas de negocio

- Una plantilla por tipo de evento, en español.
- Un correo que falla queda registrado como «fallida» y nunca bloquea al emisor.
- Sin servidor de correo configurado, la notificación se registra como «simulada».

## Lugar en la arquitectura

| | |
|---|---|
| **Publica** | `notification.sent`, `notification.failed` (patrón outbox) |
| **Consume** | `route.assigned`, `shipment.reassigned`, `shipment.incident`, `shipment.delayed`, `shipment.delivered`, `shipment.returned`, `maintenance.alert` |
| **REST** | Cliente SMTP (en local Mailpit; en la nube Mailtrap en modo de pruebas) |
| **Base de datos** | `notification_db` (PostgreSQL 16) |

Los eventos viajan por RabbitMQ (exchange `logitrack.events`, tipo topic) con reintentos y cola de mensajes fallidos (`.dlq`). Los publica el patrón *outbox* (en la misma transacción que el cambio) y los consumidores son idempotentes.

## Tecnologías

Python 3.12 · FastAPI · SQLAlchemy 2 · Pydantic v2 · PostgreSQL 16 · RabbitMQ (aio-pika) · Docker

## Base de datos

Tablas: `eventos_procesados`, `notificaciones`, `outbox_eventos`.

| Archivo | Contenido |
|---|---|
| [`db/schema.sql`](db/schema.sql) | Script de creación de tablas, índices y restricciones |
| [`db/datos_ejemplo.sql`](db/datos_ejemplo.sql) | Datos de ejemplo (respaldo de la base de demostración) |

El servicio también crea sus tablas al arrancar si no existen. Para restaurar la base a mano:

```bash
createdb notification_db
psql -d notification_db -f db/schema.sql
psql -d notification_db -f db/datos_ejemplo.sql
```

## Instalación y ejecución

### Solo este microservicio (Docker)

```bash
cd services/notification
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
PYTHONPATH=. uvicorn notification.main:app --port 8000
```

## Endpoints principales

Todos pasan por el API Gateway (`/api/v1/...`) con un JWT; el rol viaja en `X-User-Role` y cada servicio vuelve a comprobar el permiso.

| Método | Ruta | Para qué |
|---|---|---|
| GET | `/api/v1/notificaciones` | Historial de notificaciones (`envio=` código del envío) |

Además: `GET /health` (vivo) y `GET /ready` (base de datos y bus disponibles).

## Variables de entorno

Ver [`.env.example`](.env.example).

| Variable | Para qué |
|---|---|
| `DATABASE_URL` | Conexión a la base de datos propia del servicio |
| `RABBITMQ_URL` | Conexión a RabbitMQ (bus de eventos) |
| `DB_SCHEMA` | Opcional. Esquema propio cuando varios servicios comparten una instancia (Render) |
| `LOG_LEVEL` | Nivel de los logs JSON |
| `SMTP_HOST` | Servidor de correo. Vacío: notificaciones simuladas |
| `SMTP_PORT` | Puerto SMTP (Mailtrap: 2525) |
| `SMTP_USER` | Usuario SMTP (Mailtrap). Con usuario se usa STARTTLS |
| `SMTP_PASSWORD` | Clave SMTP. Nunca se sube al repositorio |
| `NOTIFICACIONES_REMITENTE` | Remitente de los correos |
| `CORREO_GESTOR` | Destinatario de las alertas de mantenimiento |

## Despliegue

- Producción (Render): https://tracklogi-notification.onrender.com — salud en `https://tracklogi-notification.onrender.com/ready`. En el plan gratuito el servicio se duerme tras 15 min; el primer acceso tarda unos 50 s.
- Las credenciales (`DATABASE_URL`, `RABBITMQ_URL`, `SMTP_PASSWORD`) se configuran como variables de entorno en Render, nunca en el código.
- Panel web: https://tracklogi.onrender.com

## Equipo

Kevin Ayaso · Keyner Madrid · Juan Vega · Luisa Alzate · Paula Fernández
