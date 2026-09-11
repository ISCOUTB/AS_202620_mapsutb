# Trazabilidad de Aspectos — MAPSUTB

Un aspecto es un corte vertical del sistema: aspecto → requisito → elementos C4 → ADR → código → pruebas → evidencia.

| ID | Aspecto | Requisito | C4 | ADR | Código | Pruebas | Evidencia |
|----|---------|-----------|----|----|--------|---------|-----------|
| A-01 | Localización y guiado en tiempo real del usuario dentro del campus, superponiendo un plano propio sobre el mapa base | RF-01: El sistema debe mostrar al usuario, sobre un mapa del campus, la ruta y su posición actual hacia un punto de interés seleccionado | `docs/c4/C2.md`  contenedores `MapaWidget` (Adapter sobre Google Maps SDK), `MapaRepository` (plano propio), Servicio de ubicación (Observer vía `Stream`) | `docs/adr/0001-patrones-de-diseno.md`, `docs/adr/0002.md` (Adapter, Repository, Observer; descarta ARCore/AR con cámara en vivo) | Parcial: `lib/adapters/`, `lib/repositories/`, `lib/services/` con la estructura y primeras implementaciones que impone el ADR 0001; ruteo y UI de guiado aún en construcción | `test/app_smoke_test.dart` (arranque en verde); sin prueba específica de A-01 todavía | Sin evidencia de ejecución en CI todavía |

## Escenario de calidad asociado a A-01 (formato de seis partes)

- **Fuente del estímulo:** un estudiante nuevo o visitante con la aplicación abierta en el campus.
- **Estímulo:** el usuario selecciona un punto de interés como destino (ej. "ZONA T").
- **Artefacto:** el módulo de mapas/ruteo de la aplicación (`MapaWidget` + Servicio de ruteo).
- **Ambiente:** operación normal, en exteriores del campus, con señal GPS disponible.
- **Respuesta:** el sistema calcula la ruta sobre el plano propio y refleja la posición del usuario en tiempo real sobre el mapa.
- **Medida de respuesta:** la ruta se muestra en un tiempo menor o igual a 5 segundos desde la selección del destino, con un margen de error de localización no mayor a 10 metros.

## Notas

- Este aspecto se actualizó tras el ADR 0002: se descartó el guiado por realidad aumentada sobre cámara (ARCore Geospatial API); el guiado ahora es sobre plano propio + mapa base.
- Aspectos candidatos adicionales identificados pero no priorizados aún para esta entrega: registro de puntos de interés, autenticación de usuarios invitados, navegación en interiores (fuera de alcance inicial), contenido panorámico 360° del tour.
