# MAPSUTB

Mapa interactivo de ubicación del campus de la UTB. App Flutter publicada
como sitio web en https://mapsutb.web.app/: muestra las zonas del campus
sobre un mapa, ubica al usuario con el GPS y traza la ruta a pie hasta la
entrada de la zona elegida. El recorrido panorámico 360° de la propuesta
inicial está diferido (no implementado). Estado detallado al final, en
"Estado actual".

## Arquitectura y diseño

El patrón arquitectural es **monolito** (una sola app Flutter, sin
backend propio por ahora). El mapa del campus se resuelve superponiendo
un plano propio (grafo peatonal y geometría del campus, empaquetados
localmente) sobre **teselas de OpenStreetMap** dibujadas con `flutter_map`
([ADR 0012](./docs/adr/0012-mapa-base-flutter-map-osm.md)), que forman el mapa base; el
ruteo interno se calcula con **Dijkstra sobre el grafo peatonal propio**,
sin depender de un servicio externo de ruteo
([ADR 0013](./docs/adr/0013-ruteo-dijkstra-grafo-propio.md)). La única
dependencia externa obligatoria son las teselas de OpenStreetMap; una vez
cargada la app, la ruta y las zonas funcionan sin red. Google Geocoding
API y Static Maps API son opcionales y en producción están apagadas por
falta de key ([ADR 0009](./docs/adr/0009-secretos-dart-define-github-secrets.md)).
Dentro de ese monolito se adoptan tres patrones de diseño,
cada uno para un problema puntual: **Repository** (servir el plano del
campus y los datos de zonas/puntos de interés), **Adapter** (aislar el
mapa base, Google Geocoding API, Static Maps API y el Measurement
Protocol) y **Observer** (ubicación en tiempo real vía `Stream`). El razonamiento
completo, la matriz comparativa por problema y las consecuencias de cada
decisión están en:

- [`docs/arc42/04_solution_strategy.adoc`](./docs/arc42/04_solution_strategy.adoc) — sección 4, "Estrategia de solución"
- [`docs/adr/0001-patrones-de-diseno.md`](./docs/adr/0001-patrones-de-diseno.md)
## Estructura del proyecto

```
lib/
  adapters/            # Adapter: MapaWidget (flutter_map + OSM), GeocodingAdapter, StaticMapAdapter, AnalyticsAdapter
  repositories/        # Repository: ZonaRepository (zonas y puntos de interés)
  routing/             # Grafo peatonal, MapaRepository y ServicioRuteo (Dijkstra)
  services/            # Observer: UbicacionService (GPS real con geolocator y FiltroUbicacion)
  features/
    mapas_ruteo/       # pantallas de mapa/ruta y "¿Dónde estoy?"
    zonas/             # pantallas de zonas y detalle de zona
  core/                # configuración de APIs y logs estructurados
assets/data/           # zonas.json y grafo.json (empaquetados en la app)
test/                  # 12 archivos de prueba (unidad, widgets, contrato y modos de fallo)
docs/
  adr/                 # decisiones de arquitectura (0001 a 0017)
  arc42/               # documentación arc42
  c4/                  # diagramas C4 (contexto, contenedores, componentes)
```

El molde de carpetas lo impone el ADR 0001. No hay carpeta `features/tour/`:
el tour panorámico 360° está diferido.

## Requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (canal
  estable) instalado y en el `PATH`.
- Chrome u otro navegador para `flutter run -d chrome` (la compilación
  para Android/iOS no está configurada; para solo correr las pruebas no
  hace falta navegador).
- Conexión a internet para las teselas del mapa base (OpenStreetMap, sin key).
  La geocodificación y las miniaturas de Google son opcionales y requieren
  key (ver "Credenciales de APIs externas" más abajo).
## Arranque con un solo comando

```bash
./scripts/start.sh
```

Este script hace, en orden: `flutter pub get`, `flutter test` y
`flutter run`. Si solo se quiere verificar que la app compila y las
pruebas pasan en verde, sin levantar la app:

```bash
flutter pub get && flutter test
```

### Ubicación

La app usa el GPS del dispositivo (`geolocator`, [ADR 0017](./docs/adr/0017-gps-real-geolocator-filtro.md));
en el navegador pide permiso de ubicación. Si no hay GPS o se está fuera del campus, en la pestaña
Mapa se toca el mapa para marcar el punto de partida. Para una demostración con una posición fija
del campus:

