"""Autenticación del gateway: contraseñas Argon2id y JWT RS256 de acceso y de refresco."""
import jwt
import pytest

from gateway.auth import decodificar, emitir_tokens, verificar_credenciales


def test_credenciales_correctas_devuelven_el_usuario_con_su_rol():
    usuario = verificar_credenciales("operador", "operador123")
    assert usuario and usuario["rol"] == "operador"
    assert verificar_credenciales("gestor", "gestor123")["rol"] == "gestor_flota"


@pytest.mark.parametrize("usuario,clave", [("operador", "mala"), ("nadie", "operador123"), ("admin", "")])
def test_credenciales_incorrectas_se_rechazan(usuario, clave):
    assert verificar_credenciales(usuario, clave) is None


def test_el_access_token_lleva_la_identidad_y_no_sirve_como_refresh():
    respuesta, jti, familia = emitir_tokens(verificar_credenciales("admin", "admin123"))
    claims = decodificar(respuesta["access_token"])
    assert (claims["usuario"], claims["rol"]) == ("admin", "admin")
    assert decodificar(respuesta["refresh_token"], "refresh")["familia"] == familia
    with pytest.raises(jwt.InvalidTokenError):
        decodificar(respuesta["access_token"], "refresh")


def test_un_token_alterado_se_rechaza():
    respuesta, _, _ = emitir_tokens(verificar_credenciales("admin", "admin123"))
    cabecera, cuerpo, firma = respuesta["access_token"].split(".")
    with pytest.raises(jwt.InvalidTokenError):
        decodificar(f"{cabecera}.{cuerpo}.{firma[::-1]}")
