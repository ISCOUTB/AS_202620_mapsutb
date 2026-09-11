# ADR 0003 — Descartar guiado por realidad aumentada (ARCore Geospatial API)

## Estado

- **Estado**: Aceptado
- **Fecha**: 2026-08-29
- **Decisores**: Equipo MAPSUTB

## Contexto

El ADR 0001 (aceptado 2026-08-23) definía que el sistema guiaría al usuario mediante **realidad
aumentada con cámara en vivo**, anclando objetos a coordenadas GPS reales del campus con **ARCore
Geospatial API** — descrita en ese momento como el diferenciador central del producto y la única
dependencia externa de Google que se mantenía (ya se habían descartado Maps SDK, Directions,
Geocoding, Places y Street View).

Al avanzar en la implementación, el equipo reevaluó esa decisión (ver [`docs/ia.md`](../ia.md),
entradas del 28 y 29/08/2026) y encontró riesgos que no se habían pesado lo suficiente en el ADR
0001:

- ARCore Geospatial API exige un dispositivo compatible con ARCore, lo que excluye a parte del
  público objetivo (estudiantes de intercambio o visitantes que no controlan qué hardware traen).
- No se puede probar en CI ni simular sin un dispositivo físico compatible, lo que choca con el
  objetivo de tener pruebas automatizadas del módulo de mapas.
- Depende de la cobertura y disponibilidad geoespacial de Google específicamente sobre el campus,
  sin garantía previa de soporte en esa zona.
- Es la única de las APIs evaluadas con la que el equipo no tenía experiencia previa, lo que elevaba
  el riesgo de no completarla dentro del tiempo restante del semestre.

Este es un cambio de **alcance del producto** (qué tan guiado, por qué medio), no una decisión de
patrón de diseño — por eso se documenta en un ADR propio en vez de editar el ADR 0001 ya aceptado o
de mezclarse dentro del ADR 0002 (que sí es, específicamente, sobre patrones de diseño).

## Decisión

Se descarta por completo el guiado por realidad aumentada con cámara en vivo y ARCore Geospatial
API. En su lugar, el sistema muestra un **plano propio del campus** (grafo peatonal y geometría,
activos propios del proyecto) **superpuesto sobre un mapa base renderizado con Google Maps SDK**,
con **Google Geocoding API** para conversión de coordenadas y direcciones. El ruteo dentro del
campus se resuelve internamente sobre el grafo peatonal propio (Dijkstra), sin depender de
Directions API.

## Alternativas consideradas

### A. Realidad aumentada con ARCore Geospatial API (descartada — versión original del ADR 0001)

Anclar objetos de guiado a coordenadas GPS reales del campus usando la cámara en vivo del
dispositivo.

- **A favor (por qué se había elegido originalmente):** era el diferenciador central del producto
  frente a una app de mapas convencional; resuelve algo que datos puramente locales no pueden
  (anclaje de objetos AR a coordenadas reales).
- **En contra (motivo del descarte):** exige hardware compatible con ARCore, lo que excluye
  usuarios sobre los que el equipo no tiene control (visitantes, intercambio); no se puede probar
  en CI ni simular sin dispositivo físico; depende de la cobertura geoespacial de Google en el
  campus específico; y era la única API del listado original sin experiencia previa del equipo,
  concentrando el riesgo de implementación en el tiempo que queda de semestre.

### B. Plano propio superpuesto sobre Google Maps SDK + Geocoding API (elegida)

Mostrar el plano propio del campus como una capa sobre un mapa base ya renderizado por Google Maps
SDK, con Geocoding API para conversión de coordenadas/direcciones.

- **A favor:** Maps SDK y Geocoding son APIs maduras y ampliamente documentadas, no requieren
  hardware especial ni permisos de cámara, y se pueden probar en dispositivos y emuladores
  estándar; el equipo evita construir un motor de renderizado de mapas desde cero al apoyarse en
  Maps SDK como base (ver [`docs/ia.md`](../ia.md), entrada del 29/08/2026).
- **En contra:** se pierde el diferenciador de "guiado en AR" frente a un mapa convencional; el
  sistema pasa a depender de dos servicios externos de Google (Maps SDK y Geocoding) en vez de uno
  solo (ARCore) — aceptado porque, según la evaluación del equipo, ambos tienen mayor madurez y
  disponibilidad histórica que Geospatial API.

### C. Plano 100% propio, sin Maps SDK (descartada)

Prescindir también de Google Maps SDK y construir el mapa base enteramente con activos propios del
proyecto (imagen, vector o grafo de nodos), sin superponerlo sobre ningún mapa externo.

- **Consecuencia de no elegirla:** habría implicado construir un motor de renderizado de mapas
  desde cero, fuera de lo razonable para el tiempo disponible del semestre (ver
  [`docs/ia.md`](../ia.md), entrada del 29/08/2026).

## Consecuencias de la decisión

**Positivas**

- El sistema deja de depender de hardware compatible con ARCore; funciona en cualquier dispositivo
  Android/iOS estándar con GPS.
- El módulo de mapas se puede probar de forma automatizada (CI, emuladores) sin necesitar un
  dispositivo AR físico.
- El equipo evita construir un motor de renderizado de mapas propio, apoyándose en un SDK ya
  maduro.

**Negativas / riesgos aceptados**

- Se pierde el diferenciador de guiado por realidad aumentada frente a otras apps de mapas de
  campus.
- El sistema pasa de una dependencia externa (ARCore) a dos (Maps SDK, Geocoding); se acepta porque
  ambas se consideran de menor riesgo individual de disponibilidad que Geospatial API.
- Deja pendiente de revisión cualquier documentación que todavía atribuya el descarte de ARCore al
  ADR 0001 en vez de a este ADR — por ejemplo, la fila correspondiente en
  [`docs/arc42/02_architecture_constraints.adoc`](../arc42/02_architecture_constraints.adoc), que
  hoy dice "Decisión registrada en ADR 0001" para el descarte de ARCore/Street View. `docs/ficha_problema.md`
  y `docs/aspectos.md` ya fueron actualizados y hoy citan el ADR de patrones de diseño para esto;
  conviene apuntarlos a este ADR 0003 en cuanto quede commiteado.

## Referencias

- [`docs/adr/0001-patrones-de-diseno.md`](./0001-patrones-de-diseno.md) — versión aceptada
  original, con ARCore como dependencia mantenida.
- [`docs/adr/0002-patrones-de-diseno-sin-realidad-aumentada.md`](./0002-patrones-de-diseno-sin-realidad-aumentada.md)
  — patrones de diseño ya con el alcance de este ADR aplicado.
- [`docs/ia.md`](../ia.md) — entradas del 28/08 y 29/08/2026 con el proceso de esta decisión.
- [`docs/arc42/02_architecture_constraints.adoc`](../arc42/02_architecture_constraints.adoc)
