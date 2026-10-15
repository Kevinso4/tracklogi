#!/usr/bin/env bash
# Regenera services/<servicio>/db/schema.sql y datos_ejemplo.sql desde el Postgres local de docker compose.
#   bash infra/postgres/exportar_bd.sh
set -euo pipefail
cd "$(dirname "$0")/../.."

pg() { docker compose exec -T postgres "$@"; }
# Tablas de mensajería interna (outbox e idempotencia): son operativas, no datos de ejemplo.
SIN_DATOS=(--exclude-table-data=outbox_eventos --exclude-table-data=eventos_procesados)

for s in fleet tracking shipment maintenance routing notification billing; do
  mkdir -p "services/$s/db"
  # -n public: solo las tablas del servicio (deja fuera el catálogo interno de TimescaleDB).
  pg pg_dump -U logitrack -d "${s}_db" -n public --schema-only --no-owner --no-privileges \
    | grep -Ev "_timescaledb|ts_insert_blocker|^CREATE SCHEMA public;|^COMMENT ON SCHEMA public" > "services/$s/db/schema.sql"
  extra=()
  [ "$s" = tracking ] && extra=(--exclude-table-data=posiciones)  # 20 000+ lecturas GPS: se toma una muestra abajo
  pg pg_dump -U logitrack -d "${s}_db" -n public --data-only --inserts --no-owner --no-privileges \
    "${SIN_DATOS[@]}" "${extra[@]}" > "services/$s/db/datos_ejemplo.sql"
done

# Muestra de telemetría: las 300 lecturas más recientes.
{
  echo "-- Muestra de las 300 lecturas GPS más recientes"
  pg psql -U logitrack -d tracking_db -tA -c \
    "SELECT format('INSERT INTO public.posiciones SELECT * FROM json_populate_record(NULL::public.posiciones, %L);', row_to_json(p))
       FROM (SELECT * FROM posiciones ORDER BY registrado_en DESC LIMIT 300) p"
} >> services/tracking/db/datos_ejemplo.sql

# \restrict solo lo entiende psql 16.10+; sin esa línea el archivo restaura en cualquier Postgres 16.
sed -i -E '/^\\(un)?restrict /d' services/*/db/*.sql
wc -l services/*/db/*.sql
