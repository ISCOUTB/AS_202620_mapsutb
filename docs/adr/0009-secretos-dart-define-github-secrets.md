# ADR 0009 — Credenciales de APIs externas: secrets del repositorio inyectados con `--dart-define`

## Estado

- **Estado**: Aceptado
- **Fecha**: 2026-09-25
- **Decisores**: Equipo MAPSUTB

## Contexto

Los adaptadores de ADR 0005 necesitan credenciales: `GOOGLE_MAPS_API_KEY` (Geocoding y Static
Maps) y `GA_MEASUREMENT_ID` + `GA_API_SECRET` (Measurement Protocol). S8 exige que los secretos
estén **fuera del código**, declarados, y que el despliegue los tome de un almacén de secretos o de
la configuración del proveedor. Hasta S7 las credenciales llegaban por constructor sin un origen
definido.

Una app cliente (móvil o web) no puede guardar un secreto de verdad: todo lo que se compila dentro
queda extraíble del binario o del JavaScript.

## Decisión

1. Las credenciales se leen en tiempo de compilación con `String.fromEnvironment`
   ([`lib/core/config_apis.dart`](../../lib/core/config_apis.dart)); ningún valor se versiona.
2. **Desarrollo local:** `.env` (en `.gitignore`) a partir de [`.env.example`](../../.env.example),
   usado con `flutter run --dart-define-from-file=.env` (`scripts/start.sh` lo hace solo si existe).
3. **Despliegue:** secrets del repositorio en GitHub Actions (`secrets.GOOGLE_MAPS_API_KEY`,
   `secrets.GA_MEASUREMENT_ID`, `secrets.GA_API_SECRET`), pasados al build en
   [`deploy.yml`](../../.github/workflows/deploy.yml). La credencial para publicar en Firebase
   Hosting es una cuenta de servicio de Google Cloud con rol de administrador de Hosting, guardada
   como `secrets.FIREBASE_SERVICE_ACCOUNT` (JSON completo); el Project ID no es secreto y va como
   variable del repositorio (`vars.FIREBASE_PROJECT_ID`). `GA_MEASUREMENT_ID` / `GA_API_SECRET`
   salen del flujo de datos web de Google Analytics vinculado al mismo proyecto de Firebase.
   En Docker, por `--env-file .env` como build-args (`infra/docker-compose.yml`).
4. Si una credencial falta, la función que depende de ella se oculta; la app no falla al arrancar.
5. Cada key se **restringe en el proveedor**: la de Google por referrer HTTP
   (`mapsutb.web.app/*`) o por paquete/huella de la app, y con cuota diaria por API
   (ver `docs/costos.md`).

Hoy el despliegue público corre **sin** la key de Google: Google Maps Platform exige facturación
con tarjeta, lo que choca con la restricción de arc42 §2.

## Alternativas consideradas

### A. Secrets del repositorio + `--dart-define` (elegida)

- **A favor:** el valor vive solo en el almacén de GitHub y en el `.env` local de cada integrante;
  no requiere backend; es el mecanismo estándar de Flutter.
- **En contra:** la key queda embebida en el build publicado. Se mitiga restringiéndola en el
  proveedor; es el mismo modelo que usa cualquier app con Maps SDK.

### B. Proxy propio (backend) que guarde las keys (descartada por ahora)

- **Motivo técnico del descarte:** es la única forma de que la key no salga nunca al cliente y
  resolvería CORS en web, pero introduce una pieza de servidor que contradice ADR 0004 (monolito
  sin backend) y otra plataforma que operar, desplegar y vigilar, sin que hoy haya una key activa
  que proteger (el despliegue corre sin facturación de Google). Se reevalúa si se activa la key de
  Google en web o si el `api_secret` de Analytics empieza a recibir eventos falsos.

### C. Archivo de configuración versionado (descartada)

- **Motivo técnico del descarte:** deja la credencial en el historial de git, visible en un
  repositorio público e irrecuperable aunque se borre después. Incumple el contrato del curso.

## Consecuencias

- `.env.example` documenta qué variables existen sin exponer valores.
- Rotar una key es cambiar el secret y re-ejecutar `deploy.yml`; no hay commit de por medio.
- Riesgo aceptado: con el `api_secret` embebido, un tercero podría enviar eventos falsos a GA4
  (solo escritura, no lectura de datos).
