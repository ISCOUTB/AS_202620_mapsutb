<a id="section-building-block-view"></a>

## Vista de Bloques

```mermaid
C4Container
    title MAPSUTB - Nivel 1 (Contenedores)
 
    Person(usuario, "Usuario del campus", "Aspirante, estudiante actual, estudiante de intercambio o invitado")
 
    System_Boundary(mapsutb, "MAPSUTB") {
        Container(app, "App móvil", "Flutter / Dart", "Interfaz, ubicación, ruteo interno y mapa base. Único artefacto desplegable (hoy, sitio web)")
        ContainerDb(plano, "Plano del campus", "Archivos empaquetados", "Grafo peatonal y geometría propia del campus, dibujada sobre el mapa base de OSM")
        ContainerDb(panoramas, "Contenido panorámico 360° (diferido)", "Imágenes equirectangulares", "No implementado: sin capturas ni TourRepository")
        ContainerDb(datos, "Datos de zonas y puntos de interés", "JSON local", "Clasificación manual de zonas y coordenadas de puntos de interés")
    }
 
    System_Ext(osm, "OpenStreetMap (teselas)", "Mapa base interactivo dibujado con flutter_map (ADR 0012)")
    System_Ext(mapsSdk, "Google Maps Platform", "Miniaturas estáticas (Static Maps API); opcional, requiere key")
    System_Ext(geocoding, "Google Geocoding API", "Convierte coordenadas y direcciones")
    System_Ext(analytics, "Measurement Protocol (Firebase/GA4)", "Registra eventos de uso de la app")
 
    Rel(usuario, app, "Explora, se ubica y traza rutas", "Interacción táctil")
    Rel(app, plano, "Lee el grafo peatonal y la geometría del campus", "Sistema de archivos, JSON")
    Rel(app, panoramas, "Leería el contenido del tour (diferido)", "Sistema de archivos, imagen equirectangular (JPEG)")
    Rel(app, datos, "Consulta zonas y puntos de interés", "Sistema de archivos, JSON")
    Rel(app, osm, "Pide teselas del mapa base", "HTTPS, PNG 256x256")
    Rel(app, mapsSdk, "Genera miniatura estática de una ubicación", "HTTPS, PNG (Static Maps API)")
    Rel(app, geocoding, "Solicita geocodificación", "HTTPS, JSON (REST)")
    Rel(app, analytics, "Registra evento de analítica", "HTTPS, JSON (Measurement Protocol)")
```

**Motivación:**

