# Taller aplicado · Mensajes y consistencia (S12)

Entregado el 2026-11-11, después del cierre de la semana 12. Es un **prototipo mínimo aislado** sobre
la única escritura hacia afuera que tiene MAPSUTB: el evento de uso que hoy se envía al Measurement
Protocol de GA4. La decisión de **no incorporarlo** al sistema está en el
[ADR 0019](./adr/0019-cola-de-eventos-de-uso-prototipo-no-incorporado.md).

## La operación y por qué es un prototipo

En la app, al pedir una ruta o abrir una zona, la pantalla llama a
`AnalyticsAdapter.registrarEvento(...)` y descarta el resultado
([`mapa_screen.dart:99`](../lib/features/mapas_ruteo/presentation/screens/mapa_screen.dart),
[`zonas_screen.dart:67-72`](../lib/features/zonas/presentation/screens/zonas_screen.dart)). El envío
es síncrono, sin reintento y como máximo una vez (ADR 0016, MF-13 a MF-15). Con una cola, la app no
dependería de que el proveedor esté disponible al momento del evento. Pero GA4 no deduplica, así
que los reintentos inflarían el conteo. Un colector propio que deduplique exige backend, y el
proyecto no puede tenerlo con costo cero y sin tarjeta. El prototipo reproduce esa operación con un
consumidor propio, para medir qué haría falta.

```
 productor (app)            ColaEventos (en memoria)                  ConsumidorConteo
 ───────────────            ────────────────────────                  ────────────────
 publicar(evento) ──JSON──▶ pendientes ──entregar──▶ procesar(m) ──▶ ¿id_mensaje visto?
                                 ▲          │                          sí → confirmar sin contar
                                 │          │ FalloTransitorio         no → contar y confirmar
                                 │          ▼
                                 │   espera 200/400/800 ms ── 4.º fallo ──▶ fallidos (motivo, intentos)
                                 └── reintento
```

Código: [`lib/experimentos/mensajes/`](../lib/experimentos/mensajes/). Ningún archivo de la app lo
importa, así que no llega al sitio publicado.

## Las siete demostraciones

### 1. Contrato del mensaje y criterio de compatibilidad

[`docs/api/eventos-uso.asyncapi.yaml`](./api/eventos-uso.asyncapi.yaml) (AsyncAPI 3.0) define el
mensaje `EventoUsoV1`, con cinco campos obligatorios (`version`, `id_mensaje`, `id_correlacion`,
`nombre` y `emitido_en`) y `parametros` opcional. También trae una tabla con el criterio de
compatibilidad:

- **Compatible:** agregar un campo opcional o un parámetro. El consumidor es un lector tolerante y
  lo ignora.
- **Incompatible:** quitar o renombrar un campo obligatorio, cambiar su tipo o su significado. Esto
  exige `version: 2`. El consumidor v1 rechaza otra versión y manda el mensaje a fallidos sin
  reintentarlo.

Implementación: `MensajeEventoUso.fromJson` en
[`mensaje_evento_uso.dart`](../lib/experimentos/mensajes/mensaje_evento_uso.dart).

### 2. Garantía de entrega y consecuencias asumidas

**Al menos una vez.** Un mensaje sale de la cola solo cuando el consumidor lo confirma, que en el
prototipo es que `procesar` termine sin excepción. Lo que se asume al elegirla:

- **El consumidor puede recibir duplicados.** Pasa en dos casos: si el productor reenvía porque no
  supo si llegó, o si el consumidor procesó y se perdió la confirmación. Por eso el consumidor
  tiene que ser idempotente (punto 3). Con un proveedor que no deduplica, como GA4, esta garantía
  no se puede usar, y esa es la razón del ADR 0019.
- **El orden se mantiene solo entre mensajes que no fallan.** Un mensaje que agota sus intentos sale
  hacia fallidos y los siguientes siguen. El conteo de eventos no depende del orden.
