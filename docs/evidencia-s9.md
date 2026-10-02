# Evidencia S9 — Ruteo a pie construido con apoyo de IA

Porción del sistema: **ruteo interno del campus** (contexto Ruteo, aspecto A-01), construida
con apoyo de IA (Claude Code) sobre datos levantados por el equipo. Este documento recorre la
cadena para la revisión de la semana 9.

## 1. Porción real del sistema

| Pieza | Ruta | Commit |
|---|---|---|
| Modelo del grafo | `lib/routing/grafo.dart` | servicio de ruteo con Dijkstra |
| Dueño del grafo (Repository) | `lib/routing/mapa_repository.dart` | ídem |
| Dijkstra, rutas entre zonas o desde el GPS | `lib/routing/servicio_ruteo.dart` | ídem, más la refactorización por complejidad cognitiva |
| Datos | `assets/data/grafo.json` (ODbL), coordenadas de `assets/data/zonas.json` | grafo peatonal del campus y coordenadas de las zonas |
| Generación de datos | `scripts/campo/analizar_campo.py`, `scripts/campo/correspondencias.json` | análisis incremental del levantamiento |
| Pruebas | `test/ruteo_test.dart`, `test/grafo_test.dart` | — |

## 2. Cadena completa

`docs/aspectos.md` **A-01** → requisito RF-01 → C4 (`docs/c4/C2.md`, `docs/c4/C3.md`: Servicio de
ruteo y `MapaRepository`) → ADR **0013** (decisión de ruteo), **0011** (fuente de datos), **0012**
(mapa base) → código (`lib/routing/`) → pruebas (`test/ruteo_test.dart`) → medición del
**Escenario 2** en CI.

## 3. Decisión del equipo

- **ADR 0013:** Dijkstra con montículo propio, ruteo sin conexión, solo ids de zona, evitar
  escaleras opcional; descarta A*, tabla precalculada y servicios externos, cada uno con su
  motivo técnico frente a las restricciones del proyecto.
- **ADR 0012:** el equipo decidió `flutter_map` + OpenStreetMap el 2026-10-01, por la
  restricción "sin tarjeta" y para coincidir con los datos trazados en OSM.

## 4. Prueba que falla ante el defecto

`test/ruteo_test.dart`, grupo "Dijkstra sobre un grafo conocido":

- **"elige la ruta de menos metros, no la de menos tramos"**: A→C debe ir por A–B–C (20 m) y no
  por el tramo directo A–C (50 m).
- **Prueba de mutación** en el mismo archivo: una implementación defectuosa a propósito
  (`rutaMutanteMenosTramos`, búsqueda por número de tramos) devuelve A–C con 50 m; la prueba
  demuestra que la verificación de 20 m la rechaza. Si alguien reemplaza Dijkstra por ese
  algoritmo, la prueba anterior falla.
- Otros defectos cubiertos: ignorar `evitarEscaleras`, geometría en sentido contrario, uniones
  con puntos repetidos, rutas a nodos inexistentes o desconectados.

**Procedimiento para verlo en rojo:** en `servicio_ruteo.dart`, cambiar `d + t.metros` por
`d + 1` (contar tramos en lugar de metros) y ejecutar `flutter test test/ruteo_test.dart`: fallan
"elige la ruta de menos metros…" y "usa la escalera si es más corta…".

## 5. Medición del escenario

**Escenario 2:** la ruta se muestra en ≤ 5 s. Medido en CI sobre el grafo real: **100 rutas
(todas las parejas de zonas), p95 0,92 ms, máximo 3,6 ms** (run
[36913480665](https://github.com/ISCOUTB/AS_202620_mapsutb/actions/runs/36913480665), salida
de la prueba "Escenario 2"). Cumple con amplio margen la parte de cálculo; falta medir la parte
de pantalla cuando exista el mapa (ADR 0012).

## 6. Uso de IA: aceptado, corregido y rechazado

Extracto de `docs/ia.md` (entradas del 01/10/2026):

- **Aceptado:** estructura de `lib/routing` (modelo, Repository, servicio), Dijkstra con montículo,
  pruebas con grafo conocido y prueba de mutación.
- **Corregido:** SonarCloud marcó complejidad cognitiva 25 en `rutaEntreNodos`; se separó en
  búsqueda y reconstrucción. La precisión de los puntos promediados en las herramientas de campo
  era optimista (±1 m) y se corrigió.
- **Rechazado con motivo:** agregar `package:collection` para la cola de prioridad (dependencia
  nueva y lockfile a regenerar por ~40 líneas); A* (sin ganancia medible con 78 nodos); sacar
  coordenadas de Google Maps/Earth (sus términos lo prohíben); asignar a la Zona T el punto
  "Bohíos" junto al A5 sin evidencia.

## 7. Auditoría de erosión

Contrastada sobre el código el 2026-10-01:

| Regla (S6, ADR 0006) | Comprobación | Resultado |
|---|---|---|
| Ruteo no depende del modelo `Zona` del Catálogo | `grep "^import" lib/routing/*.dart` → solo `dart:*`, `flutter/services`, `core/log.dart` y `grafo.dart` | Cumple |
| Un solo dueño por dato: `MapaRepository` para el grafo | `grep -rn "grafo.json\|routing/" lib` fuera de `lib/routing` → sin resultados | Cumple |
| Nadie escribe datos de otro contexto en ejecución | patrones de escritura de la ficha → solo lecturas de `ZonaRepository` desde las pantallas del Catálogo | Cumple |
| **Hallazgo:** las coordenadas de `zonas.json` (Catálogo) las escribe `scripts/campo/analizar_campo.py`, que pertenece al levantamiento del grafo | revisión del script | **Aceptado con control:** es una herramienta de construcción, no código de la app; solo escribe las líneas `lat`/`lng`, solo con `--escribir-repo`, y `test/grafo_test.dart` valida el resultado. En ejecución el único dueño sigue siendo `ZonaRepository` |

## 8. Dependencias

El ruteo no agregó dependencias (montículo propio, ADR 0013). La pantalla de mapa (ADR 0012)
agregó dos, verificadas en su registro oficial el 2026-10-01:

| Dependencia | Versión | Registro | Publicador | Repositorio |
|---|---|---|---|---|
| `flutter_map` | 8.3.2 | [pub.dev](https://pub.dev/packages/flutter_map) | `fleaflet.dev` (verificado) | github.com/fleaflet/flutter_map |
| `latlong2` | 0.10.1 | [pub.dev](https://pub.dev/packages/latlong2) | `femtopedia.de` | github.com/ThexXTURBOXx/dart-latlong |

Las transitivas (`path_provider`, `proj4dart`, `dart_earcut`, `uuid`, `logging`, entre otras)
las declara `flutter_map` y quedaron fijadas en `pubspec.lock`. El análisis de campo usa
`defusedxml` 0.7.1 (fuera de la app), verificado en [PyPI](https://pypi.org/project/defusedxml/)
(repositorio github.com/tiran/defusedxml).

## 9. Credenciales

Barrido con patrones de keys de Google, secretos, llaves privadas y tokens sobre todo el árbol,
incluido `docs/`: solo aparecen referencias a variables de entorno (`$GA_API_SECRET` en
`deploy.yml` e `infra/Dockerfile`) y el valor de prueba `secret-test` en una prueba de contrato.
Ninguna credencial real.

## 10. Componente generativo

La app no incorpora uno: **ADR 0014** (estado *Propuesto*, pendiente de confirmación del
equipo) lo justifica por costo y tarjeta, funcionamiento sin conexión y porque la búsqueda y el
grafo resuelven los casos de uso con resultados verificables.