MAPSUTB se separa en un único artefacto desplegable (la app Flutter, hoy publicada como sitio web) y dos almacenes de
datos empaquetados localmente (plano del campus y datos de zonas/puntos de interés); el tercero, el contenido
panorámico 360°, está diferido (no implementado). No existe backend propio: toda la información vive dentro del
paquete de la app o se resuelve consultando las teselas de OpenStreetMap y, de forma opcional, los servicios de Google
(Static Maps, Geocoding; apagados en producción por falta de key) y el Measurement Protocol para analítica de uso, lo
que reduce la infraestructura a cargo del equipo pero introduce una dependencia de la disponibilidad de estos
servicios externos (ver [decisiones de diseño](09_architecture_decisions.adoc#section-design-decisions) y
restricciones técnicas).

**Bloques de construcción contenidos:**

| **Nombre** | **Responsabilidad** |
|---|---|
| App móvil | Único artefacto desplegable. Contiene toda la lógica de interfaz, ubicación, ruteo interno y mapa base. El tour panorámico está diferido (no implementado). |
| Plano del campus | Empaqueta el grafo peatonal y la geometría propia del campus, usados para el ruteo interno y para dibujarse sobre el mapa base de OSM. |
| Contenido panorámico 360° | **Diferido (no implementado):** no hay capturas ni código. Si se retoma, empaquetaría las imágenes equirectangulares capturadas vía smartphone para el tour virtual. |
| Datos de zonas y puntos de interés | Empaqueta el JSON con la clasificación manual de zonas (salones, laboratorios, oficinas) y sus coordenadas. |

**Interfases importantes:**

- **OpenStreetMap (teselas)** — HTTPS/PNG, pedidas por `flutter_map` para el mapa base (ADR 0012). No tienen
  contrato propio: las pide la librería, no una llamada REST que el código de MAPSUTB construya. Modos de fallo en
  [arc42 §11](11_technical_risks.adoc#modos-de-fallo).
- **Google Maps Platform** — HTTPS/PNG (Static Maps API) para miniaturas estáticas de una ubicación, con contrato
  ejecutable (ver más abajo). Opcional: el despliegue público corre sin key (ADR 0009).
- **Google Geocoding API** (HTTPS, JSON/REST — contrato en [`docs/api/apis-externas.openapi.yaml`](../api/apis-externas.openapi.yaml)): usada por la App móvil para convertir coordenadas GPS en direcciones legibles y viceversa. Integración síncrona request/response (ver [ADR 0005](../adr/0005-integracion-apis-externas.md)).
- **Measurement Protocol (Firebase/GA4)** (HTTPS, JSON — mismo contrato): usado por la App móvil para registrar eventos de uso (consulta de zonas, solicitud de rutas) sin agregar el SDK nativo de Firebase (ver [ADR 0005](../adr/0005-integracion-apis-externas.md)).

#### App móvil

_Propósito/Responsabilidad_

Único artefacto desplegable del sistema. Provee la interfaz de usuario (pantallas de mapa/ruteo, ubicación y zonas),
gestiona la ubicación en tiempo real del usuario, calcula rutas dentro del campus sobre el grafo peatonal propio,
dibuja el mapa base de OpenStreetMap con el plano propio superpuesto y registra eventos de uso para analítica. El
tour panorámico 360° está diferido (no implementado).

_Interfase(s)_

- Consume el sensor de ubicación del dispositivo.
- Consume las teselas de OpenStreetMap (HTTPS, PNG) para el mapa base, vía `flutter_map`.
- Consume Google Maps Platform: Static Maps API (HTTPS, PNG) para miniaturas estáticas, si hay key.
- Consume Google Geocoding API (HTTPS, JSON/REST, síncrona) para geocodificación.
- Consume Measurement Protocol (HTTPS, JSON, síncrona, de mejor esfuerzo) para registrar eventos de uso.
- Lee los dos contenedores de datos empaquetados localmente (plano y datos de zonas) vía sistema de archivos, JSON.

_Características de Calidad/Performance_

Una vez cargada la app, la ruta y las zonas funcionan sin red (viajan dentro del artefacto); el mapa base necesita red
para las teselas, y sin ellas la app avisa y sigue dibujando la ruta (MF-01). No está restringida a la red wifi
institucional ni al perímetro del campus.

_Ubicación Archivo/Directorio_

Repositorio: `github.com/ISCOUTB/AS_202620_mapsutb`

_Requerimientos Satisfechos_

Geolocalización en tiempo real, trazado de rutas dentro del campus y clasificación de zonas. Pendientes: tour
panorámico (diferido) e interfaz en inglés (solo español hoy).

_Riesgos/Problemas/Incidentes Abiertos_

El tour panorámico está diferido y no tiene motor 360° elegido (RT-02). La navegación en interiores queda fuera de
alcance: la ruta termina en la entrada del edificio (RT-07).

#### Plano del campus

_Propósito/Responsabilidad_

Almacena, empaquetado dentro de la app, el grafo peatonal (nodos y conexiones entre entradas, plazoletas y bloques)
y la geometría propia del campus, usados para el ruteo interno y para dibujarse sobre el mapa base de
OpenStreetMap. Implementado: `lib/routing/mapa_repository.dart` sobre `assets/data/grafo.json` (ADR 0011, 0013).

_Interfase(s)_

Expuesto a la App móvil a través de un repositorio (`MapaRepository`) que oculta el formato interno del archivo
(sistema de archivos, JSON).

_Riesgos/Problemas/Incidentes Abiertos_

El levantamiento del grafo peatonal es manual y depende de que el equipo lo mantenga actualizado ante cambios físicos
del campus.

#### Contenido panorámico 360°

_Propósito/Responsabilidad_

**Diferido (no implementado).** Almacenaría las imágenes equirectangulares (capturas esféricas vía smartphone, tipo
Google Street View App) del tour virtual. Hoy no hay capturas en `assets/` ni código en `lib/`.

_Interfase(s)_

Se expondría a la App móvil a través de un repositorio (`TourRepository`, que hoy no existe), sistema de archivos, imagen equirectangular (JPEG).

_Riesgos/Problemas/Incidentes Abiertos_

El equipo no cuenta con cámaras 360° dedicadas; la calidad de la captura depende del smartphone usado. Aún no se ha
definido el motor/librería de renderizado 360° en Flutter.

#### Datos de zonas y puntos de interés

_Propósito/Responsabilidad_

Almacena la clasificación manual de zonas del campus (salones, laboratorios, oficinas, etc.) y las coordenadas de
sus puntos de interés.

_Interfase(s)_

Expuesto a la App móvil a través de un repositorio (`ZonaRepository`, ver ADR 0006), sistema de
archivos, JSON.

_Riesgos/Problemas/Incidentes Abiertos_

La clasificación es cargada manualmente por el equipo; no se actualiza dinámicamente ni la mantiene la universidad.

#### Google Maps Platform

_Propósito/Responsabilidad_

Servicio externo de Google que en MAPSUTB solo genera miniaturas estáticas de una ubicación (p. ej. para el detalle
de una zona) vía Static Maps API. El mapa base interactivo dejó de ser Maps SDK: es OpenStreetMap con `flutter_map`
(ADR 0012).

_Interfase(s)_

- Miniaturas estáticas: HTTPS / REST, PNG. Contrato en [`docs/api/apis-externas.openapi.yaml`](../api/apis-externas.openapi.yaml)
  (ver [ADR 0005](../adr/0005-integracion-apis-externas.md)).

_Riesgos/Problemas/Incidentes Abiertos_

Dependencia fuerte de la disponibilidad del servicio de Google; sujeto a límites de cuota/costo según uso.

#### Google Geocoding API

_Propósito/Responsabilidad_

Servicio externo de Google que convierte coordenadas GPS en direcciones legibles y viceversa.

_Interfase(s)_

HTTPS / REST, JSON. Integración síncrona request/response (ver [ADR 0005](../adr/0005-integracion-apis-externas.md)).
Contrato consumido documentado en [`docs/api/apis-externas.openapi.yaml`](../api/apis-externas.openapi.yaml).

_Riesgos/Problemas/Incidentes Abiertos_

Dependencia fuerte de la disponibilidad del servicio de Google; sujeto a límites de cuota/costo según uso.

#### Measurement Protocol (Firebase/GA4)

_Propósito/Responsabilidad_

Endpoint público de recolección de eventos de Google Analytics/GA4 (la misma plataforma detrás de Firebase
Analytics), consumido directamente por HTTP en vez de mediante el SDK nativo de Firebase, para mantener el evento
contract-testable y no agregar una dependencia nativa al proyecto (ver [ADR 0005](../adr/0005-integracion-apis-externas.md)
para el porqué de esta elección y la consecuencia aceptada de perder los eventos automáticos del SDK).

_Interfase(s)_

HTTPS / REST, JSON. Integración síncrona, de mejor esfuerzo (un fallo de red no interrumpe el flujo principal).
Contrato en [`docs/api/apis-externas.openapi.yaml`](../api/apis-externas.openapi.yaml).

_Riesgos/Problemas/Incidentes Abiertos_

Sin los eventos automáticos del SDK de Firebase (`screen_view`, `session_start`, etc.); solo se registran los
eventos personalizados que `AnalyticsAdapter` envía explícitamente.

### Nivel 2

#### Caja Blanca App móvil

Se detalla la App móvil por ser el único artefacto desplegable del sistema y el que concentra toda la lógica de
negocio. Los demás bloques del Nivel 1 (plano del campus y datos de zonas; el contenido panorámico está diferido) son
simples almacenes de datos empaquetados sin lógica propia, por lo que no se detallan en un nivel adicional.

```mermaid
C4Component
    title MAPSUTB - Nivel 2 (Componentes de la App móvil)
 
    Person(usuario, "Usuario del campus", "Explora, se ubica y traza rutas dentro del campus")
 
    Container_Boundary(app, "App móvil (Flutter)") {
        Component(ui, "Pantallas de features", "Widgets Flutter", "mapas_ruteo (MapaScreen, UbicacionScreen), zonas")
        Component(ubicacion, "Servicio de ubicación", "Observer - Stream<Ubicacion>", "UbicacionServiceGps (geolocator) + FiltroUbicacion; emite la posición o UbicacionNoDisponible")
        Component(widget, "MapaWidget", "Adapter", "Dibuja el mapa base de OSM con flutter_map y superpone zonas, posición y rutas")
        Component(ruteo, "Servicio de ruteo", "Dijkstra sobre grafo propio", "Calcula la ruta más corta dentro del campus")
        Component(mapaRepo, "MapaRepository", "Repository", "Sirve el grafo peatonal y la geometría del plano propio sin exponer su formato")
        Component(zonaRepo, "ZonaRepository", "Repository", "Clasificación manual de zonas y puntos de interés (Zona y Espacio, ver ADR 0006)")
        Component(tourRepo, "TourRepository (diferido)", "Repository", "No implementado: serviría el contenido panorámico 360°")
        Component(geocodingAdap, "GeocodingAdapter", "Adapter", "Implementa el puerto de geocodificación; aísla la API de Google")
        Component(staticMapAdap, "StaticMapAdapter", "Adapter", "Genera miniaturas estáticas de ubicación; aísla Static Maps API")
        Component(analyticsAdap, "AnalyticsAdapter", "Adapter", "Registra eventos de uso; aísla el Measurement Protocol")
    }
 
    ContainerDb(datos, "Datos de zonas y puntos de interés", "JSON local", "Clasificación manual")
    ContainerDb(plano, "Plano del campus", "Archivos empaquetados", "Grafo peatonal y geometría propia")
    ContainerDb(panoramas, "Contenido panorámico 360° (diferido)", "Imágenes equirectangulares", "No implementado")
    System_Ext(osm, "OpenStreetMap (teselas)", "Mapa base (ADR 0012)")
    System_Ext(mapssdk, "Google Maps Platform", "Miniaturas estáticas (Static Maps API)")
    System_Ext(geocoding, "Google Geocoding API", "Coordenadas y direcciones")
    System_Ext(analytics, "Measurement Protocol (Firebase/GA4)", "Eventos de uso")
    System_Ext(sensor, "Sensor de ubicación del dispositivo", "Capacidad de la plataforma")
 
    Rel(usuario, ui, "Interactúa", "Interacción táctil")
 
    Rel(ui, ubicacion, "Se suscribe al stream", "Llamada a método (in-process), Stream<Ubicacion>")
    Rel(ui, mapaRepo, "Obtiene el grafo peatonal", "Llamada a método (in-process), async/await")
    Rel(ui, ruteo, "Pide la ruta y le pasa el grafo", "Llamada a método (in-process)")
    Rel(ui, zonaRepo, "Consulta zonas y puntos de interés", "Llamada a método (in-process)")
    Rel(ui, widget, "Le pasa zonas, posición y ruta para dibujar", "Composición de widgets (in-process)")
    Rel(ui, geocodingAdap, "Solicita geocodificación", "Llamada a método (in-process), async/await")
    Rel(ui, staticMapAdap, "Solicita miniatura de una ubicación", "Llamada a método (in-process), async/await")
    Rel(ui, analyticsAdap, "Registra un evento de uso", "Llamada a método (in-process), async/await, de mejor esfuerzo")
    Rel(ui, tourRepo, "Solicitaría panorámicas del tour (diferido)", "Llamada a método (in-process)")
 
    Rel(ubicacion, sensor, "Escucha cambios de posición", "API de plataforma (in-process), coordenadas (double)")
 
    Rel(widget, osm, "Pide teselas del mapa base", "HTTPS, PNG")
    Rel(geocodingAdap, geocoding, "Solicita geocodificación", "HTTPS, JSON (REST)")
    Rel(staticMapAdap, mapssdk, "Solicita miniatura estática", "HTTPS, PNG (Static Maps API)")
    Rel(analyticsAdap, analytics, "Envía evento de uso", "HTTPS, JSON (Measurement Protocol)")
 
    Rel(mapaRepo, plano, "Lee", "Sistema de archivos, JSON")
    Rel(zonaRepo, datos, "Lee", "Sistema de archivos, JSON")
    Rel(tourRepo, panoramas, "Leería (diferido)", "Sistema de archivos, imagen equirectangular (JPEG)")
```

- **Pantallas de features** (Widgets Flutter): agrupa las pantallas de mapa/ruteo (`MapaScreen`), ubicación
  (`UbicacionScreen`) y zonas; es el único punto de entrada de la interacción del usuario. `MapaScreen` lee el grafo de
  `MapaRepository` y las zonas de `ZonaRepository`, le pasa el grafo a `ServicioRuteo` y entrega zonas, posición y
  ruta a `MapaWidget`.
- **Servicio de ubicación** (patrón Observer, `Stream<Ubicacion>`): `UbicacionServiceGps`
  (`lib/services/ubicacion_service_gps.dart`) lee el GPS con `geolocator` (en web, la API de geolocalización del
  navegador); `FiltroUbicacion` descarta lecturas viejas (más de 10 s), imprecisas (más de 30 m) o sin movimiento
  (menos de 5 m); si no hay posición, el stream emite `UbicacionNoDisponible` con el motivo y la pantalla deja marcar
  la partida a mano (ADR 0017). `UbicacionServiceSimulado` queda para demostraciones.
- **MapaWidget** (patrón Adapter, `lib/adapters/mapa_widget.dart`): dibuja con `flutter_map` las teselas de
  OpenStreetMap como mapa base (ADR 0012) y superpone las zonas, la posición del usuario y las rutas calculadas.
- **Servicio de ruteo** (Dijkstra sobre grafo propio, `lib/routing/servicio_ruteo.dart`): calcula la ruta más corta
  dentro del campus a partir del grafo peatonal que le pasa la pantalla (`ServicioRuteo(grafo)`); no lee ningún
  repositorio ni depende de servicios externos.
- **MapaRepository** (patrón Repository, `lib/routing/mapa_repository.dart`): sirve el grafo peatonal
  (`assets/data/grafo.json`) sin exponer su formato de archivo; lo consume `MapaScreen`.
- **ZonaRepository** (patrón Repository): sirve la clasificación manual de zonas y espacios/puntos de
  interés desde el JSON local.
- **TourRepository** (patrón Repository): **diferido (no implementado)**; no existe en el código. Serviría el contenido
  panorámico 360° si se retoma el tour.
- **GeocodingAdapter** (patrón Adapter): implementa el puerto de geocodificación y aísla al resto de la app del SDK de
  Google Geocoding. Integración síncrona request/response sobre HTTPS (ver [ADR 0005](../adr/0005-integracion-apis-externas.md));
  contrato consumido en [`docs/api/apis-externas.openapi.yaml`](../api/apis-externas.openapi.yaml), validado en
  [`test/geocoding_adapter_contract_test.dart`](../../test/geocoding_adapter_contract_test.dart).
- **StaticMapAdapter** (patrón Adapter): implementa el puerto de miniaturas de mapa y aísla al resto de la app de
  Google Static Maps API. Contrato en [`docs/api/apis-externas.openapi.yaml`](../api/apis-externas.openapi.yaml),
  validado en [`test/static_map_adapter_contract_test.dart`](../../test/static_map_adapter_contract_test.dart).
- **AnalyticsAdapter** (patrón Adapter): implementa el puerto de analítica de uso y aísla al resto de la app del
  Measurement Protocol; falla de forma silenciosa ante errores de red (de mejor esfuerzo). Contrato en
  [`docs/api/apis-externas.openapi.yaml`](../api/apis-externas.openapi.yaml), validado en
  [`test/analytics_adapter_contract_test.dart`](../../test/analytics_adapter_contract_test.dart).

### Nivel 3

No se documenta un Nivel 3. Los componentes descritos en el Nivel 2 (pantallas, servicios, repositorios y adaptadores)
son lo suficientemente simples y de bajo riesgo como para no justificar una descomposición interna adicional; su
implementación se resuelve a nivel de clases dentro de cada componente sin complejidad arquitectónica relevante.
