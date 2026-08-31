# ADR 0001 — Patrones de diseño para el monolito MAPSUTB

## Estado

- **Estado**: Aceptado
- **Fecha**: 2026-08-23
- **Decisores**: Equipo MAPSUTB

## Contexto

El patrón arquitectural del proyecto ya está decidido: **monolito** (una
app Flutter, sin backend propio por ahora). Este ADR **no** compara
alternativas arquitecturales; compara **patrones de diseño** (GoF y
patrones idiomáticos de Dart) para resolver problemas concretos del
proyecto.
 
**Cambio de alcance respecto a la versión anterior de este ADR:** se
decidió que la app **no** usará realidad aumentada con cámara en vivo
(se descarta ARCore Geospatial API por completo). En su lugar, el mapa
del campus combina dos fuentes: un **plano propio** (activos del
proyecto — grafo peatonal y geometría del campus) que se **superpone**
sobre un **mapa base renderizado con Google Maps SDK**. El ruteo sigue
sin buscar exactitud tipo "turn-by-turn" sobre una red vial real, y se
resuelve enteramente sobre el grafo peatonal propio, acotado a rutas
**dentro del campus** (no se usa Directions API).
 
Esto tiene una consecuencia directa sobre las dependencias externas: de
las 6 APIs de Google consideradas originalmente (Maps SDK, ARCore Geospatial API, Places, Directions, Geocoding, StreetView), **dejan de ser necesarias ARCore Geospatial API, Directions,Places y Street View**. Se mantienen **Maps SDK** (mapa base) y **Geocoding API** (conversión de coordenadas y direcciones).
 
Con ese alcance, los problemas de diseño que este ADR resuelve son:
 
1. Aislar las dos dependencias externas que quedan: Google Maps SDK y
   Google Geocoding API.
2. Servir el plano propio del campus (grafo peatonal y geometría) desde
   activos locales del proyecto.
3. Mantener actualizable la clasificación manual de zonas y los puntos de
   interés (objetivo de mantenibilidad, ver `arbol_utilidad.md`).
4. Calcular una ruta dentro del campus sobre ese plano local, sin
   depender de un servicio externo de ruteo.
5. Reflejar en tiempo real la ubicación del usuario en la UI (escenario
   de calidad de precisión de geolocalización, ver
   `escenarios_calidad.md`).
Cada uno se resuelve con un patrón distinto; no son alternativas entre
sí, así que se documentan por separado.
 
## Decisión
 
| # | Problema | Patrón adoptado |
|---|---|---|
| 1a | Aislar Google Maps SDK (mapa base) | **Adapter** |
| 1b | Aislar Google Geocoding API | **Adapter** |
| 2 | Servir el plano propio del campus (local) | **Repository** |
| 3 | Acceso a datos de zonas y puntos de interés | **Repository** |
| 4 | Ruteo dentro del campus sobre el plano local | *(pendiente de confirmar — ver nota abajo)* |
| 5 | Ubicación en tiempo real hacia la UI | **Observer** (`Stream` de Dart) |
 
## Alternativas consideradas, por problema
 
### 1a. Aislar Google Maps SDK
 
- **Adapter (elegido):** una clase `MapaWidget` que envuelve el SDK de
  Google Maps y expone al resto de la app un widget propio, sobre el
  cual se dibujan el plano propio del campus y las rutas calculadas.
  - *A favor:* el resto de la app nunca importa el SDK de Maps
    directamente; si el equipo necesita ajustar cómo se dibuja el plano
    propio encima del mapa, el cambio queda contenido en un solo lugar.
  - *En contra:* una capa de indirección adicional para un SDK que ya
    tiene su propia API de alto nivel.
- **Alternativa descartada — invocar el SDK de Maps directamente desde
  cada pantalla que lo necesite:** cada pantalla (mapas/ruteo, zonas)
  instancia y configura el widget de Maps por su cuenta.
  - *Consecuencia de no elegirla:* la lógica de superponer el plano
    propio (grafo, zonas, rutas) sobre el mapa base habría quedado
    repetida en cada pantalla, con riesgo de quedar desalineada.
### 1b. Aislar Google Geocoding API
 
- **Adapter (elegido):** una clase `GeocodingAdapter` que implementa una
  interfaz propia del dominio. El resto del código nunca importa el SDK
  de Geocoding directamente.
  - *A favor:* se puede simular en pruebas sin depender de la
    disponibilidad real del servicio; si más adelante cambia el
    proveedor de geocodificación, solo cambia el adaptador.
  - *En contra:* una interfaz y una clase para un solo proveedor externo
    — ceremonia que se acepta porque, junto con Maps SDK, sigue siendo
    una fuente de riesgo externo del proyecto (disponibilidad, cuotas).
- **Alternativa descartada — invocar el SDK de Geocoding directamente:**
  usarlo sin abstracción en los módulos que lo necesiten.
  - *Consecuencia de no elegirla:* cualquier prueba que dependa de
    geocodificación habría requerido conexión real al servicio de
    Google, y un cambio de proveedor habría implicado tocar varios
    módulos.
### 2. Servir el plano propio del campus (local)
 
- **Repository (elegido):** una interfaz `MapaRepository` que expone el
  grafo peatonal y la geometría propia del campus (activos propios:
  imagen, vector o grafo de nodos) independientemente de cómo esté
  empaquetado internamente.
  - *A favor:* tanto `MapaWidget` (para dibujar el plano sobre Maps SDK)
    como el módulo de ruteo consumen el plano a través de la misma
    interfaz, sin saber si es una imagen estática, un SVG o un grafo de
    nodos; si el equipo cambia el formato a mitad de semestre, el cambio
    queda contenido ahí.
  - *En contra:* una capa de indirección para un activo que, en la
    versión más simple, podría ser solo un archivo cargado directamente.
