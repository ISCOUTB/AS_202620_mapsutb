#!/usr/bin/env python3
"""Análisis incremental del levantamiento de campo de MAPSUTB.

Relee TODA la carpeta de datos de campo (por defecto C:\\mapsutb-campo), une lo
exportado por las herramientas web y GPS Logger, sincroniza los videos de las
gafas, descarga el área del campus de OpenStreetMap y cruza todo. Deja en
<carpeta>/resultados/:

  informe.md                 hallazgos y pendientes para la siguiente salida
  mapa.svg                   mapa visual: OSM + recorridos + puntos
  datos_unificados.json      recorridos, puntos, marcas SYNC y videos ya unidos
  osm-campus.osm             copia de la descarga de OSM usada

Se ejecuta de nuevo cada vez que se agregan datos: no guarda estado propio.
Procedimiento y decisiones: docs/levantamiento-campo.md, ADR 0011.

Uso:  python scripts/campo/analizar_campo.py [carpeta] [--sin-osm]
Requiere defusedxml (python -m pip install defusedxml); los videos, ffprobe en el PATH.
"""
import csv
import datetime as dt
import glob
import json
import math
import os
import shutil
import subprocess
import sys
import urllib.request
from collections import Counter, defaultdict

try:
    # El XML viene de internet (OSM) y del celular (GPX): parser sin entidades externas.
    import defusedxml.ElementTree as ET
except ImportError:
    sys.exit("Falta defusedxml: python -m pip install defusedxml")

BBOX = (-75.4690, 10.3650, -75.4605, 10.3725)  # oeste, sur, este, norte del Campus Tecnológico
LAT0 = 10.368
KX = math.cos(math.radians(LAT0)) * 111320
KY = 110540
CAMINABLE = {"footway", "steps", "path", "pedestrian", "service", "living_street",
             "residential", "unclassified", "track", "corridor"}
LEJOS_M = 12          # una muestra a más de esto de cualquier camino trazado es "fuera de lo trazado"
MIN_TRAMO = 4         # muestras seguidas para reportar un tramo fuera de lo trazado
DESFASE_GAFAS_S = -0.48  # medido el 2026-10-01 con el destello SYNC: las gafas van adelantadas

ZONAS_JSON = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "data", "zonas.json")


# ---------------------------------------------------------------- utilidades
def xy(lat, lng):
    return lng * KX, lat * KY


def dist_seg(p, a, b):
    (px, py), (ax, ay), (bx, by) = p, a, b
    dx, dy = bx - ax, by - ay
    l2 = dx * dx + dy * dy
    t = 0 if l2 == 0 else max(0, min(1, ((px - ax) * dx + (py - ay) * dy) / l2))
    return math.hypot(px - ax - t * dx, py - ay - t * dy)


def metros_geo(a, b):
    """Distancia en metros entre dos (lat, lng), con el coseno de su propia latitud."""
    la1, la2 = math.radians(a[0]), math.radians(b[0])
    x = math.radians(b[1] - a[1]) * math.cos((la1 + la2) / 2)
    return 6371000 * math.hypot(x, la2 - la1)


def adentro(p, poly):
    x, y = p
    c = False
    for (x1, y1), (x2, y2) in zip(poly, poly[1:] + poly[:1]):
        if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1) + x1:
            c = not c
    return c


def iso(t):
    return dt.datetime.fromisoformat(t.replace("Z", "+00:00"))


