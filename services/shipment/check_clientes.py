"""Comprobación de la gestión de clientes contra el sistema en marcha (docker compose up).

    python services/shipment/check_clientes.py            # usa http://localhost:8000
"""
import sys
from datetime import datetime, timedelta, timezone

import httpx

BASE = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8000"


def sesion(usuario: str) -> httpx.Client:
    c = httpx.Client(base_url=BASE, timeout=30)
    r = c.post("/api/v1/auth/token", json={"usuario": usuario, "clave": f"{usuario}123"})
    r.raise_for_status()
    c.headers["Authorization"] = f"Bearer {r.json()['access_token']}"
    return c


def envio(**cliente) -> dict:
    return {**cliente, "origen": "Montería", "destino": "Cartagena", "origen_lat": 8.75, "origen_lon": -75.88,
            "destino_lat": 10.39, "destino_lon": -75.48, "peso_kg": 100, "volumen_m3": 1,
            "fecha_limite_sla": (datetime.now(timezone.utc) + timedelta(days=1)).isoformat()}


op, gestor = sesion("operador"), sesion("gestor")
nit = datetime.now().strftime("%H%M%S%f")[:10]
nuevo = {"nombre": f"Cliente de Prueba {nit}", "nit": nit, "email": "pruebas@cliente.co", "telefono": "3001234567"}

assert gestor.get("/api/v1/clientes").status_code == 403, "el gestor de flota no debe ver clientes"
assert len(op.get("/api/v1/clientes").json()) >= 4, "faltan los clientes iniciales"

for malo in ({"nit": "abc"}, {"nombre": "12345"}, {"email": "sin-arroba"}, {"telefono": "letras"}):
    r = op.post("/api/v1/clientes", json=nuevo | malo)
    assert r.status_code == 422, (malo, r.status_code, r.text)

r = op.post("/api/v1/clientes", json=nuevo)
assert r.status_code == 201, r.text
c = r.json()
assert op.post("/api/v1/clientes", json=nuevo).status_code == 409, "no debe duplicar nombre"
assert op.post("/api/v1/clientes", json=nuevo | {"nombre": "Otro Nombre"}).status_code == 409, "no debe duplicar NIT"
assert op.get("/api/v1/clientes", params={"q": nit}).json()[0]["id"] == c["id"]

# Sin envíos se puede eliminar; se vuelve a crear para seguir.
assert op.delete(f"/api/v1/clientes/{c['id']}").status_code == 204
c = op.post("/api/v1/clientes", json=nuevo).json()

# El envío toma nombre y correo del cliente registrado.
e = op.post("/api/v1/envios", json=envio(cliente_id=c["id"]))
assert e.status_code == 201, e.text
assert (e.json()["cliente"], e.json()["cliente_email"]) == (nuevo["nombre"], nuevo["email"]), e.json()
# Compatibilidad: por nombre también queda enlazado al cliente.
assert op.post("/api/v1/envios", json=envio(cliente=nuevo["nombre"].upper())).json()["cliente_id"] == c["id"]
assert op.post("/api/v1/envios", json=envio()).status_code == 422, "un envío sin cliente no es válido"
assert op.post("/api/v1/envios", json=envio(cliente_id="00000000-0000-0000-0000-000000000000")).status_code == 404

assert op.get("/api/v1/clientes", params={"q": nit}).json()[0]["envios"] == 2
assert op.delete(f"/api/v1/clientes/{c['id']}").status_code == 409, "con envíos no se elimina"

# Inactivo: sale del selector y no admite envíos nuevos.
r = op.put(f"/api/v1/clientes/{c['id']}", json={"nit": nit, "email": "nuevo@cliente.co", "activo": False})
assert r.status_code == 200 and r.json()["email"] == "nuevo@cliente.co" and r.json()["telefono"] is None, r.text
assert c["id"] not in [x["id"] for x in op.get("/api/v1/clientes", params={"solo_activos": True}).json()]
assert op.post("/api/v1/envios", json=envio(cliente_id=c["id"])).status_code == 409

print("clientes: todo correcto")
