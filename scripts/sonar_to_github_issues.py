#!/usr/bin/env python3
"""Sincroniza issues abiertos de SonarCloud con GitHub Issues, etiquetados
'sonar-finding', para que el workflow "Auto-add to project" de GitHub Projects
los sume solos al backlog.

Idempotente: cada issue de Sonar lleva una marca oculta <!-- sonar-key: X -->
en el cuerpo del issue de GitHub; si ya existe uno con esa marca, no duplica.
Si un issue de Sonar se resuelve, cierra el issue de GitHub correspondiente.

Variables de entorno requeridas:
  SONAR_TOKEN         token de SonarCloud (secret del repo)
  GITHUB_TOKEN        provisto automaticamente por GitHub Actions
  GITHUB_REPOSITORY   provisto automaticamente ("ISCOUTB/AS_202620_mapsutb")
  SONAR_PROJECT_KEY   opcional, default ISCOUTB_AS_202620_mapsutb
"""
import base64
import json
import os
import re
import sys
import urllib.error
import urllib.request

SONAR_TOKEN = os.environ["SONAR_TOKEN"]
GITHUB_TOKEN = os.environ["GITHUB_TOKEN"]
REPO = os.environ["GITHUB_REPOSITORY"]
PROJECT_KEY = os.environ.get("SONAR_PROJECT_KEY", "ISCOUTB_AS_202620_mapsutb")
LABEL = "sonar-finding"
MARCA_RE = re.compile(r"<!-- sonar-key: (\S+) -->")


def sonar_get(path, params):
    qs = "&".join("%s=%s" % (k, urllib.request.quote(str(v))) for k, v in params.items())
    url = "https://sonarcloud.io/api/%s?%s" % (path, qs)
    auth = base64.b64encode((SONAR_TOKEN + ":").encode()).decode()
    req = urllib.request.Request(url, headers={"Authorization": "Basic " + auth})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode("utf-8"))


def gh_request(method, path, body=None):
    url = "https://api.github.com" + path
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(url, data=data, method=method, headers={
        "Authorization": "Bearer " + GITHUB_TOKEN,
        "Accept": "application/vnd.github+json",
        "User-Agent": "mapsutb-sonar-sync/1.0",
    })
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.loads(r.read().decode("utf-8")) if r.length != 0 else {}
    except urllib.error.HTTPError as ex:
        print("GitHub API error %s en %s: %s" % (ex.code, path, ex.read()[:300]))
        raise


def sonar_issues_abiertos():
    out, page = [], 1
    while True:
        data = sonar_get("issues/search", {
            "componentKeys": PROJECT_KEY, "resolved": "false", "ps": 100, "p": page,
        })
        out.extend(data.get("issues", []))
        if page * 100 >= data.get("paging", {}).get("total", 0):
            break
        page += 1
    return out


def github_issues_de_sonar():
    out, page = [], 1
    while True:
        data = gh_request("GET", "/repos/%s/issues?labels=%s&state=all&per_page=100&page=%d"
                           % (REPO, LABEL, page))
        if not data:
            break
        out.extend(i for i in data if "pull_request" not in i)
        page += 1
    return out


def cuerpo_issue(it):
    comp = it["component"].split(":", 1)[-1]
    linea = it.get("textRange", {}).get("startLine", it.get("line", "?"))
    permalink = "https://sonarcloud.io/project/issues?id=%s&issues=%s&open=%s" % (
        PROJECT_KEY, it["key"], it["key"])
    return (
        "**Archivo:** `%s:%s`\n\n"
        "**Regla:** `%s` · **Severidad:** %s · **Tipo:** %s\n\n"
        "%s\n\n"
        "[Ver en SonarCloud](%s)\n\n"
        "<!-- sonar-key: %s -->"
    ) % (comp, linea, it["rule"], it.get("severity", "?"), it.get("type", "?"),
         it.get("message", ""), permalink, it["key"])


def main():
    abiertos = sonar_issues_abiertos()
    claves_abiertas = {it["key"] for it in abiertos}
    existentes = github_issues_de_sonar()

    marcadas = {}
    for gh in existentes:
        m = MARCA_RE.search(gh.get("body") or "")
        if m:
            marcadas[m.group(1)] = gh

    creados, cerrados = 0, 0
    for it in abiertos:
        if it["key"] in marcadas:
            continue
        comp = it["component"].split(":", 1)[-1]
        linea = it.get("textRange", {}).get("startLine", it.get("line", "?"))
        titulo = "[Sonar] %s:%s — %s" % (comp, linea, it.get("message", "")[:80])
        gh_request("POST", "/repos/%s/issues" % REPO, {
            "title": titulo, "body": cuerpo_issue(it), "labels": [LABEL],
        })
        creados += 1

    for key, gh in marcadas.items():
        if key not in claves_abiertas and gh["state"] == "open":
            gh_request("PATCH", "/repos/%s/issues/%d" % (REPO, gh["number"]),
                       {"state": "closed", "state_reason": "completed"})
            cerrados += 1

    print("Sonar: %d issues abiertos. GitHub: %d creados, %d cerrados (ya resueltos en Sonar)."
          % (len(abiertos), creados, cerrados))


if __name__ == "__main__":
    sys.exit(main())
