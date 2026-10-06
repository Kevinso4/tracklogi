"""Notification Service — avisa al cliente y al gestor de flota por correo.

Consume:  shipment.assigned, shipment.reassigned, shipment.incident, shipment.delayed,
          shipment.delivered, shipment.returned, maintenance.alert
Publica:  notification.sent, notification.failed   (vía outbox)
Si SMTP_HOST no está configurado (p. ej. en Render), la notificación se registra como «simulada».
"""
import logging
import os
import smtplib
import uuid
from collections import defaultdict
from datetime import datetime
from email.message import EmailMessage
from typing import Annotated

from fastapi import Depends, Query
from pydantic import BaseModel, ConfigDict
from sqlalchemy import DateTime, String, Text, UniqueConstraint, Uuid, select
from sqlalchemy.orm import Mapped, Session, mapped_column

from common.app import crear_app
from common.db import Base, ahora, get_db
from common.outbox import idempotente, registrar_evento

log = logging.getLogger("notification")
Db = Annotated[Session, Depends(get_db)]

SMTP_HOST = os.getenv("SMTP_HOST")
SMTP_PORT = int(os.getenv("SMTP_PORT", "1025"))
REMITENTE = os.getenv("NOTIFICACIONES_REMITENTE", "LogiTrack <notificaciones@logitrack.co>")
CORREO_GESTOR = os.getenv("CORREO_GESTOR", "gestor.flota@logitrack.co")

# (asunto, cuerpo). Los campos vienen de los datos del evento.
PLANTILLAS = {
    "shipment.assigned": ("Tu envío {codigo} va en camino",
                          "Hola {cliente}:\n\nTu envío {codigo} salió de {origen} hacia {destino} en el vehículo {placa}."),
    "shipment.reassigned": ("Cambiamos el vehículo de tu envío {codigo}",
                            "Hola {cliente}:\n\nPara no retrasar tu envío {codigo}, ahora viaja en el vehículo {placa}."),
    "shipment.incident": ("Novedad en tu envío {codigo}",
                          "Hola {cliente}:\n\nTu envío {codigo} tuvo una incidencia en ruta ({tipo}). Te mantendremos informado."),
    "shipment.delayed": ("Tu envío {codigo} presenta un retraso",
                         "Hola {cliente}:\n\nTu envío {codigo} hacia {destino} se retrasó: {motivo}."),
    "shipment.delivered": ("Tu envío {codigo} fue entregado",
                           "Hola {cliente}:\n\nTu envío {codigo} fue entregado en {destino} y lo recibió {receptor}. ¡Gracias por confiar en LogiTrack!"),
    "shipment.returned": ("Tu envío {codigo} fue devuelto",
                          "Hola {cliente}:\n\nTu envío {codigo} fue devuelto al remitente. Motivo: {motivo}."),
    "maintenance.alert": ("Alerta de mantenimiento",
                          "Gestor de flota:\n\n{mensaje}\nPrioridad: {prioridad}. Revisa el panel de mantenimiento."),
}


class Notificacion(Base):
    __tablename__ = "notificaciones"
    __table_args__ = (UniqueConstraint("event_id", "destinatario", name="uq_notif_evento_destinatario"),)

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    event_id: Mapped[uuid.UUID] = mapped_column(Uuid)
    tipo_evento: Mapped[str] = mapped_column(String(60))
    envio_codigo: Mapped[str | None] = mapped_column(String(12), nullable=True, index=True)
    destinatario: Mapped[str] = mapped_column(String(120))
    canal: Mapped[str] = mapped_column(String(10), default="email")
    asunto: Mapped[str] = mapped_column(String(200))
    cuerpo: Mapped[str] = mapped_column(Text)
    estado: Mapped[str] = mapped_column(String(10))  # enviada | simulada | fallida
    error: Mapped[str | None] = mapped_column(Text, nullable=True)
    creada_en: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=ahora)


def enviar_correo(destinatario: str, asunto: str, cuerpo: str) -> tuple[str, str | None]:
    if not SMTP_HOST:
        return "simulada", None
    msg = EmailMessage()
    msg["From"], msg["To"], msg["Subject"] = REMITENTE, destinatario, asunto
    msg.set_content(cuerpo)
    try:
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=5) as smtp:
            smtp.send_message(msg)
        return "enviada", None
    except (OSError, smtplib.SMTPException) as exc:
        log.warning("No se pudo enviar el correo a %s: %s", destinatario, exc)
        return "fallida", str(exc)


@idempotente
def al_evento(db: Session, evento: dict) -> None:
    d = evento["datos"]
    destinatario = CORREO_GESTOR if evento["tipo"] == "maintenance.alert" else d.get("cliente_email")
    if not destinatario:
        return  # el cliente no dejó correo
    if evento["tipo"] == "maintenance.alert" and not d.get("critica"):
        return  # al gestor solo le llegan las alertas críticas
    campos = defaultdict(str, {k: v for k, v in d.items() if v is not None})
    asunto, cuerpo = (t.format_map(campos) for t in PLANTILLAS[evento["tipo"]])
    estado, error = enviar_correo(destinatario, asunto, cuerpo)
    n = Notificacion(event_id=uuid.UUID(evento["event_id"]), tipo_evento=evento["tipo"], envio_codigo=d.get("codigo"),
                     destinatario=destinatario, asunto=asunto, cuerpo=cuerpo, estado=estado, error=error)
    db.add(n)
    db.flush()
    registrar_evento(db, "notification.failed" if estado == "fallida" else "notification.sent", n.id,
                     {"notificacion_id": n.id, "codigo": n.envio_codigo, "destinatario": destinatario,
                      "asunto": asunto, "estado": estado})


app = crear_app(
    "notification",
    "LogiTrack · Notification Service",
    suscripciones=[("eventos", list(PLANTILLAS), al_evento)],
)


class NotificacionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tipo_evento: str
    envio_codigo: str | None
    destinatario: str
    asunto: str
    cuerpo: str
    estado: str
    creada_en: datetime


@app.get("/api/v1/notificaciones", response_model=list[NotificacionOut], tags=["notificaciones"])
def listar(db: Db, envio: str | None = None, limite: int = Query(default=50, ge=1, le=200)):
    consulta = select(Notificacion).order_by(Notificacion.creada_en.desc()).limit(limite)
    if envio:
        consulta = consulta.where(Notificacion.envio_codigo == envio.upper())
    return list(db.scalars(consulta))