# ---------------------------------------------------------------- lectura
def leer_exportaciones(carpeta):
    """Devuelve (muestras, puntos, sync) sin duplicados, de todas las fuentes."""
    muestras, puntos, sync = {}, {}, {}
    fuentes = Counter()

    def punto(lat, lng, props, origen):
        t = props.get("ts") or props.get("t") or ""
        clave = (round(lat, 6), round(lng, 6), t[:19])
        if clave not in puntos:
            puntos[clave] = {"lat": lat, "lng": lng, "t": t, "origen": origen,
                             **{k: v for k, v in props.items() if k not in ("ts", "t")}}

    def muestra(m, origen):
        clave = (m["t"][:19], round(m["lat"], 6), round(m["lng"], 6))
        if clave not in muestras:
            muestras[clave] = {**m, "origen": origen}

    for ruta in sorted(glob.glob(os.path.join(carpeta, "exportaciones", "*")) +
                       glob.glob(os.path.join(carpeta, "gpslogger", "*"))):
        nombre = os.path.basename(ruta)
        ext = nombre.lower().rsplit(".", 1)[-1]
        try:
            if ext == "json":
                s = json.load(open(ruta, encoding="utf-8"))
                for m in s.get("track", []):
                    muestra(m, nombre)
                for p in s.get("puntos", []):
                    punto(p["lat"], p["lng"], {k: v for k, v in p.items() if k not in ("lat", "lng")}, nombre)
                for x in s.get("sync", []):
                    sync.setdefault(x["t"][:22], {**x, "origen": nombre})
                fuentes["sesión de Grabar recorrido (JSON)"] += 1
            elif ext == "geojson":
                g = json.load(open(ruta, encoding="utf-8"))
                for f in g.get("features", []):
                    geo, props = f["geometry"], f.get("properties", {})
                    if geo["type"] == "Point":
                        lng, lat = geo["coordinates"][:2]
                        if len(geo["coordinates"]) > 2 and "alt" not in props:
                            props = {**props, "alt": geo["coordinates"][2]}
                        punto(lat, lng, props, nombre)
                    elif geo["type"] == "LineString" and props.get("tiempos"):
                        for i, c in enumerate(geo["coordinates"]):
                            muestra({"t": props["tiempos"][i], "lat": c[1], "lng": c[0],
                                     "alt": c[2] if len(c) > 2 else None,
                                     "acc": (props.get("precision_m") or [None] * len(geo["coordinates"]))[i],
                                     "zona": (props.get("zona") or [None] * len(geo["coordinates"]))[i],
                                     "piso": (props.get("piso") or [None] * len(geo["coordinates"]))[i]}, nombre)
                fuentes["GeoJSON"] += 1
            elif ext == "gpx":
                ns = {"g": "http://www.topografix.com/GPX/1/1"}
                r = ET.parse(ruta).getroot()
                if not r.tag.endswith("gpx"):
                    continue
                pref = r.tag[: r.tag.index("}") + 1] if r.tag.startswith("{") else ""
                for tp in r.iter(pref + "trkpt"):
                    t = tp.find(pref + "time")
                    e = tp.find(pref + "ele")
                    if t is None:
                        continue
                    muestra({"t": t.text, "lat": float(tp.get("lat")), "lng": float(tp.get("lon")),
                             "alt": float(e.text) if e is not None else None, "acc": None,
                             "zona": None, "piso": None}, nombre)
                for w in r.iter(pref + "wpt"):
                    n = w.find(pref + "name")
                    t = w.find(pref + "time")
                    nom = n.text if n is not None else ""
                    if nom.startswith("SYNC"):
                        continue
                    punto(float(w.get("lat")), float(w.get("lon")),
                          {"t": t.text if t is not None else "", "nota": nom, "tipo": "gpx"}, nombre)
                fuentes["GPX"] += 1
            elif ext == "csv":
                with open(ruta, encoding="utf-8-sig") as f:
                    filas = list(csv.DictReader(f))
                if filas and {"lat", "lng"} <= set(filas[0]):
                    for fl in filas:
                        punto(float(fl["lat"]), float(fl["lng"]),
                              {k: v for k, v in fl.items() if k not in ("lat", "lng") and v != ""}, nombre)
                    fuentes["CSV de puntos"] += 1
        except Exception as e:  # un archivo dañado no detiene el resto
            print(f"  ! no se pudo leer {nombre}: {e}")
    m = sorted(muestras.values(), key=lambda x: x["t"])
    p = sorted(puntos.values(), key=lambda x: x.get("t") or "")
    s = sorted(sync.values(), key=lambda x: x["t"])
    return m, p, s, fuentes


MAX_SEG_EMPAREJA = 90     # dos registros del mismo lugar no se toman con más diferencia
MAX_DIST_EMPAREJA = 40.0  # ni más lejos que esto


def emparejar(puntos):
    """Une registros del MISMO lugar hechos con herramientas distintas.

    El equipo marcó varios puntos a la vez en la herramienta web y en GPS
    Logger: son dos mediciones independientes del mismo sitio. Se conserva la
    de la herramienta web (trae tipo, zona y promediado) y la otra queda como
    confirmación, con la distancia entre ambas como medida del error del GPS.
    """
    def hora(p):
        try:
            return iso(p["t"]) if p.get("t") else None
        except ValueError:
            return None

    principales, sueltos = [], []
    for p in sorted(puntos, key=lambda x: (x.get("tipo") == "gpx", x.get("t") or "")):
        (sueltos if p.get("tipo") == "gpx" else principales).append(p)
    usados = set()
    for p in principales:
        tp = hora(p)
        mejor = None
        for i, q in enumerate(sueltos):
            if i in usados:
                continue
            tq = hora(q)
            if not tp or not tq or abs((tp - tq).total_seconds()) > MAX_SEG_EMPAREJA:
                continue
            d = metros_geo((p["lat"], p["lng"]), (q["lat"], q["lng"]))
            if d <= MAX_DIST_EMPAREJA and (mejor is None or d < mejor[0]):
                mejor = (d, i, q)
        if mejor:
            d, i, q = mejor
            usados.add(i)
            p["confirmado_por"] = q["origen"]
            p["discrepancia_m"] = round(d, 1)
    restantes = [q for i, q in enumerate(sueltos) if i not in usados]
    return principales + restantes


