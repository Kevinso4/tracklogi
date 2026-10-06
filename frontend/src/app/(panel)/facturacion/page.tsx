"use client";

import { useState } from "react";
import { IconFactura } from "@/components/icons";
import { Badge, Boton, Card, Encabezado, ErrorCaja, Metrica, Segmentado, useAvisos, Vacio } from "@/components/ui";
import { api } from "@/lib/api";
import { fmtCOP, fmtFecha, fmtNum } from "@/lib/formato";
import { useDatos, useEventosEnVivo } from "@/lib/hooks";
import { usePuede } from "@/lib/sesion";

interface Costo {
  envio_id: string;
  codigo: string;
  cliente: string;
  ruta: string;
  distancia_km: number;
  costo_combustible: number;
  costo_peajes: number;
  costo_conductor: number;
  precio_cliente: number;
  a_tiempo: boolean;
  entregado_en: string;
  factura_id: string | null;
}
interface Factura { id: string; numero: number; cliente: string; periodo: string; envios: number; monto_total: number; emitida_en: string }
interface Resumen { envios: number; ingresos: number; costos: number; margen: number; costo_por_km: number | null; pendientes_de_facturar: number }

type Vista = "costos" | "facturas";
const mes = new Intl.DateTimeFormat("es-CO", { month: "long", year: "numeric" });

export default function Facturacion() {
  const avisar = useAvisos();
  const puede = usePuede("facturacion");
  const [vista, setVista] = useState<Vista>("costos");
  const [cerrando, setCerrando] = useState(false);
  const resumen = useDatos<Resumen>("/api/v1/facturacion/resumen", 8000);
  const costos = useDatos<Costo[]>("/api/v1/facturacion/costos", 8000);
  const facturas = useDatos<Factura[]>("/api/v1/facturacion/facturas", 8000);
  useEventosEnVivo(5, (e) => {
    if (e.tipo === "shipment.delivered" || e.tipo === "invoice.issued") {
      // Billing registra el costo un instante después de la entrega.
      setTimeout(() => { resumen.recargar(); costos.recargar(); facturas.recargar(); }, 1500);
    }
  });

  async function cerrarMes() {
    setCerrando(true);
    try {
      const emitidas = await api<Factura[]>("/api/v1/facturacion/cierre", { method: "POST" });
      avisar(`${emitidas.length} ${emitidas.length === 1 ? "factura emitida" : "facturas emitidas"}`);
      resumen.recargar(); costos.recargar(); facturas.recargar();
      setVista("facturas");
    } catch (err) {
      avisar(err instanceof Error ? err.message : "Error", "error");
    } finally {
      setCerrando(false);
    }
  }

  const r = resumen.datos;
  return (
    <>
      <Encabezado titulo="Facturación" subtitulo="Costo real de cada envío entregado y factura mensual por cliente.">
        {puede ? (
          <Boton onClick={cerrarMes} cargando={cerrando} disabled={!r?.pendientes_de_facturar}>
            Cerrar el mes{r?.pendientes_de_facturar ? ` (${r.pendientes_de_facturar})` : ""}
          </Boton>
        ) : (
          <Badge tono="gray">Solo consulta</Badge>
        )}
      </Encabezado>

      <section className="mb-6 grid grid-cols-2 gap-4 lg:grid-cols-4">
        <Metrica etiqueta="Ingresos" tono="indigo" valor={r ? fmtCOP(r.ingresos) : "—"} detalle={r ? `${r.envios} envíos entregados` : " "} />
        <Metrica etiqueta="Costo operativo" tono="orange" valor={r ? fmtCOP(r.costos) : "—"} detalle="Combustible, peajes y conductor" />
        <Metrica etiqueta="Margen" tono={r && r.margen < 0 ? "red" : "green"} valor={r ? fmtCOP(r.margen) : "—"}
          detalle={r && r.ingresos ? `${fmtNum((r.margen / r.ingresos) * 100)} % de los ingresos` : " "} />
        <Metrica etiqueta="Costo por km" tono="teal" valor={r?.costo_por_km != null ? fmtCOP(r.costo_por_km) : "—"} detalle="Promedio de la flota" />
      </section>

      <div className="mb-4">
        <Segmentado
          opciones={[
            { valor: "costos" as Vista, texto: "Costos por envío", cuenta: costos.datos?.length },
            { valor: "facturas" as Vista, texto: "Facturas", cuenta: facturas.datos?.length },
          ]}
          valor={vista}
          onChange={setVista}
        />
      </div>

      <Card padding={false} className="overflow-hidden">
        {(costos.error || facturas.error) && <div className="p-4"><ErrorCaja mensaje={(costos.error || facturas.error)!} /></div>}

        {vista === "costos" &&
          (costos.datos?.length ? (
            <ul className="divide-y divide-hairline">
              {costos.datos.map((c) => {
                const operativo = c.costo_combustible + c.costo_peajes + c.costo_conductor;
                return (
                  <li key={c.envio_id} className="flex flex-wrap items-center gap-4 px-5 py-3.5">
                    <span className="w-[90px] font-mono text-[13px] font-medium">{c.codigo}</span>
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-[15px] font-medium">{c.ruta}</p>
                      <p className="truncate text-[13px] text-label-2">{c.cliente} · {fmtNum(c.distancia_km)} km · {fmtFecha(c.entregado_en)}</p>
                    </div>
                    <div className="text-right text-[13px]">
                      <p className="font-semibold tabular">{fmtCOP(c.precio_cliente)}</p>
                      <p className="text-label-3 tabular">costo {fmtCOP(operativo)}</p>
                    </div>
                    <Badge tono={c.factura_id ? "green" : "orange"}>{c.factura_id ? "Facturado" : "Pendiente"}</Badge>
                  </li>
                );
              })}
            </ul>
          ) : (
            <Vacio icono={<IconFactura className="size-10" />} titulo="Aún no hay envíos entregados"
              texto="Cuando se registre una entrega, Billing calcula su costo automáticamente." />
          ))}

        {vista === "facturas" &&
          (facturas.datos?.length ? (
            <ul className="divide-y divide-hairline">
              {facturas.datos.map((f) => (
                <li key={f.id} className="flex flex-wrap items-center gap-4 px-5 py-3.5">
                  <span className="w-[90px] font-mono text-[13px] font-medium">N.º {f.numero}</span>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-[15px] font-medium">{f.cliente}</p>
                    <p className="text-[13px] text-label-2">
                      {mes.format(new Date(`${f.periodo}T12:00:00`))} · {f.envios} {f.envios === 1 ? "envío" : "envíos"}
                    </p>
                  </div>
                  <span className="text-[15px] font-semibold tabular">{fmtCOP(f.monto_total)}</span>
                </li>
              ))}
            </ul>
          ) : (
            <Vacio icono={<IconFactura className="size-10" />} titulo="Sin facturas todavía" texto="Usa «Cerrar el mes» para facturar los envíos pendientes." />
          ))}
      </Card>
    </>
  );
}