```bash
flutter run -d chrome --dart-define=UBICACION_SIMULADA=true
```

### Credenciales de APIs externas

Las credenciales se pasan en tiempo de compilación con `--dart-define`
(ver `lib/core/config_apis.dart`); nunca se versionan en el repositorio:

```bash
flutter run \
  --dart-define=GOOGLE_MAPS_API_KEY=... \
  --dart-define=GA_MEASUREMENT_ID=G-... \
  --dart-define=GA_API_SECRET=...
```

Sin ellas la app arranca igual y solo oculta lo que depende de cada API:
el botón "¿Dónde estoy?" (Geocoding), la miniatura de la zona (Static
Maps) y el envío de eventos de uso (Measurement Protocol).

Los valores de `--dart-define` quedan embebidos en el JavaScript publicado.
Como la app solo se publica en web, la API key de Google debe restringirse
por referente HTTP (`https://mapsutb.web.app/*`) y por API en Google Cloud
Console.
El `api_secret` del Measurement Protocol solo permite enviar eventos, así
que el riesgo es que alguien inyecte eventos falsos; si eso importa, el
envío debe moverse a un backend propio.

## Despliegue (entorno público)

| | |
|---|---|
| URL del sistema | https://mapsutb.web.app/ |
| Health check | https://mapsutb.web.app/health.json → `200` con `{"status":"ok","commit":…}` |
| Métrica (Escenario 6) | https://raw.githubusercontent.com/ISCOUTB/AS_202620_mapsutb/metricas/resumen.json |
| Análisis estático | https://sonarcloud.io/summary/new_code?id=ISCOUTB_AS_202620_mapsutb |
| Costo mensual | USD 0 hoy; cálculo y punto de ruptura en [`docs/costos.md`](./docs/costos.md) |

El arranque local de arriba **no** es el despliegue. El entorno público es la
app compilada a web y alojada en Firebase Hosting, plan Spark
([ADR 0007](./docs/adr/0007-hosting-web-firebase-hosting.md)), definido como
código en [`.github/workflows/deploy.yml`](./.github/workflows/deploy.yml) y
[`firebase.json`](./firebase.json): en cada push a `master` compila, prueba,
genera `health.json`, publica y verifica que el health responde 200 con el
commit desplegado. Detalle de cada pieza y dónde se ejecuta:
[arc42 §7](./docs/arc42/07_deployment_view.adoc).

### Recrear el entorno público desde cero

