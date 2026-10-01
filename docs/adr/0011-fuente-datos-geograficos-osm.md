# ADR 0011 — Datos geográficos del campus: OpenStreetMap más levantamiento propio

## Estado

- **Estado**: Aceptado
- **Fecha**: 2026-10-01
- **Decisores**: Equipo MAPSUTB

## Contexto

El contexto de **Ruteo** necesita un grafo peatonal del Campus Tecnológico (nodos con
coordenadas y tramos caminables) y el **Catálogo** necesita las coordenadas reales de las 11
zonas de `assets/data/zonas.json`, que hoy están en (0,0). Ninguno de esos datos existe en una
fuente institucional disponible para el equipo.

Restricciones: costo cero y sin tarjeta (arc42 §2), repositorio público, y que los datos se
puedan actualizar a medida que se recorre el campus (el levantamiento se hace por partes).

Al revisar alternativas se encontró que los términos adicionales de Google Maps y Google Earth,
§2(d), prohíben usar su contenido *"to create or augment any other mapping-related dataset
(including a mapping or navigation dataset…)"*, y que sus lineamientos de uso aplican esas
restricciones también a proyectos académicos.

## Decisión

1. **Geometría base en OpenStreetMap**, trazada por el equipo con el editor iD sobre las
   imágenes satelitales que OSM autoriza para trazar (Bing, Esri). El grafo se deriva de esos
   datos, que quedan bajo la licencia **ODbL**.
2. **Levantamiento propio en campo** para lo que la imagen satelital no muestra (entradas,
   escaleras, rampas, puertas, pisos): las herramientas web `coordenadas.html` y
   `recorrido.html`, la app GPS Logger (Android) y videos de las gafas Ray-Ban Meta.
3. **Procesamiento incremental** desde `C:\mapsutb-campo\` (fuera del repositorio): cada
   ejecución relee todos los datos, regenera el grafo y lista lo pendiente.

Procedimiento completo: [`docs/levantamiento-campo.md`](../levantamiento-campo.md).

## Alternativas consideradas

### A. OpenStreetMap + levantamiento propio (elegida)

- **A favor:** gratis, sin tarjeta y con permiso explícito para trazar sobre su imagen
  satelital; los datos quedan públicos y otros pueden corregirlos; sirve de mapa base si se
  adopta `flutter_map` + OpenStreetMap.
- **En contra:** ODbL exige atribución y compartir el grafo derivado con la misma licencia; el
  trazado depende de la calidad de la imagen bajo los árboles.

### B. Trazar sobre Google Earth o Google Maps (descartada)

- **Motivo:** sus términos (§2(d)) prohíben crear o ampliar datos de mapas o de navegación con su
  contenido, sin excepción académica. El grafo quedaría publicado en un repositorio y en una app
  pública.

### C. Solo GPS en campo, sin trazado (descartada como fuente principal)

- **Motivo técnico:** el GPS del celular tiene 5–10 m de error horizontal en exteriores y más
  junto a edificios; los caminos saldrían desplazados y con cruces falsos. Se usa como
  validación del trazado, no como geometría.

## Consecuencias

**Positivas**

- Los datos del mapa tienen una licencia clara y compatible con un repositorio público.
- Cada salida de campo mejora el grafo sin rehacer lo anterior.
- Las dos herramientas web reusan el despliegue existente (ADR 0007) sin infraestructura nueva.

**Negativas / riesgos aceptados**

- `grafo.json` y las coordenadas derivadas de OSM llevan atribución “© colaboradores de
  OpenStreetMap” y licencia ODbL; el resto del código mantiene su licencia.
- Las ediciones en OSM son públicas: solo se mapea lo que existe y es verificable.
- Los videos y recorridos crudos contienen personas y ubicaciones con hora: no se publican.

## Referencias

- [`docs/levantamiento-campo.md`](../levantamiento-campo.md)
- [OpenStreetMap — derechos de autor y licencia](https://www.openstreetmap.org/copyright)
- [Términos adicionales de Google Maps y Google Earth](https://www.google.com/help/terms_maps/)
- [ADR 0006](./0006-reajuste-limites-contexto.md) — contextos Catálogo y Ruteo.
