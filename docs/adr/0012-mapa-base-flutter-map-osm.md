# ADR 0012 — Mapa base con flutter_map y teselas de OpenStreetMap

## Estado

- **Estado**: Aceptado
- **Fecha**: 2026-10-01
- **Decisores**: Equipo MAPSUTB
- **Reemplaza**: la elección de Google Maps SDK como mapa base de los ADR 0001 y 0002 (el resto de
  esos ADR sigue vigente: Adapter, Repository y Observer)

## Contexto

Los ADR 0001 y 0002 eligieron Google Maps SDK como mapa base, aislado con un Adapter
(`MapaWidget`). Desde entonces cambiaron tres cosas:

1. **Restricción de costo:** Google Maps Platform exige una cuenta de facturación con tarjeta,
   aun para la capa gratuita, y el proyecto no puede usar tarjeta (arc42 §2, ADR 0009).
2. **El sistema se publica en web** (ADR 0007): en web, la key quedaría visible en el JavaScript.
3. **Los datos del campus están en OpenStreetMap** (ADR 0011): el grafo y los edificios se
   trazaron ahí, y dibujarlos sobre un mapa base de otra fuente produce desajustes.

## Decisión

El mapa base de la app será **`flutter_map`** (paquete de Flutter) con **teselas de
OpenStreetMap**, y sobre él se dibujarán los edificios, el grafo y las rutas
(`ServicioRuteo`, ADR 0013). `MapaWidget` sigue siendo el Adapter que aísla al resto de la app
del proveedor del mapa.

Condiciones de uso de las teselas: atribución visible “© colaboradores de OpenStreetMap” y
respeto de la [política de uso de teselas](https://operations.osmfoundation.org/policies/tiles/)
(identificar la app con su `User-Agent`, sin descargas masivas). Si el tráfico crece, se cambia
de servidor de teselas sin tocar el resto de la app.

## Alternativas consideradas

### A. flutter_map + OpenStreetMap (elegida)

- **A favor:** sin tarjeta ni key; funciona igual en Android, iOS y web; el mapa base y los datos
  propios vienen de la misma fuente, así que coinciden.
- **En contra:** el servidor público de teselas de OSM es para volumen bajo; con volumen alto hay
  que usar otro proveedor o uno propio.

### B. Google Maps SDK (descartada)

- **Motivo:** exige facturación con tarjeta (incumple arc42 §2) y en web expone la key.

### C. Plano propio sin mapa base (descartada)

- **Motivo:** obligaría a dibujar a mano calles, vegetación y referencias que ya existen en OSM, y
  el usuario perdería contexto fuera de los edificios.

## Consecuencias

- Pantalla de mapa construida el 2026-10-01 (`lib/adapters/mapa_widget.dart`,
  `lib/features/mapas_ruteo/presentation/screens/mapa_screen.dart`). Dependencias agregadas y
  verificadas en pub.dev: `flutter_map` 8.3.2 (publicador verificado `fleaflet.dev`, repositorio
  `github.com/fleaflet/flutter_map`) y `latlong2` 0.10.1 (publicador `femtopedia.de`, repositorio
  `github.com/ThexXTURBOXx/dart-latlong`). Ningún tipo de esos paquetes sale de `MapaWidget`.
- Static Maps y Geocoding (ADR 0005) dejan de ser necesarios para el mapa; se reevalúan cuando
  se construya la pantalla.
- La atribución a OpenStreetMap debe verse en la pantalla del mapa.