- **El dato llega con retraso.** En el peor caso del prototipo, 1,4 s de esperas; en un despliegue
  real, lo que tarde en volver la red.

Se descartaron las otras dos garantías:

- **Como máximo una vez** es lo que ya hace la app (alternativa A del ADR 0019).
- **Exactamente una vez** no existe de punta a punta sin un consumidor transaccional. Lo que se
  obtiene en la práctica es "al menos una vez + deduplicación", y eso es justo lo que implementa el
  prototipo.

### 3. Duplicados: deduplicación por `id_mensaje`

[`consumidor_conteo.dart`](../lib/experimentos/mensajes/consumidor_conteo.dart) guarda los
`id_mensaje` ya procesados. Si llega uno que ya vio, lo confirma sin contarlo y emite el log
`mensaje_duplicado_descartado`.

La clave la crea el productor: son 128 bits aleatorios (`MensajeEventoUso.nuevo`), y un reenvío del
mismo evento conserva el mismo id.

### 4. Reintentos con espera creciente y cola de fallidos

`PoliticaReintentos` en [`cola_eventos.dart`](../lib/experimentos/mensajes/cola_eventos.dart):

- 4 intentos en total, con esperas de 200, 400 y 800 ms (factor ×2 y tope de 5 s).
- Solo se reintenta ante `FalloTransitorio`: consumidor no disponible, tiempo agotado o confirmación
  perdida.
- Hay tres casos que van directo a `ColaEventos.fallidos`, la cola de mensajes fallidos, guardando
  el cuerpo original, los intentos y el motivo:
  - un error no recuperable;
  - un contrato incompatible;
  - un mensaje que agotó los intentos.

  Ningún mensaje se descarta en silencio. Siempre se cumple que publicados = entregados + fallidos
  cuando la cola queda vacía; hay una prueba que lo comprueba.

### 5. Pruebas automatizadas

Están en [`test/taller_mensajes_test.dart`](../test/taller_mensajes_test.dart). El CI las corre con
nombre propio en el paso «Taller de mensajes — duplicado y fallo recuperable» de
[`ci.yml`](../.github/workflows/ci.yml).

| Prueba | Qué demuestra |
|---|---|
| `duplicado: el mismo mensaje entregado dos veces se cuenta una sola vez` | El productor reenvía el mismo mensaje. Se cuenta 1, se descarta 1 duplicado y las dos entregas se confirman. |
| `duplicado: se perdió la confirmación y el reintento no cuenta dos veces` | El consumidor procesa y la confirmación se pierde. La cola reintenta, el reintento llega como duplicado y se descarta. |
| `fallo recuperable: se reintenta con espera creciente y se entrega una vez` | Dos fallos transitorios y luego éxito: esperas de 200 y 400 ms, conteo 1, nada en fallidos. |
| `agotados los 4 intentos, el mensaje queda en la cola de fallidos` | Esperas de 200, 400 y 800 ms; los dos mensajes terminan en fallidos y la cola queda vacía. |
| `un error no recuperable va a fallidos sin reintentar` | No hay ninguna espera. |
| `cambio compatible…` / `cambio incompatible…` | Un campo nuevo se ignora. Otra versión o un campo obligatorio ausente se rechaza sin reintento. |
| `trazabilidad: el id de correlación sigue al mensaje…` | La secuencia exacta de logs de un mensaje, del productor al consumidor. |

