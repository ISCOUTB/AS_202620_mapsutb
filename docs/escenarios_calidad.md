# Escenarios de calidad medibles — MAPSUTB

Estos escenarios operacionalizan el [árbol de utilidad](./arbol_utilidad.md) definido para el
proyecto. Cada uno se describe en el formato de seis partes (fuente del estímulo, estímulo,
artefacto, ambiente, respuesta, medida de respuesta), igual que el escenario de A-01 documentado en
[`aspectos.md`](./aspectos.md).

## Escenario 1 — Rendimiento

- **Fuente del estímulo:** un usuario dentro de la app, en el módulo de tour panorámico.
- **Estímulo:** el usuario abre un punto del tour con conexión 4G.
- **Artefacto:** el módulo de tour (`TourRepository` + visor de panorámicas).
- **Ambiente:** operación normal, con conexión 4G disponible.
- **Respuesta:** la escena panorámica se carga y renderiza completamente.
- **Medida de respuesta:** menos de 3 segundos.

## Escenario 2 — Precisión de geolocalización y ruteo

- **Fuente del estímulo:** un usuario dentro del campus, en exteriores, con señal GPS disponible.
- **Estímulo:** el usuario solicita una ruta hacia un punto de interés del campus.
- **Artefacto:** el módulo de mapas/ruteo (`MapaWidget` + Servicio de ruteo).
- **Ambiente:** operación normal, en exteriores del campus, con señal GPS disponible.
- **Respuesta:** el sistema calcula la ruta y refleja la posición del usuario sobre el mapa.
- **Medida de respuesta:** menos de 5 segundos, con margen de error de ubicación menor a 10 metros.

## Escenario 3 — Disponibilidad / confiabilidad

- **Fuente del estímulo:** la red de datos del dispositivo del usuario.
- **Estímulo:** la conexión a internet se interrumpe o se degrada mientras se usa la app.
- **Artefacto:** la app completa, en particular los módulos que dependen de red (mapa base,
  geocodificación).
- **Ambiente:** operación degradada, con pérdida parcial o total de conectividad.
- **Respuesta:** la app no se cae y muestra un mensaje de error controlado en vez de fallar de
  forma silenciosa.
- **Medida de respuesta:** 0% de caídas de la app; 100% de los casos con mensaje de error
  controlado.

## Escenario 4 — Usabilidad

- **Fuente del estímulo:** un usuario nuevo (estudiante nuevo, de intercambio o visitante).
- **Estímulo:** abre la app por primera vez, sin instrucciones previas, e intenta moverse de un
  punto a otro del campus.
- **Artefacto:** la interfaz completa de la app (pantallas de mapas/ruteo y zonas).
- **Ambiente:** primer uso, sin capacitación ni ayuda externa.
- **Respuesta:** el usuario logra moverse de un punto a otro del campus sin ayuda externa.
- **Medida de respuesta:** menos de 2 minutos.

## Escenario 5 — Fidelidad de contenido

- **Fuente del estímulo:** el equipo del proyecto, durante la validación de contenido.
- **Estímulo:** se revisa un punto capturado (panorámica) contra el espacio real correspondiente.
- **Artefacto:** el contenido panorámico 360° capturado (activos que expondrá `TourRepository`).
- **Ambiente:** proceso de validación de contenido, antes de publicar/entregar.
- **Respuesta:** el punto capturado corresponde fielmente al espacio real que representa.
- **Medida de respuesta:** mínimo 90% de los puntos aprobados sin necesidad de recaptura.
