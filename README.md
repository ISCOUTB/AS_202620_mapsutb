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

- [`docs/arc42/04_solution_strategy.adoc`](./docs/arc42/04_solution_strategy.adoc) — sección 4, "Estrategia de solución"
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
  arc42/                # Modelo ARC42 de documentación
  C4/                  #descripción de la arquitectura
  
```
 
El molde de carpetas lo impone el ADR 0001. Sobre él ya hay código real:
`adapters/` (`GeocodingAdapter`, `StaticMapAdapter`, `AnalyticsAdapter`),
`repositories/` (`ZonaRepository`), `services/` (`UbicacionService`) y las
primeras pantallas en `features/`. `routing/` y las carpetas de tour siguen
como molde (solo `.gitkeep`), pendientes para el corte 2.

## Requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (canal
  estable) instalado y en el `PATH`.
- Un dispositivo, emulador o navegador configurado para `flutter run`
  (para solo compilar y correr las pruebas no hace falta dispositivo).
- Conexión a internet y una API key válida de Google Maps SDK / Geocoding
  API (el mapa base y la geocodificación no funcionan sin ella; ver
  "Credenciales de APIs externas" más abajo).
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

Los valores de `--dart-define` quedan embebidos en el binario. La API key
de Google debe restringirse por paquete/huella en Google Cloud Console.
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

Revertir a la versión anterior: *Firebase console → Hosting → historial de
versiones → Revertir* (no hace falta recompilar).

### Recrear el entorno en el servidor del laboratorio (Docker)

```bash
cp .env.example .env          # opcional: credenciales
docker compose --env-file .env -f infra/docker-compose.yml up --build
curl http://localhost:8080/health
docker compose -f infra/docker-compose.yml logs web   # logs JSON de nginx
```

### Observabilidad

- **Logs estructurados:** una línea JSON por evento desde
  [`lib/core/log.dart`](./lib/core/log.dart) (consola del navegador o
  `adb logcat`) y desde nginx en Docker ([arc42 §8](./docs/arc42/08_concepts.adoc)).
- **Métrica:** disponibilidad y p95 del health check, medidos cada hora por
  [`sonda-disponibilidad.yml`](./.github/workflows/sonda-disponibilidad.yml)
  ([ADR 0008](./docs/adr/0008-metrica-disponibilidad-sonda-actions.md)) y
  ligados al Escenario 6 de [`docs/escenarios_calidad.md`](./docs/escenarios_calidad.md).

## Estado actual

- Arranca con un solo comando.
- Integración con APIs externas por HTTP con contrato ejecutable
  ([`docs/api/apis-externas.openapi.yaml`](./docs/api/apis-externas.openapi.yaml))
  e implementación en `lib/adapters/` (Geocoding, Static Maps, Analytics).
- Catálogo de lugares (`ZonaRepository`) y posicionamiento
  (`UbicacionService`) implementados en primera versión.
- Pruebas automatizadas en verde: arranque (`test/app_smoke_test.dart`) y
  tres pruebas de contrato (`test/*_contract_test.dart`), ejecutadas por el
  pipeline de CI ([`.github/workflows/ci.yml`](./.github/workflows/ci.yml))
  junto con `flutter analyze` y el análisis estático de SonarCloud.
- Desplegado como sitio web en Firebase Hosting, con health check, logs
  estructurados, métrica de disponibilidad y secretos fuera del código (S8).
- Ruteo (Dijkstra) y tour panorámico 360° pendientes para el corte 2.
- Las 11 zonas de `assets/data/zonas.json` aún no tienen coordenadas reales
  (están en 0,0).
