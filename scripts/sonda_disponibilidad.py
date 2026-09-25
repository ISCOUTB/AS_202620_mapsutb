#!/usr/bin/env python3
"""Sonda de disponibilidad del sitio desplegado (Escenario 6, ADR 0008).

Hace una petición a la URL pública y otra a su health check, agrega una
muestra a <dir>/disponibilidad.jsonl (una línea JSON por muestra) y
recalcula <dir>/resumen.json con la métrica del escenario sobre los
últimos 7 días:

  disponibilidad_pct   % de muestras en que sitio y health respondieron 200
  latencia_p95_ms      p95 del tiempo de respuesta del health check

Uso: python scripts/sonda_disponibilidad.py <url_base> <dir_salida>
Nunca falla por que el sitio esté caído: eso es un dato, no un error.
"""
import json
import math
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path

VENTANA = timedelta(days=7)
# Umbrales del Escenario 6 (docs/escenarios_calidad.md).
META_DISPONIBILIDAD_PCT = 99.0
META_P95_MS = 1000


def medir(url):
    inicio = time.monotonic()
    try:
        with urllib.request.urlopen(url, timeout=15) as r:
            r.read()
            codigo = r.status
    except urllib.error.HTTPError as ex:
        codigo = ex.code
    except Exception:  # timeout, DNS, conexión rechazada
        codigo = 0
    return codigo, round((time.monotonic() - inicio) * 1000)


def p95(valores):
    if not valores:
        return None
    ordenados = sorted(valores)
    return ordenados[max(0, math.ceil(0.95 * len(ordenados)) - 1)]


def main(url_base, dir_salida):
    url_base = url_base.rstrip("/") + "/"
    salida = Path(dir_salida)
    salida.mkdir(parents=True, exist_ok=True)
    ahora = datetime.now(timezone.utc)

    http_sitio, ms_sitio = medir(url_base)
    http_health, ms_health = medir(url_base + "health.json")
    muestra = {
        "ts": ahora.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "url": url_base,
        "http_sitio": http_sitio,
        "ms_sitio": ms_sitio,
        "http_health": http_health,
        "ms_health": ms_health,
        "disponible": http_sitio == 200 and http_health == 200,
    }
    registro = salida / "disponibilidad.jsonl"
    with registro.open("a", encoding="utf-8") as f:
        f.write(json.dumps(muestra) + "\n")
    print(json.dumps(muestra))

    desde = ahora - VENTANA
    muestras = []
    for linea in registro.read_text(encoding="utf-8").splitlines():
        m = json.loads(linea)
        ts = datetime.strptime(m["ts"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
        if ts >= desde:
            muestras.append(m)

    disponibles = [m for m in muestras if m["disponible"]]
    disponibilidad = round(100 * len(disponibles) / len(muestras), 2)
    latencia = p95([m["ms_health"] for m in disponibles])
    resumen = {
        "escenario": "Escenario 6 — Disponibilidad del despliegue web",
        "ventana": "7 días",
        "actualizado": muestra["ts"],
        "muestras": len(muestras),
        "disponibilidad_pct": disponibilidad,
        "latencia_p95_ms": latencia,
        "meta": {"disponibilidad_pct": META_DISPONIBILIDAD_PCT, "latencia_p95_ms": META_P95_MS},
        "cumple": disponibilidad >= META_DISPONIBILIDAD_PCT
        and latencia is not None
        and latencia < META_P95_MS,
    }
    (salida / "resumen.json").write_text(json.dumps(resumen, indent=2, ensure_ascii=False) + "\n",
                                         encoding="utf-8")
    print(json.dumps(resumen, ensure_ascii=False))


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
