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
-- Name: modelo_tarifa; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.modelo_tarifa AS ENUM (
    'por_km',
    'por_envio'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: costos_envio; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.costos_envio (
    envio_id uuid NOT NULL,
    codigo character varying(12) NOT NULL,
    cliente character varying(120) NOT NULL,
    ruta character varying(200) NOT NULL,
    distancia_km numeric(8,1) NOT NULL,
    costo_combustible numeric(14,2) NOT NULL,
    costo_peajes numeric(14,2) NOT NULL,
    costo_conductor numeric(14,2) NOT NULL,
    precio_cliente numeric(14,2) NOT NULL,
    a_tiempo boolean NOT NULL,
    entregado_en timestamp with time zone NOT NULL,
    factura_id uuid
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
-- Name: facturas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.facturas (
    id uuid NOT NULL,
    numero integer NOT NULL,
    cliente character varying(120) NOT NULL,
    periodo date NOT NULL,
    envios integer NOT NULL,
    monto_total numeric(14,2) NOT NULL,
    emitida_en timestamp with time zone NOT NULL
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
-- Name: tarifas_cliente; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tarifas_cliente (
    cliente character varying(120) NOT NULL,
    modelo public.modelo_tarifa NOT NULL,
    valor numeric(14,2) NOT NULL
);


--
-- Name: outbox_eventos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outbox_eventos ALTER COLUMN id SET DEFAULT nextval('public.outbox_eventos_id_seq'::regclass);


--
-- Name: costos_envio costos_envio_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.costos_envio
    ADD CONSTRAINT costos_envio_pkey PRIMARY KEY (envio_id);


--
-- Name: eventos_procesados eventos_procesados_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_procesados
    ADD CONSTRAINT eventos_procesados_pkey PRIMARY KEY (event_id);


--
-- Name: facturas facturas_numero_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.facturas
    ADD CONSTRAINT facturas_numero_key UNIQUE (numero);


--
-- Name: facturas facturas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.facturas
    ADD CONSTRAINT facturas_pkey PRIMARY KEY (id);


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
-- Name: tarifas_cliente tarifas_cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tarifas_cliente
    ADD CONSTRAINT tarifas_cliente_pkey PRIMARY KEY (cliente);


--
-- Name: facturas uq_factura_cliente_periodo; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.facturas
    ADD CONSTRAINT uq_factura_cliente_periodo UNIQUE (cliente, periodo);


--
-- Name: ix_costos_envio_cliente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_costos_envio_cliente ON public.costos_envio USING btree (cliente);


--
-- Name: ix_costos_envio_factura_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_costos_envio_factura_id ON public.costos_envio USING btree (factura_id);


--
-- Name: ix_outbox_eventos_publicado_en; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_outbox_eventos_publicado_en ON public.outbox_eventos USING btree (publicado_en);


--
-- Name: costos_envio costos_envio_factura_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.costos_envio
    ADD CONSTRAINT costos_envio_factura_id_fkey FOREIGN KEY (factura_id) REFERENCES public.facturas(id);


--
-- PostgreSQL database dump complete
--


