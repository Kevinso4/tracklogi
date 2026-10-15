# LogiTrack · API Gateway

Microservicio de **LogiTrack**, plataforma de gestión de flotas y envíos construida con arquitectura de microservicios (Universidad Cooperativa de Colombia – Arquitectura y Modelamiento de Software).

## Responsabilidad

Único punto de entrada público del sistema: autentica (JWT RS256), aplica límites de tráfico por rol (Redis), enruta cada petición al microservicio que corresponde y normaliza los errores. También transmite al panel los eventos del bus en vivo (SSE).

## Lugar en la arquitectura

| | |
|---|---|
| **Publica** | — |
| **Consume** | todos los eventos (solo para el feed en vivo del panel) |
| **REST** | REST hacia todos los microservicios internos (timeout, sin lógica de negocio) |
| **Base de datos** | No tiene: usa Redis |

Los eventos viajan por RabbitMQ (exchange `logitrack.events`, tipo topic) con reintentos y cola de mensajes fallidos (`.dlq`). Los publica el patrón *outbox* (en la misma transacción que el cambio) y los consumidores son idempotentes.

## Tecnologías

Python 3.12 · FastAPI · SQLAlchemy 2 · Pydantic v2 · PostgreSQL 16 · RabbitMQ (aio-pika) · Docker

## Instalación y ejecución

### Solo este microservicio (Docker)

```bash
cd services/gateway
docker compose up --build
```

Levanta Redis, RabbitMQ y el servicio en http://localhost:8000 (documentación interactiva en `/docs`). Usa `PUERTO=8100 docker compose up` si el 8000 está ocupado.

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
PYTHONPATH=. uvicorn gateway.main:app --port 8000
```

## Endpoints principales

Todos pasan por el API Gateway (`/api/v1/...`) con un JWT; el rol viaja en `X-User-Role` y cada servicio vuelve a comprobar el permiso.

| Método | Ruta | Para qué |
|---|---|---|
| POST | `/api/v1/auth/token` | Inicia sesión; devuelve access token y deja el refresh en cookie HttpOnly |
| POST | `/api/v1/auth/refresh` | Renueva el access token (refresh rotativo) |
| POST | `/api/v1/auth/logout` | Cierra la sesión |
| GET | `/api/v1/estado/servicios` | Salud de cada microservicio, RabbitMQ y Redis |
| GET | `/api/v1/eventos/stream` | Eventos del sistema en vivo (Server-Sent Events) |
| ANY | `/api/v1/{vehiculos|envios|clientes|telemetria|mantenimiento|rutas|notificaciones|facturacion}/**` | Proxy hacia el microservicio dueño del recurso |
| GET | `/health · /ready` | Vida y disponibilidad |

Además: `GET /health` (vivo) y `GET /ready` (base de datos y bus disponibles).

## Variables de entorno

Ver [`.env.example`](.env.example).

| Variable | Para qué |
|---|---|
| `RABBITMQ_URL` | Conexión a RabbitMQ (bus de eventos) |
| `REDIS_URL` | Redis para el rate limiting y los refresh tokens |
| `JWT_PRIVATE_KEY` | Clave privada RSA (PEM) para firmar los JWT. Vacía: se genera una temporal |
| `JWT_ACCESS_MINUTOS` | Vida del access token |
| `JWT_REFRESH_DIAS` | Vida del refresh token |
| `CORS_ORIGINS` | Orígenes permitidos (separados por coma) |
| `COOKIE_SECURE` | true en producción (HTTPS) |
| `PROXY_TIMEOUT_S` | Tiempo máximo de espera de un microservicio |
| `FLEET_URL` | Dirección interna de Fleet |
| `TRACKING_URL` | Dirección interna de Tracking |
| `SHIPMENT_URL` | Dirección interna de Shipment |
| `MAINTENANCE_URL` | Dirección interna de Maintenance |
| `ROUTING_URL` | Dirección interna de Routing |
| `NOTIFICATION_URL` | Dirección interna de Notification |
| `BILLING_URL` | Dirección interna de Billing |
| `LOG_LEVEL` | Nivel de los logs JSON |

## Despliegue

- Producción (Render): https://tracklogi-gateway.onrender.com — salud en `https://tracklogi-gateway.onrender.com/ready`. En el plan gratuito el servicio se duerme tras 15 min; el primer acceso tarda unos 50 s.
- Las credenciales (`DATABASE_URL`, `RABBITMQ_URL`) se configuran como variables de entorno en Render, nunca en el código.
- Panel web: https://tracklogi.onrender.com

## Equipo

Kevin Ayaso · Keyner Madrid · Juan Vega · Luisa Alzate · Paula Fernández
