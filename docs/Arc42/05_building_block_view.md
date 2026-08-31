<a id="section-building-block-view"></a>

## Vista de Bloques

> **Contenido**
>
> La vista de bloques muestra la descomposición estática del sistema en bloques de construcción (módulos, componentes,
> subsistemas, clases, interfases, paquetes, bibliotecas, marcos de desarrollo, capas, particiones, funciones, macros,
> operaciones, estructuras de datos,...) así como sus dependencias (relaciones, asociaciones,...)
>
> Esta vista es obligatoria para cualquier documentación de arquitectura.
> Es la analogía al plano de una casa.
>
> **Motivación**
>
> Mantener una visión general de su código fuente haciendo su estructura comprensible de manera abstracta.
>
> Esto permite comunicar a las partes interesades en un nivel abstracto sin entrar en detalles de implementación.
>
> **Forma**
>
> La vista de bloques comprende una colección jerárquica de cajas negras y cajas blancas (ver figura de abajo)
> y sus descripciones.
>
> ![Jerarquía de bloques de construcción](../images/05_building_blocks-ES.png)
>
> **Nivel 1** comprende la descripción de Caja Blanca del sistema en general junto con las descripciones de Caja Negra de
> todos los bloques contenidos.
>
> **Nivel 2** hace zoom a los bloques de construcción del Nivel 1. Entonces contiene la descripción de Caja Blanca de los
> bloques de construcción selecionadas del nivel 1,junto con las descripciones de caja negra de sus bloques de construcción
> internas.
>
> **Nivel 3** Hace zoom a los bloques selectos del nivel 2, y así sucesivamente.

### Sistema General de Caja Blanca

> Aquí se describe la descomposición del sistema en general usando la siguiente plantilla de caja blanca. Contiene:
>
> - Un diagrama general
> - La motivación para la descomposición
> - Descripciones de caja negra de los bloques de construcción contenidos. Para estos se ofrecen las siguientes
>   alternativas:
>   - Usar _una_ tabla para una revisión pragmática y corta de todos los bloques de construcción contenidos y sus
>     interfaces
>   - Usar una lista de descripciones de caja negra de los bloques de construcción acorde a la plantilla de caja negra (ver abajo). Dependiendo de la herramienta utilizada, esta lista podría constar de sub-capítulos (en archivos de texto),
>     sub-páginas (en un wiki) o elementos anidados (en una herramienta de modelado).
> - (opcional:) Interfases importantes, que no están explicadas en las plantillas de caja negra de un bloque de construcción,
>   pero que son muy importantes para entender la caja blanca. En el peor de los casos se deberá especificar y desribir la
>   sintaxis, semántica, protocolos, manejo de errores, restricciones, versiones, calidades, compatibilidades necesarias, entre
>   otras. En el mejor de los casos bastará con ejemplos o la firma de los mismos.

```mermaid
C4Container
    title MAPSUTB - Nivel 1 (Contenedores)
 
    Person(usuario, "Usuario del campus", "Aspirante, estudiante actual, estudiante de intercambio o invitado")
 
    System_Boundary(mapsutb, "MAPSUTB") {
        Container(app, "App móvil", "Flutter / Dart", "Interfaz, ruteo interno, tour panorámico y mapa base. Único artefacto desplegable")
        ContainerDb(plano, "Plano del campus", "Archivos empaquetados", "Grafo peatonal y geometría propia del campus, superpuesta sobre Maps SDK")
        ContainerDb(panoramas, "Contenido panorámico 360°", "Imágenes equirectangulares", "Capturas esféricas vía smartphone para el tour virtual")
        ContainerDb(datos, "Datos de zonas y puntos de interés", "JSON local", "Clasificación manual de zonas y coordenadas de puntos de interés")
    }
 
    System_Ext(mapsSdk, "Google Maps SDK", "Renderiza el mapa base sobre el que se superpone el plano propio")
    System_Ext(geocoding, "Google Geocoding API", "Convierte coordenadas y direcciones")
 
    Rel(usuario, app, "Explora, se ubica y traza rutas", "Pantalla táctil")
    Rel(app, plano, "Lee el grafo peatonal y la geometría del campus")
    Rel(app, panoramas, "Lee el contenido del tour")
    Rel(app, datos, "Consulta zonas y puntos de interés")
    Rel(app, mapsSdk, "Renderiza el mapa base", "HTTPS")
    Rel(app, geocoding, "Solicita geocodificación", "HTTPS")
```

