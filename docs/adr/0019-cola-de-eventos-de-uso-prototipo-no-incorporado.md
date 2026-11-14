# ADR 0019 — Cola de eventos de uso con entrega al menos una vez: prototipo aislado, no se incorpora

## Estado

- **Estado**: Aceptado
- **Fecha**: 2026-11-11
- **Decisores**: Equipo MAPSUTB
- **Relación**: taller de mensajes y consistencia (S12, entregado tarde). No cambia el
  [ADR 0005](./0005-integracion-apis-externas.md) (integración síncrona) ni el
  [ADR 0016](./0016-no-extraer-modulos-por-ahora.md) (analítica como máximo una vez): los confirma
  con un experimento.

## Contexto

El taller pide una operación del proyecto con desacoplamiento temporal, reintento o procesamiento
en segundo plano. MAPSUTB tiene una sola escritura hacia afuera: el **evento de uso**
(`solicitud_ruta`, `consulta_zona`) que `AnalyticsAdapterHttp` envía al Measurement Protocol de
GA4. Hoy es síncrona respecto de la red: un `POST` por evento, tiempo límite de 5 s, sin reintento
y sin cola. Si no hay red el evento se pierde (MF-13 a MF-15, arc42 §11).

Esa operación es la única candidata, pero no justifica una cola en el sistema real:

- El Measurement Protocol **no deduplica**. Con entrega al menos una vez, cada reintento después de
  una confirmación perdida contaría el evento dos veces en GA4, y el equipo no controla al
  consumidor para hacerlo idempotente.
- Una cola durable necesita un lugar donde guardar los mensajes pendientes y un consumidor propio
  que deduplique. Las dos cosas exigen backend (Cloud Functions o Firestore con escrituras), y la
  restricción de costo cero sin tarjeta los descarta (arc42 §2, ADR 0007).
- Perder algunos eventos no afecta a ningún usuario: la analítica sirve para priorizar mejoras, no
  es parte del flujo principal (Escenario 3).

Por eso la ficha se cumple con su segunda vía: un **prototipo mínimo aislado** sobre esa misma
operación, y esta decisión registrada de no incorporarlo.

## Opciones comparadas

| Criterio | A. Síncrona, como máximo una vez (hoy) | B. Cola con entrega al menos una vez (prototipo) |
|---|---|---|
| Flujo | La pantalla dispara `registrarEvento(...)` y descarta el `Future`. Un `POST` al proveedor con tiempo límite de 5 s. | La app publica en `ColaEventos` y sigue. Un despachador entrega al consumidor, reintenta y aparta los fallidos. |
| Acoplamiento temporal | El proveedor tiene que estar disponible **en el momento** del evento; si no, el evento se pierde. | Ninguno: el consumidor puede estar caído y el mensaje espera en la cola, con hasta 4 intentos y esperas de 200, 400 y 800 ms. |
| Acoplamiento de contrato | Directo con el formato del proveedor (OpenAPI, prueba de contrato del ADR 0005). | Con un contrato propio versionado (`docs/api/eventos-uso.asyncapi.yaml`); el proveedor queda detrás del consumidor. |
| Latencia para el usuario | Ninguna visible (fire-and-forget), pero hasta 5 s de petición abierta por evento. | Ninguna: publicar es encolar en memoria. |
| Latencia hasta el dato | Inmediata si hay red, nunca si no la hay. | Variable: en el peor caso la suma de esperas (1,4 s en el prototipo); en un despliegue real, hasta que vuelva la red. |
| Pérdida | Acepta perder eventos sin red. | No pierde mientras la cola sobreviva; lo que agota intentos queda en fallidos para revisarlo. |
| Duplicados | Imposibles: nunca se reenvía (MF-15). | Posibles por diseño; el consumidor los descarta por `id_mensaje`. Exige un consumidor propio. |
| Piezas nuevas | Ninguna. | Cola durable, consumidor propio, registro de ids vistos, monitoreo de la cola de fallidos. |
| Costo | 0. | Backend propio (fuera del plan Spark sin tarjeta). |

## Decisión

1. **El sistema se queda con A.** La analítica sigue siendo síncrona y como máximo una vez.
2. **B queda como prototipo aislado** en `lib/experimentos/mensajes/`. Ninguna pantalla ni servicio
   lo importa, así que no llega al sitio publicado: `dart2js` solo compila lo que se alcanza
   desde `main.dart`. Sus pruebas corren en CI con nombre propio («Taller de mensajes — duplicado
   y fallo recuperable»).
3. El prototipo usa el mismo nombre y los mismos parámetros que `EventoAnalitica` para que la
   comparación sea sobre la operación real, no sobre un ejemplo inventado.

## Consecuencias

- **Lo que se asume con A:** sin red se pierden eventos y la analítica subcuenta el uso en zonas
  con mala señal. No hay forma de saber cuántos se perdieron, salvo los logs `analitica_fallo_red`
  de cada navegador.
- **Lo que se gana:** ninguna pieza nueva que operar, ningún costo, y la garantía de no contar dos
  veces un evento en un proveedor que no deduplica.
- **El prototipo demuestra** que, si algún día existe un colector propio, la entrega al menos una
  vez es viable: el consumidor deduplica por `id_mensaje` y la cola de fallidos evita la pérdida
  silenciosa. Sus límites están en [`docs/taller-mensajes.md`](../taller-mensajes.md#límites-del-experimento).

## Cuándo revisar esta decisión

- Si el proyecto obtiene un backend propio (cuenta de facturación institucional, o despliegue en
  la infraestructura de la universidad): el colector propio puede deduplicar y B se vuelve viable.
- Si aparece una operación que **sí** escriba datos del usuario (por ejemplo, reportar un lugar
  mal ubicado): perderla ya no sería aceptable y la cola dejaría de ser opcional.
