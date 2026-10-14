"use client";

import { useState } from "react";
import { IconBuscar, IconChevron, IconMas, IconPersonas } from "@/components/icons";
import {
  Badge,
  Boton,
  Campo,
  Card,
  Encabezado,
  ErrorCaja,
  Esqueleto,
  Hoja,
  Input,
  Interruptor,
  Select,
  soloTelefono,
  useAvisos,
  Vacio,
} from "@/components/ui";
import { api } from "@/lib/api";
import { fmtCOP, plural } from "@/lib/formato";
import { useDatos } from "@/lib/hooks";
import type { Cliente } from "@/lib/types";

interface Tarifa { modelo: "por_km" | "por_envio"; valor: number }
interface Tarifas { por_defecto: Tarifa; clientes: (Tarifa & { cliente: string })[] }

const soloNit = (v: string) => v.replace(/[^0-9-]/g, "").slice(0, 14);
const textoTarifa = (t: Tarifa) => `${fmtCOP(t.valor)} ${t.modelo === "por_km" ? "por km" : "por envío"}`;

/** Alta (sin `cliente`) o edición. El nombre no se edita: Billing factura por nombre. */
function FormCliente({ cliente, tarifas, onListo }: { cliente?: Cliente; tarifas?: Tarifas; onListo: () => void }) {
  const avisar = useAvisos();
  const pactada = tarifas?.clientes.find((t) => t.cliente === cliente?.nombre);
  const [f, setF] = useState({
    nombre: cliente?.nombre ?? "",
    nit: cliente?.nit ?? "",
    email: cliente?.email ?? "",
    telefono: cliente?.telefono ?? "",
    activo: cliente?.activo ?? true,
    modelo: pactada?.modelo ?? "",
    valor: pactada ? String(pactada.valor) : "",
  });
  const [error, setError] = useState<string | null>(null);
  const [ocupado, setOcupado] = useState(false);
  const set = <K extends keyof typeof f>(k: K, v: (typeof f)[K]) => setF((x) => ({ ...x, [k]: v }));

  async function ejecutar(accion: () => Promise<unknown>, mensaje: string) {
    setOcupado(true);
    setError(null);
    try {
      await accion();
      avisar(mensaje);
      onListo();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Error");
    } finally {
      setOcupado(false);
    }
  }

  const guardar = (e: React.FormEvent) => {
    e.preventDefault();
    ejecutar(async () => {
      const json = { nombre: f.nombre, nit: f.nit, email: f.email || null, telefono: f.telefono || null, activo: f.activo };
      await api(cliente ? `/api/v1/clientes/${cliente.id}` : "/api/v1/clientes", { method: cliente ? "PUT" : "POST", json });
      // La tarifa pactada vive en Billing: se guarda allí solo si se definió o cambió.
      if (f.modelo && f.valor && (f.modelo !== pactada?.modelo || Number(f.valor) !== pactada?.valor)) {
        await api(`/api/v1/facturacion/tarifas/${encodeURIComponent(f.nombre.trim())}`, { method: "PUT", json: { modelo: f.modelo, valor: Number(f.valor) } });
      }
    }, cliente ? "Cliente actualizado" : `${f.nombre} registrado`);
  };

  return (
    <form onSubmit={guardar} className="space-y-4">
      <Campo etiqueta="Razón social" ayuda={cliente ? "No se puede cambiar: las facturas ya emitidas llevan este nombre." : undefined}>
        <Input value={f.nombre} onChange={(e) => set("nombre", e.target.value)} disabled={!!cliente} required minLength={2} maxLength={120} placeholder="Ej.: Distribuidora del Sinú S.A.S." />
      </Campo>
      <div className="grid grid-cols-2 gap-3">
        <Campo etiqueta="NIT">
          <Input inputMode="numeric" value={f.nit} onChange={(e) => set("nit", soloNit(e.target.value))} required pattern="[0-9]{6,12}(-[0-9])?" title="Solo números, de 6 a 12 dígitos. Ejemplo: 900123456-7" placeholder="900123456-7" />
        </Campo>
        <Campo etiqueta="Teléfono">
          <Input type="tel" inputMode="numeric" value={f.telefono} onChange={(e) => set("telefono", soloTelefono(e.target.value))} pattern="\+?[0-9 ]{7,15}" title="Solo números, de 7 a 15 dígitos" placeholder="3001234567" />
        </Campo>
      </div>
      <Campo etiqueta="Correo de notificación" ayuda="Aquí llegan los avisos de cada envío (asignación, incidencias, entrega).">
        <Input type="email" value={f.email} onChange={(e) => set("email", e.target.value)} maxLength={120} placeholder="logistica@empresa.co" />
      </Campo>
      {tarifas && (
        <div className="grid grid-cols-2 gap-3">
          <Campo etiqueta="Tarifa pactada">
            <Select value={f.modelo} onChange={(e) => set("modelo", e.target.value as typeof f.modelo)}>
              <option value="">General ({textoTarifa(tarifas.por_defecto)})</option>
              <option value="por_km">Por kilómetro</option>
              <option value="por_envio">Por envío</option>
            </Select>
          </Campo>
          <Campo etiqueta="Valor (COP)">
            <Input type="number" min="1" step="any" value={f.valor} onChange={(e) => set("valor", e.target.value)} disabled={!f.modelo} required={!!f.modelo} />
          </Campo>
        </div>
      )}
      {cliente && (
        <div className="rounded-[12px] bg-fill px-3">
          <Interruptor etiqueta="Cliente activo (puede recibir envíos nuevos)" activo={f.activo} onChange={(v) => set("activo", v)} />
        </div>
      )}
      {error && <ErrorCaja mensaje={error} />}
      <Boton type="submit" cargando={ocupado} className="h-11 w-full">{cliente ? "Guardar cambios" : "Registrar cliente"}</Boton>
      {cliente && cliente.envios === 0 && (
        <Boton type="button" variante="peligro" cargando={ocupado} className="h-11 w-full"
          onClick={() => confirm(`¿Eliminar a ${cliente.nombre}?`) && ejecutar(() => api(`/api/v1/clientes/${cliente.id}`, { method: "DELETE" }), "Cliente eliminado")}>
          Eliminar cliente
        </Boton>
      )}
    </form>
  );
}

