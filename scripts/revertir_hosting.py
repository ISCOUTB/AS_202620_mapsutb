#!/usr/bin/env python3
"""Reversión del sitio en Firebase Hosting a la versión publicada anterior,
con medición de tiempo (taller de despliegue, condición «necesidad de
reversión»; ADR 0010, Escenario 7).

Pasos:
  1. Lista los releases del canal live y toma el actual y el anterior.
  2. Publica de nuevo la versión anterior (sin recompilar nada).
  3. Mide hasta que /health.json responde con un commit distinto al actual.
  4. Si --restaurar, vuelve a publicar la versión original y mide igual.

Uso (en CI, con la cuenta de servicio en FIREBASE_SERVICE_ACCOUNT):
  python scripts/revertir_hosting.py --sitio mapsutb [--restaurar] [--salida resultado.json]

Requiere: pip install google-auth requests
"""
import argparse
import json
import os
import sys
import time

import requests
from google.auth.transport.requests import Request
from google.oauth2 import service_account

API = "https://firebasehosting.googleapis.com/v1beta1"
ESPERA_MAX_S = 300


def token():
    info = json.loads(os.environ["FIREBASE_SERVICE_ACCOUNT"])
    cred = service_account.Credentials.from_service_account_info(
        info, scopes=["https://www.googleapis.com/auth/cloud-platform"])
    cred.refresh(Request())
    return cred.token


def releases(sesion, sitio):
    r = sesion.get(f"{API}/sites/{sitio}/channels/live/releases", params={"pageSize": 20})
    r.raise_for_status()
    # Del más reciente al más antiguo, sin depender del orden de la API.
    return sorted(r.json().get("releases", []), key=lambda x: x["releaseTime"], reverse=True)


def publicar(sesion, sitio, version):
    r = sesion.post(f"{API}/sites/{sitio}/channels/live/releases",
                    params={"versionName": version}, json={"message": "reversion medida (taller)"})
    r.raise_for_status()
    return r.json()


def commit_en_linea(sitio):
    try:
        r = requests.get(f"https://{sitio}.web.app/health.json",
                         params={"t": time.time()}, timeout=10,
                         headers={"Cache-Control": "no-cache"})
        return r.json().get("commit") if r.status_code == 200 else None
    except (requests.RequestException, ValueError):
        return None


def esperar(sitio, condicion):
    """Devuelve (segundos, commit) cuando el commit en línea cumple la condición."""
    inicio = time.monotonic()
    while time.monotonic() - inicio < ESPERA_MAX_S:
        commit = commit_en_linea(sitio)
        if commit and condicion(commit):
            return round(time.monotonic() - inicio, 1), commit
        time.sleep(1)
    raise TimeoutError(f"health.json no cambió en {ESPERA_MAX_S} s")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--sitio", required=True)
    p.add_argument("--restaurar", action="store_true")
    p.add_argument("--salida")
    a = p.parse_args()

    sesion = requests.Session()
    sesion.headers["Authorization"] = f"Bearer {token()}"

    lista = releases(sesion, a.sitio)
    actual = lista[0]["version"]["name"]
    anterior = next((r["version"]["name"] for r in lista[1:] if r["version"]["name"] != actual), None)
    if not anterior:
        sys.exit("No hay una versión anterior distinta a la actual para revertir.")

    commit_actual = commit_en_linea(a.sitio)
    print(f"Versión actual: {actual} (commit {commit_actual})")
    print(f"Versión anterior: {anterior}")

    t0 = time.monotonic()
    publicar(sesion, a.sitio, anterior)
    api_s = round(time.monotonic() - t0, 1)
    espera_s, commit_revertido = esperar(a.sitio, lambda c: c != commit_actual)
    resultado = {
        "sitio": a.sitio,
        "alternativa": "Firebase Hosting (release de la versión anterior)",
        "commit_antes": commit_actual,
        "commit_revertido": commit_revertido,
        "reversion": {"llamada_api_s": api_s, "hasta_health_s": espera_s, "total_s": round(api_s + espera_s, 1)},
        "recompila": False,
    }
    print(f"Revertido a {commit_revertido} en {resultado['reversion']['total_s']} s")

    if a.restaurar:
        t0 = time.monotonic()
        publicar(sesion, a.sitio, actual)
        api_s = round(time.monotonic() - t0, 1)
        espera_s, commit_final = esperar(a.sitio, lambda c: c == commit_actual)
        resultado["restauracion"] = {"llamada_api_s": api_s, "hasta_health_s": espera_s,
                                     "total_s": round(api_s + espera_s, 1), "commit": commit_final}
        print(f"Restaurado a {commit_final} en {resultado['restauracion']['total_s']} s")

    texto = json.dumps(resultado, indent=2, ensure_ascii=False)
    print(texto)
    if a.salida:
        with open(a.salida, "w", encoding="utf-8") as f:
            f.write(texto + "\n")


if __name__ == "__main__":
    main()
