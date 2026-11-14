#!/usr/bin/env python3
"""Medición del Escenario 6 (DI-03) sobre las muestras de la sonda (S14).

Lee el registro que la sonda horaria publica en la rama `metricas`
(`disponibilidad.jsonl`, ADR 0008) y lo corta en ventanas consecutivas de
7 días, la ventana que fija el escenario. Cada ventana es una repetición de
la medición; para cada una calcula:

  muestras / esperadas   cuántas horas tuvieron muestra (la sonda corre cada hora)
  disponibilidad_pct     % de muestras con sitio y health en HTTP 200
  p95_health_ms          p95 del tiempo de respuesta del health check
  p95_sitio_ms           p95 del tiempo de respuesta de la página principal

El p95 se calcula sobre TODAS las muestras de la ventana, también las
fallidas (a diferencia de `resumen.json`, que solo usa las disponibles):
una caída o un tiempo agotado cuenta como respuesta lenta, no desaparece.

Uso:
  git show origin/metricas:disponibilidad.jsonl > disponibilidad.jsonl
  python scripts/medicion/analizar_disponibilidad.py disponibilidad.jsonl [--hasta AAAA-MM-DD]

Imprime una tabla Markdown y un JSON con el veredicto frente a los umbrales
de docs/escenarios_calidad.md (Escenario 6): disponibilidad >= 99 % y
p95 del health < 1000 ms.
"""
import argparse
import json
import math
import sys
from datetime import datetime, timedelta, timezone

META_DISPONIBILIDAD_PCT = 99.0
META_P95_MS = 1000
VENTANA = timedelta(days=7)
FORMATO_TS = "%Y-%m-%dT%H:%M:%SZ"


def p95(valores):
    """Percentil 95 por rango más cercano (el mismo de la sonda)."""
    if not valores:
        return None
    ordenados = sorted(valores)
    return ordenados[max(0, math.ceil(0.95 * len(ordenados)) - 1)]


def leer(lineas):
    muestras = []
    for linea in lineas:
        linea = linea.strip()
        if not linea:
            continue
        m = json.loads(linea)
        m["_ts"] = datetime.strptime(m["ts"], FORMATO_TS).replace(tzinfo=timezone.utc)
        muestras.append(m)
    return sorted(muestras, key=lambda m: m["_ts"])


def ventanas(muestras, hasta):
    """Ventanas de 7 días completas, contadas hacia atrás desde `hasta`."""
    if not muestras:
        return []
    inicio_datos = muestras[0]["_ts"]
    resultado = []
    fin = hasta
    while fin - VENTANA >= inicio_datos:
        desde = fin - VENTANA
        dentro = [m for m in muestras if desde <= m["_ts"] < fin]
        resultado.append(resumir(desde, fin, dentro))
        fin = desde
    return list(reversed(resultado))


def resumir(desde, hasta, muestras):
    esperadas = int((hasta - desde) / timedelta(hours=1))
    disponibles = [m for m in muestras if m["disponible"]]
    disponibilidad = round(100 * len(disponibles) / len(muestras), 2) if muestras else None
    p95_health = p95([m["ms_health"] for m in muestras])
    return {
        "desde": desde.strftime(FORMATO_TS),
        "hasta": hasta.strftime(FORMATO_TS),
        "muestras": len(muestras),
        "esperadas": esperadas,
        "caidas": len(muestras) - len(disponibles),
        "disponibilidad_pct": disponibilidad,
        "p95_health_ms": p95_health,
        "max_health_ms": max((m["ms_health"] for m in muestras), default=None),
        "p95_sitio_ms": p95([m["ms_sitio"] for m in muestras]),
        "cumple": disponibilidad is not None
        and disponibilidad >= META_DISPONIBILIDAD_PCT
        and p95_health is not None
        and p95_health < META_P95_MS,
    }


def tabla(filas):
    encabezado = (
        "| Ventana (UTC) | Muestras / esperadas | Caídas | Disponibilidad | p95 health | máx. health "
        "| p95 sitio | ¿Cumple? |\n|---|---|---|---|---|---|---|---|"
    )
    cuerpo = [
        f"| {f['desde'][:10]} → {f['hasta'][:10]} | {f['muestras']} / {f['esperadas']} | {f['caidas']} "
        f"| {f['disponibilidad_pct']} % | {f['p95_health_ms']} ms | {f['max_health_ms']} ms "
        f"| {f['p95_sitio_ms']} ms | {'sí' if f['cumple'] else 'no'} |"
        for f in filas
    ]
    return "\n".join([encabezado, *cuerpo])


def main():
    sys.stdout.reconfigure(encoding="utf-8")  # consola de Windows
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("registro", help="disponibilidad.jsonl de la rama metricas")
    parser.add_argument("--hasta", help="fin (exclusivo) de la última ventana, AAAA-MM-DD; por defecto hoy 00:00 UTC")
    args = parser.parse_args()

    hasta = (
        datetime.strptime(args.hasta, "%Y-%m-%d").replace(tzinfo=timezone.utc)
        if args.hasta
        else datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
    )
    with open(args.registro, encoding="utf-8") as f:
        muestras = leer(f)
    filas = ventanas(muestras, hasta)
    print(tabla(filas))
    total = None
    if filas:
        desde = hasta - VENTANA * len(filas)
        total = resumir(desde, hasta, [m for m in muestras if desde <= m["_ts"] < hasta])
    print(json.dumps({"ventanas": len(filas),
                      "ventanas_que_cumplen": sum(f["cumple"] for f in filas),
                      "periodo_completo": total,
                      "meta": {"disponibilidad_pct": META_DISPONIBILIDAD_PCT, "p95_health_ms": META_P95_MS}},
                     ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
