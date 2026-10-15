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
-- Data for Name: notificaciones; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.notificaciones VALUES ('68e8fd0d-5f01-4cec-ac1b-332264382e95', '40158c38-924e-4527-b011-4f63ff231ace', 'route.assigned', 'LT-U0KQIW', 'logistica@sinu.co', 'email', 'Tu envío LT-U0KQIW va en camino', 'Hola Distribuidora del Sinú S.A.S.:

Tu envío LT-U0KQIW salió de Montería hacia Cartagena en el vehículo MTR-202.
Son 297.3 km por carretera y la llegada estimada es el 13/10 a las 22:32.', 'enviada', NULL, '2026-10-13 22:36:47.185962+00');
INSERT INTO public.notificaciones VALUES ('11bc2024-c893-401f-ad35-f3c646665773', '8b4c360c-aebc-4640-9bca-8cedbeff537b', 'shipment.delivered', 'LT-U0KQIW', 'logistica@sinu.co', 'email', 'Tu envío LT-U0KQIW fue entregado', 'Hola Distribuidora del Sinú S.A.S.:

Tu envío LT-U0KQIW fue entregado en Cartagena y lo recibió luis ozuna. ¡Gracias por confiar en LogiTrack!', 'enviada', NULL, '2026-10-13 22:36:57.155195+00');
INSERT INTO public.notificaciones VALUES ('ee8207fe-a162-4216-b5a8-d8aa28cbb779', '7a8722e4-1b01-47a8-9d18-69b6708fc9bb', 'route.assigned', 'LT-AE14FE', 'logistica@sinu.co', 'email', 'Tu envío LT-AE14FE va en camino', 'Hola Distribuidora del Sinú S.A.S.:

Tu envío LT-AE14FE salió de Montería hacia Ciudad de Panamá en el vehículo SIN-808.
Son 520.8 km por carretera y la llegada estimada es el 14/10 a las 03:09.', 'enviada', NULL, '2026-10-13 22:41:32.164053+00');
INSERT INTO public.notificaciones VALUES ('88f35b4c-6f4b-4a53-a6df-a2598dcbd00f', '9ebf5a55-255e-4495-b7fd-88e0775e6858', 'shipment.delivered', 'LT-AE14FE', 'logistica@sinu.co', 'email', 'Tu envío LT-AE14FE fue entregado', 'Hola Distribuidora del Sinú S.A.S.:

Tu envío LT-AE14FE fue entregado en Ciudad de Panamá y lo recibió luisa diaz. ¡Gracias por confiar en LogiTrack!', 'enviada', NULL, '2026-10-13 22:41:58.451863+00');
INSERT INTO public.notificaciones VALUES ('6da7c5ac-8f4a-417b-b6fc-b51e2fb1d16a', 'bf818c01-00ad-4661-9a27-00ed5a34539e', 'route.assigned', 'LT-TRRSJI', 'logistica@sinu.co', 'email', 'Tu envío LT-TRRSJI va en camino', 'Hola Distribuidora del Sinú S.A.S.:

Tu envío LT-TRRSJI salió de Montería hacia Cali en el vehículo SIN-808.
Son 903.0 km por carretera y la llegada estimada es el 14/10 a las 10:02.', 'enviada', NULL, '2026-10-13 22:42:17.600035+00');
INSERT INTO public.notificaciones VALUES ('2c36d6ff-f44d-4c96-a81c-e20fbee3c568', 'f60bb918-ee9e-4026-801d-f9ae2ae2bac0', 'maintenance.alert', NULL, 'gestor.flota@logitrack.co', 'email', 'Alerta de mantenimiento', 'Gestor de flota:

Código de diagnóstico OBD2 activo: P0420
Prioridad: 1. Revisa el panel de mantenimiento.', 'enviada', NULL, '2026-10-13 22:57:17.070249+00');
INSERT INTO public.notificaciones VALUES ('0a2a7482-2522-4b9e-9760-d8309d4919fe', '32c04f5f-49e3-4686-aa45-7a51c7f30ab7', 'shipment.reassigned', 'LT-TRRSJI', 'logistica@sinu.co', 'email', 'Cambiamos el vehículo de tu envío LT-TRRSJI', 'Hola Distribuidora del Sinú S.A.S.:

Para no retrasar tu envío LT-TRRSJI, ahora viaja en el vehículo CTG-404.', 'enviada', NULL, '2026-10-13 22:57:17.827034+00');
INSERT INTO public.notificaciones VALUES ('30e08e2e-1de4-4e14-abf2-67815e15bf87', 'd56162fb-57ec-4be6-892d-149522083cd2', 'maintenance.alert', NULL, 'gestor.flota@logitrack.co', 'email', 'Alerta de mantenimiento', 'Gestor de flota:

Sobrecalentamiento de motor: 108.7 °C
Prioridad: 1. Revisa el panel de mantenimiento.', 'enviada', NULL, '2026-10-13 23:27:48.613959+00');
INSERT INTO public.notificaciones VALUES ('e4aaa6ae-27fe-439f-a1c0-dfb3f80895de', 'c816b212-3ec5-4596-8186-b813f1770826', 'shipment.reassigned', 'LT-TRRSJI', 'logistica@sinu.co', 'email', 'Cambiamos el vehículo de tu envío LT-TRRSJI', 'Hola Distribuidora del Sinú S.A.S.:

Para no retrasar tu envío LT-TRRSJI, ahora viaja en el vehículo MTR-202.', 'enviada', NULL, '2026-10-13 23:27:49.349989+00');
INSERT INTO public.notificaciones VALUES ('f6177832-c422-4f38-a4e3-0ae1446f2c51', '20ad33ab-3061-4884-8341-b81d2bcb1658', 'maintenance.alert', NULL, 'gestor.flota@logitrack.co', 'email', 'Alerta de mantenimiento', 'Gestor de flota:

Código de diagnóstico OBD2 activo: P0217
Prioridad: 1. Revisa el panel de mantenimiento.', 'enviada', NULL, '2026-10-14 00:24:49.735914+00');
INSERT INTO public.notificaciones VALUES ('1fe55e5a-133c-4475-83da-8ff1a1079f2c', 'fb82e662-420c-43fe-a7b7-32d88bd58458', 'shipment.delayed', 'LT-TRRSJI', 'logistica@sinu.co', 'email', 'Tu envío LT-TRRSJI presenta un retraso', 'Hola Distribuidora del Sinú S.A.S.:

Tu envío LT-TRRSJI hacia Cali se retrasó: Sin vehículo alternativo.', 'enviada', NULL, '2026-10-14 00:24:50.362302+00');
INSERT INTO public.notificaciones VALUES ('4147ddea-73f9-463c-8a55-07b3c54b72d2', '8aa98f74-940b-4e17-b644-8892eeb50d67', 'route.assigned', 'LT-5WESIH', 'pruebas@cliente.co', 'email', 'Tu envío LT-5WESIH va en camino', 'Hola Cliente de Prueba 2120285691:

Tu envío LT-5WESIH salió de Montería hacia Cartagena en el vehículo MTR-101.
Son 297.2 km por carretera y la llegada estimada es el 14/10 a las 02:17.', 'enviada', NULL, '2026-10-14 02:20:30.290485+00');
INSERT INTO public.notificaciones VALUES ('25a0c30f-f34c-42c8-b850-bbf3afbe0dd8', '8caff329-7c33-4894-b215-295aa867c916', 'route.assigned', 'LT-HPI1FA', 'pruebas@cliente.co', 'email', 'Tu envío LT-HPI1FA va en camino', 'Hola Cliente de Prueba 2120285691:

Tu envío LT-HPI1FA salió de Montería hacia Cartagena en el vehículo MTR-303.
Son 297.2 km por carretera y la llegada estimada es el 14/10 a las 02:17.', 'enviada', NULL, '2026-10-14 02:20:30.307714+00');
INSERT INTO public.notificaciones VALUES ('a3f7c0e8-3f10-4dfd-b2bb-8471a09ec42d', '95fee2d6-d182-49ad-a736-c545812bb85e', 'shipment.returned', 'LT-HPI1FA', 'pruebas@cliente.co', 'email', 'Tu envío LT-HPI1FA fue devuelto', 'Hola Cliente de Prueba 2120285691:

Tu envío LT-HPI1FA fue devuelto al remitente. Motivo: Envío de prueba automática.', 'enviada', NULL, '2026-10-14 02:22:20.001434+00');
INSERT INTO public.notificaciones VALUES ('c6197496-51a1-4c5b-9e19-70a1addb1e9c', 'ecda9a2d-1343-489c-8758-e31b329b6ac7', 'shipment.returned', 'LT-5WESIH', 'pruebas@cliente.co', 'email', 'Tu envío LT-5WESIH fue devuelto', 'Hola Cliente de Prueba 2120285691:

Tu envío LT-5WESIH fue devuelto al remitente. Motivo: Envío de prueba automática.', 'enviada', NULL, '2026-10-14 02:22:20.013695+00');


--
-- Name: outbox_eventos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.outbox_eventos_id_seq', 15, true);


--
-- PostgreSQL database dump complete
--


