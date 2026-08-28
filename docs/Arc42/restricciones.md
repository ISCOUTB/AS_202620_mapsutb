# Restricciones de arquitectura — MAPSUTB

## Restricciones técnicas

| Restricción | Justificación |
|---|---|
| Dependencia de APIS (ARCore SDK base y ARCore Geospatial API) | Al mantener la informacion de ubicacion y mapas de manera local, el sistema de realidad aumentada depende de las apis para que este funcione, no afecta la funcionalidad de la app. |
| ARCore Geospatial API como componente clave del sistema | Es la única forma viable de anclar contenido de realidad aumentada a coordenadas geográficas reales sin infraestructura propia (p. ej. beacons BLE o mapeo SLAM personalizado). |
| ARCore Geospatial API y el ruteo solo funcionan en exteriores del campus | Consecuencia directa de la API elegida: no existe cobertura geoespacial confiable en interiores, y, aunque la navegación en interiores del campus no queda fuera de alcance, esta necesita de ser creada manualmente. |
| La RA Requiere dispositivos compatibles con ARCore / ARKit (vía Geospatial API) | No todos los dispositivos de gama baja soportan realidad aumentada; limita el público que puede usar ese feature específico, aunque el resto de la app sí es compatible. |
| No hay cámara 360° dedicada; captura vía panorámica de smartphone | Limitación de presupuesto y recursos del equipo; se complementa utilizando la camara panoramica de smartphone para dar la posibilidad de uso. |
| La realidad aumentada requiere conexión a internet constante | La API de Google que se utilizara se consume en línea. |
| Framework: Flutter | Permite un solo código base multiplataforma (Android/iOS), reduciendo el esfuerzo de desarrollo dado el tamaño del equipo. |
| Clasificación de zonas del campus manual (no dinámica) | Fuera de alcance un panel administrativo institucional; se prioriza tener un producto funcional dentro del tiempo del semestre. |

## Restricciones organizacionales

| Restricción | Justificación |
|---|---|
| Duración limitada por el calendario académico (un semestre) | Define el alcance realista de funcionalidades que pueden implementarse. |
| Equipo estudiantil sin presupuesto institucional asignado | Condiciona decisiones como no adquirir cámara 360° y usar APIs con capa gratuita en vez de soluciones propietarias. |

## Restricciones políticas / institucionales

| Restricción | Justificación |
|---|---|
| El contenido debe representar fielmente los espacios reales de la UTB | Es una herramienta con potencial uso institucional (admisiones); errores de representación afectan la imagen de la universidad. |
| Debe incluir interfaz en inglés | El público objetivo incluye estudiantes de intercambio extranjeros, identificados como interesados del proyecto. |
| La navegación en interiores del campus queda limitada en su alcance de forma explícita | Limitación técnica de ARCore Geospatial API; se documenta como decisión consciente, no como omisión. |
