# MAPSUTB — esqueleto de arquitectura

Mapa Interactivo de Ubicación con Realidad Aumentada — UTB.
Este repositorio contiene el **esqueleto ejecutable** de la arquitectura
decidida para el proyecto. No incluye lógica de negocio: su objetivo es
que el equipo pueda empezar la semana 4 construyendo sobre una
arquitectura ya montada, en lugar de perder tiempo armando el proyecto.

## Arquitectura y diseño

El patrón arquitectural es **monolito** (una sola app Flutter, sin
backend propio por ahora). El mapa del campus se aloja **de forma
local** (activos propios del proyecto) y el ruteo **no busca ser
exacto**; por eso la única dependencia externa que queda es **ARCore
Geospatial API** (para anclar la RA a coordenadas GPS reales). Dentro de
ese monolito se adoptan cuatro patrones de diseño, cada uno para un
problema puntual: **Adapter** (aislar ARCore), **Repository** (servir el
mapa local y los datos de zonas/puntos de interés), **Strategy** (ruteo
aproximado dentro del mapa local) y **Observer** (ubicación en tiempo
real vía `Stream`). El razonamiento completo, la matriz comparativa por
problema y las consecuencias de cada decisión están en:

- [`docs/arc42.md`](./docs/arc42.md) — sección 4, "Estrategia de solución"
- [`docs/adr/0001-patrones-de-diseno.md`](./docs/adr/0001-patrones-de-diseno.md)

## Estructura del proyecto

```
lib/
  adapters/            # Adapter: ARCore Geospatial API (única dependencia externa)
  repositories/         # Repository: mapa local del campus + datos de zonas y puntos de interés
  strategies/            # Strategy: algoritmos de ruteo aproximado sobre el mapa local
  services/               # Observer: servicios que exponen Stream (p. ej. ubicación en tiempo real)
  features/
    tour/                  # UI y casos de uso del tour panorámico
    mapas_ruteo/            # UI y casos de uso de mapas y ruteo aproximado
    realidad_aumentada/      # UI y casos de uso de RA
    zonas/                     # UI y casos de uso de clasificación de zonas
  core/                # utilidades compartidas transversales
test/
  app_smoke_test.dart  # prueba de arranque del esqueleto
docs/
  arc42.md
  adr/0001-patrones-de-diseno.md
```

Las carpetas `adapters/`, `repositories/`, `strategies/`, `services/` y
cada subcarpeta de `features/` están vacías a propósito (solo contienen
un `.gitkeep`): son el molde que impone el ADR 0001, listo para que cada
integrante del equipo empiece a llenar su parte sin decidir estructura de
nuevo.

## Requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (canal
  estable) instalado y en el `PATH`.
- Un dispositivo, emulador o navegador configurado para `flutter run`
  (para solo compilar y correr las pruebas no hace falta dispositivo).

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

- ✅ Arranca con un solo comando.
- ✅ Una prueba automatizada en verde (`test/app_smoke_test.dart`).
- ✅ Paquetes vacíos según el estilo del ADR 0001.
- ⛔ Sin lógica de negocio todavía — a propósito, queda para la semana 4.