Run: ver [Evidencia de ejecución](#evidencia-de-ejecución).

### 6. Seguir un mensaje de productor a consumidor

Cada línea de log del prototipo lleva `id_mensaje` e `id_correlacion`, en el mismo formato JSON del
resto de la app (arc42 §8, observabilidad). Así se ve un mensaje con un fallo transitorio:

```json
{"ts":"2026-11-11T14:00:00.001Z","nivel":"info","evento":"mensaje_publicado","id_mensaje":"m-1","id_correlacion":"accion-42","pendientes":1}
{"ts":"2026-11-11T14:00:00.002Z","nivel":"warn","evento":"mensaje_reintento","id_mensaje":"m-1","id_correlacion":"accion-42","intento":1,"espera_ms":200,"motivo":"colector_no_disponible"}
{"ts":"2026-11-11T14:00:00.203Z","nivel":"info","evento":"mensaje_procesado","id_mensaje":"m-1","id_correlacion":"accion-42","evento_uso":"solicitud_ruta"}
{"ts":"2026-11-11T14:00:00.203Z","nivel":"info","evento":"mensaje_entregado","id_mensaje":"m-1","id_correlacion":"accion-42","intento":2}
```

Basta filtrar por `id_correlacion` para reconstruir el recorrido. La prueba de trazabilidad
comprueba esa secuencia exacta. `ColaEventos.metricas` cuenta publicados, entregados, reintentos y
fallidos, y `ConsumidorConteo.duplicadosDescartados` cuenta los duplicados.

### 7. ADR contra la alternativa síncrona

En el [ADR 0019](./adr/0019-cola-de-eventos-de-uso-prototipo-no-incorporado.md) hay una tabla que
compara el envío síncrono de hoy con la cola. Mide acoplamiento temporal y de contrato, latencia
para el usuario y hasta el dato, pérdida, duplicados, piezas nuevas y costo. Con esa comparación
se decide no incorporar la cola.

## Límites del experimento

Lo que el montaje **no cubre** y lo que haría falta en producción:

- **La cola vive en memoria.** Si se cierra la pestaña o se reinicia la app, se pierde lo pendiente
  y lo que había en fallidos. En producción haría falta almacenamiento durable: IndexedDB en el
  navegador como bandeja de salida, o un broker como Pub/Sub o una cola de Cloud Tasks.
- **El registro de ids vistos crece sin límite y vive en memoria.** En producción tendría que ser
  persistente, con caducidad (por ejemplo, 7 días, más que la ventana máxima de reintento), y
  guardarse **en la misma transacción** que el conteo. Si no, una caída entre los dos deja un
  evento contado y no marcado, y se duplicaría.
- **Un solo consumidor y entrega en serie.** No hay concurrencia, particiones ni consumidores en
  competencia. Con varios consumidores, la deduplicación tendría que ser atómica (por ejemplo, un
  `insert` con clave única).
- **Las esperas no tienen jitter.** Con muchos clientes reintentando a la vez, todos lo harían al
  mismo ritmo. En producción conviene la espera exponencial con jitter aleatorio.
- **La cola de fallidos no tiene reinyección ni alertas.** Solo se puede inspeccionar desde el
  código y las pruebas. En producción haría falta una alerta cuando crece y una herramienta para
  reinyectar.
- **No hay red real ni proveedor real.** Los fallos se simulan con un consumidor de prueba. No se
  midió la latencia con un broker ni el comportamiento con GA4, que de todos modos no permitiría
  deduplicar.
- **No hay seguridad del canal.** No hay autenticación del productor ni firma del mensaje. Un
  colector público necesitaría ambas, y es la misma razón por la que el `api_secret` de GA4 no
  puede ir en el cliente (T-02, [modelo de amenazas](./modelo-amenazas.md)).
- **No está en el sistema publicado**, por decisión (ADR 0019). Las métricas de la cola no se ven en
  producción.

## Evidencia de ejecución

- Commit del prototipo: `c4233af` (rama `s12-s14`, fusionada a `master`).
- CI de la rama: [run 43034881403](https://github.com/ISCOUTB/AS_202620_mapsutb/actions/runs/43034881403) sobre `4b3b99e`, en verde: 12 pruebas del taller, 154 de la suite completa y Quality Gate de SonarCloud. Incluye los pasos «Taller de mensajes — duplicado y fallo
  recuperable» y «Suite completa con cobertura».
