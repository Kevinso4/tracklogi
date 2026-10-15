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
-- Data for Name: facturas; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.facturas VALUES ('d7ba01bf-13b8-4822-8de3-c4481896cbae', 1001, 'Distribuidora del Sinú S.A.S.', '2026-10-01', 2, 3108780.00, '2026-10-13 23:44:05.710691+00');


--
-- Data for Name: costos_envio; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.costos_envio VALUES ('264c04c9-538a-4a65-8db4-a91b722dfc34', 'LT-U0KQIW', 'Distribuidora del Sinú S.A.S.', 'Montería → Cartagena', 297.3, 282435.00, 53514.00, 97298.18, 1129740.00, true, '2026-10-13 22:36:57.174415+00', 'd7ba01bf-13b8-4822-8de3-c4481896cbae');
INSERT INTO public.costos_envio VALUES ('ab428f97-1135-4630-a8e0-b576bf1270b0', 'LT-AE14FE', 'Distribuidora del Sinú S.A.S.', 'Montería → Ciudad de Panamá', 520.8, 494760.00, 93744.00, 170443.64, 1979040.00, true, '2026-10-13 22:41:58.452319+00', 'd7ba01bf-13b8-4822-8de3-c4481896cbae');


--
-- Data for Name: tarifas_cliente; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tarifas_cliente VALUES ('Distribuidora del Sinú S.A.S.', 'por_km', 4200.00);


--
-- Name: outbox_eventos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.outbox_eventos_id_seq', 1, true);


--
-- PostgreSQL database dump complete
--


