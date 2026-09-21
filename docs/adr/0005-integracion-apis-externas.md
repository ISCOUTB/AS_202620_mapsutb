# ADR 0005 — Integración síncrona con las APIs externas de MAPSUTB

> **Numeración — reemplaza dos borradores anteriores, ninguno comiteado todavía:**
> el ADR "Integración síncrona con Google Geocoding API" (solo geocodificación) y el ADR "Adoptar
> Firebase Analytics" (adopción del SDK de Firebase). Este documento los **reemplaza a ambos** como
> el único ADR 0005: cubre la misma decisión de integración síncrona, pero ampliada a las tres APIs
> externas que hoy tiene MAPSUTB, y cambia el mecanismo de Firebase de "SDK" a "Measurement
> Protocol vía HTTP" por la razón explicada en la sección Firebase más abajo. No comitees los otros
> dos borradores — usa solo este archivo como `docs/adr/0005-*.md`.

## Estado

- **Estado**: Aceptado
- **Fecha**: 2026-09-20
- **Decisores**: Equipo MAPSUTB

## Contexto

La ficha S7 del curso ("Contrato de API y prueba de contrato") pide un contrato ejecutable de la
API principal del sistema, una prueba de contrato que pueda fallar ante un cambio incompatible, y
un ADR que justifique la estrategia de integración (síncrona o asíncrona) contra un escenario de
calidad. MAPSUTB no tiene backend propio (ADR 0004), pero sí consume tres servicios externos por
HTTP desde su propio código:

