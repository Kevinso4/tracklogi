"""Cálculo de costos y precio al cliente de un envío entregado."""
import os

import pytest

os.environ.setdefault("DATABASE_URL", "postgresql://ci:ci@localhost:5432/ci")
os.environ.setdefault("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/")

from billing import main  # noqa: E402


def test_tarifa_por_km():
    c = main.calcular(297.3, "por_km", 3800)
    assert c["precio_cliente"] == 1_129_740.0  # 297,3 km × $3.800 (el envío real de la demo)
    assert c["costo_combustible"] == round(297.3 * main.COMBUSTIBLE_POR_KM, 2)
    assert c["costo_peajes"] == round(297.3 * main.PEAJES_POR_KM, 2)


def test_tarifa_fija_por_envio_no_depende_de_los_km():
    assert main.calcular(10, "por_envio", 250_000)["precio_cliente"] == 250_000
    assert main.calcular(900, "por_envio", 250_000)["precio_cliente"] == 250_000


def test_el_conductor_se_paga_por_horas_de_viaje():
    horas = 110 / main.VELOCIDAD_PROMEDIO_KMH
    assert main.calcular(110, "por_km", 1)["costo_conductor"] == round(horas * main.CONDUCTOR_POR_HORA, 2)


def test_distancia_de_respaldo_por_carretera():
    recta = main.distancia_km(8.7479, -75.8814, 10.391, -75.4794) / main.FACTOR_CARRETERA
    assert recta == pytest.approx(186, abs=6)
    assert main.distancia_km(8.75, -75.88, 8.75, -75.88) == 0
