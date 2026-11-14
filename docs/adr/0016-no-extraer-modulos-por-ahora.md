# ADR 0016 — No extraer ningún módulo de la app por ahora; los fallos de integración se manejan dentro del monolito

## Estado

- **Estado**: Aceptado
- **Fecha**: 2026-10-13
- **Decisores**: Equipo MAPSUTB
- **Complementa**: [ADR 0004](./0004-adoptar-monolito-como-estilo-arquitectonico.md) (monolito) y
  [ADR 0005](./0005-integracion-apis-externas.md) (integración síncrona), sin cambiar sus decisiones

## Contexto

La semana 11 pide revisar qué pasa cuando el otro lado de una integración no responde, responde
tarde o responde dos veces, y decidir con criterios si algún módulo debe salir de la app a un
servicio propio. La tabla de modos de fallo está en
[arc42 §11](../arc42/11_technical_risks.adoc#modos-de-fallo).

Hoy MAPSUTB es una sola app Flutter publicada como sitio estático en Firebase Hosting (ADR 0007).
El flujo principal, pedir una ruta (A-01), **no depende de la red**: el grafo y las zonas viajan
dentro de la app. En producción solo hay dos llamadas externas en ese flujo: las teselas del mapa
base de OpenStreetMap (decorado, no datos de la ruta) y el sensor de posición. Geocoding y Static
Maps están apagados en el despliegue público porque Google exige tarjeta (arc42 §2, ADR 0009). La
analítica funciona por el principio de mejor esfuerzo.

Al revisar los modos de fallo aparecieron tres módulos que serían candidatos a extracción:

1. **Ruteo** (`lib/routing/`): calcular la ruta en un servidor.
2. **Intermediario de integraciones**: un servicio propio entre la app y Google (Geocoding, Static
   Maps) y el Measurement Protocol. Guardaría las credenciales, cachearía respuestas y podría
   deduplicar eventos.
3. **Datos del campus** (`grafo.json`, `zonas.json`): servirlos desde fuera de la app para
   actualizarlos sin volver a desplegar.

## Criterios de decisión

| Criterio | Pregunta | Por qué importa aquí |
|---|---|---|
| C1. Costo y tarjeta | ¿Cabe en el plan Spark sin tarjeta? | Restricción dura de arc42 §2 |
| C2. Fallos nuevos | ¿Agrega una llamada de red que puede no responder, tardar o duplicarse? | Es el tema de la semana; cada salto de red suma los tres modos de fallo |
| C3. Escenario 2 | ¿Mantiene la ruta en < 5 s, incluso sin conexión? | Hoy p95 0,68 ms, local |
| C4. Ritmo de cambio | ¿El módulo cambia a un ritmo distinto del resto de la app? | Si cambia junto con la app, separarlo solo agrega coordinación |
| C5. Seguridad | ¿Protege algo que hoy está expuesto? | `api_secret` y la key quedan dentro del binario (ADR 0009) |
| C6. Operación | ¿Cuántas piezas más hay que desplegar, vigilar y revertir? | El equipo ya opera sitio, sonda y reversión (ADR 0008, 0010) |

## Opciones consideradas

### A. No extraer ningún módulo (elegida)

| Criterio | Evaluación |
|---|---|
| C1 | Cumple: sigue siendo un sitio estático en Spark. |
| C2 | Cumple: no agrega llamadas. Los modos de fallo existentes se mitigan en los adaptadores con un tiempo límite de 5 s, sin reintento automático, y con un aviso cuando falta el mapa base (arc42 §11). |
| C3 | Cumple: la ruta sigue calculándose en el dispositivo, también sin conexión. |
| C4 | Cumple: ruteo, datos y pantallas cambian juntos. Las correcciones del grafo llegan con el mismo despliegue que las pantallas que las usan. |
| C5 | **No cumple del todo:** el `api_secret` del Measurement Protocol sigue en el binario y un tercero podría inyectar eventos falsos. Se acepta porque ese secreto solo permite escribir eventos, no leerlos (`lib/core/config_apis.dart`). |
| C6 | Cumple: una sola pieza que desplegar y revertir. |

- **Motivo de la elección:** es la única opción que cumple C1 y la única que no agrega un modo de
  fallo nuevo al flujo principal. Su debilidad (C5) está acotada y declarada.

### B. Extraer un intermediario de integraciones (descartada)

| Criterio | Evaluación |
|---|---|
| C1 | **No cumple:** Cloud Functions exige el plan Blaze, que pide tarjeta. |
| C2 | **Empeora:** cada llamada a Google pasa a tener dos saltos que pueden fallar (app → servicio → Google). |
| C3 | No afecta el ruteo. |
| C4 | Las integraciones cambian poco: el contrato está fijado en `docs/api/apis-externas.openapi.yaml`. |
| C5 | **Mejora:** las credenciales saldrían del binario y se podría deduplicar la analítica con un id por evento. |
| C6 | Empeora: un segundo artefacto con su propio despliegue, health y reversión. |

- **Motivo técnico del descarte:** viola la restricción de tarjeta (C1) y es la que más modos de
  fallo agrega. Es la opción que se debe revisar primero si cambia una de las condiciones de abajo.

### C. Extraer el ruteo a un servicio (descartada)

| Criterio | Evaluación |
|---|---|
| C1 | No cumple, por el mismo motivo que B. |
| C2 | **Empeora mucho:** un cálculo local de 0,68 ms pasa a ser una llamada de red con los tres modos de fallo, en el centro del flujo principal. |
| C3 | **No cumple sin conexión:** hoy la ruta sale aunque no haya red. |
| C4 | El ruteo cambia junto con el grafo y la pantalla. |
| C5 | No protege nada: el grafo es público (ODbL). |
| C6 | Empeora. |

- **Motivo técnico del descarte:** convierte la parte que hoy no puede fallar por red en la que
  más falla, sin ninguna ganancia frente a los criterios.

### D. Servir los datos del campus fuera de la app (descartada por ahora)

| Criterio | Evaluación |
|---|---|
| C1 | Cumple: serían archivos estáticos en el mismo Hosting. |
| C2 | **Empeora:** el grafo pasa a descargarse, con los tres modos de fallo, y obliga a decidir qué hacer sin conexión. |
| C3 | Se puede cumplir con una copia empaquetada de respaldo, pero eso suma lógica de versiones. |
| C4 | Es el único criterio a favor: el grafo podría cambiar por obras sin desplegar la app. Hoy cambia en la misma semana en que se procesa el levantamiento, junto con el código. |
| C5 | No afecta. |
| C6 | Empeora poco: mismo Hosting, pero dos versiones que mantener alineadas (app y datos). |

- **Motivo técnico del descarte:** su única ventaja (C4) todavía no se da. Los cambios del grafo
  vienen del levantamiento y salen en el mismo commit que el código que los usa.

## Decisión

**No extraer.** MAPSUTB sigue siendo un monolito (ADR 0004) y los fallos de integración se
manejan en cada adaptador:

- **Tiempo límite de 5 s** en Geocoding, Static Maps y analítica. Antes no había ninguno: una
  respuesta tardía dejaba el botón «¿Dónde estoy?» deshabilitado sin fin.
- **Sin reintento automático en el código propio.** Geocoding y Static Maps son lecturas (GET) que
  el usuario puede repetir, y cada intento consume cuota de Google (`docs/costos.md`). La analítica
  se envía **como máximo una vez**: el Measurement Protocol no deduplica, así que reenviar tras un
  tiempo agotado podría contar el evento dos veces.
- **Las teselas las reintenta `flutter_map`** (usa un `RetryClient` con espera creciente por
  defecto). Si aun así fallan, la pantalla avisa que la ruta sigue siendo válida.

### Idempotencia y saga

- **Idempotencia:** las operaciones que se pueden repetir son las lecturas (Geocoding, Static Maps,
  teselas, `grafo.json`, `zonas.json`). Son GET sin efectos en el otro lado, así que repetirlas no
  cambia nada y no hace falta una clave de idempotencia. La única escritura es el evento de
  analítica. No es idempotente y por eso no se reintenta (como máximo una vez). La pantalla tampoco
  dispara una segunda consulta mientras la primera está en curso: el botón se deshabilita, y eso
  tiene prueba (MF-03).
- **Saga:** no aplica. Ninguna operación escribe en más de un sistema ni necesita deshacer pasos
  ya hechos. La app no tiene base de datos propia: Firestore quedó para la estrategia de datos de
  la semana 12. Si esa estrategia agrega una escritura (por ejemplo, guardar rutas favoritas), esta
  sección se revisa en un ADR nuevo.

## Cuándo revisar esta decisión

- Si aparecen eventos falsos en la analítica (C5): pasar a la opción B. Exige una cuenta de
  facturación institucional, no personal.
- Si Geocoding supera 10.000 consultas al mes (`docs/costos.md`): un intermediario con caché
  (opción B) reduciría el costo.
- Si el campus cambia más rápido que los despliegues (por ejemplo, cierres temporales por obras):
  pasar a la opción D, con copia empaquetada de respaldo.

## Consecuencias

- **Positivas:** ningún modo de fallo nuevo, y el flujo principal sigue funcionando sin conexión.
  Todo lo que antes podía quedarse esperando sin fin ahora termina en un mensaje controlado
  (Escenario 3).
- **Negativas:** el `api_secret` de la analítica sigue en el binario; la analítica pierde eventos
  cuando no hay red, porque nunca se reenvían; actualizar el grafo exige desplegar la app.
- **Pruebas:** `test/modos_de_fallo_test.dart` y la prueba MF-01 de `test/mapa_test.dart` (la
  tabla de arc42 §11 indica cuáles modos tienen prueba y cuáles solo están descritos).
