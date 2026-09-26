# Trazabilidad de Aspectos — MAPSUTB

Un aspecto es un corte vertical del sistema: aspecto → requisito → elementos C4 → ADR → código → pruebas → evidencia.

| ID | Aspecto | Contexto (arc42 §8) | Requisito | C4 | ADR | Código | Pruebas | Evidencia |
|----|---------|----------------------|-----------|----|----|--------|---------|-----------|
| A-01 | Localización y guiado en tiempo real del usuario dentro del campus, superponiendo un plano propio sobre el mapa base | Posicionamiento + Ruteo | RF-01: El sistema debe mostrar al usuario, sobre un mapa del campus, la ruta y su posición actual hacia un punto de interés seleccionado | `docs/c4/C2.md`  contenedores `MapaWidget` (Adapter sobre Google Maps SDK), `MapaRepository` (plano propio), Servicio de ubicación (Observer vía `Stream`) | `docs/adr/0001-patrones-de-diseno.md`, `docs/adr/0002-patrones-de-diseno-sin-realidad-aumentada.md` (Adapter, Repository, Observer), `docs/adr/0003-descartar-realidad-aumentada.md` (descarta ARCore/AR con cámara en vivo) | Parcial: `lib/adapters/`, `lib/repositories/`, `lib/services/` con la estructura y primeras implementaciones que impone el ADR 0001; ruteo y UI de guiado aún en construcción | `test/app_smoke_test.dart` (arranque); `test/ubicacion_test.dart` (Stream de `UbicacionService` y pantalla de Ubicación); sin prueba de ruteo todavía (Dijkstra pendiente) | [run CI verde `c4d036e`](https://github.com/ISCOUTB/AS_202620_mapsutb/actions/runs/36202698033); posicionamiento visible en https://mapsutb.web.app/ (pestaña Ubicación, GPS simulado) |
| A-02 | Integración con APIs externas por HTTP (geocodificación, miniaturas de mapa y analítica de uso), con contrato ejecutable y prueba de contrato | Transversal — no pertenece a los cuatro contextos de dominio (ver ADR 0006) | RF-02: El sistema debe poder convertir coordenadas GPS en direcciones legibles y viceversa (geocodificación); RF-03: El sistema debe registrar eventos de uso reales para priorizar mejoras (analítica) | `docs/c4/C2.md` y `docs/arc42/05_building_block_view.md`, relaciones `app→geocoding`, `app→mapsSdk` (Static Maps) y `app→analytics`; componentes `GeocodingAdapter`, `StaticMapAdapter`, `AnalyticsAdapter` (patrón Adapter) | `docs/adr/0005-integracion-apis-externas.md` (integración síncrona request/response sobre HTTPS para las tres integraciones) | `lib/adapters/geocoding_adapter.dart`, `lib/adapters/static_map_adapter.dart`, `lib/adapters/analytics_adapter.dart`; modelos `lib/models/direccion.dart`, `lib/models/imagen_mapa.dart`, `lib/models/evento_analitica.dart` | `test/geocoding_adapter_contract_test.dart`, `test/static_map_adapter_contract_test.dart`, `test/analytics_adapter_contract_test.dart` — validan la correspondencia con `docs/api/apis-externas.openapi.yaml` vía `http.testing.MockClient`, sin red real | [run CI verde `c4d036e`](https://github.com/ISCOUTB/AS_202620_mapsutb/actions/runs/36202698033) (paso "Prueba de contrato (APIs externas)" de `.github/workflows/ci.yml`); corrida en rojo ante el cambio incompatible citada en la auditoría definitiva de S7 |
| A-03 | Consulta del catálogo de lugares: zonas del campus y, por zona, sus pisos, espacios y salones | Catálogo de lugares | RF-04: El sistema debe permitir consultar las zonas del campus y, para cada una, sus pisos con los espacios y salones que contienen | `docs/c4/C2.md` contenedor "Datos de zonas y puntos de interés" (JSON local, relación `app→datos`); `docs/c4/C3.md` componentes `ZonaRepository` y pantallas de `zonas` | `docs/adr/0002-patrones-de-diseno-sin-realidad-aumentada.md` (Repository), `docs/adr/0006-reajuste-limites-contexto.md` (Zona, Espacio y punto de interés en el Catálogo) | `lib/repositories/zona_repository.dart`, `lib/models/zona.dart`, `piso.dart`, `espacio.dart`, `salon.dart`, `lib/features/zonas/presentation/screens/`, `assets/data/zonas.json` | `test/zonas_test.dart`: modelo `Zona`, `ZonaRepositoryLocal` contra el `zonas.json` real, lista con error y reintento, sin recarga en cada rebuild, detalle por piso | [run CI verde `c4d036e`](https://github.com/ISCOUTB/AS_202620_mapsutb/actions/runs/36202698033); desplegado en https://mapsutb.web.app/ (pestaña Zonas); log `zonas_cargadas` con `duracion_ms` (arc42 §8). Pendiente: coordenadas reales de las 11 zonas (hoy en 0,0) |
| A-04 | Recorrido panorámico 360° de los espacios del campus | Tour 360° | RF-05: El sistema debe mostrar el contenido panorámico 360° de un espacio del campus | `docs/c4/C2.md` contenedor "Contenido Panorámico 360°"; `docs/c4/C3.md` componente `TourRepository` | `docs/adr/0002-patrones-de-diseno-sin-realidad-aumentada.md` (Repository), `docs/adr/0006-reajuste-limites-contexto.md` (el tour referencia `Espacio`/`Salon`, no los extiende) | Pendiente: no existe `TourRepository` ni activos panorámicos (`lib/features/tour/` solo tiene `.gitkeep`) | Pendiente | Pendiente — declarado como diferido en `docs/c4/C2.md` |

## Escenario de calidad asociado a A-01 (formato de seis partes)

- **Fuente del estímulo:** un estudiante nuevo o visitante con la aplicación abierta en el campus.
- **Estímulo:** el usuario selecciona un punto de interés como destino (ej. "ZONA T").
- **Artefacto:** el módulo de mapas/ruteo de la aplicación (`MapaWidget` + Servicio de ruteo).
- **Ambiente:** operación normal, en exteriores del campus, con señal GPS disponible.
- **Respuesta:** el sistema calcula la ruta sobre el plano propio y refleja la posición del usuario en tiempo real sobre el mapa.
- **Medida de respuesta:** la ruta se muestra en un tiempo menor o igual a 5 segundos desde la selección del destino, con un margen de error de localización no mayor a 10 metros.

## Escenario de calidad asociado a A-02 (formato de seis partes)

- **Fuente del estímulo:** cualquier módulo de la App móvil que necesite geocodificar una ubicación,
  mostrar una miniatura de mapa o registrar un evento de uso.
- **Estímulo:** se realiza una petición HTTP a Google Geocoding API, Google Static Maps API o al
  Measurement Protocol, y el proveedor responde con degradación, error o pérdida de conexión.
- **Artefacto:** `GeocodingAdapter`, `StaticMapAdapter` y `AnalyticsAdapter`.
- **Ambiente:** operación normal, con conectividad intermitente o inexistente.
- **Respuesta:** la app no se cae; Geocoding y Static Maps propagan una excepción propia
  (`GeocodingException`, `StaticMapException`) que la UI traduce a un mensaje de error controlado;
  Analytics falla de forma silenciosa (de mejor esfuerzo) sin interrumpir el flujo principal.
- **Medida de respuesta:** 0% de caídas de la app; 100% de los casos de Geocoding/Static Maps con
  mensaje de error controlado (mismo estándar del Escenario 3 de
  [`docs/escenarios_calidad.md`](./escenarios_calidad.md), extendido aquí a las tres integraciones —
  ver [ADR 0005](./adr/0005-integracion-apis-externas.md)).

## Escenario de calidad asociado a A-03 (formato de seis partes)

- **Fuente del estímulo:** un estudiante nuevo o visitante con la app abierta.
- **Estímulo:** abre la pestaña Zonas y elige una zona para ver sus pisos y espacios.
- **Artefacto:** `ZonaRepositoryLocal`, `ZonasScreen` y `ZonaDetalleScreen`.
- **Ambiente:** operación normal, incluso sin conexión (el catálogo viaja dentro de la app).
- **Respuesta:** la lista de zonas se muestra y el detalle presenta cada piso con sus espacios y
  salones; si el catálogo no se puede cargar, la pantalla muestra un mensaje controlado con opción
  de reintentar.
- **Medida de respuesta:** lista visible en ≤ 1 s desde abrir la pestaña (medible con el campo
  `duracion_ms` del log `zonas_cargadas`); 100 % de los fallos de carga con mensaje controlado y
  reintento (cubierto por `test/zonas_test.dart`).

## Notas

- Este aspecto se actualizó tras el ADR 0003: se descartó el guiado por realidad aumentada sobre cámara (ARCore Geospatial API); el guiado ahora es sobre plano propio + mapa base.
- Aspectos candidatos adicionales identificados pero no priorizados aún para esta entrega: registro de puntos de interés, autenticación de usuarios invitados, navegación en interiores (fuera de alcance inicial), contenido panorámico 360° del tour.
- A-02 se agregó para la ficha S7 (Contrato de API y prueba de contrato): cubre las tres
  integraciones HTTP reales del sistema. Google Maps SDK (mapa interactivo) queda fuera de A-02
  a propósito — se consume como SDK nativo embebido, sin llamada REST propia que corresponder.
- Los cuatro contextos del mapa de dominio (`docs/arc42/08_concepts.adoc`) tienen ya un aspecto:
  **Posicionamiento** y **Ruteo** en A-01, **Catálogo de lugares** en A-03 y **Tour 360°** en A-04
  (este último declarado pendiente de punta a punta). A-02 es transversal. A-03 y A-04 se
  agregaron el 2026-09-25 para cerrar el hallazgo de S6 ("la fila A-01 no cubre los cuatro
  contextos").
