"use client";

import { createContext, useCallback, useContext, useEffect, useState } from "react";
import { api, onSesionExpirada, refrescarSesion, setAccessToken } from "./api";
import type { Usuario } from "./types";

interface Sesion {
  usuario: Usuario | null;
  cargando: boolean;
  entrar: (usuario: string, clave: string) => Promise<void>;
  salir: () => Promise<void>;
}

const Contexto = createContext<Sesion | null>(null);

export function ProveedorSesion({ children }: { children: React.ReactNode }) {
  const [usuario, setUsuario] = useState<Usuario | null>(null);
  const [cargando, setCargando] = useState(true);

  useEffect(() => {
    // Al recargar la página se recupera la sesión desde la cookie HttpOnly de refresh.
    refrescarSesion()
      .then((datos) => setUsuario(datos?.usuario ?? null))
      .finally(() => setCargando(false));
    onSesionExpirada(() => {
      setAccessToken(null);
      setUsuario(null);
    });
  }, []);

  const entrar = useCallback(async (u: string, clave: string) => {
    const datos = await api<{ access_token: string; usuario: Usuario }>("/api/v1/auth/token", {
      method: "POST",
      json: { usuario: u, clave },
    });
    setAccessToken(datos.access_token);
    setUsuario(datos.usuario);
  }, []);

  const salir = useCallback(async () => {
    await api("/api/v1/auth/logout", { method: "POST" }).catch(() => undefined);
    setAccessToken(null);
    setUsuario(null);
  }, []);

  return <Contexto.Provider value={{ usuario, cargando, entrar, salir }}>{children}</Contexto.Provider>;
}

export function useSesion() {
  const s = useContext(Contexto);
  if (!s) throw new Error("useSesion debe usarse dentro de ProveedorSesion");
  return s;
}

/** Quién gestiona cada área. Refleja los requiere_rol del backend; el resto de roles solo consulta. */
const GESTIONA: Record<"envios" | "flota" | "mantenimiento" | "facturacion", string[]> = {
  envios: ["admin", "operador"],
  flota: ["admin", "gestor_flota"],
  mantenimiento: ["admin", "gestor_flota"],
  facturacion: ["admin", "operador"],
};

export function usePuede(area: keyof typeof GESTIONA) {
  const { usuario } = useSesion();
  return !!usuario && GESTIONA[area].includes(usuario.rol);
}

export const ETIQUETA_ROL: Record<string, string> = {
  admin: "Administrador",
  operador: "Operador logístico",
  gestor_flota: "Gestor de flota",
  conductor: "Conductor",
  cliente: "Cliente",
};
