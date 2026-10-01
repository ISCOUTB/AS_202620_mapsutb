# ADR 0013 — Ruteo a pie con Dijkstra sobre el grafo propio, sin dependencias nuevas

## Estado

- **Estado**: Aceptado
- **Fecha**: 2026-10-01
- **Decisores**: Equipo MAPSUTB
- **Concreta**: la decisión de ruteo interno con Dijkstra de los ADR 0001 y 0002

## Contexto

El Escenario 2 exige mostrar la ruta a un punto de interés en ≤ 5 s. El ruteo interno se
decidió desde el ADR 0001 (Dijkstra sobre un grafo peatonal propio, sin Directions API); faltaba
el grafo, que ya existe: `assets/data/grafo.json`, generado desde OpenStreetMap y el
levantamiento de campo (ADR 0011), con 78 nodos y 90 tramos.

Restricciones que pesan:

- **El ruteo debe funcionar sin conexión** (arc42 §2): el grafo viaja dentro de la app.
- **Límites de contexto de S6** (ADR 0006): Ruteo no puede depender del modelo `Zona` del
  Catálogo; solo de ids de zona.
- **El grafo se regenera** cada vez que se suman datos de campo, por partes.
- **Equipo pequeño y semestre corto:** se prefiere lo simple y verificable.

## Decisión

1. **Dijkstra con montículo binario** sobre el grafo completo, en `lib/routing/servicio_ruteo.dart`.
   Peso = metros del tramo. Opción `evitarEscaleras` para rutas accesibles.
2. **Montículo escrito en el proyecto** en lugar de agregar `package:collection` como dependencia
   directa: son ~40 líneas, evita una dependencia más que verificar y no obliga a regenerar el
   lockfile.
3. **El dueño del grafo es `MapaRepository`** (arc42 §8), que lo carga del asset una vez y lo
   guarda en memoria.
4. **Ruteo solo conoce ids de zona**: el nodo de llegada de cada zona viene en
   `grafo.json → entradas`.
5. Tiempo estimado a 1,2 m/s.

## Alternativas consideradas

### A. Dijkstra con montículo (elegida)

- **A favor:** exacto, simple de probar; con 78 nodos el costo es despreciable (medido: p95 de
  0,92 ms).

### B. A* con heurística de distancia en línea recta (descartada por ahora)

- **Motivo técnico:** con un grafo de este tamaño no hay ganancia medible y suma una heurística
  que también hay que probar. Se reevalúa si el grafo pasa de unos miles de nodos (por ejemplo, al
  agregar interiores de todos los edificios).

### C. Tabla precalculada de todas las rutas (descartada)

- **Motivo técnico:** el grafo se regenera con cada salida de campo y las rutas también parten
  de la posición del GPS, que no es un nodo fijo; habría que recalcular la tabla igual.

### D. Servicio externo de rutas (OSRM, GraphHopper, Google Directions) (descartada)

- **Motivo:** exige red y, en algunos casos, key o servidor propio; incumple el ruteo sin conexión
  y Directions ya se había descartado (ADR 0001).

## Consecuencias

- Medición del Escenario 2 en CI: 100 rutas sobre el grafo real, p95 0,92 ms, máximo 3,6 ms
  (run [36913480665](https://github.com/ISCOUTB/AS_202620_mapsutb/actions/runs/36913480665)),
  frente a un umbral de 5 s.
- La prueba de "ruta más corta" incluye una prueba de mutación: una búsqueda por menor número de
  tramos (BFS) da 50 m donde Dijkstra da 20 m, y la verificación la rechaza.
- Las entradas de las zonas siguen siendo provisionales hasta registrarlas en campo; las rutas a
  esas zonas son tan buenas como esa aproximación.
