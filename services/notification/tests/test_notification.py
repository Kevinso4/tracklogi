"""Plantillas de correo y envío: cada evento produce un mensaje completo y nunca bloquea al emisor."""
import os

import pytest

os.environ.setdefault("DATABASE_URL", "postgresql://ci:ci@localhost:5432/ci")
os.environ.setdefault("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/")

from notification import main  # noqa: E402

DATOS = dict(codigo="LT-ABC123", cliente="Agroinsumos Córdoba Ltda.", origen="Montería", destino="Cartagena",
             placa="MTR-202", distancia_km=297.3, eta_texto="15/10 a las 17:24", tipo="averia",
             motivo="Sin vehículos disponibles", receptor="Laura Méndez", mensaje="Motor a 110 °C", prioridad=1)


@pytest.mark.parametrize("evento", list(main.PLANTILLAS))
def test_cada_plantilla_se_completa_sin_huecos(evento):
    asunto, cuerpo = main.PLANTILLAS[evento]
    texto = asunto.format(**DATOS) + cuerpo.format(**DATOS)
    assert "{" not in texto and "}" not in texto


def test_el_aviso_de_salida_incluye_ruta_y_llegada():
    asunto, cuerpo = main.PLANTILLAS["route.assigned"]
    texto = cuerpo.format(**DATOS)
    assert "LT-ABC123" in asunto.format(**DATOS)
    assert "297.3 km" in texto and "MTR-202" in texto and "17:24" in texto


def test_sin_servidor_de_correo_queda_simulada(monkeypatch):
    monkeypatch.setattr(main, "SMTP_HOST", None)
    assert main.enviar_correo("cliente@empresa.co", "Asunto", "Cuerpo") == ("simulada", None)


def test_si_el_servidor_falla_se_registra_y_no_explota(monkeypatch):
    monkeypatch.setattr(main, "SMTP_HOST", "127.0.0.1")
    monkeypatch.setattr(main, "SMTP_PORT", 1)  # puerto cerrado
    estado, error = main.enviar_correo("cliente@empresa.co", "Asunto", "Cuerpo")
    assert estado == "fallida" and error
