-- Database per Service: una base de datos independiente por microservicio.
CREATE DATABASE fleet_db;
CREATE DATABASE tracking_db;
CREATE DATABASE shipment_db;
CREATE DATABASE maintenance_db;
CREATE DATABASE notification_db;
CREATE DATABASE billing_db;

-- tracking_db usa la extensión TimescaleDB para la hypertable de posiciones.
\c tracking_db
CREATE EXTENSION IF NOT EXISTS timescaledb;
