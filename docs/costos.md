# Estimación de costo mensual — MAPSUTB

Estimación hecha **desde el volumen del escenario del equipo**, no desde el catálogo del proveedor:
primero se fija cuánto se usa el sistema, después cuánto cuesta cada pieza a ese volumen y en qué
punto deja de ser gratis. Restricciones que la enmarcan: presupuesto cero y ninguna cuenta personal
con tarjeta (arc42 §2).

Precios verificados el 2026-09-25 en las páginas oficiales:
[Google Maps Platform — precios por SKU](https://developers.google.com/maps/billing-and-pricing/pricing)
y [planes de Firebase](https://firebase.google.com/pricing) (plan Spark: sin método de pago).

## Supuestos de volumen

| Supuesto | Valor | De dónde sale |
|---|---|---|
| Visitantes únicos al mes | 2.000 | Público objetivo de la ficha: aspirantes (admisiones), estudiantes nuevos y de intercambio; pico en inducción de semestre. |
| Visitas por visitante | 3 | Uso puntual para ubicarse en las primeras semanas. |
| Visitas al mes | **6.000** | 2.000 × 3 |
| Transferencia por visita | 3 MB la primera, ~0,3 MB las siguientes (caché del navegador) | Tamaño de `build/web` de Flutter (JS + assets); CanvasKit se sirve desde el CDN de Google. |
| Consultas de "¿Dónde estoy?" (Geocoding) | 2 por visita → **12.000/mes** | Botón de la pantalla Ubicación. |
| Miniaturas de zona (Static Maps) | 3 por visita → **18.000/mes** | Una por cada detalle de zona abierto (solo zonas con coordenadas). |
| Eventos de analítica (Measurement Protocol) | 3 por visita → 18.000/mes | Evento `consulta_zona`. |
| Muestras de la sonda de disponibilidad | 24/día → ~720/mes | `.github/workflows/sonda-disponibilidad.yml` |
| Concurrencia | < 20 usuarios simultáneos | Sitio estático; no hay servidor propio que dimensionar. |

## Costo por pieza al volumen supuesto

| Pieza | Plataforma | Capa gratuita | Uso supuesto | Costo mensual | Punto de ruptura de la capa gratuita |
|---|---|---|---|---|---|
| Sitio web (Flutter web) | Firebase Hosting, plan Spark (ADR 0007) | 10 GB almacenados, **360 MB/día** de transferencia | 2.000 × 3 MB + 4.000 × 0,3 MB ≈ 7,2 GB/mes ≈ **240 MB/día** en promedio | **USD 0** | **≈ 120 primeras visitas en un mismo día** (360 MB ÷ 3 MB), o ≈ 9.000 visitas/mes con la mezcla supuesta. En Spark no hay cobro: el sitio deja de servirse hasta el día siguiente. |
| CI, despliegue y sonda | GitHub Actions (repo público) | Minutos ilimitados en repositorios públicos | ~35 runs de CI + ~720 de sonda | **USD 0** | No aplica mientras el repositorio sea público. |
| Métrica | Rama `metricas` + raw.githubusercontent.com (ADR 0008) | Incluido en GitHub | ~720 líneas JSON/mes (< 150 KB) | **USD 0** | No aplica a este volumen. |
| Geocoding API | Google Maps Platform | 10.000 eventos/mes | 12.000 | **USD 10** = (12.000 − 10.000) ÷ 1.000 × USD 5 | **5.000 visitas/mes** (10.000 ÷ 2). |
| Static Maps API | Google Maps Platform | 10.000 eventos/mes | 18.000 | **USD 16** = (18.000 − 10.000) ÷ 1.000 × USD 2 | **≈ 3.333 visitas/mes** (10.000 ÷ 3). |
| Maps SDK Android/iOS (mapa base, pendiente) | Google Maps Platform | Ilimitado | — | **USD 0** | No tiene. |
| Analítica | Google Analytics vinculado al proyecto de Firebase, vía Measurement Protocol (ADR 0005) | Gratuito (GA4 estándar) | 18.000 eventos | **USD 0** | No aplica a este volumen. |
| Base de datos | Cloud Firestore (recomendado por el docente, **no adoptado aún**) | 1 GiB, 50.000 lecturas/día, 20.000 escrituras/día | — | **USD 0** | Pendiente de decisión (estrategia de datos, S12). |

**Total con las APIs de Google activas: ≈ USD 26/mes. Total del despliegue actual: USD 0.**

## Qué significa para el equipo

- **El riesgo real está en el hosting, no en el costo:** el promedio (≈ 240 MB/día) cabe en los
  360 MB/día de Spark, pero la carga no es pareja. En la semana de inducción, un día con más de
  ~120 visitantes nuevos agota la cuota y el sitio deja de responder hasta el día siguiente (lo
  detectaría la sonda del Escenario 6). Mitigaciones sin tarjeta: reducir el tamaño del build web
  (`--tree-shake-icons`, fuentes e imágenes) y cachear los estáticos con `Cache-Control` largo;
  con tarjeta, pasar a Blaze, que mantiene la misma cuota gratis y cobra solo el excedente.
- **Google Maps Platform exige una cuenta de facturación con tarjeta** incluso para la capa
  gratuita ([primeros pasos](https://developers.google.com/maps/get-started)). Eso choca con la
  restricción "sin tarjeta" de arc42 §2. Por eso el despliegue público corre **sin**
  `GOOGLE_MAPS_API_KEY`: la app arranca y oculta Geocoding y Static Maps (ver ADR 0009). El costo
  real de hoy es USD 0.
- Si el equipo o la universidad activan la facturación, **Static Maps es la primera pieza que se
  rompe** (≈ 3.300 visitas/mes), seguida de Geocoding (5.000). Antes de llegar ahí, las dos
  mitigaciones baratas son: guardar en caché la miniatura por zona (las coordenadas no cambian) y
  poner cuotas diarias por API en Google Cloud Console para que el tope sea un error controlado
  (Escenario 3) y no una factura.
- En la versión web, la key quedaría visible en el JavaScript publicado y las llamadas REST desde
  el navegador pueden bloquearse por CORS; Google orienta estos servicios web a uso desde servidor
  o app nativa. En la app móvil no aplica. Ver ADR 0007 y ADR 0009.
