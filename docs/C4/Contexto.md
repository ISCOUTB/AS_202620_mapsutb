# C4 — Contexto del sistema — MAPSUTB

## Contexto de negocio

El sistema de MAPSUTB interactúa con cuatro tipos de actores humanos y con dos servicios externos de Google.

| Actor / sistema externo | Tipo | Relación con MAPSUTB |
|---|---|---|
| Aspirante nuevo | Actor (persona) | Explora el campus antes de matricularse mediante el mapa. |
| Estudiante actual | Actor (persona) | Usa geolocalización y ruteo para ubicarse y desplazarse dentro del campus. |
| Estudiante de intercambio | Actor (persona) | Usa la app en su interfaz en inglés para orientarse en un campus desconocido. |
| Invitado | Actor (persona) | Usa la app para ubicarse y desplazarse en el campus. |
| Google Maps SDK | Sistema externo (clave) | Renderiza el mapa base sobre el cual se superpone el plano propio del campus. |
| Google Geocoding API | Sistema externo | Convierte coordenadas GPS en direcciones legibles y viceversa. |

## Contexto técnico

Técnicamente, la aplicación (cliente Flutter para Android/iOS) se comunica de forma directa con las dos APIs de Google mencionadas mediante HTTPS/REST. No existe backend propio: la lógica de mapas y geolocalización se apoya en estos servicios de terceros, mientras que el ruteo (sobre un grafo peatonal propio) y la clasificación de zonas y puntos de interés se resuelven completamente con datos locales, empaquetados dentro de la app. Esto reduce la complejidad de infraestructura a cargo del equipo pero introduce una dependencia fuerte de la disponibilidad de Maps SDK y Geocoding API (ver [restricciones](../Arc42/restricciones.md)).

El contenido panorámico (capturado vía smartphone) se gestiona como asset propio del proyecto, independiente de las APIs externas, y se muestra mediante el motor de renderizado 360° que el equipo defina dentro de Flutter (pendiente de selección al momento de este documento).

## Pendiente para completar el modelo C4

Para tener el modelo C4 completo del proyecto, aún haría falta documentar:
- **Contenedores:** app móvil Flutter, y si aplica, algún contenedor de almacenamiento de assets panorámicos.
- **Componentes:** módulos internos de la app (p. ej. módulo de tour panorámico, módulo de mapas/ruteo, módulo de clasificación de zonas).
- **Código:** solo si se requiere para partes críticas (opcional en arc42).