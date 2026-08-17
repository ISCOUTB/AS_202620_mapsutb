# C4 — Contexto del sistema — MAPSUTB

> **Nota:** el documento original no incluye diagramas C4 explícitos (Contexto/Contenedores/Componentes). Este archivo reúne el contenido de la sección 3 ("Alcance y contexto del sistema"), que corresponde al **System Context** del modelo C4, como punto de partida para construir el diagrama.

## Contexto de negocio

El sistema de MAPSUTB interactúa con tres tipos de actores humanos y con seis servicios externos de Google.

| Actor / sistema externo | Tipo | Relación con MAPSUTB |
|---|---|---|
| Aspirante nuevo | Actor (persona) | Explora el campus antes de matricularse mediante el tour panorámico y el mapa. |
| Estudiante actual | Actor (persona) | Usa geolocalización y ruteo para ubicarse y desplazarse dentro del campus. |
| Estudiante de intercambio | Actor (persona) | Usa la app en su interfaz en inglés para orientarse en un campus desconocido. |
| Google Maps SDK | Sistema externo | Provee la visualización del mapa base del campus. |
| ARCore Geospatial API | Sistema externo (clave) | Ancla los objetos de realidad aumentada a ubicaciones geográficas reales en exteriores. |
| Google Places API | Sistema externo | Permite el registro y la búsqueda de puntos de interés dentro del campus. |
| Google Directions API | Sistema externo | Calcula las rutas peatonales entre la ubicación del usuario y su destino. |
| Google Geocoding API | Sistema externo | Convierte entre direcciones y coordenadas geográficas. |
| Google Street View / Maps Static API | Sistema externo | Provee referencias visuales complementarias al contenido panorámico propio. |

## Contexto técnico

Técnicamente, la aplicación (cliente Flutter para Android/iOS) se comunica de forma directa con las APIs de Google mencionadas mediante HTTPS/REST y los SDK nativos correspondientes (Maps SDK y ARCore). No existe backend propio: toda la lógica de mapas, geolocalización, ruteo y realidad aumentada se resuelve consumiendo servicios de terceros, lo que reduce la complejidad de infraestructura a cargo del equipo pero introduce una dependencia fuerte de la disponibilidad y las cuotas de dichos servicios (ver [restricciones](./restricciones.md)).

El contenido panorámico (capturado vía smartphone) se gestiona como asset propio del proyecto, independiente de las APIs externas, y se muestra mediante el motor de renderizado 360° que el equipo defina dentro de Flutter (pendiente de selección al momento de este documento).

## Pendiente para completar el modelo C4

Para tener el modelo C4 completo del proyecto, aún haría falta documentar:
- **Contenedores:** app móvil Flutter, y si aplica, algún contenedor de almacenamiento de assets panorámicos.
- **Componentes:** módulos internos de la app (p. ej. módulo de tour panorámico, módulo de mapas/ruteo, módulo de RA, módulo de clasificación de zonas).
- **Código:** solo si se requiere para partes críticas (opcional en arc42).