1. En [console.firebase.google.com](https://console.firebase.google.com),
   crear un proyecto (plan Spark, sin método de pago) y activar Hosting.
2. En Google Cloud Console → *IAM → Cuentas de servicio* del mismo proyecto,
   crear una cuenta con el rol **Administrador de Firebase Hosting** y
   descargar su clave JSON.
3. En *Settings → Secrets and variables → Actions* del repositorio:
   - secret `FIREBASE_SERVICE_ACCOUNT` = contenido completo del JSON;
   - variable `FIREBASE_PROJECT_ID` = el Project ID;
   - (opcional) los secrets de [`.env.example`](./.env.example)
     ([ADR 0009](./docs/adr/0009-secretos-dart-define-github-secrets.md)).
     Sin ellos la app se publica igual, sin Geocoding ni Static Maps.
4. *Actions → Despliegue web (Firebase Hosting) → Run workflow* sobre `master`.
5. Comprobar:
   ```bash
   curl -sS -o /dev/null -w 'http=%{http_code} tiempo=%{time_total}s\n' https://mapsutb.web.app/
   curl -sS https://mapsutb.web.app/health.json
   ```

Revertir a la versión anterior sin recompilar: *Actions → Reversión medida
(Firebase Hosting)*, o *Firebase console → Hosting → historial de versiones →
Revertir*. Procedimiento completo y mediciones en
[`docs/taller-despliegue.md`](./docs/taller-despliegue.md) (taller de despliegue,
[ADR 0010](./docs/adr/0010-reversion-sitio-web.md)).

### Recrear el entorno en el servidor del laboratorio (Docker)

```bash
cp .env.example .env          # opcional: credenciales
docker compose --env-file .env -f infra/docker-compose.yml up --build
curl http://localhost:8080/health
docker compose -f infra/docker-compose.yml logs web   # logs JSON de nginx
```

### Observabilidad

- **Logs estructurados:** una línea JSON por evento desde
  [`lib/core/log.dart`](./lib/core/log.dart) (consola del navegador; no
  hay build móvil, así que `adb logcat` no aplica) y desde nginx en Docker
  ([arc42 §8](./docs/arc42/08_concepts.adoc)).
- **Métrica:** disponibilidad y p95 del health check, medidos cada hora por
  [`sonda-disponibilidad.yml`](./.github/workflows/sonda-disponibilidad.yml)
  ([ADR 0008](./docs/adr/0008-metrica-disponibilidad-sonda-actions.md)) y
  ligados al Escenario 6 de [`docs/escenarios_calidad.md`](./docs/escenarios_calidad.md).

## Herramientas de campo

Fuentes, herramientas y procedimiento del levantamiento del campus:
[`docs/levantamiento-campo.md`](./docs/levantamiento-campo.md)
([ADR 0011](./docs/adr/0011-fuente-datos-geograficos-osm.md)).

- **Registro de coordenadas:** https://mapsutb.web.app/herramientas/coordenadas.html
  (`web/herramientas/coordenadas.html`). Página para el celular que guarda
  puntos GPS del campus (entradas de cada zona, cruces, escaleras, rampas,
  puertas) con su precisión y hora UTC, promediando varias lecturas, y los
  exporta a GeoJSON o CSV. Sirve para levantar el grafo peatonal y cruzarlo
  con los videos del recorrido y el trazado de OpenStreetMap. Los datos
  quedan solo en el celular hasta que se exportan.

- **Grabar recorrido:** https://mapsutb.web.app/herramientas/recorrido.html
  (`web/herramientas/recorrido.html`). Graba el recorrido continuo con hora
  UTC, coordenadas, altitud del GPS (si el celular la entrega), precisión y
  el contexto declarado (zona → piso → espacio de `zonas.json`), registra
  puntos y tiene un cronómetro con pantalla de sincronización: al mirarla
  con las gafas y tocar "Marcar SYNC", el destello y la hora quedan en el
  video y en el registro. Exporta GPX, GeoJSON y JSON completo. La altitud
  del GPS no distingue pisos (error vertical de ±10–30 m); el piso sale del
  contexto declarado.

## Estado actual

Implementado:

- **Mapa y ruta** (A-01): zonas sobre teselas de OpenStreetMap con
  `flutter_map` ([ADR 0012](./docs/adr/0012-mapa-base-flutter-map-osm.md)) y
  ruta a pie con Dijkstra sobre `assets/data/grafo.json`
  ([ADR 0013](./docs/adr/0013-ruteo-dijkstra-grafo-propio.md)); opción de
  evitar escaleras. Cálculo de ruta: p95 0,68 ms en CI.
- **Posición** (A-01): GPS real con `geolocator`, filtrado por
  `FiltroUbicacion`; sin GPS o fuera del campus, el usuario marca la
  partida tocando el mapa ([ADR 0017](./docs/adr/0017-gps-real-geolocator-filtro.md)).
- **Catálogo de zonas** (A-03): 11 zonas con pisos, espacios y salones;
  10 tienen coordenadas medidas en campo (falta Contenedores, que no
  aparece en el mapa hasta tenerla).
- **Integraciones HTTP** (A-02): Geocoding, Static Maps y Measurement
  Protocol con contrato ejecutable
  ([`docs/api/apis-externas.openapi.yaml`](./docs/api/apis-externas.openapi.yaml)),
  tiempo límite de 5 s y modos de fallo MF-01 a MF-15
  ([arc42 §11](./docs/arc42/11_technical_risks.adoc)). En producción,
  Geocoding y Static Maps están apagados por falta de key.
- **Pruebas:** 12 archivos con 84 pruebas en `test/`, ejecutadas por el
  pipeline de CI ([`.github/workflows/ci.yml`](./.github/workflows/ci.yml))
  junto con `flutter analyze`, cobertura y el Quality Gate de SonarCloud.
- **Despliegue:** sitio web en Firebase Hosting con health check, logs
  estructurados, métrica de disponibilidad, reversión medida y secretos
  fuera del código.

No implementado:

- Tour panorámico 360° (A-04): diferido; no hay código ni panorámicas.
- Interfaz en inglés: solo español.
- Versión móvil nativa: la compilación para Android/iOS no está
  configurada (faltan los permisos de ubicación); en el celular se usa el
  sitio web.
- Navegación en interiores: fuera de alcance; la ruta termina en la
  entrada del edificio.
- Pendiente de medir: el margen de 10 m del Escenario 2 con la app y el GPS
  real en el campus (RT-08).