- **Alternativa descartada — cargar los activos del plano directamente en
  cada pantalla que lo necesite:** el módulo de mapas/ruteo y el de zonas
  cargan y parsean el archivo del plano cada uno por su cuenta.
  - *Consecuencia de no elegirla:* varios puntos leyendo el mismo
    archivo, con riesgo de interpretaciones distintas del formato o de
    quedar desalineados si el archivo cambia.
### 3. Acceso a datos de zonas y puntos de interés
 
- **Repository (elegido):** interfaces `ZonaRepository` y
  `PuntoInteresRepository`, con una primera implementación simple (JSON
  local).
  - *A favor:* la clasificación manual de zonas queda concentrada en un
    solo punto de cambio en vez de repetirse en cada pantalla que la
    necesite. Esta decisión no depende de Places API — los puntos de
    interés son datos propios del proyecto desde el inicio.
  - *En contra:* una capa de indirección más para un dato que, al inicio
    del proyecto, es pequeño.
- **Alternativa descartada — acceso a datos disperso:** cada módulo lee y
  filtra los datos de zonas/puntos de interés por su cuenta.
  - *Consecuencia de no elegirla:* actualizar la clasificación de una
    zona habría implicado revisar varios módulos, contradiciendo el
    objetivo de mantenibilidad ya priorizado.
### 4. Ruteo dentro del campus sobre el plano local
 
> **Nota:** esta sección depende de una decisión pendiente de confirmar
> (¿se mantiene el patrón Strategy con varios algoritmos intercambiables,
> o se simplifica a un único servicio de ruteo?). Se deja el análisis de
> la versión anterior del ADR a la espera de esa confirmación.
 
- **Strategy (versión anterior de este ADR):** una interfaz
  `RuteoStrategy` con implementaciones intercambiables, calculadas
  siempre sobre el plano local (`MapaRepository`), sin llamar a ningún
  servicio externo de ruteo.
  - *A favor:* el equipo puede empezar con un algoritmo simple y, si el
    tiempo del semestre lo permite, añadir uno más elaborado sin tocar
    el código que ya funciona; cada estrategia se prueba de forma
    aislada.
  - *En contra:* si al final el equipo solo implementa un algoritmo
    durante todo el semestre, la interfaz se siente como una capa
    adicional innecesaria.
- **Alternativa — un único servicio de ruteo (Dijkstra sobre el grafo
  propio):** sin interfaz de Strategy, un solo servicio calcula la ruta
  más corta dentro del campus.
  - *Consecuencia de elegirla:* más simple de escribir y mantener si el
    equipo no planea evaluar otros algoritmos, pero un cambio de
    algoritmo más adelante implicaría modificar el servicio existente
    en vez de añadir una implementación nueva.
### 5. Ubicación en tiempo real hacia la UI
 
- **Observer vía `Stream` de Dart (elegido):** un servicio de ubicación
  expone un `Stream<Ubicacion>`; la pantalla de mapa se suscribe a ese
  stream para reflejar la posición del usuario en tiempo real.
  - *A favor:* mecanismo idiomático de Dart/Flutter; distintas partes de
    la app pueden reaccionar al mismo cambio de ubicación sin acoplarse
    entre sí.
  - *En contra:* exige manejar correctamente la cancelación de
    suscripciones (`dispose`).
- **Alternativa descartada — *polling* manual:** consultar la ubicación
  actual cada cierto intervalo con un `Timer`.
  - *Consecuencia de no elegirla:* desperdicia batería y CPU en
    dispositivos de gama media, y añade latencia impredecible.
## Consecuencias de la decisión
 
**Positivas**
 
- La superficie de dependencias externas se reduce de 6 APIs
  originalmente consideradas a **2** (Maps SDK y Geocoding API), lo que
  baja el riesgo señalado en `restricciones.md` (cuotas, cambios de API,
  disponibilidad de terceros) frente a la línea base de 6.
- El plano propio y el ruteo quedan detrás de interfaces
  (`MapaRepository`, `MapaWidget`, ruteo) que se pueden probar sin
  depender de un dispositivo con capacidades especiales (ya no se
  requiere hardware compatible con ARCore).
- El equipo puede avanzar el módulo de mapas/ruteo sin esperar
  decisiones de cuotas o disponibilidad de más de dos servicios externos.
**Negativas / riesgos aceptados**
 
- Los adaptadores para Maps SDK y Geocoding mantienen ceremonia
  (interfaz + implementación) para dos proveedores externos; se acepta
  porque siguen siendo la mayor fuente de riesgo externo del proyecto
  (disponibilidad, cuotas — ver riesgo RT-01 en `11_technical_risks.adoc`).
- La calidad del ruteo depende enteramente del plano local (grafo
  peatonal); si este no representa bien la conectividad real del campus,
  ninguna estrategia ni algoritmo lo compensará — este riesgo se
  traslada a la fidelidad de contenido del plano, no al patrón de
  diseño.
- Este cambio de alcance deja desalineados `c4_contexto.md`,y `ficha-problema.md`, que aún podrían listar APIs
  o el módulo de realidad aumentada que ya no se usan; se recomienda
  actualizarlos en el próximo corte (ya se corrigió `Contexto.md` del
  modelo C4 — ver conversación previa).
## Referencias
 
- [`arbol_utilidad.md`](../arbol_utilidad.md)
- [`escenarios_calidad.md`](../Arc42\10_quality_requirements.adoc)
- [`restricciones.md`](../Arc42/02_architecture_constraints) 
- [`aspectos.md`](../Arc42/02_architecture_constraints) 
- [`arc42.md`](../Arc42/04_solution_strategy.adoc)
