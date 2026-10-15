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
-- Name: eventos_procesados; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eventos_procesados (
    event_id uuid NOT NULL,
    tipo character varying(60) NOT NULL,
    procesado_en timestamp with time zone NOT NULL
);


--
-- Name: historial_rutas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.historial_rutas (
    id bigint NOT NULL,
    ruta_id uuid NOT NULL,
    motivo character varying(120) NOT NULL,
    eta_anterior timestamp with time zone NOT NULL,
    eta_nueva timestamp with time zone NOT NULL,
    registrado_en timestamp with time zone NOT NULL
);


--
-- Name: historial_rutas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.historial_rutas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: historial_rutas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.historial_rutas_id_seq OWNED BY public.historial_rutas.id;


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
-- Name: rutas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rutas (
    id uuid NOT NULL,
    envio_id uuid NOT NULL,
    codigo character varying(12) NOT NULL,
    vehiculo_id uuid,
    placa character varying(10),
    origen character varying(200) NOT NULL,
    destino character varying(200) NOT NULL,
    geometria jsonb NOT NULL,
    distancia_km numeric(8,1) NOT NULL,
    duracion_min integer NOT NULL,
    eta timestamp with time zone NOT NULL,
    proveedor character varying(12) NOT NULL,
    estado character varying(12) NOT NULL,
    recalculos integer NOT NULL,
    creada_en timestamp with time zone NOT NULL
);


--
-- Name: historial_rutas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historial_rutas ALTER COLUMN id SET DEFAULT nextval('public.historial_rutas_id_seq'::regclass);


--
-- Name: outbox_eventos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outbox_eventos ALTER COLUMN id SET DEFAULT nextval('public.outbox_eventos_id_seq'::regclass);


--
-- Name: eventos_procesados eventos_procesados_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_procesados
    ADD CONSTRAINT eventos_procesados_pkey PRIMARY KEY (event_id);


--
-- Name: historial_rutas historial_rutas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historial_rutas
    ADD CONSTRAINT historial_rutas_pkey PRIMARY KEY (id);


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
-- Name: rutas rutas_envio_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rutas
    ADD CONSTRAINT rutas_envio_id_key UNIQUE (envio_id);


--
-- Name: rutas rutas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rutas
    ADD CONSTRAINT rutas_pkey PRIMARY KEY (id);


--
-- Name: ix_outbox_eventos_publicado_en; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_outbox_eventos_publicado_en ON public.outbox_eventos USING btree (publicado_en);


--
-- Name: ix_rutas_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_rutas_estado ON public.rutas USING btree (estado);


--
-- Name: historial_rutas historial_rutas_ruta_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historial_rutas
    ADD CONSTRAINT historial_rutas_ruta_id_fkey FOREIGN KEY (ruta_id) REFERENCES public.rutas(id);


--
-- PostgreSQL database dump complete
--


