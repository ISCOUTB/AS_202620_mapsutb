#!/usr/bin/env python3
"""Medición complementaria del Escenario 6 desde un cliente real (S14).

La sonda de ADR 0008 mide desde los servidores de GitHub Actions, no desde
la red de un usuario. Este script hace N peticiones secuenciales, con una
pausa fija entre ellas, a la página principal y a `/health.json` desde la
máquina donde se ejecuta, y guarda cada muestra en un JSONL más un resumen.

Uso:
  python scripts/medicion/medir_cliente.py https://mapsutb.web.app/ 60 salida.jsonl [--pausa 2]

Cada petición abre una conexión nueva (sin keep-alive) y pide sin caché
(`Cache-Control: no-cache`), así que el tiempo incluye DNS, TCP y TLS, como
la primera visita de un usuario.
"""
import argparse
import json
import math
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone


def medir(url):
    peticion = urllib.request.Request(url, headers={"Cache-Control": "no-cache", "User-Agent": "mapsutb-medicion/1.0"})
    inicio = time.monotonic()
    try:
        with urllib.request.urlopen(peticion, timeout=15) as r:
            r.read()
            codigo = r.status
    except urllib.error.HTTPError as ex:
        codigo = ex.code
    except Exception:  # tiempo agotado, DNS, conexión rechazada
        codigo = 0
    return codigo, round((time.monotonic() - inicio) * 1000)


def percentil(valores, p):
    ordenados = sorted(valores)
    return ordenados[max(0, math.ceil(p * len(ordenados)) - 1)]


def main():
    sys.stdout.reconfigure(encoding="utf-8")  # consola de Windows
    parser = argparse.ArgumentParser()
    parser.add_argument("url")
    parser.add_argument("repeticiones", type=int)
    parser.add_argument("salida")
    parser.add_argument("--pausa", type=float, default=2.0)
    args = parser.parse_args()
    base = args.url.rstrip("/") + "/"

    muestras = []
    with open(args.salida, "w", encoding="utf-8") as f:
        for i in range(args.repeticiones):
            http_sitio, ms_sitio = medir(base)
            http_health, ms_health = medir(base + "health.json")
            m = {"ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"), "i": i + 1,
                 "http_sitio": http_sitio, "ms_sitio": ms_sitio,
                 "http_health": http_health, "ms_health": ms_health,
                 "disponible": http_sitio == 200 and http_health == 200}
            f.write(json.dumps(m) + "\n")
            muestras.append(m)
            time.sleep(args.pausa)

    health = [m["ms_health"] for m in muestras]
    sitio = [m["ms_sitio"] for m in muestras]
    print(json.dumps({
        "url": base,
        "repeticiones": len(muestras),
        "desde": muestras[0]["ts"],
        "hasta": muestras[-1]["ts"],
        "disponibilidad_pct": round(100 * sum(m["disponible"] for m in muestras) / len(muestras), 2),
        "health_ms": {"p50": percentil(health, 0.5), "p95": percentil(health, 0.95), "max": max(health)},
        "sitio_ms": {"p50": percentil(sitio, 0.5), "p95": percentil(sitio, 0.95), "max": max(sitio)},
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
