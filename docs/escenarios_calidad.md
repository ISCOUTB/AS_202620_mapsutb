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
- **Medición, cálculo de la ruta:** 100 rutas sobre el grafo real del campus, **p95 0,68 ms**
  y máximo 1,85 ms.
- **Medición, parte de pantalla:** desde que la pantalla tiene destino y posición hasta que el
  frame con la ruta está presentado, **19 ms** (evento `ruta_mostrada` de los logs
  estructurados). No incluye la espera del sensor GPS, que este escenario mide aparte con su
  margen de 10 m.
- Ambas en CI, [run](https://github.com/ISCOUTB/AS_202620_mapsutb/actions/runs/37042248426); umbral del escenario: 5 s. Ver `docs/evidencia-s9.md`.
- **Medición del margen de ubicación (umbral: 10 m).** 25 lugares del campus se midieron a la vez
  con dos aplicaciones distintas (la herramienta web y GPS Logger); la diferencia entre ambas
  mediciones estima el error real del GPS:

  | Dónde | Lugares | Mediana | Máxima | Umbral de 10 m |
  |---|---:|---:|---:|---|
  | Exterior o planta baja | 11 | 5,8 m | 31,2 m | cumple |
  | Dentro de un edificio | 14 | 16,5 m | 38,4 m | **no cumple** |

  El escenario se cumple en exteriores, que es su alcance declarado (arc42 §2). Dentro de los
  edificios el GPS no alcanza para ubicar un espacio: por eso la ruta termina en la entrada y el
  piso se declara a mano (ADR 0013). Medido el 2026-10-02 con los datos de
  `C:\mapsutb-campo`; procedimiento en `docs/levantamiento-campo.md`.

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

## Escenario 6 — Disponibilidad del despliegue web

- **Fuente del estímulo:** un usuario o evaluador fuera de la red de la universidad.
- **Estímulo:** abre la URL pública del sistema en cualquier momento de la semana.
- **Artefacto:** el sitio web desplegado en Firebase Hosting y su health check (`/health.json`).
- **Ambiente:** operación normal del entorno público.
- **Respuesta:** el sitio y el health check responden HTTP 200.
- **Medida de respuesta:** disponibilidad ≥ 99 % y p95 del tiempo de respuesta del health check
  menor a 1 s, en una ventana de 7 días.
- **Métrica consultable:** `disponibilidad_pct` y `latencia_p95_ms` en
  [`resumen.json`](https://raw.githubusercontent.com/ISCOUTB/AS_202620_mapsutb/metricas/resumen.json),
  medidos cada hora por la sonda de [ADR 0008](./adr/0008-metrica-disponibilidad-sonda-actions.md).

## Escenario 7 — Reversión del sitio web

- **Fuente del estímulo:** un integrante del equipo, desde fuera de la universidad.
- **Estímulo:** detecta que el último despliegue dejó el sitio roto y decide volver a la versión
  anterior.
- **Artefacto:** el sitio web desplegado (`https://mapsutb.web.app/`) y su `health.json`.
- **Ambiente:** operación normal, justo después de un despliegue automático desde `master`.
- **Respuesta:** el sitio vuelve a servir la versión anterior sin recompilar, y `health.json`
  muestra el commit de esa versión.
- **Medida de respuesta:** 5 minutos o menos desde la decisión hasta que `health.json` muestra el
  commit anterior. Medido: 0,4 s en Firebase Hosting
  ([run](https://github.com/ISCOUTB/AS_202620_mapsutb/actions/runs/36351911654)); ver
  [ADR 0010](./adr/0010-reversion-sitio-web.md) y [`taller-despliegue.md`](./taller-despliegue.md).
