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
-- Name: estado_alerta; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.estado_alerta AS ENUM (
    'abierta',
    'cerrada'
);


--
-- Name: estado_programa; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.estado_programa AS ENUM (
    'programado',
    'completado'
);


--
-- Name: metrica; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.metrica AS ENUM (
    'temperatura_motor',
    'nivel_combustible',
    'velocidad',
    'temperatura_carga',
    'codigo_obd2'
);


--
-- Name: operador_regla; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.operador_regla AS ENUM (
    'mayor',
    'menor',
    'presente'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alertas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alertas (
    id uuid NOT NULL,
    vehiculo_id uuid NOT NULL,
    regla_id uuid NOT NULL,
    metrica public.metrica NOT NULL,
    valor character varying(40) NOT NULL,
    mensaje character varying(250) NOT NULL,
    prioridad smallint NOT NULL,
    estado public.estado_alerta NOT NULL,
    creada_en timestamp with time zone NOT NULL,
    cerrada_en timestamp with time zone
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
-- Name: intervenciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.intervenciones (
    id uuid NOT NULL,
    vehiculo_id uuid NOT NULL,
    programa_id uuid,
    descripcion text NOT NULL,
    realizado_en timestamp with time zone NOT NULL,
    costo numeric(12,2) NOT NULL,
    taller character varying(120) NOT NULL,
    km_al_servicio integer NOT NULL
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
-- Name: programas_mantenimiento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.programas_mantenimiento (
    id uuid NOT NULL,
    vehiculo_id uuid NOT NULL,
    tipo character varying(80) NOT NULL,
    fecha_prevista date NOT NULL,
    km_previsto integer,
    prioridad smallint NOT NULL,
    estado public.estado_programa NOT NULL,
    creado_en timestamp with time zone NOT NULL
);


--
-- Name: reglas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reglas (
    id uuid NOT NULL,
    nombre character varying(120) NOT NULL,
    tipo_vehiculo character varying(20),
    metrica public.metrica NOT NULL,
    operador public.operador_regla NOT NULL,
    umbral numeric(10,2) NOT NULL,
    prioridad smallint NOT NULL,
    activa boolean NOT NULL
);


--
-- Name: ultimas_lecturas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ultimas_lecturas (
    vehiculo_id uuid NOT NULL,
    odometro_km numeric(10,1) NOT NULL,
    temperatura_motor_max numeric(5,2) NOT NULL,
    nivel_combustible numeric(5,2) NOT NULL,
    actualizado_en timestamp with time zone NOT NULL
);


--
-- Name: outbox_eventos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outbox_eventos ALTER COLUMN id SET DEFAULT nextval('public.outbox_eventos_id_seq'::regclass);


--
-- Name: alertas alertas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alertas
    ADD CONSTRAINT alertas_pkey PRIMARY KEY (id);


--
-- Name: eventos_procesados eventos_procesados_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_procesados
    ADD CONSTRAINT eventos_procesados_pkey PRIMARY KEY (event_id);


--
-- Name: intervenciones intervenciones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervenciones
    ADD CONSTRAINT intervenciones_pkey PRIMARY KEY (id);


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
-- Name: programas_mantenimiento programas_mantenimiento_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programas_mantenimiento
    ADD CONSTRAINT programas_mantenimiento_pkey PRIMARY KEY (id);


--
-- Name: reglas reglas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reglas
    ADD CONSTRAINT reglas_pkey PRIMARY KEY (id);


--
-- Name: ultimas_lecturas ultimas_lecturas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ultimas_lecturas
    ADD CONSTRAINT ultimas_lecturas_pkey PRIMARY KEY (vehiculo_id);


--
-- Name: idx_alerta_vehiculo_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_alerta_vehiculo_estado ON public.alertas USING btree (vehiculo_id, estado);


--
-- Name: idx_prog_vehiculo_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prog_vehiculo_estado ON public.programas_mantenimiento USING btree (vehiculo_id, estado);


--
-- Name: ix_intervenciones_vehiculo_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_intervenciones_vehiculo_id ON public.intervenciones USING btree (vehiculo_id);


--
-- Name: ix_outbox_eventos_publicado_en; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_outbox_eventos_publicado_en ON public.outbox_eventos USING btree (publicado_en);


--
-- Name: alertas alertas_regla_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alertas
    ADD CONSTRAINT alertas_regla_id_fkey FOREIGN KEY (regla_id) REFERENCES public.reglas(id);


--
-- Name: intervenciones intervenciones_programa_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervenciones
    ADD CONSTRAINT intervenciones_programa_id_fkey FOREIGN KEY (programa_id) REFERENCES public.programas_mantenimiento(id);


--
-- PostgreSQL database dump complete
--


