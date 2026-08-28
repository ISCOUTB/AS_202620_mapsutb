# Uso de IA como herramienta de construcción — MAPSUTB

Este documento registra el uso de IA generativa durante el desarrollo del proyecto: qué se le pidió, qué propuso, qué se aceptó, qué se rechazó y por qué. La IA propone; el equipo decide y verifica.

## Registro de uso

| Fecha | Etapa | Herramienta | Uso / Prompt (resumen) | Resultado | Aceptado / Rechazado | Motivo |
|-------|-------|-------------|--------------------------|-----------|------------------------|--------|
| 07/08/2026 | Declarar | Claude | Exploración de APIs de Google aplicables a un proyecto de mapa universitario con realidad aumentada, y comparación de opciones de arquitectura (frontend/backend) | Listado de APIs (Maps SDK, ARCore Geospatial API, Places, Directions, Geocoding) y sugerencias de stack | Aceptado parcialmente | Se aceptó el listado de APIs como insumo de análisis; la elección final de stack (frontend/backend) queda pendiente de decisión del equipo, no se adoptó automáticamente lo sugerido por la IA. |
| 07/08/2026 | Declarar / Especificar | Claude | Redacción de la ficha del problema y de un escenario de calidad en formato de seis partes para el aspecto A-01 | Borrador de ficha del problema y escenario de calidad | Aceptado con ajustes | El contenido generado fue revisado por el equipo; los umbrales de la medida (3 segundos, 5 metros) quedan sujetos a validación técnica una vez se defina la arquitectura, no son un valor definitivo. |
| 28/08/2026 | Especificar y Verificar | Claude | Revision de las APIs con el nuevo sistema hosteando el mapa de forma local en la app | Se limito las APIs a ARCore SDK base y ARCore Geospatial API | Aceptado | Se reviso por el equipo para evitar que la app este el 100% del tiempo conectada a conexion internet y simplificar el desarrollo de la aplicacion al no usar demasiadas APIs externas |

## Lo que sigue siendo del equipo (no delegado a la IA)

- El alcance exacto del proyecto (outdoor vs. indoor).
- La decisión final de arquitectura y stack tecnológico.
- La verificación de que el código generado (cuando exista) cumple los requisitos y pasa las pruebas.
- La ejecución real de cualquier medición de calidad (no se aceptan medidas propuestas por la IA sin comprobación).

## Notas

- Este archivo se encuentra iniciado como parte de la entrega 1. Se irá completando en cada corte incremental a medida que se use IA en las etapas de Ubicar, Decidir, Construir, Verificar y Evidenciar.
