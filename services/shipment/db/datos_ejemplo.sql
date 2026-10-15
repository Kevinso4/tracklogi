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
-- Data for Name: clientes; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.clientes VALUES ('3d1103fe-75d4-47bc-a957-14e5bcc40484', 'Distribuidora del Sinú S.A.S.', '900123456-7', 'logistica@sinu.co', '6047891234', true, '2026-10-14 02:19:35.331045+00');
INSERT INTO public.clientes VALUES ('4676c490-9442-4a50-a798-0d0aa187e6df', 'Lácteos de la Costa S.A.', '800456789-1', 'despachos@lacteoscosta.co', '6053214567', true, '2026-10-14 02:19:35.331055+00');
INSERT INTO public.clientes VALUES ('cd5e708b-6f80-4be4-abc2-5a4a556b4a36', 'Agroinsumos Córdoba Ltda.', '901234567-3', 'compras@agrocordoba.co', '3004567890', true, '2026-10-14 02:19:35.331058+00');
INSERT INTO public.clientes VALUES ('f561085d-3a04-4382-9b41-e4f682d2471f', 'Farmacéutica Caribe S.A.S.', '900987654-2', 'envios@farmacaribe.co', '3157654321', true, '2026-10-14 02:19:35.331061+00');


--
-- Data for Name: envios; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.envios VALUES ('8ae22eff-3eda-4db3-84b9-9727cfa955ad', 'LT-TRRSJI', 'Distribuidora del Sinú S.A.S.', 'logistica@sinu.co', 'Montería', 'Cali', 8.747900, -75.881400, 3.451600, -76.532000, 'retrasado', '2026-10-14 22:00:00+00', false, true, false, 1200.00, 8.00, NULL, NULL, 'ae6b0412-9fad-40a1-a398-50ff9735e53d', NULL, 771.3, '2026-10-13 22:42:12.677239+00', '2026-10-14 00:24:49.965634+00', '3d1103fe-75d4-47bc-a957-14e5bcc40484');
INSERT INTO public.envios VALUES ('ab428f97-1135-4630-a8e0-b576bf1270b0', 'LT-AE14FE', 'Distribuidora del Sinú S.A.S.', 'logistica@sinu.co', 'Montería', 'Ciudad de Panamá', 8.747900, -75.881400, 8.982400, -79.519900, 'entregado', '2026-10-14 22:00:00+00', true, true, false, 1200.00, 8.00, '15033e37-aae7-4f79-94fb-b81a37996c2b', 'SIN-808', 'be460d1d-dc2d-4409-8b83-b3b17ff2ea75', '2026-10-14 08:09:31.57201+00', 520.8, '2026-10-13 22:41:30.237074+00', '2026-10-13 22:41:58.016852+00', '3d1103fe-75d4-47bc-a957-14e5bcc40484');
INSERT INTO public.envios VALUES ('264c04c9-538a-4a65-8db4-a91b722dfc34', 'LT-U0KQIW', 'Distribuidora del Sinú S.A.S.', 'logistica@sinu.co', 'Montería', 'Cartagena', 8.747900, -75.881400, 10.391000, -75.479400, 'entregado', '2026-10-14 22:00:00+00', false, true, false, 1200.00, 8.00, 'a1901c5c-8123-4a4c-bb73-18a7f374a123', 'MTR-202', '83be062a-5706-4306-a9a5-6d6ea095b296', '2026-10-14 03:32:46.794365+00', 297.3, '2026-10-13 22:36:38.215963+00', '2026-10-13 22:36:57.013008+00', '3d1103fe-75d4-47bc-a957-14e5bcc40484');


--
-- Data for Name: eventos_envio; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.eventos_envio VALUES (1, '264c04c9-538a-4a65-8db4-a91b722dfc34', 'creado', '2026-10-13 22:36:38.224987+00', 'Montería → Cartagena');
INSERT INTO public.eventos_envio VALUES (2, '264c04c9-538a-4a65-8db4-a91b722dfc34', 'asignado', '2026-10-13 22:36:38.301265+00', 'Vehículo MTR-202 asignado');
INSERT INTO public.eventos_envio VALUES (3, '264c04c9-538a-4a65-8db4-a91b722dfc34', 'entregado', '2026-10-13 22:36:57.015039+00', 'Recibido por luis ozuna');
INSERT INTO public.eventos_envio VALUES (4, 'ab428f97-1135-4630-a8e0-b576bf1270b0', 'creado', '2026-10-13 22:41:30.240221+00', 'Montería → Ciudad de Panamá');
INSERT INTO public.eventos_envio VALUES (5, 'ab428f97-1135-4630-a8e0-b576bf1270b0', 'asignado', '2026-10-13 22:41:30.321559+00', 'Vehículo SIN-808 asignado');
INSERT INTO public.eventos_envio VALUES (6, 'ab428f97-1135-4630-a8e0-b576bf1270b0', 'entregado', '2026-10-13 22:41:58.017991+00', 'Recibido por luisa diaz');
INSERT INTO public.eventos_envio VALUES (7, '8ae22eff-3eda-4db3-84b9-9727cfa955ad', 'creado', '2026-10-13 22:42:12.680162+00', 'Montería → Cali');
INSERT INTO public.eventos_envio VALUES (8, '8ae22eff-3eda-4db3-84b9-9727cfa955ad', 'asignado', '2026-10-13 22:42:12.754027+00', 'Vehículo SIN-808 asignado');
INSERT INTO public.eventos_envio VALUES (9, '8ae22eff-3eda-4db3-84b9-9727cfa955ad', 'reasignado', '2026-10-13 22:57:17.35293+00', 'SIN-808 → CTG-404 (Alerta de mantenimiento: Código de diagnóstico OBD2 activo: P0420)');
INSERT INTO public.eventos_envio VALUES (10, '8ae22eff-3eda-4db3-84b9-9727cfa955ad', 'reasignado', '2026-10-13 23:27:48.888591+00', 'CTG-404 → MTR-202 (Alerta de mantenimiento: Sobrecalentamiento de motor: 108.7 °C)');
INSERT INTO public.eventos_envio VALUES (11, '8ae22eff-3eda-4db3-84b9-9727cfa955ad', 'retrasado', '2026-10-14 00:24:49.967343+00', 'Compensación: sin vehículo alternativo tras salida de MTR-202');


--
-- Data for Name: pruebas_entrega; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.pruebas_entrega VALUES ('264c04c9-538a-4a65-8db4-a91b722dfc34', 'luis ozuna', NULL, NULL, 10.391000, -75.479400, '2026-10-13 22:36:57.017432+00');
INSERT INTO public.pruebas_entrega VALUES ('ab428f97-1135-4630-a8e0-b576bf1270b0', 'luisa diaz', NULL, NULL, 8.982400, -79.519900, '2026-10-13 22:41:58.019239+00');


--
-- Name: eventos_envio_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.eventos_envio_id_seq', 17, true);


--
-- Name: outbox_eventos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.outbox_eventos_id_seq', 17, true);


--
-- PostgreSQL database dump complete
--


