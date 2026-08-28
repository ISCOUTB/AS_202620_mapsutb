# ADR 0001 — Patrones de diseño para el monolito MAPSUTB

## Estado

Aceptado — 2026-08-23 (revisado: mapa local + ruteo no exacto)

## Contexto

El patrón arquitectural del proyecto ya está decidido: **monolito** (una
app Flutter, sin backend propio por ahora. Este ADR **no** compara
alternativas arquitecturales; compara **patrones de diseño** (GoF y
patrones idiomáticos de Dart) para resolver problemas concretos del
proyecto.

**Cambio de alcance respecto a la versión anterior de este ADR:** se
decidió que el mapa del campus se aloja **de forma local** (activos
propios del proyecto — imagen, vector o grafo de nodos, sin depender de
un SDK de mapas externo) y que el ruteo **no busca ser exacto** (no hay
un cálculo tipo "turn-by-turn" sobre una red vial real, como haría una
API de direcciones).

Esto tiene una consecuencia directa sobre las dependencias externas: de
las 6 APIs de Google consideradas originalmente en `restricciones.md`
(Maps SDK, ARCore Geospatial API, Places, Directions, Geocoding, Street
View), **dejan de ser necesarias Maps SDK, Directions, Geocoding, Places
y Street View**. La única que se mantiene es **ARCore Geospatial API**,
porque anclar objetos de realidad aumentada a coordenadas GPS reales del
campus sigue siendo un problema que no se puede resolver con datos
locales — es, además, el diferenciador central del producto.

Con ese alcance reducido, los problemas de diseño que este ADR resuelve
son:

1. Aislar la única dependencia externa que queda: ARCore Geospatial API.
2. Servir el mapa del campus desde activos locales del proyecto.
3. Mantener actualizable la clasificación manual de zonas y los puntos de
   interés (objetivo de mantenibilidad, ver `arbol_utilidad.md`).
4. Calcular una ruta aproximada dentro de ese mapa local, sin depender de
   un servicio externo de ruteo.
5. Reflejar en tiempo real la ubicación del usuario en la UI y en la RA
   (escenario de calidad A-01 en `aspectos.md`: respuesta ≤ 3 s).

Cada uno se resuelve con un patrón distinto; no son alternativas entre
sí, así que se documentan por separado.

## Decisión

| # | Problema | Patrón adoptado |
|---|---|---|
| 1 | Aislar ARCore Geospatial API | **Adapter** |
| 2 | Servir el mapa del campus alojado localmente | **Repository** |
| 3 | Acceso a datos de zonas y puntos de interés | **Repository** |
| 4 | Ruteo aproximado dentro del mapa local | **Strategy** |
| 5 | Ubicación en tiempo real hacia UI y RA | **Observer** (`Stream` de Dart) |

## Alternativas consideradas, por problema

### 1. Aislar ARCore Geospatial API

- **Adapter (elegido):** una única clase `ArCoreAdapter` que implementa
  una interfaz propia del dominio (p. ej. `AnclajeArPort`). El resto del
  código nunca importa el SDK de ARCore directamente.
  - *A favor:* se puede simular en pruebas sin necesitar un dispositivo
    compatible con ARCore; si más adelante cambia de SDK (ARCore → ARKit
    en iOS, por ejemplo) solo cambia el adaptador.
  - *En contra:* una interfaz y una clase para un solo proveedor externo
    — ceremonia que antes se justificaba por 6 APIs y ahora es por 1.
    Se acepta igual porque sigue siendo la mayor fuente de riesgo externo
    del proyecto (disponibilidad, compatibilidad de dispositivo).
- **Alternativa descartada — invocar el SDK de ARCore directamente:**
  usar `ArCoreController` (o equivalente) directamente en el módulo de
  realidad aumentada.
  - *Consecuencia de no elegirla:* menos código al inicio, pero cualquier
    prueba del flujo de RA habría requerido un dispositivo compatible con
    ARCore corriendo la app; el módulo de RA habría quedado imposible de
    probar de forma aislada.

### 2. Servir el mapa del campus alojado localmente

- **Repository (elegido):** una interfaz `MapaRepository` que expone el
  mapa del campus (activos propios: imagen, vector o grafo de nodos)
  independientemente de cómo esté empaquetado internamente.
  - *A favor:* la UI y el módulo de ruteo no necesitan saber si el mapa
    es una imagen estática, un SVG o un grafo de nodos — solo consumen lo
    que expone el repositorio; si el equipo cambia el formato del mapa a
    mitad de semestre (p. ej. de imagen a grafo, para soportar mejor el
    ruteo aproximado del problema 4), el cambio queda contenido ahí.
  - *En contra:* una capa de indirección para un activo que, en la
    versión más simple, podría ser solo un archivo de imagen cargado
    directamente.
- **Alternativa descartada — cargar los activos del mapa directamente en
  cada pantalla que lo necesite:** el módulo de tour, el de mapas/ruteo y
  el de RA cargan y parsean el archivo del mapa cada uno por su cuenta.
  - *Consecuencia de no elegirla:* tres puntos distintos leyendo el mismo
    archivo, con riesgo de que cada uno interprete el formato del mapa de
    forma distinta o quede desalineado si el archivo cambia.

### 3. Acceso a datos de zonas y puntos de interés

- **Repository (elegido):** interfaces `ZonaRepository` y
  `PuntoInteresRepository`, con una primera implementación simple (en
  memoria o JSON local).
  - *A favor:* la clasificación manual de zonas queda concentrada en un
    solo punto de cambio en vez de repetirse en cada pantalla que la
    necesite. A diferencia de la versión anterior de este ADR, esta
    decisión ya no depende de Places API — los puntos de interés son
    datos propios del proyecto desde el inicio.
  - *En contra:* una capa de indirección más para un dato que, al inicio
    del proyecto, es pequeño.
- **Alternativa descartada — acceso a datos disperso:** cada módulo lee y
  filtra los datos de zonas/puntos de interés por su cuenta.
  - *Consecuencia de no elegirla:* actualizar la clasificación de una
    zona habría implicado revisar varios módulos, contradiciendo el
    objetivo de mantenibilidad ya priorizado.

### 4. Ruteo aproximado dentro del mapa local

- **Strategy (elegido):** una interfaz `RuteoAproximadoStrategy` con
  implementaciones intercambiables — por ejemplo, una que traza una línea
  recta hacia el destino y otra que recorre un grafo simple de rutas
  peatonales del campus (usando el mapa que expone `MapaRepository`).
  Ninguna alternativa llama a un servicio externo de ruteo.
  - *A favor:* el equipo puede empezar con el algoritmo más simple
    (línea recta) y, si el tiempo del semestre lo permite, añadir uno más
    elaborado (grafo de nodos) sin tocar el código que ya funciona ni el
    resto de la app; cada estrategia se prueba de forma aislada.
  - *En contra:* si al final el equipo solo implementa una estrategia
    durante todo el semestre, la interfaz se siente como una capa
    adicional innecesaria — costo pequeño que se acepta a cambio de
    dejar la puerta abierta sin comprometerse a un algoritmo desde ya.
- **Alternativa descartada — un único algoritmo embebido en el caso de
  uso:** calcular la ruta aproximada directamente dentro del caso de uso
  de "trazar ruta", sin una interfaz que lo abstraiga.
  - *Consecuencia de no elegirla:* habría sido más rápido de escribir al
    inicio, pero mezclar la lógica de "qué es una ruta aceptable en este
    proyecto" (dado que no se exige exactitud) con el caso de uso que la
    usa habría dificultado ajustarla o compararla con otro enfoque más
    adelante.

### 5. Ubicación en tiempo real hacia UI y RA

- **Observer vía `Stream` de Dart (elegido):** un servicio de ubicación
  expone un `Stream<Ubicacion>`; tanto la pantalla de mapa como el módulo
  de RA se suscriben a ese stream.
  - *A favor:* mecanismo idiomático de Dart/Flutter; múltiples partes de
    la app reaccionan al mismo cambio de ubicación sin acoplarse entre
    sí, ayudando a cumplir la medida de respuesta ≤ 3 s del escenario
    A-01.
  - *En contra:* exige manejar correctamente la cancelación de
    suscripciones (`dispose`).
- **Alternativa descartada — *polling* manual:** consultar la ubicación
  actual cada cierto intervalo con un `Timer`.
  - *Consecuencia de no elegirla:* desperdicia batería y CPU en
    dispositivos de gama media, y añade latencia impredecible frente al
    límite de 3 segundos del escenario de calidad.

## Consecuencias de la decisión

**Positivas**

- La superficie de dependencias externas se reduce de 6 APIs a 1
  (ARCore), lo que baja directamente el riesgo señalado en
  `restricciones.md` (cuotas, cambios de API, disponibilidad de terceros).
- El mapa local y el ruteo aproximado quedan detrás de interfaces
  (`MapaRepository`, `RuteoAproximadoStrategy`) que se pueden probar sin
  red y sin dispositivo AR.
- El equipo puede avanzar el módulo de mapas/ruteo sin esperar decisiones
  de cuotas o disponibilidad de servicios externos de Google.

**Negativas / riesgos aceptados**

- El adaptador para ARCore mantiene ceremonia (interfaz + implementación)
  para un solo proveedor; se acepta porque sigue siendo la pieza más
  riesgosa del sistema.
- La calidad del ruteo aproximado depende enteramente de las estrategias
  que el equipo implemente; si el mapa local (grafo o imagen) no
  representa bien la conectividad real del campus, ninguna estrategia lo
  compensará — este riesgo se traslada a la fidelidad de contenido del
  mapa, no al patrón de diseño.
- Este cambio de alcance deja desalineados `c4_contexto.md`,
  `restricciones.md` y `ficha-problema.md`, que aún listan las 5 APIs que
  ya no se usan; se recomienda actualizarlos en el próximo corte.

## Referencias

- [`restricciones.md`](../Arc42/restricciones.md)
- [`arbol_utilidad.md`](../arbol_utilidad.md)
- [`escenarios_calidad.md`](../escenarios_calidad.md)
- [`aspectos.md`](../aspectos.md) — escenario de calidad A-01
- [`arc42.md`](../Arc42/Estrategias_Solucion.md), sección 4 (Estrategia de solución)
