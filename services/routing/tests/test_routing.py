"""Cálculo de rutas: geometría reducida y plan B cuando el proveedor de mapas (OSRM) falla."""
import os

import httpx

os.environ.setdefault("DATABASE_URL", "postgresql://ci:ci@localhost:5432/ci")
os.environ.setdefault("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/")

from routing import main  # noqa: E402

MONTERIA, CARTAGENA = (8.7479, -75.8814), (10.391, -75.4794)


def test_distancia_en_linea_recta_monteria_cartagena():
    assert 180 < main._linea_recta_km(*MONTERIA, *CARTAGENA) < 195


def test_reduce_la_geometria_conservando_inicio_y_fin():
    puntos = [[i, i] for i in range(1000)]
    reducidos = main._reducir(puntos)
    assert len(reducidos) <= main.MAX_PUNTOS
    assert reducidos[0] == puntos[0] and reducidos[-1] == puntos[-1]
    assert main._reducir(puntos[:10]) == puntos[:10]


def test_si_osrm_falla_usa_una_ruta_estimada(monkeypatch):
    def sin_red(*_a, **_k):
        raise httpx.ConnectError("sin conexión")

    monkeypatch.setattr(main.osrm, "get", sin_red)
    geometria, km, minutos, proveedor = main.calcular(*MONTERIA, *CARTAGENA)
    assert proveedor == "estimada"
    assert km == round(main._linea_recta_km(*MONTERIA, *CARTAGENA) * main.FACTOR_CARRETERA, 1)
    assert minutos > 0 and geometria[0] == [MONTERIA[1], MONTERIA[0]]


def test_usa_la_ruta_de_osrm_cuando_responde(monkeypatch):
    class Respuesta:
        def raise_for_status(self):
            pass

        def json(self):
            return {"code": "Ok", "routes": [{"distance": 297300, "duration": 13200,
                                              "geometry": {"coordinates": [[-75.88, 8.75], [-75.48, 10.39]]}}]}

    monkeypatch.setattr(main.osrm, "get", lambda *_a, **_k: Respuesta())
    _, km, minutos, proveedor = main.calcular(*MONTERIA, *CARTAGENA)
    assert (proveedor, km) == ("osrm", 297.3)
    assert minutos == round(13200 / 60 * main.FACTOR_CAMION)  # el camión va más lento que un auto
