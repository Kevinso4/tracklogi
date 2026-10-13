"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect } from "react";
import { useDatos } from "@/lib/hooks";
import { ETIQUETA_ROL, useSesion } from "@/lib/sesion";
import type { EstadoServicio } from "@/lib/types";
import { IconCaja, IconCamion, IconFactura, IconLlave, IconMapa, IconResumen, IconSalir } from "./icons";
import { cx } from "./ui";

// Mínimo privilegio: cada perfil solo ve los apartados de su área. Sin `roles`, el apartado es común.
// El operador conserva Flota en modo consulta porque necesita ver qué camiones hay disponibles.
// `servicio`: microservicio del que depende el apartado; si no está desplegado, el apartado no se ofrece.
const NAV: { href: string; texto: string; icono: typeof IconResumen; roles?: string[]; servicio?: string }[] = [
  { href: "/", texto: "Resumen", icono: IconResumen },
  { href: "/mapa", texto: "Seguimiento", icono: IconMapa },
  { href: "/envios", texto: "Envíos", icono: IconCaja, roles: ["admin", "operador"] },
  { href: "/flota", texto: "Flota", icono: IconCamion, roles: ["admin", "operador", "gestor_flota"] },
  { href: "/mantenimiento", texto: "Mantenimiento", icono: IconLlave, roles: ["admin", "gestor_flota"] },
  { href: "/facturacion", texto: "Facturación", icono: IconFactura, roles: ["admin", "operador"], servicio: "billing" },
];

const permitido = (item: (typeof NAV)[number], rol: string) => !item.roles || item.roles.includes(rol);

export function Logo({ className = "size-7" }: { className?: string }) {
  return (
    <div className={cx("grid place-items-center rounded-[9px] bg-gradient-to-br from-[#0a84ff] to-[#5e5ce6] text-white shadow-sm", className)}>
      <svg viewBox="0 0 24 24" className="size-[60%]" fill="none" stroke="currentColor" strokeWidth={2.2} strokeLinecap="round" strokeLinejoin="round">
        <path d="M4 17V7l8 5 8-5v10" />
      </svg>
    </div>
  );
}

export function Shell({ children }: { children: React.ReactNode }) {
  const { usuario, cargando, salir } = useSesion();
  const ruta = usePathname();
  const router = useRouter();
  const servicios = useDatos<EstadoServicio[]>(usuario ? "/api/v1/estado/servicios" : null, 30000);
  const caidos = new Set((servicios.datos ?? []).filter((x) => !x.ok).map((x) => x.servicio));

  // Apartado al que corresponde la URL actual; si el rol no lo tiene, vuelve al Resumen.
  const actual = NAV.find((i) => i.href !== "/" && ruta.startsWith(i.href));
  const sinAcceso = !!usuario && !!actual && !permitido(actual, usuario.rol);

  useEffect(() => {
    if (!cargando && !usuario) router.replace("/login");
    else if (sinAcceso) router.replace("/");
  }, [cargando, usuario, sinAcceso, router]);

  if (cargando || !usuario || sinAcceso) {
    return (
      <div className="grid min-h-dvh place-items-center">
        <Logo className="size-12 animate-pulse" />
      </div>
    );
  }

  const menu = NAV.filter((i) => permitido(i, usuario.rol) && !(i.servicio && caidos.has(i.servicio)));
  const iniciales = usuario.nombre.split(" ").map((p) => p[0]).slice(0, 2).join("");

  return (
    <div className="min-h-dvh md:pl-[248px]">
      {/* Barra lateral translúcida (escritorio) */}
      <aside className="glass fixed inset-y-0 left-0 z-40 hidden w-[248px] flex-col border-r border-hairline md:flex">
        <div className="flex items-center gap-2.5 px-5 pt-6 pb-5">
          <Logo />
          <span className="font-display text-[19px] font-semibold tracking-tight">LogiTrack</span>
        </div>
        <p className="px-6 pb-1.5 text-[11px] font-semibold tracking-[0.08em] text-label-3 uppercase">Operación</p>
        <nav className="flex-1 space-y-0.5 px-3">
          {menu.map(({ href, texto, icono: Icono }) => {
            const activo = href === "/" ? ruta === "/" : ruta.startsWith(href);
            return (
              <Link
                key={href}
                href={href}
                className={cx(
                  "nav-item flex h-9 items-center gap-3 rounded-[9px] px-3 text-[14px] font-medium transition-colors",
                  activo ? "bg-accent text-white" : "text-label hover:bg-fill",
                )}
              >
                <Icono className={cx("size-[18px]", !activo && "text-accent")} />
                {texto}
              </Link>
            );
          })}
        </nav>
        <div className="m-3 flex items-center gap-3 rounded-[14px] p-2.5 hover:bg-fill">
          <div className="grid size-9 place-items-center rounded-full bg-gradient-to-br from-[#8e8e93] to-[#636366] text-[13px] font-semibold text-white">
            {iniciales}
          </div>
          <div className="min-w-0 flex-1">
            <div className="truncate text-[13px] font-semibold">{usuario.nombre}</div>
            <div className="truncate text-[12px] text-label-2">{ETIQUETA_ROL[usuario.rol]}</div>
          </div>
          <button onClick={() => salir()} title="Cerrar sesión" aria-label="Cerrar sesión" className="grid size-8 place-items-center rounded-full text-label-2 hover:bg-fill-strong hover:text-label">
            <IconSalir />
          </button>
        </div>
      </aside>

      {/* Barra de pestañas inferior (móvil), como en iOS */}
      <nav className="glass fixed inset-x-0 bottom-0 z-40 flex border-t border-hairline pb-[env(safe-area-inset-bottom)] md:hidden">
        {menu.map(({ href, texto, icono: Icono }) => {
          const activo = href === "/" ? ruta === "/" : ruta.startsWith(href);
          return (
            <Link key={href} href={href} className={cx("flex flex-1 flex-col items-center gap-0.5 pt-2 pb-1.5 text-[10px] font-medium", activo ? "text-accent" : "text-label-3")}>
              <Icono className="size-6" />
              {texto}
            </Link>
          );
        })}
      </nav>

      <main key={ruta} className="mx-auto max-w-[1400px] px-4 pt-8 pb-28 sm:px-8 md:pb-12 animate-aparecer">{children}</main>
    </div>
  );
}
