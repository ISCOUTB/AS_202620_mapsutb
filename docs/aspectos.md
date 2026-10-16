# Trazabilidad de Aspectos — MAPSUTB

Un aspecto es un corte vertical del sistema: aspecto → requisito → elementos C4 → ADR → código → pruebas → evidencia.

| ID | Aspecto | Contexto (arc42 §8) | Requisito | C4 | ADR | Código | Pruebas | Evidencia |
|----|---------|----------------------|-----------|----|----|--------|---------|-----------|
| A-01 | Localización y guiado en tiempo real del usuario dentro del campus, con un plano propio sobre el mapa base | Posicionamiento + Ruteo | RF-01: El sistema debe mostrar al usuario, sobre un mapa del campus, la ruta y su posición actual hacia un punto de interés seleccionado | [C2](./c4/C2.md): contenedor «Plano del campus» (implementado) y relaciones con OpenStreetMap y el sensor; [C3](./c4/C3.md): `MapaWidget` (Adapter de `flutter_map`), `MapaRepository`, Servicio de ruteo, Servicio de ubicación (Observer) | [0002](./adr/0002-patrones-de-diseno-sin-realidad-aumentada.md) (Adapter, Repository, Observer), [0003](./adr/0003-descartar-realidad-aumentada.md) (sin RA), [0011](./adr/0011-fuente-datos-geograficos-osm.md) (datos del grafo), [0012](./adr/0012-mapa-base-flutter-map-osm.md) (mapa base), [0013](./adr/0013-ruteo-dijkstra-grafo-propio.md) (ruteo), [0016](./adr/0016-no-extraer-modulos-por-ahora.md) (fallos de integración, no extraer), [0017](./adr/0017-gps-real-geolocator-filtro.md) (GPS real) | Ruteo: [`grafo.dart`](../lib/routing/grafo.dart), [`mapa_repository.dart`](../lib/routing/mapa_repository.dart), [`servicio_ruteo.dart`](../lib/routing/servicio_ruteo.dart) sobre [`grafo.json`](../assets/data/grafo.json); mapa: [`mapa_widget.dart`](../lib/adapters/mapa_widget.dart) y [`mapa_screen.dart`](../lib/features/mapas_ruteo/presentation/screens/mapa_screen.dart) (aviso sin mapa base, MF-01); posición: [`ubicacion_service_gps.dart`](../lib/services/ubicacion_service_gps.dart) (GPS real con `geolocator`, filtro y vigía de señal) y [`ubicacion_service.dart`](../lib/services/ubicacion_service.dart) (interfaz, `FiltroUbicacion`, simulador para demostraciones) | [`ruteo_test.dart`](../test/ruteo_test.dart) (ruta más corta, mutación, escaleras, grafo real), [`grafo_test.dart`](../test/grafo_test.dart), [`mapa_test.dart`](../test/mapa_test.dart) (destino, ruta, fuera del campus, «Cómo llegar», MF-01), [`ubicacion_test.dart`](../test/ubicacion_test.dart), [`ubicacion_gps_test.dart`](../test/ubicacion_gps_test.dart) (MF-04 a MF-06), [`app_smoke_test.dart`](../test/app_smoke_test.dart) | Escenario 2, cálculo y pantalla: p95 0,68 ms y 19 ms con **posición simulada** ([run](https://github.com/ISCOUTB/AS_202620_mapsutb/actions/runs/37042248426)); margen de ubicación medido **aparte**, en campo, con dos apps GPS: mediana 5,8 m en exteriores ([escenarios](./escenarios_calidad.md)). Desde el 2026-10-13 la app usa el GPS real (ADR 0017), pero el flujo completo con GPS en el campus todavía no se ha medido. Mapa con ruta en https://mapsutb.web.app/ (pestaña Mapa); detalle en [`evidencia-s9.md`](./evidencia-s9.md); modos de fallo en [arc42 §11](./arc42/11_technical_risks.adoc#modos-de-fallo) |
| A-02 | Integración con APIs externas por HTTP (geocodificación, miniaturas de mapa y analítica de uso), con contrato ejecutable y prueba de contrato | Transversal — no pertenece a los cuatro contextos de dominio (ver ADR 0006) | RF-02: El sistema debe poder convertir coordenadas GPS en direcciones legibles y viceversa (geocodificación); RF-03: El sistema debe registrar eventos de uso reales para priorizar mejoras (analítica) | [C2](./c4/C2.md) y [arc42 §5](./arc42/05_building_block_view.md), relaciones `app→geocoding`, `app→mapsSdk` (Static Maps) y `app→analytics`; [C3](./c4/C3.md): componentes `GeocodingAdapter`, `StaticMapAdapter`, `AnalyticsAdapter` (patrón Adapter) | [0005](./adr/0005-integracion-apis-externas.md) (integración síncrona request/response sobre HTTPS para las tres integraciones); [`0016`](./adr/0016-no-extraer-modulos-por-ahora.md) (tiempo límite de 5 s, sin reintento propio, analítica como máximo una vez) | [`geocoding_adapter.dart`](../lib/adapters/geocoding_adapter.dart), [`static_map_adapter.dart`](../lib/adapters/static_map_adapter.dart), [`analytics_adapter.dart`](../lib/adapters/analytics_adapter.dart); modelos [`direccion.dart`](../lib/models/direccion.dart), [`imagen_mapa.dart`](../lib/models/imagen_mapa.dart), [`evento_analitica.dart`](../lib/models/evento_analitica.dart) | [`geocoding_adapter_contract_test.dart`](../test/geocoding_adapter_contract_test.dart), [`static_map_adapter_contract_test.dart`](../test/static_map_adapter_contract_test.dart), [`analytics_adapter_contract_test.dart`](../test/analytics_adapter_contract_test.dart) — validan la correspondencia con [`apis-externas.openapi.yaml`](./api/apis-externas.openapi.yaml) vía `http.testing.MockClient`, sin red real; [`modos_de_fallo_test.dart`](../test/modos_de_fallo_test.dart): no responde, responde tarde y responde dos veces (MF-07 a MF-15, [arc42 §11](./arc42/11_technical_risks.adoc#modos-de-fallo)) | [run CI verde `c4d036e`](https://github.com/ISCOUTB/AS_202620_mapsutb/actions/runs/36202698033) (paso "Prueba de contrato (APIs externas)" de `.github/workflows/ci.yml`); corrida en rojo ante el cambio incompatible citada en la auditoría definitiva de S7 |
| A-03 | Consulta del catálogo de lugares: zonas del campus y, por zona, sus pisos, espacios y salones | Catálogo de lugares | RF-04: El sistema debe permitir consultar las zonas del campus y, para cada una, sus pisos con los espacios y salones que contienen | [C2](./c4/C2.md): contenedor "Datos de zonas y puntos de interés" (JSON local, relación `app→datos`); [C3](./c4/C3.md): componentes `ZonaRepository` y pantallas de `zonas` | [0002](./adr/0002-patrones-de-diseno-sin-realidad-aumentada.md) (Repository), [0006](./adr/0006-reajuste-limites-contexto.md) (Zona, Espacio y punto de interés en el Catálogo) | [`zona_repository.dart`](../lib/repositories/zona_repository.dart), [`zona.dart`](../lib/models/zona.dart), [`piso.dart`](../lib/models/piso.dart), [`espacio.dart`](../lib/models/espacio.dart), [`salon.dart`](../lib/models/salon.dart), [`features/zonas/presentation/screens/`](../lib/features/zonas/presentation/screens/), [`zonas.json`](../assets/data/zonas.json) | [`zonas_test.dart`](../test/zonas_test.dart): modelo `Zona`, `ZonaRepositoryLocal` contra el `zonas.json` real, lista con error y reintento, sin recarga en cada rebuild, detalle por piso | [run CI verde `c4d036e`](https://github.com/ISCOUTB/AS_202620_mapsutb/actions/runs/36202698033); desplegado en https://mapsutb.web.app/ (pestaña Zonas); log `zonas_cargadas` con `duracion_ms` (arc42 §8). Coordenadas medidas en campo para 10 de las 11 zonas (OSM + levantamiento, [`levantamiento-campo.md`](./levantamiento-campo.md)); falta Contenedores, que no aparece en el mapa hasta tenerla |
| A-04 | Recorrido panorámico 360° de los espacios del campus | Tour 360° | RF-05: El sistema debe mostrar el contenido panorámico 360° de un espacio del campus | [C2](./c4/C2.md): contenedor "Contenido Panorámico 360°" (diferido); [C3](./c4/C3.md): componente `TourRepository` (diferido) | [0002](./adr/0002-patrones-de-diseno-sin-realidad-aumentada.md) (Repository), [0006](./adr/0006-reajuste-limites-contexto.md) (el tour referencia `Espacio`/`Salon`, no los extiende) | Diferido: no existe `TourRepository`, ni activos panorámicos, ni `lib/features/tour/` | Diferido | Diferido — declarado así en [C2](./c4/C2.md), [arc42 §5](./arc42/05_building_block_view.md) y [escenarios](./escenarios_calidad.md) (Escenarios 1 y 5) |

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
  integraciones HTTP reales del sistema. Las teselas de OpenStreetMap del mapa base (ADR 0012) quedan
  fuera de A-02 a propósito: las pide `flutter_map`, sin llamada REST propia que corresponder; sus
  modos de fallo están en A-01 y en arc42 §11 (MF-01 a MF-03).
- Los cuatro contextos del mapa de dominio (`docs/arc42/08_concepts.adoc`) tienen ya un aspecto:
  **Posicionamiento** y **Ruteo** en A-01, **Catálogo de lugares** en A-03 y **Tour 360°** en A-04
  (este último declarado diferido de punta a punta). A-02 es transversal. A-03 y A-04 se
  agregaron el 2026-09-25 para cerrar el hallazgo de S6 ("la fila A-01 no cubre los cuatro
  contextos").
