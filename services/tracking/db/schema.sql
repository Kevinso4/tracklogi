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



SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: posiciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.posiciones (
    vehiculo_id uuid NOT NULL,
    registrado_en timestamp with time zone NOT NULL,
    lat numeric(9,6) NOT NULL,
    lon numeric(9,6) NOT NULL,
    velocidad_kmh numeric(5,2) NOT NULL,
    nivel_combustible numeric(5,2) NOT NULL,
    temperatura_c numeric(5,2),
    temperatura_motor_c numeric(5,2) NOT NULL,
    odometro_km numeric(10,1) NOT NULL,
    codigo_obd2 character varying(8)
);


--
-- Name: dispositivos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dispositivos (
    id uuid NOT NULL,
    vehiculo_id uuid NOT NULL,
    fabricante character varying(60) NOT NULL,
    api_key_hash character(64) NOT NULL,
    ultima_lectura timestamp with time zone,
    creado_en timestamp with time zone NOT NULL
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
-- Name: outbox_eventos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outbox_eventos ALTER COLUMN id SET DEFAULT nextval('public.outbox_eventos_id_seq'::regclass);


--
-- Name: dispositivos dispositivos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispositivos
    ADD CONSTRAINT dispositivos_pkey PRIMARY KEY (id);


--
-- Name: dispositivos dispositivos_vehiculo_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispositivos
    ADD CONSTRAINT dispositivos_vehiculo_id_key UNIQUE (vehiculo_id);


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
-- Name: posiciones posiciones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posiciones
    ADD CONSTRAINT posiciones_pkey PRIMARY KEY (vehiculo_id, registrado_en);


--
-- Name: ix_outbox_eventos_publicado_en; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_outbox_eventos_publicado_en ON public.outbox_eventos USING btree (publicado_en);


--
-- Name: posiciones_registrado_en_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX posiciones_registrado_en_idx ON public.posiciones USING btree (registrado_en DESC);


--
-- PostgreSQL database dump complete
--


