# Evidencia S11 — Fallos parciales y decisión de extracción

Qué pasa cuando el otro lado de una integración **no responde**, **responde tarde** o **responde
dos veces**, qué se hizo en cada caso, y la decisión de no extraer ningún módulo.

## 1. Integración principal, en el código

El flujo principal (A-01, pedir una ruta) no necesita red: el grafo y las zonas viajan dentro de la
app (`lib/routing/mapa_repository.dart`, `lib/repositories/zona_repository.dart`). En el despliegue
público hay una sola llamada de red en ese flujo, que por eso es la integración principal:

| Integración | Dónde ocurre la llamada | En producción |
|---|---|---|
| **Teselas de OpenStreetMap** (principal) | `lib/adapters/mapa_widget.dart`, `TileLayer` (`urlTemplate: https://tile.openstreetmap.org/...`) | Sí |
| Sensor de posición | `lib/services/ubicacion_service.dart` | Sí, **simulado** (RT-08) |
| Google Geocoding | `lib/adapters/geocoding_adapter.dart`, `_client.get(uri)` | No: sin key (ADR 0009) |
| Google Static Maps | `lib/adapters/static_map_adapter.dart`, `_client.get(uri)` | No: sin key (ADR 0009) |
| Measurement Protocol | `lib/adapters/analytics_adapter.dart`, `_client.post(...)` | Según los secretos del despliegue |

## 2. Tabla de modos de fallo

Está en [arc42 §11, «Modos de fallo de las integraciones»](./arc42/11_technical_risks.adoc#modos-de-fallo):
15 filas (MF-01 a MF-15), con los tres casos de la semana para cada integración. Cada fila indica
la mitigación asignada y si tiene prueba, si solo está descrita o si está pendiente con plan.

## 3. Mitigaciones declaradas frente a mitigaciones implementadas

| Mitigación | Código | Prueba |
|---|---|---|
| Tiempo límite de 5 s en Geocoding (MF-08) | `geocoding_adapter.dart`: `.timeout(tiempoLimite)` → `GeocodingException('TIEMPO_AGOTADO')` | `test/modos_de_fallo_test.dart` «MF-08» (adaptador y pantalla) |
| Sin red en Geocoding → error propio (MF-07) | `on http.ClientException` → `GeocodingException('SIN_CONEXION')` | «MF-07» |
| Una consulta a la vez (MF-09) | `ubicacion_screen.dart`: botón deshabilitado con `_geocodificando` | «MF-09» (dos toques, una llamada) |
| Tiempo límite y sin red en Static Maps (MF-10, MF-11) | `static_map_adapter.dart`: `.timeout(...)`, `StaticMapException` | «MF-10», «MF-11» |
| Tiempo límite en analítica (MF-14) | `analytics_adapter.dart`: `.timeout(tiempoLimite)` | «MF-14» |
| Analítica como máximo una vez (MF-15) | `analytics_adapter.dart`: ningún reenvío | «MF-15» |
| Reintento de teselas con espera creciente (MF-01) | Lo hace `flutter_map` (`RetryClient` por defecto en `NetworkTileProvider`) | De la librería, sin prueba propia |
| Aviso «Sin conexión al mapa base» (MF-01) | `mapa_widget.dart` `errorTileCallback` → `mapa_screen.dart` `_avisarSinMapaBase` | `test/mapa_test.dart` «MF-01» |
| Límite sin señal GPS, lecturas viejas y filtro de ruido (MF-04 a MF-06) | **Pendiente, con plan**, al integrar el GPS real (RT-08) | — |

**Antes de esta semana ninguna llamada HTTP tenía tiempo límite.** Si Geocoding no contestaba, el
botón «¿Dónde estoy?» quedaba deshabilitado sin fin, y la miniatura de Static Maps giraba sin
terminar.

## 4. Idempotencia y saga

Todas las operaciones que se pueden repetir son lecturas (GET), así que repetirlas no cambia nada.
La única escritura, el evento de analítica, no es idempotente: por eso se envía como máximo una vez
y nunca se reintenta. No hay saga, porque ninguna operación escribe en más de un sistema. Detalle
en [ADR 0016, «Idempotencia y saga»](./adr/0016-no-extraer-modulos-por-ahora.md#idempotencia-y-saga).

## 5. Decisión de extracción

[ADR 0016](./adr/0016-no-extraer-modulos-por-ahora.md): **no extraer**. Evalúa cuatro opciones
(no extraer; un intermediario de integraciones; el ruteo como servicio; los datos del campus fuera
de la app) con seis criterios: costo y tarjeta, fallos nuevos, Escenario 2, ritmo de cambio,
seguridad y operación. «No extraer» tiene su propia tabla de criterios, incluido el que **no**
cumple (el `api_secret` de la analítica sigue en el binario), y el ADR dice en qué condiciones se
revisa la decisión.

## 6. Trazabilidad

- `docs/aspectos.md`: A-01 suma ADR 0016, la prueba MF-01 y la tabla de §11, con enlaces
  navegables; A-02 suma las pruebas MF-07 a MF-15.
- C4 al día con el código: el «Plano del campus» figura como implementado en
  [`C2.md`](./c4/C2.md), y C1, C3 y arc42 §5 ya no describen Google Maps SDK como mapa base.

## 7. Para el proyecto final (calidad y resiliencia)

- **Con prueba automatizada:** MF-01, MF-07 a MF-11, MF-13 a MF-15.
- **Solo descritos:** MF-02, MF-03 y MF-12 (comportamiento de la librería, o lecturas idempotentes).
- **Pendientes con plan:** MF-04 a MF-06, que dependen del GPS real.
