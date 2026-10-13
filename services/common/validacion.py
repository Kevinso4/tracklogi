"""Patrones de validación compartidos y mensajes de error en español.

Los patrones se usan con `Field(pattern=...)` de Pydantic (motor sin lookahead: por eso CON_LETRA
se escribe como búsqueda simple). La validación de verdad ocurre aquí, en el servidor; los
formularios del panel solo evitan que el usuario llegue a equivocarse.
"""

_LETRAS = "A-Za-zÁÉÍÓÚÜÑáéíóúüñ"

NOMBRE = rf"^[{_LETRAS}' .-]+$"            # personas: solo letras, espacios, punto, guion y apóstrofo
CON_LETRA = rf"[{_LETRAS}]"                # texto libre que no puede ser solo números o símbolos
TELEFONO = r"^\+?[0-9 ]{7,15}$"
EMAIL = r"^[^@\s]+@[^@\s]+\.[^@\s]+$"
ALFANUMERICO = r"^[A-Za-z0-9-]+$"

_POR_PATRON = {
    NOMBRE: "Solo se permiten letras y espacios",
    CON_LETRA: "Debe contener letras, no solo números o símbolos",
    TELEFONO: "Solo números (de 7 a 15 dígitos)",
    EMAIL: "El correo no es válido (ejemplo: nombre@empresa.co)",
    ALFANUMERICO: "Solo letras, números y guion",
}

_POR_TIPO = {
    "missing": "Este campo es obligatorio",
    "float_parsing": "Debe ser un número",
    "float_type": "Debe ser un número",
    "int_parsing": "Debe ser un número entero",
    "int_type": "Debe ser un número entero",
    "int_from_float": "Debe ser un número entero, sin decimales",
    "greater_than": "Debe ser mayor que {gt}",
    "greater_than_equal": "Debe ser mayor o igual que {ge}",
    "less_than": "Debe ser menor que {lt}",
    "less_than_equal": "Debe ser menor o igual que {le}",
    "string_type": "Debe ser un texto",
    "string_too_short": "Debe tener al menos {min_length} caracteres",
    "string_too_long": "Debe tener máximo {max_length} caracteres",
    "bool_parsing": "Debe ser sí o no",
    "bool_type": "Debe ser sí o no",
    "date_parsing": "La fecha no es válida",
    "date_from_datetime_parsing": "La fecha no es válida",
    "datetime_parsing": "La fecha y hora no son válidas",
    "datetime_from_date_parsing": "La fecha y hora no son válidas",
    "uuid_parsing": "El identificador no es válido",
    "enum": "El valor no está entre las opciones permitidas",
    "literal_error": "El valor no está entre las opciones permitidas",
    "json_invalid": "El cuerpo de la petición no es un JSON válido",
}


def mensaje_es(err: dict) -> str:
    """Traduce un error de validación de Pydantic a un mensaje claro en español."""
    tipo, ctx = err.get("type", ""), err.get("ctx") or {}
    ctx = {k: int(v) if isinstance(v, float) and v.is_integer() else v for k, v in ctx.items()}  # «0», no «0.0»
    if tipo == "string_pattern_mismatch":
        return _POR_PATRON.get(ctx.get("pattern"), "El formato no es válido")
    if tipo == "value_error":  # validadores propios: ya están en español
        return str(err.get("msg", "")).removeprefix("Value error, ")
    plantilla = _POR_TIPO.get(tipo)
    try:
        return plantilla.format_map(ctx) if plantilla else str(err.get("msg", "Valor no válido"))
    except KeyError:
        return "Valor no válido"
