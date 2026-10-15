--
-- PostgreSQL database dump
--


-- Dumped from database version 16.15
-- Dumped by pg_dump version 16.15

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--



--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--



--
-- Name: estado_vehiculo; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.estado_vehiculo AS ENUM (
    'activo',
    'en_transito',
    'en_mantenimiento',
    'fuera_de_servicio'
);


--
-- Name: tipo_vehiculo; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.tipo_vehiculo AS ENUM (
    'furgon',
    'camion',
    'tractomula',
    'van'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: asignaciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asignaciones (
    id uuid NOT NULL,
    vehiculo_id uuid NOT NULL,
    conductor_id uuid NOT NULL,
    desde timestamp with time zone NOT NULL,
    hasta timestamp with time zone
);


--
-- Name: conductor_categorias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conductor_categorias (
    conductor_id uuid NOT NULL,
    categoria character varying(4) NOT NULL
);


--
-- Name: conductores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conductores (
    id uuid NOT NULL,
    nombre character varying(120) NOT NULL,
    numero_licencia character varying(30) NOT NULL,
    telefono character varying(20),
    certificacion_hazmat boolean NOT NULL,
    horas_conducidas_semana numeric(5,2) NOT NULL
);


--
-- Name: eventos_procesados; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eventos_procesados (
    event_id uuid NOT NULL,
    tipo character varying(60) NOT NULL,
    procesado_en timestamp with time zone NOT NULL
);


--
-- Name: outbox_eventos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.outbox_eventos (
    id bigint NOT NULL,
    event_id uuid NOT NULL,
    agregado_id character varying(64) NOT NULL,
    tipo character varying(60) NOT NULL,
    payload jsonb NOT NULL,
    creado_en timestamp with time zone NOT NULL,
    publicado_en timestamp with time zone
);


--
-- Name: outbox_eventos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.outbox_eventos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: outbox_eventos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.outbox_eventos_id_seq OWNED BY public.outbox_eventos.id;


--
-- Name: vehiculos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehiculos (
    id uuid NOT NULL,
    placa character varying(10) NOT NULL,
    tipo public.tipo_vehiculo NOT NULL,
    marca character varying(60) NOT NULL,
    capacidad_kg numeric(10,2) NOT NULL,
    capacidad_m3 numeric(8,2) NOT NULL,
    anio smallint NOT NULL,
    vencimiento_seguro date NOT NULL,
    estado public.estado_vehiculo NOT NULL,
    refrigerado boolean NOT NULL,
    certificado_hazmat boolean NOT NULL,
    zona character varying(60) NOT NULL,
    creado_en timestamp with time zone NOT NULL,
    actualizado_en timestamp with time zone NOT NULL,
    CONSTRAINT ck_capacidad_kg CHECK ((capacidad_kg > (0)::numeric)),
    CONSTRAINT ck_capacidad_m3 CHECK ((capacidad_m3 > (0)::numeric))
);


--
-- Name: outbox_eventos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outbox_eventos ALTER COLUMN id SET DEFAULT nextval('public.outbox_eventos_id_seq'::regclass);


--
-- Name: asignaciones asignaciones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asignaciones
    ADD CONSTRAINT asignaciones_pkey PRIMARY KEY (id);


--
-- Name: conductor_categorias conductor_categorias_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conductor_categorias
    ADD CONSTRAINT conductor_categorias_pkey PRIMARY KEY (conductor_id, categoria);


--
-- Name: conductores conductores_numero_licencia_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conductores
    ADD CONSTRAINT conductores_numero_licencia_key UNIQUE (numero_licencia);


--
-- Name: conductores conductores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conductores
    ADD CONSTRAINT conductores_pkey PRIMARY KEY (id);


--
-- Name: eventos_procesados eventos_procesados_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_procesados
    ADD CONSTRAINT eventos_procesados_pkey PRIMARY KEY (event_id);


--
-- Name: outbox_eventos outbox_eventos_event_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outbox_eventos
    ADD CONSTRAINT outbox_eventos_event_id_key UNIQUE (event_id);


--
-- Name: outbox_eventos outbox_eventos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outbox_eventos
    ADD CONSTRAINT outbox_eventos_pkey PRIMARY KEY (id);


--
-- Name: vehiculos vehiculos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehiculos
    ADD CONSTRAINT vehiculos_pkey PRIMARY KEY (id);


--
-- Name: vehiculos vehiculos_placa_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehiculos
    ADD CONSTRAINT vehiculos_placa_key UNIQUE (placa);


--
-- Name: idx_asig_vigente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_asig_vigente ON public.asignaciones USING btree (vehiculo_id, hasta);


--
-- Name: idx_veh_estado_tipo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_veh_estado_tipo ON public.vehiculos USING btree (estado, tipo, refrigerado);


--
-- Name: ix_outbox_eventos_publicado_en; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_outbox_eventos_publicado_en ON public.outbox_eventos USING btree (publicado_en);


--
-- Name: ix_vehiculos_zona; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_vehiculos_zona ON public.vehiculos USING btree (zona);


--
-- Name: asignaciones asignaciones_conductor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asignaciones
    ADD CONSTRAINT asignaciones_conductor_id_fkey FOREIGN KEY (conductor_id) REFERENCES public.conductores(id);


--
-- Name: asignaciones asignaciones_vehiculo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asignaciones
    ADD CONSTRAINT asignaciones_vehiculo_id_fkey FOREIGN KEY (vehiculo_id) REFERENCES public.vehiculos(id);


--
-- Name: conductor_categorias conductor_categorias_conductor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conductor_categorias
    ADD CONSTRAINT conductor_categorias_conductor_id_fkey FOREIGN KEY (conductor_id) REFERENCES public.conductores(id);


--
-- PostgreSQL database dump complete
--


