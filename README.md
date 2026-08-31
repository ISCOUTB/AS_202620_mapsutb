# MAPSUTB — esqueleto de arquitectura

Mapa Interactivo de Ubicación con Recorrido panorámico 360° — UTB.
Este repositorio contiene el **esqueleto ejecutable** de la arquitectura
decidida para el proyecto. No incluye lógica de negocio: su objetivo es
que el equipo pueda empezar la semana 4 construyendo sobre una
arquitectura ya montada, en lugar de perder tiempo armando el proyecto.

## Arquitectura y diseño

El patrón arquitectural es **monolito** (una sola app Flutter, sin
backend propio por ahora). El mapa del campus se resuelve superponiendo
un plano propio (grafo peatonal y geometría del campus, empaquetados
localmente) sobre **Google Maps SDK**, que renderiza el mapa base; el
ruteo interno se calcula con **Dijkstra sobre el grafo peatonal propio**,
sin depender de un servicio externo de ruteo. Por eso las dependencias
externas del sistema son dos APIs de Google: **Maps SDK** (mapa base) y
**Geocoding API** (conversión de coordenadas a direcciones y viceversa),
ambas consumidas vía HTTPS — la app requiere conexión a internet para
funcionar. Dentro de ese monolito se adoptan tres patrones de diseño,
cada uno para un problema puntual: **Repository** (servir el plano del
campus, los datos de zonas/puntos de interés y el contenido panorámico
local), **Adapter** (aislar Google Maps SDK y Google Geocoding API) y
**Observer** (ubicación en tiempo real vía `Stream`). El razonamiento
completo, la matriz comparativa por problema y las consecuencias de cada
decisión están en:

- [`docs/arc42.md`](./docs/Arc42/04_solution_strategy.adoc) — sección 4, "Estrategia de solución"
- [`docs/adr/0001-patrones-de-diseno.md`](./docs/adr/0001-patrones-de-diseno.md)
## Estructura del proyecto

```
lib/
  adapters/            # Adapter: MapaWidget (Google Maps SDK) y GeocodingAdapter (Geocoding API)
  repositories/         # Repository: plano del campus, datos de zonas/puntos de interés, contenido panorámico
  routing/                # Servicio de ruteo: Dijkstra sobre el grafo peatonal propio
  services/               # Observer: servicios que exponen Stream (p. ej. ubicación en tiempo real)
  features/
    tour/                  # UI y casos de uso del tour panorámico
    mapas_ruteo/            # UI y casos de uso de mapas y ruteo
    zonas/                     # UI y casos de uso de clasificación de zonas
  core/                # utilidades compartidas transversales
test/
  app_smoke_test.dart  # prueba de arranque del esqueleto
docs/
  adr/                #patrones de diseño
  Arc42/                # Modelo ARC42 de documentación
  C4/                  #descripción de la arquitectura
  
```
 
Las carpetas `adapters/`, `repositories/`, `routing/`, `services/` y
cada subcarpeta de `features/` están vacías a propósito (solo contienen
un `.gitkeep`): son el molde que impone el ADR 0001, listo para que cada
integrante del equipo empiece a llenar su parte sin decidir estructura de
nuevo.

## Requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (canal
  estable) instalado y en el `PATH`.
- Un dispositivo, emulador o navegador configurado para `flutter run`
  (para solo compilar y correr las pruebas no hace falta dispositivo).
- Conexión a internet y una API key válida de Google Maps SDK / Geocoding
  API (el mapa base y la geocodificación no funcionan sin ella).
## Arranque con un solo comando

```bash
./scripts/start.sh
```

Este script hace, en orden: `flutter pub get`, `flutter test` y
`flutter run`. Si solo se quiere verificar que el esqueleto compila y la
prueba pasa en verde, sin levantar la app:

```bash
flutter pub get && flutter test
```

## Estado actual

- Arranca con un solo comando.
- Una prueba automatizada en verde (`test/app_smoke_test.dart`).
- Paquetes vacíos según el estilo del ADR 0001.
- Sin lógica de negocio todavía
