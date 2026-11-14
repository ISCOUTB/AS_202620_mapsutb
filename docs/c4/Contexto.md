# C4 — Contexto del sistema — MAPSUTB

## Contexto de negocio

El sistema de MAPSUTB interactúa con cuatro tipos de actores humanos, con OpenStreetMap (teselas del mapa base) y, opcionalmente, con Geocoding y Static Maps de Google (apagados en producción por falta de key, ADR 0009).

| Actor / sistema externo | Tipo | Relación con MAPSUTB |
|---|---|---|
| Aspirante nuevo | Actor (persona) | Explora el campus antes de matricularse mediante el mapa. |
| Estudiante actual | Actor (persona) | Usa geolocalización y ruteo para ubicarse y desplazarse dentro del campus. |
| Estudiante de intercambio | Actor (persona) | Usa la app para orientarse en un campus desconocido (interfaz en inglés pendiente: solo español hoy). |
| Invitado | Actor (persona) | Usa la app para ubicarse y desplazarse en el campus. |
| OpenStreetMap (teselas) | Sistema externo (clave) | Mapa base sobre el cual la app dibuja zonas, posición y rutas con `flutter_map` (ADR 0012; reemplaza a Google Maps SDK). |
| Google Geocoding API | Sistema externo (opcional) | Convierte coordenadas GPS en direcciones legibles y viceversa. Apagada en producción (sin key). |
| Google Static Maps API | Sistema externo (opcional) | Miniatura estática del detalle de una zona. Apagada en producción (sin key). |

## Contexto técnico

Técnicamente, la aplicación (Flutter, publicada como sitio web en Firebase Hosting) pide las teselas del mapa base a OpenStreetMap con `flutter_map` y, cuando hay key, se comunica de forma directa con las APIs de Google mediante HTTPS/REST. No existe backend propio, mientras que el ruteo (sobre un grafo peatonal propio) y la clasificación de zonas y puntos de interés se resuelven completamente con datos locales, empaquetados dentro de la app. Esto reduce la complejidad de infraestructura a cargo del equipo pero introduce una dependencia de la disponibilidad del servidor de teselas y de Geocoding API; sus modos de fallo y mitigaciones están en [arc42 §11](../arc42/11_technical_risks.adoc#modos-de-fallo).

El contenido panorámico 360° está diferido (no implementado): no hay capturas ni código. Si se retoma, se gestionaría como asset propio del proyecto, independiente de las APIs externas, y se mostraría con un motor de renderizado 360° todavía no elegido (RT-02).

Los niveles siguientes del modelo están en [`C1.md`](./C1.md) (contexto), [`C2.md`](./C2.md) (contenedores) y [`C3.md`](./C3.md) (componentes). El nivel de código no se documenta (opcional en arc42).