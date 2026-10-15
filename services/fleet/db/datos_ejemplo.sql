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
-- Data for Name: conductores; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.conductores VALUES ('0a7dc3fa-b80c-408a-abc7-f391d81f3293', 'Carlos Pérez', 'CC1067845123', '3001234567', false, 0.00);
INSERT INTO public.conductores VALUES ('a3d93b2c-26ff-423f-8d05-849ee15d722e', 'Andrea Gómez', 'CC1003456789', '3019876543', true, 0.00);
INSERT INTO public.conductores VALUES ('8acf4db0-52db-4fd2-be80-dc35d53329dc', 'Luis Martínez', 'CC1067111222', '3024567890', true, 0.00);
INSERT INTO public.conductores VALUES ('98db1a3b-7ad4-4287-af93-624b121adb15', 'Diana Ríos', 'CC1045678901', '3105551234', false, 0.00);
INSERT INTO public.conductores VALUES ('8df13524-4985-44ef-acd5-515e1fe54880', 'Jorge Salgado', 'CC1067333444', '3156667788', false, 0.00);
INSERT INTO public.conductores VALUES ('386a0d79-66c8-4500-a1ba-b358e1cdb803', 'María Hoyos', 'CC1102998877', '3187778899', true, 0.00);


--
-- Data for Name: vehiculos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.vehiculos VALUES ('e01860ce-a9e8-4cd8-8225-e2ff30abe7e4', 'CTG-505', 'van', 'Renault Master', 1400.00, 10.00, 2024, '2027-05-15', 'activo', false, false, 'Cartagena', '2026-10-13 22:28:54.284252+00', '2026-10-13 22:28:54.284252+00');
INSERT INTO public.vehiculos VALUES ('2e00fcbb-a048-436c-8bc9-bc824452521d', 'BAQ-606', 'tractomula', 'Freightliner M2', 30000.00, 85.00, 2019, '2027-06-15', 'activo', false, true, 'Barranquilla', '2026-10-13 22:28:54.284256+00', '2026-10-13 22:28:54.284256+00');
INSERT INTO public.vehiculos VALUES ('ff487022-9cfc-4d0e-a8e2-b60e682238f3', 'MED-707', 'furgon', 'JAC 1063', 3500.00, 18.00, 2022, '2027-07-15', 'activo', false, false, 'Medellín', '2026-10-13 22:28:54.28426+00', '2026-10-13 22:28:54.284261+00');
INSERT INTO public.vehiculos VALUES ('15033e37-aae7-4f79-94fb-b81a37996c2b', 'SIN-808', 'camion', 'Foton Aumark', 4500.00, 22.00, 2021, '2027-08-15', 'en_mantenimiento', true, false, 'Ciudad de Panamá', '2026-10-13 22:28:54.284264+00', '2026-10-13 22:57:17.062019+00');
INSERT INTO public.vehiculos VALUES ('18d8b936-9caf-4277-bd18-6442e52c7ee5', 'CTG-404', 'camion', 'Isuzu NPR', 5000.00, 25.00, 2023, '2027-04-15', 'en_mantenimiento', true, false, 'Cartagena', '2026-10-13 22:28:54.284248+00', '2026-10-13 23:27:48.607053+00');
INSERT INTO public.vehiculos VALUES ('a1901c5c-8123-4a4c-bb73-18a7f374a123', 'MTR-202', 'camion', 'Hino 300', 6000.00, 30.00, 2021, '2027-02-15', 'en_mantenimiento', true, false, 'Cartagena', '2026-10-13 22:28:54.284238+00', '2026-10-14 00:24:49.690173+00');
INSERT INTO public.vehiculos VALUES ('7fe2ee66-8154-4a9f-8983-c75b69fdde0a', 'MTR-303', 'tractomula', 'Kenworth T800', 34000.00, 90.00, 2020, '2027-03-15', 'activo', false, true, 'Montería', '2026-10-13 22:28:54.284244+00', '2026-10-14 02:22:19.994982+00');
INSERT INTO public.vehiculos VALUES ('08b76bd7-382e-424c-97de-545c02dabf6a', 'MTR-101', 'furgon', 'Chevrolet NHR', 2500.00, 12.00, 2022, '2027-01-15', 'activo', false, false, 'Montería', '2026-10-13 22:28:54.284179+00', '2026-10-14 02:22:20.011316+00');


--
-- Data for Name: asignaciones; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.asignaciones VALUES ('3d4d303c-c607-49cd-ba16-4f800763233c', '08b76bd7-382e-424c-97de-545c02dabf6a', '0a7dc3fa-b80c-408a-abc7-f391d81f3293', '2026-10-13 22:28:54.297338+00', NULL);
INSERT INTO public.asignaciones VALUES ('1a78ef42-92ec-4c10-9726-3d7b5667fdb9', 'a1901c5c-8123-4a4c-bb73-18a7f374a123', 'a3d93b2c-26ff-423f-8d05-849ee15d722e', '2026-10-13 22:28:54.29735+00', NULL);
INSERT INTO public.asignaciones VALUES ('7abca061-f6f7-471f-98a3-a1725036ccfd', '7fe2ee66-8154-4a9f-8983-c75b69fdde0a', '8acf4db0-52db-4fd2-be80-dc35d53329dc', '2026-10-13 22:28:54.297355+00', NULL);
INSERT INTO public.asignaciones VALUES ('6d71b89f-a039-49f9-8bdf-ec960f7dcc96', '18d8b936-9caf-4277-bd18-6442e52c7ee5', '98db1a3b-7ad4-4287-af93-624b121adb15', '2026-10-13 22:28:54.297359+00', NULL);
INSERT INTO public.asignaciones VALUES ('1640a346-ff0c-44ac-9f86-b2107338036d', 'e01860ce-a9e8-4cd8-8225-e2ff30abe7e4', '8df13524-4985-44ef-acd5-515e1fe54880', '2026-10-13 22:28:54.297363+00', NULL);
INSERT INTO public.asignaciones VALUES ('c86048a7-f029-42bb-a9b6-daa1b55f0561', '2e00fcbb-a048-436c-8bc9-bc824452521d', '386a0d79-66c8-4500-a1ba-b358e1cdb803', '2026-10-13 22:28:54.297369+00', NULL);


--
-- Data for Name: conductor_categorias; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.conductor_categorias VALUES ('0a7dc3fa-b80c-408a-abc7-f391d81f3293', 'C2');
INSERT INTO public.conductor_categorias VALUES ('a3d93b2c-26ff-423f-8d05-849ee15d722e', 'C2');
INSERT INTO public.conductor_categorias VALUES ('a3d93b2c-26ff-423f-8d05-849ee15d722e', 'C3');
INSERT INTO public.conductor_categorias VALUES ('8acf4db0-52db-4fd2-be80-dc35d53329dc', 'C3');
INSERT INTO public.conductor_categorias VALUES ('98db1a3b-7ad4-4287-af93-624b121adb15', 'C1');
INSERT INTO public.conductor_categorias VALUES ('98db1a3b-7ad4-4287-af93-624b121adb15', 'C2');
INSERT INTO public.conductor_categorias VALUES ('8df13524-4985-44ef-acd5-515e1fe54880', 'C2');
INSERT INTO public.conductor_categorias VALUES ('386a0d79-66c8-4500-a1ba-b358e1cdb803', 'C3');


--
-- Name: outbox_eventos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.outbox_eventos_id_seq', 14, true);


--
-- PostgreSQL database dump complete
--


