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
-- Name: estado_envio; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.estado_envio AS ENUM (
    'pendiente',
    'en_transito',
    'con_incidencia',
    'retrasado',
    'entregado',
    'devuelto'
);


--
-- Name: tipo_evento_envio; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.tipo_evento_envio AS ENUM (
    'creado',
    'asignado',
    'reasignado',
    'incidencia',
    'retrasado',
    'reanudado',
    'entregado',
    'devuelto'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: clientes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes (
    id uuid NOT NULL,
    nombre character varying(120) NOT NULL,
    nit character varying(14) NOT NULL,
    email character varying(120),
    telefono character varying(20),
    activo boolean NOT NULL,
    creado_en timestamp with time zone NOT NULL
);


--
-- Name: envios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.envios (
    id uuid NOT NULL,
    codigo character varying(12) NOT NULL,
    cliente character varying(120) NOT NULL,
    cliente_email character varying(120),
    origen character varying(200) NOT NULL,
    destino character varying(200) NOT NULL,
    origen_lat numeric(9,6) NOT NULL,
    origen_lon numeric(9,6) NOT NULL,
    destino_lat numeric(9,6) NOT NULL,
    destino_lon numeric(9,6) NOT NULL,
    estado public.estado_envio NOT NULL,
    fecha_limite_sla timestamp with time zone NOT NULL,
    es_internacional boolean NOT NULL,
    requiere_refrigeracion boolean NOT NULL,
    es_hazmat boolean NOT NULL,
    peso_kg numeric(10,2) NOT NULL,
    volumen_m3 numeric(8,2) NOT NULL,
    vehiculo_id uuid,
    vehiculo_placa character varying(10),
    idempotency_key character varying(64),
    eta timestamp with time zone,
    distancia_km numeric(8,1),
    creado_en timestamp with time zone NOT NULL,
    actualizado_en timestamp with time zone NOT NULL,
    cliente_id uuid,
    CONSTRAINT ck_peso CHECK ((peso_kg > (0)::numeric)),
    CONSTRAINT ck_volumen CHECK ((volumen_m3 > (0)::numeric))
);


--
-- Name: eventos_envio; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eventos_envio (
    id bigint NOT NULL,
    envio_id uuid NOT NULL,
    tipo_evento public.tipo_evento_envio NOT NULL,
    ocurrido_en timestamp with time zone NOT NULL,
    notas text
);


--
-- Name: eventos_envio_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.eventos_envio_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: eventos_envio_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.eventos_envio_id_seq OWNED BY public.eventos_envio.id;


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
-- Name: pruebas_entrega; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pruebas_entrega (
    envio_id uuid NOT NULL,
    nombre_receptor character varying(120) NOT NULL,
    url_firma text,
    url_foto text,
    lat numeric(9,6),
    lon numeric(9,6),
    entregado_en timestamp with time zone NOT NULL
);


--
-- Name: eventos_envio id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_envio ALTER COLUMN id SET DEFAULT nextval('public.eventos_envio_id_seq'::regclass);


--
-- Name: outbox_eventos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outbox_eventos ALTER COLUMN id SET DEFAULT nextval('public.outbox_eventos_id_seq'::regclass);


--
-- Name: clientes clientes_nit_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_nit_key UNIQUE (nit);


--
-- Name: clientes clientes_nombre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_nombre_key UNIQUE (nombre);


--
-- Name: clientes clientes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_pkey PRIMARY KEY (id);


--
-- Name: envios envios_codigo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envios
    ADD CONSTRAINT envios_codigo_key UNIQUE (codigo);


--
-- Name: envios envios_idempotency_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envios
    ADD CONSTRAINT envios_idempotency_key_key UNIQUE (idempotency_key);


--
-- Name: envios envios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envios
    ADD CONSTRAINT envios_pkey PRIMARY KEY (id);


--
-- Name: eventos_envio eventos_envio_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_envio
    ADD CONSTRAINT eventos_envio_pkey PRIMARY KEY (id);


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
-- Name: pruebas_entrega pruebas_entrega_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pruebas_entrega
    ADD CONSTRAINT pruebas_entrega_pkey PRIMARY KEY (envio_id);


--
-- Name: idx_env_estado_sla; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_env_estado_sla ON public.envios USING btree (estado, fecha_limite_sla);


--
-- Name: idx_ev_envio; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ev_envio ON public.eventos_envio USING btree (envio_id, ocurrido_en);


--
-- Name: ix_envios_vehiculo_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_envios_vehiculo_id ON public.envios USING btree (vehiculo_id);


--
-- Name: ix_outbox_eventos_publicado_en; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_outbox_eventos_publicado_en ON public.outbox_eventos USING btree (publicado_en);


--
-- Name: envios envios_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envios
    ADD CONSTRAINT envios_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.clientes(id);


--
-- Name: eventos_envio eventos_envio_envio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_envio
    ADD CONSTRAINT eventos_envio_envio_id_fkey FOREIGN KEY (envio_id) REFERENCES public.envios(id);


--
-- Name: pruebas_entrega pruebas_entrega_envio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pruebas_entrega
    ADD CONSTRAINT pruebas_entrega_envio_id_fkey FOREIGN KEY (envio_id) REFERENCES public.envios(id);


--
-- PostgreSQL database dump complete
--