def leer_videos(carpeta, sync):
    videos = []
    if not shutil.which("ffprobe"):
        return videos
    for ruta in sorted(glob.glob(os.path.join(carpeta, "videos", "*"))):
        if not ruta.lower().endswith((".mov", ".mp4")):
            continue
        out = subprocess.run(["ffprobe", "-v", "error", "-show_entries",
                              "format=duration:format_tags=com.apple.quicktime.creationdate,creation_time",
                              "-of", "json", ruta], capture_output=True, text=True).stdout
        fmt = json.loads(out or "{}").get("format", {})
        tags = fmt.get("tags", {})
        inicio = tags.get("com.apple.quicktime.creationdate") or tags.get("creation_time")
        if not inicio:
            continue
        ini = iso(inicio) + dt.timedelta(seconds=DESFASE_GAFAS_S)
        dur = float(fmt.get("duration", 0))
        fin = ini + dt.timedelta(seconds=dur)
        marcas = [x["n"] for x in sync if ini <= iso(x["t"]) <= fin]
        videos.append({"archivo": os.path.basename(ruta), "inicio_utc": ini.isoformat(),
                       "fin_utc": fin.isoformat(), "duracion_s": round(dur, 1), "sync": marcas})
    return sorted(videos, key=lambda v: v["inicio_utc"])


def video_en(videos, t):
    if not t:
        return None
    tt = iso(t)
    for v in videos:
        a, b = iso(v["inicio_utc"]), iso(v["fin_utc"])
        if a <= tt <= b:
            s = (tt - a).total_seconds()
            return f"{v['archivo']} {int(s // 60)}:{int(s % 60):02d}"
    return None


# ---------------------------------------------------------------- OSM
def osm(carpeta, sin_descarga):
    ruta = os.path.join(carpeta, "resultados", "osm-campus.osm")
    if not sin_descarga:
        url = "https://api.openstreetmap.org/api/0.6/map?bbox=%f,%f,%f,%f" % BBOX
        req = urllib.request.Request(url, headers={"User-Agent": "mapsutb-curso/1.0"})
        with urllib.request.urlopen(req, timeout=120) as r, open(ruta, "wb") as f:
            f.write(r.read())
    r = ET.parse(ruta).getroot()
    tg = lambda e: {t.get("k"): t.get("v") for t in e.iter("tag")}
    pos = {n.get("id"): (float(n.get("lat")), float(n.get("lon"))) for n in r.iter("node")}
    ways = [(w.get("id"), tg(w), [nd.get("ref") for nd in w.iter("nd")]) for w in r.iter("way")]
    nodos_tag = {n.get("id"): tg(n) for n in r.iter("node") if n.find("tag") is not None}
    return pos, ways, nodos_tag


