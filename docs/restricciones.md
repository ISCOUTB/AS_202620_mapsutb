# Restricciones de arquitectura — MAPSUTB

## Restricciones técnicas

| Restricción | Justificación |
|---|---|
| Dependencia del stack de Google (Maps SDK, ARCore Geospatial API, Places, Directions, Geocoding, Street View) | El equipo no desarrolla infraestructura propia de mapas, geolocalización ni RA; se apalanca en servicios maduros y con capa gratuita, dado el tamaño del equipo y el tiempo disponible. |
| ARCore Geospatial API como componente clave del sistema | Es la única forma viable de anclar contenido de realidad aumentada a coordenadas geográficas reales sin infraestructura propia (p. ej. beacons BLE o mapeo SLAM personalizado). |
| ARCore Geospatial API y el ruteo solo funcionan en exteriores del campus | Consecuencia directa de la API elegida: no existe cobertura geoespacial confiable en interiores, por lo que la navegación en interiores queda fuera de alcance. |
| Requiere dispositivos compatibles con ARCore / ARKit (vía Geospatial API) | No todos los dispositivos de gama baja soportan realidad aumentada; limita el público que puede usar ese feature específico, aunque el resto de la app sí es compatible. |
| No hay cámara 360° dedicada; captura vía panorámica de smartphone | Limitación de presupuesto y recursos del equipo; se complementa con Street View API para referencias visuales adicionales. |
| La app requiere conexión a internet constante (no hay modo offline) | Todas las APIs de Google utilizadas se consumen en línea; no se contempla almacenamiento local dado el alcance del proyecto. |
| Framework: Flutter | Permite un solo código base multiplataforma (Android/iOS), reduciendo el esfuerzo de desarrollo dado el tamaño del equipo. |
| Clasificación de zonas del campus manual (no dinámica) | Fuera de alcance un panel administrativo institucional; se prioriza tener un producto funcional dentro del tiempo del semestre. |

## Restricciones organizacionales

| Restricción | Justificación |
|---|---|
| Duración limitada por el calendario académico (un semestre) | Define el alcance realista de funcionalidades que pueden implementarse. |
| Equipo estudiantil sin presupuesto institucional asignado | Condiciona decisiones como no adquirir cámara 360° y usar APIs con capa gratuita en vez de soluciones propietarias. |
| Cuotas gratuitas de las APIs de Google Maps Platform | Existen límites de uso gratuito mensual; el equipo debe monitorear el consumo para evitar costos no previstos. |

## Restricciones políticas / institucionales

| Restricción | Justificación |
|---|---|
| El contenido debe representar fielmente los espacios reales de la UTB | Es una herramienta con potencial uso institucional (admisiones); errores de representación afectan la imagen de la universidad. |
| Debe incluir interfaz en inglés | El público objetivo incluye estudiantes de intercambio extranjeros, identificados como interesados del proyecto. |
| La navegación en interiores queda fuera de alcance de forma explícita | Limitación técnica de ARCore Geospatial API; se documenta como decisión consciente, no como omisión. |