export default function Clientes() {
  const [q, setQ] = useState("");
  const [creando, setCreando] = useState(false);
  const [editando, setEditando] = useState<Cliente | null>(null);
  const { datos, cargando, error, recargar } = useDatos<Cliente[]>(`/api/v1/clientes${q ? `?q=${encodeURIComponent(q)}` : ""}`, 15000);
  // Si Billing no está disponible, la página funciona igual, sin la tarifa.
  const tarifas = useDatos<Tarifas>("/api/v1/facturacion/tarifas", 30000);
  const listo = () => { setCreando(false); setEditando(null); recargar(); tarifas.recargar(); };

  return (
    <>
      <Encabezado titulo="Clientes" subtitulo="Empresas que contratan los envíos, su contacto y su tarifa.">
        <Boton onClick={() => setCreando(true)}><IconMas /> Nuevo cliente</Boton>
      </Encabezado>

      <div className="relative mb-4 w-full sm:w-72">
        <IconBuscar className="absolute top-1/2 left-3 size-4 -translate-y-1/2 text-label-3" />
        <Input placeholder="Buscar por nombre o NIT" value={q} onChange={(e) => setQ(e.target.value)} className="h-9 pl-9 text-[14px]" />
      </div>

      <Card padding={false} className="overflow-hidden">
        {error && <div className="p-4"><ErrorCaja mensaje={error} /></div>}
        {cargando && !datos ? (
          <div className="space-y-2 p-4">{[0, 1, 2].map((i) => <Esqueleto key={i} className="h-14" />)}</div>
        ) : !datos?.length ? (
          <Vacio icono={<IconPersonas className="size-10" />} titulo="No hay clientes" texto="Registra el primero con «Nuevo cliente»." />
        ) : (
          <ul className="divide-y divide-hairline">
            {datos.map((c, i) => {
              const tarifa = tarifas.datos?.clientes.find((t) => t.cliente === c.nombre);
              return (
                <li key={c.id} style={{ "--i": i } as React.CSSProperties} className="animate-fila">
                  <button onClick={() => setEditando(c)} className="flex w-full items-center gap-4 px-5 py-3.5 text-left transition hover:bg-fill/60">
                    <div className="grid size-10 shrink-0 place-items-center rounded-full bg-gradient-to-br from-[#0a84ff] to-[#5e5ce6] text-[14px] font-semibold text-white">
                      {c.nombre.split(" ").map((p) => p[0]).slice(0, 2).join("").toUpperCase()}
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-[15px] font-medium">{c.nombre}</p>
                      <p className="truncate text-[13px] text-label-2">NIT {c.nit}{c.email ? ` · ${c.email}` : ""}{c.telefono ? ` · ${c.telefono}` : ""}</p>
                    </div>
                    <span className="hidden text-right text-[13px] sm:block">
                      <span className="block text-label-3">Tarifa</span>
                      <span className="font-medium tabular">{tarifa ? textoTarifa(tarifa) : "General"}</span>
                    </span>
                    <Badge tono={c.envios ? "accent" : "gray"}>{plural(c.envios, "envío", "envíos")}</Badge>
                    {!c.activo && <Badge tono="red">Inactivo</Badge>}
                    <IconChevron className="size-4 text-label-3" />
                  </button>
                </li>
              );
            })}
          </ul>
        )}
      </Card>

      <Hoja abierta={creando} onCerrar={() => setCreando(false)} titulo="Nuevo cliente">
        <FormCliente tarifas={tarifas.datos ?? undefined} onListo={listo} />
      </Hoja>
      <Hoja abierta={!!editando} onCerrar={() => setEditando(null)} titulo="Editar cliente">
        {editando && <FormCliente key={editando.id} cliente={editando} tarifas={tarifas.datos ?? undefined} onListo={listo} />}
      </Hoja>
    </>
  );
}
