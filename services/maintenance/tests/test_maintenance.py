"""Motor de reglas de mantenimiento: cuándo una lectura de telemetría dispara una alerta."""
import os

import pytest

os.environ.setdefault("DATABASE_URL", "postgresql://ci:ci@localhost:5432/ci")
os.environ.setdefault("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/")

from maintenance.main import REGLAS_INICIALES, evaluar  # noqa: E402
from maintenance.models import Metrica, Operador, Regla  # noqa: E402


def regla(operador, umbral=0):
    return Regla(nombre="prueba", metrica=Metrica.temperatura_motor, operador=operador, umbral=umbral, prioridad=1)


@pytest.mark.parametrize("operador,umbral,valor,alerta", [
    (Operador.mayor, 105, 110, True),     # motor sobrecalentado
    (Operador.mayor, 105, 105, False),    # justo en el umbral: aún no
    (Operador.menor, 10, 8, True),        # combustible en reserva
    (Operador.menor, 10, 40, False),
    (Operador.presente, 0, ["P0217"], True),  # hay código OBD2
    (Operador.presente, 0, [], False),
    (Operador.mayor, 105, None, False),   # sin dato no hay alerta
])
def test_evalua_cada_operador(operador, umbral, valor, alerta):
    assert evaluar(regla(operador, umbral), valor) is alerta


def test_las_reglas_iniciales_cubren_las_cinco_metricas():
    assert {m for _, m, *_ in REGLAS_INICIALES} == set(Metrica)
