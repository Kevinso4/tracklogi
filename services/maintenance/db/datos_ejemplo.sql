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
-- Data for Name: reglas; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.reglas VALUES ('0ff5dddd-476d-48ef-8be5-88ed7bde3418', 'Sobrecalentamiento de motor', NULL, 'temperatura_motor', 'mayor', 105.00, 1, true);
INSERT INTO public.reglas VALUES ('bafb5cd3-9e12-4e2a-8ebd-19891f59f102', 'Código de diagnóstico OBD2 activo', NULL, 'codigo_obd2', 'presente', 0.00, 1, true);
INSERT INTO public.reglas VALUES ('658184a5-12a4-4d01-9e4f-8d1149f20287', 'Exceso de velocidad', NULL, 'velocidad', 'mayor', 110.00, 2, true);
INSERT INTO public.reglas VALUES ('fa00fcec-3311-4fbc-b7d4-8f562c3b32d9', 'Cadena de frío rota (carga > 8 °C)', NULL, 'temperatura_carga', 'mayor', 8.00, 2, true);
INSERT INTO public.reglas VALUES ('13fe6515-13d8-449a-88ef-cb59a2f2db9a', 'Combustible en reserva', NULL, 'nivel_combustible', 'menor', 10.00, 3, true);


--
-- Data for Name: alertas; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.alertas VALUES ('26371736-1087-4fc8-8422-407773839e40', '15033e37-aae7-4f79-94fb-b81a37996c2b', 'bafb5cd3-9e12-4e2a-8ebd-19891f59f102', 'codigo_obd2', 'P0420', 'Código de diagnóstico OBD2 activo: P0420', 1, 'abierta', '2026-10-13 22:57:17.004293+00', NULL);
INSERT INTO public.alertas VALUES ('64d854fe-879c-4553-ae1c-5b422a8bf337', '18d8b936-9caf-4277-bd18-6442e52c7ee5', '0ff5dddd-476d-48ef-8be5-88ed7bde3418', 'temperatura_motor', '108.7 °C', 'Sobrecalentamiento de motor: 108.7 °C', 1, 'abierta', '2026-10-13 23:27:48.41677+00', NULL);
INSERT INTO public.alertas VALUES ('621059a2-954f-4482-8f81-e2bdfe6e06ef', 'a1901c5c-8123-4a4c-bb73-18a7f374a123', 'bafb5cd3-9e12-4e2a-8ebd-19891f59f102', 'codigo_obd2', 'P0217', 'Código de diagnóstico OBD2 activo: P0217', 1, 'abierta', '2026-10-14 00:24:49.396145+00', NULL);


--
-- Data for Name: programas_mantenimiento; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.programas_mantenimiento VALUES ('6d0b4e6a-e5c5-4c8c-89ff-627c8e44051a', '2e00fcbb-a048-436c-8bc9-bc824452521d', 'Revisión preventiva: aceite, filtros y frenos', '2026-12-12', 20000, 2, 'programado', '2026-10-13 22:29:07.713613+00');
INSERT INTO public.programas_mantenimiento VALUES ('a8a6229e-8734-46d4-915d-b20cc5b28468', 'e01860ce-a9e8-4cd8-8225-e2ff30abe7e4', 'Revisión preventiva: aceite, filtros y frenos', '2026-12-12', 60000, 2, 'programado', '2026-10-13 22:29:07.747232+00');
INSERT INTO public.programas_mantenimiento VALUES ('c9e6bb32-906b-4fcb-b215-2d0b4fb21549', '18d8b936-9caf-4277-bd18-6442e52c7ee5', 'Revisión preventiva: aceite, filtros y frenos', '2026-12-12', 60000, 2, 'programado', '2026-10-13 22:29:07.755364+00');
INSERT INTO public.programas_mantenimiento VALUES ('f059e981-6e29-4fbd-a6ab-a2e7603da1e3', 'ff487022-9cfc-4d0e-a8e2-b60e682238f3', 'Revisión preventiva: aceite, filtros y frenos', '2026-12-12', 80000, 2, 'programado', '2026-10-13 22:29:07.76794+00');
INSERT INTO public.programas_mantenimiento VALUES ('abb64989-b2db-44f1-9f09-ed46024d3c79', '08b76bd7-382e-424c-97de-545c02dabf6a', 'Revisión preventiva: aceite, filtros y frenos', '2026-12-12', 80000, 2, 'programado', '2026-10-13 22:29:07.783968+00');
INSERT INTO public.programas_mantenimiento VALUES ('52bba448-7e44-41a1-8267-0c13d8caf9d4', 'a1901c5c-8123-4a4c-bb73-18a7f374a123', 'Revisión preventiva: aceite, filtros y frenos', '2026-12-12', 30000, 2, 'programado', '2026-10-13 22:29:07.804444+00');
INSERT INTO public.programas_mantenimiento VALUES ('44cfb6ee-321a-47f3-b006-0c5fc42f2ef2', '7fe2ee66-8154-4a9f-8983-c75b69fdde0a', 'Revisión preventiva: aceite, filtros y frenos', '2026-12-12', 50000, 2, 'programado', '2026-10-13 22:29:07.824791+00');
INSERT INTO public.programas_mantenimiento VALUES ('9e002c93-159e-45fa-87f0-73ed4233ed61', '15033e37-aae7-4f79-94fb-b81a37996c2b', 'Revisión preventiva: aceite, filtros y frenos', '2026-12-12', 90000, 2, 'programado', '2026-10-13 22:29:07.847117+00');


--
-- Data for Name: intervenciones; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: ultimas_lecturas; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.ultimas_lecturas VALUES ('2e00fcbb-a048-436c-8bc9-bc824452521d', 63538.1, 69.80, 64.70, '2026-10-15 15:45:03.445917+00');
INSERT INTO public.ultimas_lecturas VALUES ('18d8b936-9caf-4277-bd18-6442e52c7ee5', 78815.2, 70.10, 99.90, '2026-10-15 15:45:03.463881+00');
INSERT INTO public.ultimas_lecturas VALUES ('e01860ce-a9e8-4cd8-8225-e2ff30abe7e4', 68022.5, 70.90, 95.00, '2026-10-15 15:45:03.480838+00');
INSERT INTO public.ultimas_lecturas VALUES ('ff487022-9cfc-4d0e-a8e2-b60e682238f3', 62450.5, 70.70, 69.60, '2026-10-15 15:45:03.499807+00');
INSERT INTO public.ultimas_lecturas VALUES ('08b76bd7-382e-424c-97de-545c02dabf6a', 40888.0, 67.90, 66.30, '2026-10-15 15:45:03.517453+00');
INSERT INTO public.ultimas_lecturas VALUES ('a1901c5c-8123-4a4c-bb73-18a7f374a123', 92708.2, 69.70, 71.50, '2026-10-15 15:45:03.534446+00');
INSERT INTO public.ultimas_lecturas VALUES ('7fe2ee66-8154-4a9f-8983-c75b69fdde0a', 42874.4, 70.40, 66.30, '2026-10-15 15:45:03.555864+00');
INSERT INTO public.ultimas_lecturas VALUES ('15033e37-aae7-4f79-94fb-b81a37996c2b', 57860.3, 70.80, 81.80, '2026-10-15 15:45:03.573456+00');


--
-- Name: outbox_eventos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.outbox_eventos_id_seq', 11, true);


--
-- PostgreSQL database dump complete
--