1. **Google Geocoding API** — ya documentada en `docs/arc42/06_runtime_view.md` ("Geocodificar una
   ubicación") y en `GeocodingAdapter`.
2. **Google Static Maps API** — nueva, para generar miniaturas/preview estáticos de una ubicación
   (p. ej. una tarjeta de punto de interés), sin depender del SDK interactivo embebido.
3. **Measurement Protocol (Firebase/Google Analytics)** — nueva, para los eventos de uso que el
   profesor pidió instrumentar (ver contexto del borrador anterior de este ADR: consulta de zonas,
   solicitud de rutas, tour 360°).

Deliberadamente **no** se incluye Google Maps SDK en este contrato: se consume como SDK nativo
embebido dentro de `MapaWidget` (ver ADR 0001/0002), no mediante llamadas REST que el propio código
Dart construya. No existe una implementación de MAPSUTB con la que un contrato HTTP de Maps SDK
pudiera corresponder, y forzar uno sin código real que lo consuma sería un contrato sin
correspondencia verificable — justo lo que la ficha pide evitar.

El Escenario 3 de `docs/escenarios_calidad.md` (Disponibilidad/confiabilidad) nombra la
geocodificación como módulo dependiente de red y exige que, ante degradación o pérdida de
conexión, "la app no se cae y muestra un mensaje de error controlado" (0% de caídas, 100% de casos
con mensaje de error controlado). Ese mismo estándar se extiende aquí a las tres integraciones.

## Decisión

Las tres integraciones son **síncronas, de tipo petición/respuesta (request/response) sobre
HTTPS**. Cada adaptador hace la llamada, la espera (`await`), y devuelve un resultado del dominio
propio o lanza una excepción propia — ninguna deja la solicitud "en curso" en segundo plano ni
depende de un callback o evento posterior:

| API externa | Adaptador | Modelo de dominio | Excepción propia |
|---|---|---|---|
| Google Geocoding API | `GeocodingAdapter` / `GeocodingAdapterHttp` | `Direccion` | `GeocodingException` |
| Google Static Maps API | `StaticMapAdapter` / `StaticMapAdapterHttp` | `ImagenMapa` | `StaticMapException` |
| Measurement Protocol | `AnalyticsAdapter` / `AnalyticsAdapterHttp` | `EventoAnalitica` | `AnalyticsException` (capturada internamente, ver más abajo) |

El contrato ejecutable de las tres integraciones vive en un único archivo,
`docs/api/apis-externas.openapi.yaml`, y la correspondencia entre ese contrato y cada
implementación se valida en `test/geocoding_adapter_contract_test.dart`,
`test/static_map_adapter_contract_test.dart` y `test/analytics_adapter_contract_test.dart`.

**Caso especial — analítica nunca bloquea ni rompe el flujo principal:** a diferencia de
Geocoding y Static Maps (donde un error se propaga como excepción para que la UI decida qué
mostrar), `AnalyticsAdapterHttp.registrarEvento` captura internamente cualquier fallo de red y
retorna sin lanzar. Un evento de analítica perdido no es un caso que deba interrumpir la
navegación del usuario; sigue siendo un requerimiento del Escenario 3 ("la app no se cae"), pero
aplicado de forma más estricta porque este flujo ni siquiera necesita mostrar el mensaje de error
controlado — el usuario nunca debería notar que un evento no se registró.

## Alternativas consideradas

### A. Síncrona request/response para las tres (elegida)

- **A favor:** es exactamente cómo funcionan las tres APIs — ninguna ofrece push del lado del
  proveedor. Cumple el Escenario 3 directamente: cada llamada se captura en su propio `try/catch`,
  permitiendo mostrar (o, en el caso de analítica, silenciar) el resultado de inmediato.
- **En contra:** la UI debe manejar un estado de carga mientras dura cada llamada (aceptable, las
  tres responden en el orden de cientos de milisegundos).

### B. Asíncrona basada en eventos (descartada)

Encolar las solicitudes y notificar el resultado más tarde mediante un evento o callback (como ya
hace `UbicacionService` con su `Stream<Ubicacion>`).

- **Consecuencia de no elegirla:** ninguna de las tres APIs ofrece un mecanismo de notificación
  push — adoptar este patrón exigiría construir una cola o polling encima de APIs que ya son
  síncronas. Este patrón sí tiene sentido en MAPSUTB para datos que cambian continuamente sin que
  la UI los solicite (ubicación GPS), no para peticiones puntuales como estas.

### C. Firebase Analytics vía SDK oficial en vez de Measurement Protocol por HTTP (descartada para este ADR)

El borrador anterior de este ADR proponía adoptar el SDK de Firebase Analytics.

- **Consecuencia de no elegirla ahora:** el SDK de Firebase es un paquete nativo (requiere
  `google-services.json`/configuración por plataforma) que instrumenta eventos automáticos
  (`screen_view`, `session_start`, `engagement_time_msec`) pero **no expone una llamada HTTP que el
  propio código de MAPSUTB construya** — igual que Maps SDK, no habría con qué corresponder un
  contrato ejecutable. El Measurement Protocol es la misma plataforma de analítica (Google
  Analytics/GA4) consumida como REST puro, con contrato y prueba de contrato reales, y sin agregar
  una dependencia nativa a un proyecto que hasta ahora no tenía SDKs adicionales más allá de Maps y
  Geocoding.
- **Consecuencia aceptada:** se pierden los eventos automáticos del SDK (`screen_view`,
  `session_start`, `first_open`, `engagement_time_msec`); solo quedan los eventos personalizados
  que `AnalyticsAdapter` envía explícitamente (`consulta_zona`, `solicitud_ruta`, etc., ver tabla
  de eventos en el borrador anterior de este ADR conservada como referencia de producto). Si más
  adelante el equipo quiere recuperar esos eventos automáticos, puede añadir el SDK de Firebase
  como una capa adicional sin afectar `AnalyticsAdapter` ni este contrato — son mecanismos
  complementarios, no mutuamente excluyentes.

## Consecuencias de la decisión

**Positivas**

- Un único contrato ejecutable (`docs/api/apis-externas.openapi.yaml`) y tres pruebas de contrato
  cubren toda la superficie HTTP real del sistema.
- Ninguna integración agrega una dependencia nativa nueva al proyecto (todas usan `package:http`,
  ya requerido por Geocoding).
- El manejo de errores queda simple y localizado en cada adaptador.

**Negativas / riesgos aceptados**

- La UI debe manejar el estado de carga de Geocoding y Static Maps mientras la llamada está en
  curso (indicador visual pendiente de implementar en las pantallas que los usen).
- Se pierden los eventos automáticos que el SDK de Firebase Analytics instrumentaría solo por
  incluir el paquete (ver alternativa C).
- Un evento de analítica perdido por fallo de red no se reintenta ni se encola; se acepta como
  costo de mantener la analítica fuera del camino crítico.

## Referencias

- [`docs/arc42/06_runtime_view.md`](../arc42/06_runtime_view.md) — flujo "Geocodificar una ubicación".
- [`docs/arc42/05_building_block_view.md`](../arc42/05_building_block_view.md) — interfaces HTTP de la App móvil.
- [`docs/escenarios_calidad.md`](../escenarios_calidad.md) — Escenario 3, Disponibilidad/confiabilidad.
- [`docs/api/apis-externas.openapi.yaml`](../api/apis-externas.openapi.yaml) — contrato ejecutable de las tres integraciones.
- [`docs/adr/0001-patrones-de-diseno.md`](./0001-patrones-de-diseno.md) — patrón Adapter, base de los tres adaptadores.
