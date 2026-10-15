# LogiTrack · Microservicios

Implementación funcional del **Momento 2** sobre la arquitectura definida en
*LogiTrack — Arquitectura de Microservicios y Estrategia DevOps* (Momento 1).

- **Aplicación desplegada:** https://tracklogi.onrender.com — `operador` / `operador123` (envíos y facturación) o
  `gestor` / `gestor123` (flota y mantenimiento)
  (los servicios gratuitos de Render se duermen: el primer acceso puede tardar hasta un minuto).
- **Explicación sencilla del sistema:** [docs/LogiTrack_Explicado_Facil.docx](docs/LogiTrack_Explicado_Facil.docx)

## Repositorios y despliegue de cada microservicio

Este es el repositorio de **integración** (compose del sistema completo, panel web y despliegue). Cada
microservicio tiene además su propio repositorio, con su historial, su README, su `.env.example`, su
`docker-compose.yml` para ejecutarlo solo y su base de datos (`db/schema.sql` y `db/datos_ejemplo.sql`).
Se generan desde aquí con `bash infra/repos/publicar.sh`.

| Microservicio | Repositorio | Despliegue (backend) | Base de datos |
|---|---|---|---|
| API Gateway | [logitrack-gateway](https://github.com/Kevinso4/logitrack-gateway) | https://tracklogi-gateway.onrender.com | — (Redis) |
| Fleet | [logitrack-fleet](https://github.com/Kevinso4/logitrack-fleet) | https://tracklogi-fleet.onrender.com | [`fleet_db`](services/fleet/db) |
| Tracking | [logitrack-tracking](https://github.com/Kevinso4/logitrack-tracking) | https://tracklogi-tracking.onrender.com | [`tracking_db`](services/tracking/db) |
| Shipment | [logitrack-shipment](https://github.com/Kevinso4/logitrack-shipment) | https://tracklogi-shipment.onrender.com | [`shipment_db`](services/shipment/db) |
| Maintenance | [logitrack-maintenance](https://github.com/Kevinso4/logitrack-maintenance) | https://tracklogi-maintenance.onrender.com | [`maintenance_db`](services/maintenance/db) |
| Routing | [logitrack-routing](https://github.com/Kevinso4/logitrack-routing) | https://tracklogi-routing.onrender.com | [`routing_db`](services/routing/db) |
| Notification | [logitrack-notification](https://github.com/Kevinso4/logitrack-notification) | https://tracklogi-notification.onrender.com | [`notification_db`](services/notification/db) |
| Billing | [logitrack-billing](https://github.com/Kevinso4/logitrack-billing) | https://tracklogi-billing.onrender.com | [`billing_db`](services/billing/db) |

Cada enlace de despliegue responde `/health`, `/ready` (conexión a su base y a RabbitMQ) y `/docs`
(documentación interactiva). Las credenciales se configuran como variables de entorno en Render, nunca
en el código, y los microservicios solo aceptan peticiones que llegan por el API Gateway. Integraciones
externas: OSRM (rutas por carretera), OpenFreeMap (mapa) y Mailtrap en modo de pruebas (correos).

| Pieza | Tecnología | Base de datos | Publica | Consume |
|---|---|---|---|---|
| **API Gateway** | FastAPI · JWT RS256 · Redis | — (Redis para rate limit y sesiones) | — | `#` (feed en vivo para el panel) |
| **Fleet Service** | FastAPI · SQLAlchemy | `fleet_db` | `vehicle.status_changed` | `maintenance.alert`, `maintenance.completed`, `shipment.incident`, `shipment.assigned`, `shipment.reassigned`, `shipment.delivered`, `shipment.returned` |
| **Tracking Ingestion** | FastAPI async | `tracking_db` (TimescaleDB, hypertable 7 días) | `telemetry.raw`, `telemetry.aggregated` | — |
| **Shipment Service** | FastAPI · SQLAlchemy · Outbox | `shipment_db` | `shipment.created/assigned/reassigned/incident/delayed/delivered/returned` | `vehicle.status_changed` |
| **Maintenance Service** | FastAPI · motor de reglas | `maintenance_db` | `maintenance.alert/scheduled/completed` | `telemetry.aggregated` |
| **Notification Service** | FastAPI · SMTP | `notification_db` | `notification.sent/failed` | `shipment.*` (asignado, retrasado, entregado…), `maintenance.alert` |
| **Billing Service** | FastAPI | `billing_db` | `invoice.issued` | `shipment.delivered` |
| **Routing Service** | FastAPI · OSRM (OpenStreetMap) | `routing_db` | `route.assigned/recalculated` | `shipment.assigned/reassigned/delivered/returned` |
| **Frontend** | Next.js 15 · TypeScript · Tailwind · MapLibre GL | — | — | vía Gateway (REST + SSE) |

Infraestructura: **PostgreSQL 16 + TimescaleDB**, **RabbitMQ** (exchange topic + DLQ por cola), **Redis**, todo en Docker.
Además hay un `simulator` que actúa como los dispositivos GPS embarcados (no es parte de la arquitectura de producción).

```
                 ┌──────────── Frontend (Next.js, :3000) ────────────┐
                 │            REST + JWT          SSE (eventos)      │
                 └────────────────────┬──────────────────────────────┘
                                      ▼
                         API Gateway :8000  ── Redis (rate limit, refresh tokens)
                  ┌──────────┬────────┴─────┬──────────────┐
                  ▼          ▼              ▼              ▼
               Fleet     Tracking       Shipment      Maintenance
              fleet_db  tracking_db    shipment_db   maintenance_db
                  ▲          │    REST  │  ▲               ▲  │
                  └──────────┼──────────┘  │               │  │
                             ▼             │               │  ▼
               ════════════ RabbitMQ · exchange "logitrack.events" (topic) ════════════
                             ▲
                       simulator (dispositivos IoT)
```

## Cómo ejecutarlo

Requisitos: **Docker Desktop** y **Node.js 20+**.

```bash
# 1. Backend completo (Postgres, RabbitMQ, Redis, gateway, 4 microservicios y simulador)
docker compose up --build -d

# 2. Frontend
cd frontend
npm install
npm run dev
```

| URL | Qué es |
|---|---|
| http://localhost:3000 | Panel de operaciones |
| http://localhost:3000/seguimiento | Seguimiento público de envíos (sin sesión) |
| http://localhost:8000/docs | Swagger del API Gateway |
| http://localhost:15672 | Consola de RabbitMQ (`logitrack` / `logitrack`) |
| http://localhost:8025 | Mailpit: correos que envía Notification |

Usuarios de demostración:

| Usuario | Gestiona | Solo consulta |
|---|---|---|
| `operador` / `operador123` | Envíos, clientes y facturación | — |
| `gestor` / `gestor123` | Flota y mantenimiento | — |
| `admin` / `admin123` | Todo | — |

Mínimo privilegio: cada perfil solo ve en el menú los apartados de su área (Resumen y Seguimiento son
comunes), y Clientes y Facturación están bloqueados también en el backend para quien no sea operador o
admin. El operador no entra a Flota: el formulario *Nuevo envío* le indica cuántos camiones libres
cumplen la carga.

**Gestión de clientes** (`/clientes`, dentro de Shipment): alta, edición, desactivación y borrado (solo
si no tiene envíos) con NIT y nombre únicos. Cada envío se crea para un cliente registrado y toma de él
el correo al que Notification avisa; la tarifa pactada se guarda en Billing. Comprobación automática:
`python services/shipment/check_clientes.py`.

Comandos útiles:

```bash
docker compose ps                      # estado y health checks
docker compose logs -f shipment fleet  # logs JSON de un servicio
docker compose down                    # detener (conserva datos)
docker compose down -v                 # detener y borrar las bases de datos
```

## Guion de demostración (cómo se conectan los servicios)

1. **Flujo feliz — REST + eventos** (sección 05, diagrama de secuencia)
   En *Envíos → Nuevo envío* crea un envío Montería → Cartagena. Shipment guarda el envío **y** la fila
   de outbox en la misma transacción y responde 201 al instante. En segundo plano consulta a Fleet por REST
   (`GET /vehiculos/disponibles`), asigna un vehículo y publica `shipment.assigned`; Fleet lo consume y
   cambia el vehículo a *En tránsito*. En *Seguimiento* verás el vehículo moverse hacia el destino.

2. **Saga de avería con reasignación** (sección 05, patrón Saga)
   Abre el envío y usa *Reportar incidencia → Avería*. Cadena: `shipment.incident` → Fleet marca el
   vehículo *Fuera de servicio* → `vehicle.status_changed` → Shipment busca otro vehículo (REST a Fleet)
   → `shipment.reassigned`. Todo queda en la *cadena de custodia* y en el feed *Actividad en vivo*.

3. **Compensación de la saga**
   Si no hay vehículo alternativo (p. ej. un envío refrigerado de 5 t cuando todos los refrigerados están
   ocupados), Shipment compensa: el envío pasa a *Retrasado* y publica `shipment.delayed`. Cada 15 s
   reintenta la asignación, así que al liberarse un vehículo el envío sale solo.

4. **Mantenimiento predictivo**
   El simulador inyecta de vez en cuando un sobrecalentamiento o un código OBD2. Tracking publica
   `telemetry.aggregated` → Maintenance evalúa sus reglas → `maintenance.alert` (crítica) → Fleet pasa el
   vehículo a *Mantenimiento* → si llevaba carga, Shipment la reasigna. En *Mantenimiento → Atender* se
   registra la intervención → `maintenance.completed` → Fleet lo devuelve a *Disponible*.
   Para forzarlo en la demo: sube `PROB_ANOMALIA` en `docker-compose.yml` o baja el umbral de una regla
   desde la pestaña *Reglas*.

5. **Resiliencia**
   `docker compose stop fleet` y crea un envío: Shipment responde igual (201) y lo deja *Pendiente*;
   el circuit breaker del gateway se abre tras 5 fallos. `docker compose start fleet` y el envío se asigna
   solo en el siguiente reintento. Los eventos esperan en RabbitMQ; ninguno se pierde.

## Correspondencia con el documento de arquitectura

| Decisión del documento | Dónde está en el código |
|---|---|
| Database per Service | Una BD por servicio en `infra/postgres/init.sql`; ninguna FK cruza servicios (columnas `(externo)`) |
| Patrón Outbox | `services/common/outbox.py` (`registrar_evento` + `publicador_outbox`) |
| Idempotencia de consumidores | `@idempotente` deduplica por `event_id` en `eventos_procesados`; `Idempotency-Key` en `POST /envios` |
| DLQ | `services/common/bus.py`: cada cola declara `<cola>.dlq`; 3 reintentos con backoff antes de enviarla |
| REST síncrono solo en el camino crítico | Shipment → Fleet (`GET /vehiculos/disponibles`) con timeout 2 s, 3 reintentos con jitter y circuit breaker (`common/cliente_http.py`) |
| Saga coreografiada + compensación | `services/shipment/main.py` → `al_cambio_estado_vehiculo` |
| Gateway: JWT RS256, rate limit por rol, CORS por lista blanca, formato único de error | `services/gateway/main.py`, `services/gateway/auth.py`, `services/common/errores.py` |
| Refresh tokens rotativos en cookie HttpOnly SameSite=Strict | `POST /api/v1/auth/refresh` (reutilizar uno ya usado revoca la sesión) |
| Argon2id para contraseñas | `services/gateway/auth.py` |
| RBAC dentro de cada servicio | `services/common/seguridad.py` (`requiere_rol`) |
| TimescaleDB, hypertable de 7 días | `services/tracking/main.py` → `preparar_timescale` |
| Dispositivos IoT con API key (solo se guarda el SHA-256) | `POST /api/v1/dispositivos`, cabecera `X-Device-Key` |
| Auditoría de solo inserción | `eventos_envio`, `intervenciones` |
| Logs JSON con `request_id`, `shipment_id`, `vehicle_id` | `services/common/logs.py` |
| `/health` y `/ready` | `services/common/app.py` |
| Dockerfile multi-etapa único | `services/Dockerfile` (`--build-arg SERVICE=...`) |
| Un workflow de CI/CD por servicio con `paths:` | `.github/workflows/*.yml` |

### Simplificaciones de este entregable (y por qué)

- **Routing calcula la ruta, Shipment asigna el vehículo**: el documento pone ambas cosas en Routing. Aquí
  Shipment elige el vehículo consultando a Fleet por REST y Routing calcula la ruta real por carretera (OSRM),
  la distancia y el ETA. Si el proveedor de mapas no responde, se abre el circuito y se usa una ruta estimada.
  Routing además reconcilia cada 30 s los envíos en tránsito que hayan quedado sin ruta.
- **Mapa**: MapLibre GL (fork abierto de Mapbox GL JS, misma API) con teselas de OpenFreeMap, para no
  depender de un token de Mapbox. Con un token basta cambiar `NEXT_PUBLIC_MAP_STYLE`.
- **Usuarios**: cuentas de demostración en memoria dentro del gateway (no hay servicio de usuarios en el alcance).
- **Esquema**: `create_all` al arrancar en lugar de migraciones Alembic.
- **Una sola instancia de Postgres** con 4 bases de datos en local; en Render serían instancias separadas.

## Estructura

```
logitrack/
├── docker-compose.yml
├── infra/postgres/init.sql          # crea las 4 bases de datos + extensión TimescaleDB
├── services/
│   ├── Dockerfile                   # plantilla única multi-etapa
│   ├── requirements.txt
│   ├── common/                      # bus, outbox, errores, logs, RBAC, cliente HTTP con circuit breaker
│   ├── gateway/  fleet/  tracking/  shipment/  maintenance/
│   └── simulator/                   # dispositivos GPS simulados
├── frontend/                        # Next.js 15 (App Router) + Tailwind
└── .github/workflows/               # CI/CD por servicio
```