# ---------------------------------------------------------------- análisis
def analizar(carpeta, sin_descarga=False):
    res = os.path.join(carpeta, "resultados")
    os.makedirs(res, exist_ok=True)
    muestras, puntos, sync, fuentes = leer_exportaciones(carpeta)
    # Correcciones de zona confirmadas por el equipo (scripts/campo/correspondencias.json).
    correccion = json.load(open(os.path.join(os.path.dirname(__file__), "correspondencias.json"),
                                encoding="utf-8")).get("zona_de_punto", {})
    for p in puntos:
        z = correccion.get(str(p.get("n")))
        if z and p.get("zona") != z:
            p["zona_declarada"], p["zona"] = p.get("zona"), z
    puntos = emparejar(puntos)
    videos = leer_videos(carpeta, sync)
    pos, ways, nodos_tag = osm(carpeta, sin_descarga)
    zonas = json.load(open(ZONAS_JSON, encoding="utf-8"))

    segs = [(wid, t.get("highway"), xy(*pos[a]), xy(*pos[b]))
            for wid, t, nd in ways if t.get("highway") in CAMINABLE for a, b in zip(nd, nd[1:])]
    edif = [(wid, t.get("name") or (f"sin nombre ({t['amenity']})" if t.get("amenity") else "sin nombre"),
             [xy(*pos[n]) for n in nd]) for wid, t, nd in ways if "building" in t]

    def cercano(lat, lng):
        p = xy(lat, lng)
        d, wid = min((dist_seg(p, a, b), w) for w, _, a, b in segs)
        return d, wid

    def edificio(lat, lng):
        p = xy(lat, lng)
        for wid, nom, poly in edif:
            if adentro(p, poly):
                return wid, nom, 0.0
        d, wid, nom = min((min(dist_seg(p, a, b) for a, b in zip(poly, poly[1:] + poly[:1])), w, n)
                          for w, n, poly in edif)
        return (wid, nom, d) if d < 15 else (None, "fuera de edificios", d)

    # recorridos frente a lo trazado
    ds = [cercano(m["lat"], m["lng"]) for m in muestras]
    tramos, act = [], []
    for m, (d, _) in zip(muestras, ds):
        if d > LEJOS_M and (m.get("acc") or 0) <= 15:
            act.append((m, d))
        else:
            if len(act) >= MIN_TRAMO:
                tramos.append(act)
            act = []
    if len(act) >= MIN_TRAMO:
        tramos.append(act)
    usados = Counter(w for (d, w) in ds if d <= 6)
    foot = [w for w in ways if w[1].get("highway") in {"footway", "steps"}]
    no_recorridos = [w for w in foot if usados.get(w[0], 0) < 2]

    # puntos frente a edificios y a la zona declarada
    nombre_zona = {z["id"]: z["nombre"] for z in zonas}
    por_edif = defaultdict(list)
    for p in puntos:
        wid, nom, d = edificio(p["lat"], p["lng"])
        p["edificio_osm"] = nom
        p["edificio_osm_dist_m"] = round(d, 1)
        p["video"] = video_en(videos, p.get("t"))
        por_edif[nom].append(p)

    # zonas de zonas.json con y sin entrada registrada
    entradas = defaultdict(list)
    for p in puntos:
        if p.get("tipo") == "entrada" and p.get("zona"):
            entradas[p["zona"]].append(p)
    edif_nombres = {nom for _, nom, _ in edif}

    # ---------- informe ----------
    L = []
    w = L.append
    ahora = dt.datetime.now().strftime("%Y-%m-%d %H:%M")
    w(f"# Análisis de campo · MAPSUTB\n\nGenerado: {ahora} · carpeta `{carpeta}`\n")
    w("## Datos leídos\n")
    w(f"- Muestras de recorrido: **{len(muestras)}**"
      + (f" ({muestras[0]['t'][:16]} → {muestras[-1]['t'][:16]} UTC)" if muestras else ""))
    dobles = [p for p in puntos if p.get("discrepancia_m") is not None]
    w(f"- Puntos registrados: **{len(puntos)}** · tipos: "
      + ", ".join(f"{k} {v}" for k, v in Counter(p.get("tipo") for p in puntos).most_common()))
    if dobles:
        difs = sorted(p["discrepancia_m"] for p in dobles)
        w(f"- **{len(dobles)} lugares medidos dos veces** (herramienta web y GPS Logger): "
          f"diferencia mediana {difs[len(difs)//2]:.1f} m, p90 {difs[int(len(difs)*0.9)]:.1f} m, "
          f"máxima {difs[-1]:.1f} m. "
          "Es una medida del error real del GPS en el campus.")
    w(f"- Marcas SYNC: **{len(sync)}** · videos: **{len(videos)}** · fuentes: "
      + ", ".join(f"{k} ×{v}" for k, v in fuentes.items()))
    if muestras:
        alts = [m["alt"] for m in muestras if m.get("alt") is not None]
        accs = sorted(m["acc"] for m in muestras if m.get("acc") is not None)
        if accs:
            w(f"- Precisión horizontal del recorrido: mediana {accs[len(accs)//2]:.1f} m")
        if alts:
            w(f"- Altitud GPS: {min(alts):.1f}–{max(alts):.1f} m (solo informativa; no se usa para pisos)")
        w(f"- Contexto declarado en el recorrido: "
          + ", ".join(f"{z or 'exterior'}/{p or '-'} {n}" for (z, p), n in
                      Counter((m.get('zona'), m.get('piso')) for m in muestras).most_common()))
    w("\n## Videos\n")
    if videos:
        w("| Video | Inicio UTC (corregido) | Duración | Marcas SYNC |\n|---|---|---|---|")
        for v in videos:
            w(f"| {v['archivo']} | {v['inicio_utc'][11:22]} | {v['duracion_s']:.0f} s | {', '.join(map(str, v['sync'])) or '—'} |")
        cubiertos = sum(1 for m in muestras if video_en(videos, m["t"]))
        w(f"\nMuestras del recorrido con video: {cubiertos} de {len(muestras)}.")
    else:
        w("Sin videos (o sin ffprobe).")
    w("\n## Recorrido frente a OpenStreetMap\n")
    if muestras:
        for lim in (5, 10, 20):
            w(f"- A ≤ {lim} m de un camino trazado: {sum(d <= lim for d, _ in ds) / len(ds) * 100:.0f} %")
        w(f"- Andenes y escaleras de OSM recorridos: {len(foot) - len(no_recorridos)} de {len(foot)}")
        # Un tramo que transcurre dentro de un edificio no es un camino que
        # falte en OSM: es el interior, donde además el GPS deriva.
        def interior(t):
            dentro = sum(1 for m, _ in t if edificio(m["lat"], m["lng"])[2] == 0)
            return dentro > len(t) / 2

        interiores = [t for t in tramos if interior(t)]
        exteriores = [t for t in tramos if not interior(t)]
        w(f"\n**Tramos caminados lejos (> {LEJOS_M} m) de lo trazado:** {len(tramos)} "
          f"({len(exteriores)} en exterior, {len(interiores)} dentro de edificios)\n")
        if exteriores:
            w("Posibles caminos que faltan por trazar en OSM:\n")
            for t in exteriores:
                a, b = t[0][0], t[-1][0]
                w(f"- {a['t'][11:19]}–{b['t'][11:19]} UTC · hasta {max(d for _, d in t):.0f} m · "
                  f"[{a['lat']:.6f}, {a['lng']:.6f}](https://www.openstreetmap.org/?mlat={a['lat']:.6f}&mlon={a['lng']:.6f}#map=20/{a['lat']:.6f}/{a['lng']:.6f})"
                  f" · video: {video_en(videos, a['t']) or 'sin video'}")
        if interiores:
            nombres = Counter(edificio(t[0][0]["lat"], t[0][0]["lng"])[1] for t in interiores)
            w("\nDentro de edificios (no hay nada que trazar; el GPS deriva en interiores): "
              + ", ".join(f"{k} ×{v}" for k, v in nombres.most_common()))
    # Calidad de las coordenadas: lugares medidos dos veces por dos apps. Se
    # separan por la zona que declaró quien midió (un edificio) o ninguna
    # (exterior); clasificar por el polígono de OSM no sirve, porque un punto
    # interior con error grande cae fuera del edificio.
    dentro = sorted(p["discrepancia_m"] for p in puntos
                    if p.get("discrepancia_m") is not None and p.get("zona"))
    fuera = sorted(p["discrepancia_m"] for p in puntos
                   if p.get("discrepancia_m") is not None and not p.get("zona"))
    if dentro or fuera:
        w("\n## Calidad de las coordenadas\n")
        w("Diferencia entre las dos mediciones del mismo lugar, tomadas a la vez con la "
          "herramienta web y con GPS Logger. El Escenario 2 exige un margen de ubicación "
          "menor a 10 m.\n")
        w("| Dónde se declaró el punto | Lugares | Mediana | Máxima | Umbral de 10 m |")
        w("|---|---:|---:|---:|---|")
        for nombre, v in (("Sin zona: exterior o planta baja", fuera),
                          ("Dentro de un edificio (zona declarada)", dentro)):
            if v:
                med = v[len(v) // 2]
                w(f"| {nombre} | {len(v)} | {med:.1f} m | {v[-1]:.1f} m | "
                  f"{'cumple' if med < 10 else '**no cumple**'} |")
        w("\nLa precisión que informan las herramientas (±1 a ±5 m) es la que reporta el sistema "
          "operativo y resulta optimista frente a esta comparación entre dos mediciones reales. "
          "Para ubicar un espacio dentro de un edificio el GPS no alcanza: el ruteo termina en la "
          "entrada y el piso se declara a mano (ADR 0011, ADR 0013).")

    w("\n## Puntos frente a los edificios de OSM\n")
    w("Cada punto se asigna al edificio de OSM que lo contiene o al más cercano (< 15 m). "
      "Si la zona declarada no coincide con el edificio, se marca ⚠.\n")
    alias = {"a1": "Edificio A1", "a2": "Edificio A2", "a3": "Edificio A3", "a4": "Edificio A4",
             "a5": "Edificio A5", "zonat": "ZONA T", "biblioteca": "biblioteca"}
    for nom, ps in sorted(por_edif.items(), key=lambda x: -len(x[1])):
        w(f"\n**{nom}** · {len(ps)} puntos\n")
        for p in ps:
            z = p.get("zona")
            raro = z and alias.get(z) and alias[z] != nom and nom != "fuera de edificios"
            w(f"- {'⚠ ' if raro else ''}{p.get('n', '·')} · {p.get('tipo')}"
              f"{' · zona declarada ' + nombre_zona.get(z, z) if z else ''} · {p.get('nota') or p.get('espacio_nombre') or ''}"
              f" · ±{p.get('precision_m', '?')} m{' · ' + p['video'] if p.get('video') else ''}")
    w("\n## Pendientes para la siguiente salida\n")
    for z in zonas:
        if z["id"] not in entradas:
            w(f"- Sin **entrada** registrada: {z['nombre']}")
    for nom in ("EDA2", "Contenedores", "Quid", "Alcatraz"):
        if not any(nom.lower() in n.lower() for n in edif_nombres):
            w(f"- En OSM no hay edificio con nombre **{nom}**")
    sin_piso = sum(1 for m in muestras if not m.get("piso"))
    if muestras and sin_piso == len(muestras):
        w("- Ninguna muestra del recorrido tiene piso declarado: dentro de edificios, usar **Dónde estoy**")
    w(f"- Andenes de OSM sin recorrer: {len(no_recorridos)} "
      + " ".join(f"[{w_[0]}](https://www.openstreetmap.org/way/{w_[0]})" for w_ in no_recorridos[:25]))
    w("\n---\n© colaboradores de OpenStreetMap (ODbL) para la geometría base.")
    open(os.path.join(res, "informe.md"), "w", encoding="utf-8").write("\n".join(L) + "\n")

    json.dump({"generado": ahora, "muestras": muestras, "puntos": puntos, "sync": sync, "videos": videos},
              open(os.path.join(res, "datos_unificados.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    dibujar(os.path.join(res, "mapa.svg"), pos, ways, muestras, puntos, tramos)
    return len(muestras), len(puntos), len(videos), len(tramos)


# ---------------------------------------------------------------- mapa
def dibujar(ruta, pos, ways, muestras, puntos, tramos):
    W = 1400
    # Encuadre: donde hay datos de campo (más 40 m); si no hay, el campus completo.
    lats = [m["lat"] for m in muestras] + [p["lat"] for p in puntos]
    lngs = [m["lng"] for m in muestras] + [p["lng"] for p in puntos]
    if lats:
        x0, y0 = xy(min(lats), min(lngs))
        x1, y1 = xy(max(lats), max(lngs))
        x0, y0, x1, y1 = x0 - 40, y0 - 40, x1 + 40, y1 + 40
    else:
        x0, y0 = xy(BBOX[1], BBOX[0])
        x1, y1 = xy(BBOX[3], BBOX[2])
    esc = W / (x1 - x0)
    H = int((y1 - y0) * esc)
    P = lambda la, lo: ((lo * KX - x0) * esc, H - (la * KY - y0) * esc)
    o = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" font-family="Arial">',
         f'<rect width="{W}" height="{H}" fill="#F3F5FB"/>']
    for wid, t, nd in ways:
        pts = " ".join("%.1f,%.1f" % P(*pos[n]) for n in nd if n in pos)
        if "building" in t:
            o.append(f'<polygon points="{pts}" fill="#E1E7F5" stroke="#9AA9C0" stroke-width="1"/>')
    for wid, t, nd in ways:
        hw = t.get("highway")
        if hw in CAMINABLE:
            pts = " ".join("%.1f,%.1f" % P(*pos[n]) for n in nd if n in pos)
            col, ancho = ("#FF6947", 3) if hw == "steps" else ("#7A8699", 2.5) if hw == "footway" else ("#C3CBD8", 4)
            o.append(f'<polyline points="{pts}" fill="none" stroke="{col}" stroke-width="{ancho}"/>')
    for wid, t, nd in ways:
        if "building" in t and t.get("name"):
            cx = sum(P(*pos[n])[0] for n in nd) / len(nd)
            cy = sum(P(*pos[n])[1] for n in nd) / len(nd)
            o.append(f'<text x="{cx:.0f}" y="{cy:.0f}" font-size="13" font-weight="bold" fill="#032742" text-anchor="middle">{t["name"]}</text>')
    # Una polilínea por tramo continuo: cambiar de archivo o un hueco de más de
    # dos minutos no es un trayecto caminado, así que no se dibuja una recta.
    trozo = []
    for i, m in enumerate(muestras):
        corta = i > 0 and (m["origen"] != muestras[i - 1]["origen"]
                           or (iso(m["t"]) - iso(muestras[i - 1]["t"])).total_seconds() > 120)
        if corta and len(trozo) > 1:
            pts = " ".join("%.1f,%.1f" % P(x["lat"], x["lng"]) for x in trozo)
            o.append(f'<polyline points="{pts}" fill="none" stroke="#093AD8" stroke-width="2.5" stroke-opacity=".75"/>')
        if corta:
            trozo = []
        trozo.append(m)
    if len(trozo) > 1:
        pts = " ".join("%.1f,%.1f" % P(x["lat"], x["lng"]) for x in trozo)
        o.append(f'<polyline points="{pts}" fill="none" stroke="#093AD8" stroke-width="2.5" stroke-opacity=".75"/>')
    for t in tramos:
        pts = " ".join("%.1f,%.1f" % P(m["lat"], m["lng"]) for m, _ in t)
        o.append(f'<polyline points="{pts}" fill="none" stroke="#B3261E" stroke-width="7" stroke-opacity=".6"/>')
    color = {"entrada": "#028C5C", "escalera": "#FF6947", "rampa": "#5817D3", "acceso": "#032742"}
    for p in puntos:
        x, y = P(p["lat"], p["lng"])
        o.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="6" fill="{color.get(p.get("tipo"), "#0FC5EF")}" stroke="#fff" stroke-width="1.5"/>')
        o.append(f'<text x="{x + 7:.1f}" y="{y - 5:.1f}" font-size="10" fill="#032742">{p.get("n", "")}</text>')
    ley = [("#093AD8", "recorrido"), ("#B3261E", "fuera de lo trazado"), ("#7A8699", "andén OSM"),
           ("#FF6947", "escalera"), ("#028C5C", "punto: entrada"), ("#0FC5EF", "punto: otro")]
    for i, (c, txt) in enumerate(ley):
        o.append(f'<rect x="12" y="{12 + i * 20}" width="14" height="14" fill="{c}"/>'
                 f'<text x="32" y="{24 + i * 20}" font-size="13" fill="#032742">{txt}</text>')
    o.append(f'<text x="{W - 12}" y="{H - 10}" font-size="12" fill="#5B6B82" text-anchor="end">© colaboradores de OpenStreetMap</text>')
    o.append("</svg>")
    open(ruta, "w", encoding="utf-8").write("\n".join(o))


# ---------------------------------------------------------------- grafo y zonas
REPO = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
CORRESPONDENCIAS = os.path.join(os.path.dirname(__file__), "correspondencias.json")
CAMINABLE_GRAFO = {"footway", "steps", "path", "pedestrian", "service", "living_street", "corridor", "track", "unclassified"}
MARGEN_CAMPUS_M = 20     # caminos pegados al límite del campus también cuentan
MAX_ENTRADA_M = 40       # una zona a más de esto del camino más cercano queda sin conectar


def generar_grafo_y_zonas(carpeta, escribir_repo):
    """Construye grafo.json desde OSM y las coordenadas de las zonas.

    Devuelve un resumen. Si escribir_repo, actualiza assets/data/grafo.json y las
    coordenadas de assets/data/zonas.json (sin reformatear el archivo).
    """
    corr = json.load(open(CORRESPONDENCIAS, encoding="utf-8"))
    pos, ways, _ = osm(carpeta, sin_descarga=True)
    datos = json.load(open(os.path.join(carpeta, "resultados", "datos_unificados.json"), encoding="utf-8"))
    puntos = {p.get("n"): p for p in datos["puntos"] if p.get("n") is not None}
    zonas = json.load(open(ZONAS_JSON, encoding="utf-8"))
    nombre_zona = {z["id"]: z["nombre"] for z in zonas}
    way = {wid: (t, nd) for wid, t, nd in ways}

    campus = [xy(*pos[n]) for n in way[corr["campus_osm_way"]][1]]

    def cerca_campus(n):
        p = xy(*pos[n])
        return adentro(p, campus) or min(dist_seg(p, a, b) for a, b in zip(campus, campus[1:] + campus[:1])) <= MARGEN_CAMPUS_M

    # segmentos caminables dentro del campus
    adj = defaultdict(dict)          # nodo -> vecino -> (metros, escaleras, tipo)
    usos = Counter()
    for wid, (t, nd) in way.items():
        hw = t.get("highway")
        if hw not in CAMINABLE_GRAFO:
            continue
        dentro = [n for n in nd if n in pos and cerca_campus(n)]
        if len(dentro) < 2:
            continue
        for n in set(dentro):
            usos[n] += 1
        for a, b in zip(nd, nd[1:]):
            if a in pos and b in pos and cerca_campus(a) and cerca_campus(b):
                m = metros_geo(pos[a], pos[b])
                adj[a][b] = adj[b][a] = (m, hw == "steps", hw)

    # zonas: coordenada y nodo de llegada provisional
    def poligono(wid):
        return [xy(*pos[n]) for n in way[wid][1]]

    def nodo_mas_cercano(p_xy, poly=None):
        mejor = None
        for n in adj:
            q = xy(*pos[n])
            d = min(dist_seg(q, a, b) for a, b in zip(poly, poly[1:] + poly[:1])) if poly else math.hypot(q[0] - p_xy[0], q[1] - p_xy[1])
            if mejor is None or d < mejor[0]:
                mejor = (d, n)
        return mejor

    coords, entradas = {}, []
    for wid, zid in corr["edificio_osm_a_zona"].items():
        nd = way[wid][1][:-1] if way[wid][1][0] == way[wid][1][-1] else way[wid][1]
        coords[zid] = (sum(pos[n][0] for n in nd) / len(nd), sum(pos[n][1] for n in nd) / len(nd),
                       f"centro del edificio OSM way {wid}")
        d, n = nodo_mas_cercano(None, poligono(wid))
        entradas.append({"zona": zid, "nodo": n, "distancia_m": round(d, 1),
                         "fuente": f"provisional: nodo de camino más cercano al edificio (way {wid})"})
    for zid, info in corr["zona_desde_puntos"].items():
        ps = [puntos[i] for i in info["puntos"] if i in puntos]
        if not ps:
            continue
        la = sum(p["lat"] for p in ps) / len(ps)
        lo = sum(p["lng"] for p in ps) / len(ps)
        coords[zid] = (la, lo, "puntos de campo " + ", ".join(str(i) for i in info["puntos"]))
        d, n = nodo_mas_cercano(xy(la, lo))
        entradas.append({"zona": zid, "nodo": n, "distancia_m": round(d, 1),
                         "fuente": "provisional: nodo de camino más cercano a los puntos de campo " + ", ".join(map(str, info["puntos"]))})
    entradas = [e for e in entradas if e["distancia_m"] <= MAX_ENTRADA_M]

    # comprimir cadenas: se conservan cruces, extremos, nodos compartidos y nodos de entrada
    anclas = {e["nodo"] for e in entradas}
    importante = {n for n in adj if len(adj[n]) != 2 or usos[n] > 1 or n in anclas}
    aristas, vistos = [], set()
    for a in importante:
        for b in adj[a]:
            if (a, b) in vistos:
                continue
            camino, metros, escaleras, tipos = [a, b], adj[a][b][0], adj[a][b][1], {adj[a][b][2]}
            prev, act = a, b
            while act not in importante and act != a:
                sig = next(x for x in adj[act] if x != prev)
                metros += adj[act][sig][0]
                escaleras |= adj[act][sig][1]
                tipos.add(adj[act][sig][2])
                prev, act = act, sig
                camino.append(act)
            for x, y in zip(camino, camino[1:]):
                vistos.add((x, y))
                vistos.add((y, x))
            aristas.append({"desde": f"n{a}", "hasta": f"n{act}", "metros": round(metros, 1),
                            "escaleras": escaleras, "via": "steps" if escaleras else sorted(tipos)[0],
                            "geometria": [[round(pos[n][0], 7), round(pos[n][1], 7)] for n in camino]})

    # componentes conexas
    vec = defaultdict(set)
    for e in aristas:
        vec[e["desde"]].add(e["hasta"])
        vec[e["hasta"]].add(e["desde"])
    comp, cid = {}, 0
    for n in vec:
        if n in comp:
            continue
        pila = [n]
        comp[n] = cid
        while pila:
            x = pila.pop()
            for y in vec[x]:
                if y not in comp:
                    comp[y] = cid
                    pila.append(y)
        cid += 1
    tam = Counter(comp.values())
    principal = tam.most_common(1)[0][0] if tam else None

    nodos = [{"id": f"n{n}", "lat": round(pos[n][0], 7), "lng": round(pos[n][1], 7),
              **({"entrada_de": [e["zona"] for e in entradas if e["nodo"] == n]} if n in anclas else {})}
             for n in sorted(importante)]
    for e in entradas:
        e["nodo"] = f"n{e['nodo']}"
        e["conectada"] = comp.get(e["nodo"]) == principal
    grafo = {
        "version": 1,
        "licencia": "ODbL 1.0 · © colaboradores de OpenStreetMap",
        "fuente": "OpenStreetMap (área del campus, way %s) + levantamiento de campo MAPSUTB; ver docs/levantamiento-campo.md" % corr["campus_osm_way"],
        "generado": dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "nodos": nodos, "aristas": sorted(aristas, key=lambda e: (e["desde"], e["hasta"])), "entradas": sorted(entradas, key=lambda e: e["zona"]),
    }

    resumen = [f"\n## Grafo generado\n",
               f"- Nodos: {len(nodos)} · tramos: {len(aristas)} · {sum(e['metros'] for e in aristas) / 1000:.2f} km caminables"
               f" · con escaleras: {sum(e['escaleras'] for e in aristas)}",
               f"- Componentes conexas: {len(tam)} (la principal tiene {tam[principal] if tam else 0} nodos)"]
    for z in zonas:
        e = next((x for x in entradas if x["zona"] == z["id"]), None)
        c = coords.get(z["id"])
        estado = ("sin coordenada ni entrada" if not c else
                  f"coordenada: {c[2]} · entrada {'conectada' if e and e['conectada'] else 'SIN conectar'}"
                  + (f" a {e['distancia_m']} m del edificio (provisional)" if e else ""))
        resumen.append(f"- {nombre_zona[z['id']]}: {estado}")

    if escribir_repo:
        json.dump(grafo, open(os.path.join(REPO, "assets", "data", "grafo.json"), "w", encoding="utf-8"),
                  ensure_ascii=False, indent=1)
        actualizar_coordenadas(coords)
    return "\n".join(resumen)


def actualizar_coordenadas(coords):
    """Escribe lat/lng de cada zona en zonas.json tocando solo esas dos líneas."""
    import re
    texto = open(ZONAS_JSON, encoding="utf-8").read()
    for zid, (la, lo, _) in coords.items():
        m = re.search(r'"id"\s*:\s*"%s"' % re.escape(zid), texto)
        if not m:
            continue
        bloque = re.compile(r'("lat"\s*:\s*)(-?[\d.]+)(\s*,\s*"lng"\s*:\s*)(-?[\d.]+)')
        b = bloque.search(texto, m.end())
        if b:
            texto = texto[:b.start()] + f"{b.group(1)}{la:.7f}{b.group(3)}{lo:.7f}" + texto[b.end():]
    open(ZONAS_JSON, "w", encoding="utf-8", newline="").write(texto)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    carpeta = args[0] if args else r"C:\mapsutb-campo"
    n = analizar(carpeta, sin_descarga="--sin-osm" in sys.argv)
    print("muestras %d · puntos %d · videos %d · tramos fuera de lo trazado %d" % n)
    resumen = generar_grafo_y_zonas(carpeta, escribir_repo="--escribir-repo" in sys.argv)
    with open(os.path.join(carpeta, "resultados", "informe.md"), "a", encoding="utf-8") as f:
        f.write(resumen + "\n")
    print(resumen)
    print("resultados en", os.path.join(carpeta, "resultados"))