**Motivación:**

MAPSUTB se separa en un único artefacto desplegable (la app móvil Flutter) y tres almacenes de datos empaquetados
localmente (plano del campus, contenido panorámico y datos de zonas/puntos de interés). No existe backend propio:
toda la información vive dentro del paquete de la app o se resuelve consultando directamente los servicios de Google
(Maps SDK y Geocoding API), lo que reduce la infraestructura a cargo del equipo pero introduce una dependencia fuerte
de la disponibilidad de estos servicios externos (ver [decisiones de diseño](#section-design-decisions) y
restricciones técnicas).

**Bloques de construcción contenidos:**

| **Nombre** | **Responsabilidad** |
|---|---|
| App móvil | Único artefacto desplegable. Contiene toda la lógica de interfaz, ubicación, ruteo interno, mapa base y tour panorámico. |
| Plano del campus | Empaqueta el grafo peatonal y la geometría propia del campus, usados para el ruteo interno y para superponerse sobre Maps SDK. |
| Contenido panorámico 360° | Empaqueta las imágenes equirectangulares capturadas vía smartphone para el módulo de tour virtual. |
| Datos de zonas y puntos de interés | Empaqueta el JSON con la clasificación manual de zonas (salones, laboratorios, oficinas) y sus coordenadas. |

**Interfases importantes:**

- **Google Maps SDK** (HTTPS): usada por la App móvil para renderizar el mapa base sobre el cual se dibuja el plano propio del campus.
- **Google Geocoding API** (HTTPS): usada por la App móvil para convertir coordenadas GPS en direcciones legibles y viceversa.

#### App móvil

_Propósito/Responsabilidad_

Único artefacto desplegable del sistema. Provee la interfaz de usuario (pantallas de tour, mapas/ruteo y zonas),
gestiona la ubicación en tiempo real del usuario, calcula rutas dentro del campus sobre el grafo peatonal propio,
renderiza el mapa base (Maps SDK) con el plano propio superpuesto, y muestra el tour panorámico 360°.

_Interfase(s)_

- Consume el sensor de ubicación del dispositivo.
- Consume Google Maps SDK (HTTPS) para el mapa base.
- Consume Google Geocoding API (HTTPS) para geocodificación.
- Lee los tres contenedores de datos empaquetados localmente (plano, panoramas, datos de zonas).

_(Opcional) Características de Calidad/Performance_

Requiere conexión a internet permanente; no funciona offline. No está restringida a la red wifi institucional ni al
perímetro del campus.

_(Opcional) Ubicación Archivo/Directorio_

Repositorio: `github.com/ISCOUTB/AS_202620_mapsutb`

_(Opcional) Requerimientos Satisfechos_

Geolocalización en tiempo real, trazado de rutas dentro del campus, clasificación de zonas, tour panorámico, interfaz
en inglés para estudiantes de intercambio.

_(Opcional) Riesgos/Problemas/Incidentes Abiertos_

Aún no se ha definido el motor/librería para mostrar panorámicas 360° en Flutter. La navegación en interiores queda
fuera del alcance inicial.

#### Plano del campus

_Propósito/Responsabilidad_

Almacena, empaquetado dentro de la app, el grafo peatonal (nodos y conexiones entre entradas, plazoletas y bloques)
y la geometría propia del campus, usados para el ruteo interno y para superponerse visualmente sobre el mapa base
de Maps SDK.

_Interfase(s)_

Expuesto a la App móvil a través de un repositorio (`MapaRepository`) que oculta el formato interno del archivo.

_(Opcional) Riesgos/Problemas/Incidentes Abiertos_

El levantamiento del grafo peatonal es manual y depende de que el equipo lo mantenga actualizado ante cambios físicos
del campus.

#### Contenido panorámico 360°

_Propósito/Responsabilidad_

Almacena las imágenes equirectangulares (capturas esféricas vía smartphone, tipo Google Street View App) usadas por
el módulo de tour virtual.

_Interfase(s)_

Expuesto a la App móvil a través de un repositorio (`TourRepository`).

_(Opcional) Riesgos/Problemas/Incidentes Abiertos_

El equipo no cuenta con cámaras 360° dedicadas; la calidad de la captura depende del smartphone usado. Aún no se ha
definido el motor/librería de renderizado 360° en Flutter.

#### Datos de zonas y puntos de interés

_Propósito/Responsabilidad_

Almacena la clasificación manual de zonas del campus (salones, laboratorios, oficinas, etc.) y las coordenadas de
sus puntos de interés.

_Interfase(s)_

Expuesto a la App móvil a través de un repositorio (`ZonaRepository` / `PuntoInteresRepository`).

_(Opcional) Riesgos/Problemas/Incidentes Abiertos_

La clasificación es cargada manualmente por el equipo; no se actualiza dinámicamente ni la mantiene la universidad.

#### Google Maps SDK

_Propósito/Responsabilidad_

Servicio externo de Google que renderiza el mapa base (con coordenadas GPS reales) sobre el cual la App móvil
superpone el plano propio del campus.

_Interfase(s)_

HTTPS / SDK nativo de Google Maps.

_(Opcional) Riesgos/Problemas/Incidentes Abiertos_

Dependencia fuerte de la disponibilidad del servicio de Google; sujeto a límites de cuota/costo según uso.

#### Google Geocoding API

_Propósito/Responsabilidad_

Servicio externo de Google que convierte coordenadas GPS en direcciones legibles y viceversa.

_Interfase(s)_

HTTPS / REST.

_(Opcional) Riesgos/Problemas/Incidentes Abiertos_

Dependencia fuerte de la disponibilidad del servicio de Google; sujeto a límites de cuota/costo según uso.

### Nivel 2

> Aquí se especifica la estructura interna de (algunos) bloques de construcción del nivel 1 como cajas blancas.
>
> Debe decidir cuales bloques de construcción del sistema son lo suficientemente importantes para justificar una
> descripción detallada. Prefiera la relevancia sobre la completitud. Especifique bloques de construcción importantes,
> sorprendentes, riesgosos, complejos o volátiles. Deje fuera las partes normales, simples, estándares o aburridas del sistema.

#### Caja Blanca App móvil

> ...Describe la estructura interna de _bloque de construcción 1_.

Se detalla la App móvil por ser el único artefacto desplegable del sistema y el que concentra toda la lógica de
negocio. Los demás bloques del Nivel 1 (plano del campus, contenido panorámico, datos de zonas) son simples
almacenes de datos empaquetados sin lógica propia, por lo que no se detallan en un nivel adicional.

```mermaid
C4Component
    title MAPSUTB - Nivel 2 (Componentes de la App móvil)
 
    Person(usuario, "Usuario del campus", "Explora, se ubica y traza rutas dentro del campus")
 
    Container_Boundary(app, "App móvil (Flutter)") {
        Component(ui, "Pantallas de features", "Widgets Flutter", "tour, mapas_ruteo, zonas")
        Component(ubicacion, "Servicio de ubicación", "Observer - Stream<Ubicacion>", "Emite la posición en tiempo real a quien se suscriba")
        Component(widget, "MapaWidget", "Adapter", "Renderiza Maps SDK como mapa base y superpone el plano propio y las rutas")
        Component(ruteo, "Servicio de ruteo", "Dijkstra sobre grafo propio", "Calcula la ruta más corta dentro del campus")
        Component(mapaRepo, "MapaRepository", "Repository", "Sirve el grafo peatonal y la geometría del plano propio sin exponer su formato")
        Component(zonaRepo, "ZonaRepository / PuntoInteresRepository", "Repository", "Clasificación manual de zonas y puntos de interés")
        Component(tourRepo, "TourRepository", "Repository", "Sirve el contenido panorámico 360° del tour")
        Component(geocodingAdap, "GeocodingAdapter", "Adapter", "Implementa el puerto de geocodificación; aísla la API de Google")
    }
 
    ContainerDb(datos, "Datos de zonas y puntos de interés", "JSON local", "Clasificación manual")
    ContainerDb(plano, "Plano del campus", "Archivos empaquetados", "Grafo peatonal y geometría propia")
    ContainerDb(panoramas, "Contenido panorámico 360°", "Imágenes equirectangulares", "Capturas esféricas propias")
    System_Ext(mapssdk, "Google Maps SDK", "Mapa base")
    System_Ext(geocoding, "Google Geocoding API", "Coordenadas y direcciones")
    System_Ext(sensor, "Sensor de ubicación del dispositivo", "Capacidad de la plataforma")
 
    Rel(usuario, ui, "Interactúa")
 
    Rel(ui, ubicacion, "Se suscribe al stream")
    Rel(ui, ruteo, "Solicita una ruta dentro del campus")
    Rel(ui, zonaRepo, "Consulta zonas y puntos de interés")
    Rel(ui, widget, "Muestra el mapa base con capas propias")
    Rel(ui, geocodingAdap, "Solicita geocodificación")
    Rel(ui, tourRepo, "Solicita panorámicas del tour")
 
    Rel(ubicacion, sensor, "Escucha cambios de posición")
 
    Rel(ruteo, mapaRepo, "Lee el grafo peatonal")
    Rel(widget, mapaRepo, "Lee la geometría del plano propio")
    Rel(widget, mapssdk, "Renderiza el mapa base", "HTTPS")
    Rel(geocodingAdap, geocoding, "Solicita geocodificación", "HTTPS")
 
    Rel(mapaRepo, plano, "Lee")
    Rel(zonaRepo, datos, "Lee")
    Rel(tourRepo, panoramas, "Lee")
```

- **Pantallas de features** (Widgets Flutter): agrupa las pantallas de tour, mapas/ruteo y zonas; es el único punto de
  entrada de la interacción del usuario.
- **Servicio de ubicación** (patrón Observer, `Stream<Ubicacion>`): escucha el sensor de ubicación del dispositivo y
  emite la posición en tiempo real a quien se suscriba.
- **MapaWidget** (patrón Adapter): renderiza Google Maps SDK como mapa base y superpone sobre él el plano propio del
  campus y las rutas calculadas.
- **Servicio de ruteo** (Dijkstra sobre grafo propio): calcula la ruta más corta dentro del campus a partir del grafo
  peatonal; no depende de ningún servicio externo.
- **MapaRepository** (patrón Repository): sirve el grafo peatonal y la geometría del plano propio sin exponer su
  formato de archivo.
- **ZonaRepository / PuntoInteresRepository** (patrón Repository): sirve la clasificación manual de zonas y puntos de
  interés desde el JSON local.
- **TourRepository** (patrón Repository): sirve el contenido panorámico 360° al módulo de tour.
- **GeocodingAdapter** (patrón Adapter): implementa el puerto de geocodificación y aísla al resto de la app del SDK de
  Google Geocoding.

### Nivel 3

> Aqui se especifica la estructura interna de (algunos) de los bloques de construcción del nivel 2 como cajas blancas.
>
> Cuando la arquitectura requiera más niveles detallados copiar esta sección para niveles adicionales.

No se documenta un Nivel 3. Los componentes descritos en el Nivel 2 (pantallas, servicios, repositorios y adaptadores)
son lo suficientemente simples y de bajo riesgo como para no justificar una descomposición interna adicional; su
implementación se resuelve a nivel de clases dentro de cada componente sin complejidad arquitectónica relevante.