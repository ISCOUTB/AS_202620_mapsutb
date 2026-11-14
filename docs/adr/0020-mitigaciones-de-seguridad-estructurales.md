# ADR 0020 — Mitigaciones de seguridad que cambian cómo se construye y publica el sistema

## Estado

- **Estado**: Aceptado
- **Fecha**: 2026-11-11
- **Decisores**: Equipo MAPSUTB
- **Relación**: sale del [modelo de amenazas](../modelo-amenazas.md) (S13, entregado tarde).
  Complementa el [ADR 0007](./0007-hosting-web-firebase-hosting.md) (hosting) y el
  [ADR 0009](./0009-secretos-dart-define-github-secrets.md) (secretos) sin reescribirlos. El
  ADR 0009 ya advertía que todo valor pasado con `--dart-define` puede extraerse. Esta decisión
  convierte esa advertencia en una regla que el pipeline hace cumplir.

## Contexto

El modelo STRIDE sobre el C4 dejó dos amenazas de prioridad alta, y las dos están en la forma en
que el sistema se construye y se publica, no en el código de la app:

- **T-01:** el pipeline que tiene la credencial de Firebase usaba acciones de terceros por
  etiqueta móvil (`@v0`, `@v4`). Quien controle esa etiqueta controla lo que se publica.
- **T-02:** el sitio es un cliente público. Todo lo que entra al build con `--dart-define` termina
  legible en `main.dart.js`. Si se configurara `GA_API_SECRET`, cualquiera podría mandar eventos
  falsos a GA4 a nombre de MAPSUTB. Hoy no está configurado: se comprobó que el bundle publicado
  no contiene el endpoint del Measurement Protocol. Pero nada impedía configurarlo.

Hay dos amenazas medias que también cambian la configuración del despliegue: **T-03**
(dependencias con vulnerabilidades conocidas) y **T-04** (el sitio no enviaba más cabecera de
seguridad que HSTS).

## Decisión

1. **Acciones fijadas por SHA.** Todos los `uses:` de los seis workflows apuntan a un commit, con
   la etiqueta en un comentario. Las actualizaciones llegan como PR de Dependabot
   (`.github/dependabot.yml`) y pasan por el CI y la revisión del equipo.
2. **El build público no lleva secretos de escritura.** `deploy.yml` falla antes de compilar si
   `GA_API_SECRET` existe. Si el equipo quiere analítica en producción, tiene que pasar por un
   colector propio que guarde el secreto del lado del servidor y deduplique, como el prototipo del
   [ADR 0019](./0019-cola-de-eventos-de-uso-prototipo-no-incorporado.md). Eso requiere backend y
   reabre la restricción de costo. La key de Google Maps sigue permitida, porque está pensada para
   ir en el cliente y se restringe por referente HTTP y por API (ADR 0009).
3. **Análisis de dependencias bloqueante.** OSV-Scanner revisa `pubspec.lock` en cada CI y una
   vulnerabilidad conocida hace fallar el pipeline. Así ninguna versión vulnerable llega al
   despliegue, que solo corre desde `master`.
4. **Cabeceras de seguridad en Firebase Hosting** (`firebase.json`): `nosniff`,
   `X-Frame-Options: DENY`, `Referrer-Policy: strict-origin-when-cross-origin` (conserva el origen
   que exige OpenStreetMap, T-05), `Permissions-Policy` (geolocalización solo del propio sitio,
   T-07) y la CSP **en modo report-only**. El paso de verificación del despliegue comprueba que las
   cabeceras están presentes.

## Alternativas descartadas

- **Imponer la CSP desde el primer despliegue.** Flutter web carga CanvasKit desde `gstatic.com`,
  compila WebAssembly y pide teselas y fuentes a otros orígenes. Una CSP mal ajustada deja la app
  en blanco, y en este equipo de trabajo no se puede compilar Flutter para probarla antes. Se
  publica en report-only y se impone después de revisar la consola del sitio (T-04b).
- **Proxy propio para la analítica (Cloud Functions).** Resolvería T-02 sin apagar la analítica,
  pero requiere el plan Blaze con tarjeta, lo que va contra la restricción de arc42 §2.
- **Fijar las acciones solo por versión exacta** (`@v4.2.2`). Una etiqueta se puede mover de
  commit; un SHA no.
- **Solo Dependabot, sin OSV en CI.** Dependabot avisa, pero no bloquea un despliegue. OSV en el
  pipeline sí lo bloquea.

## Consecuencias

- Actualizar una acción o una dependencia cuesta un PR revisado en vez de ocurrir solo. Es el
  precio de T-01 y T-03.
- La analítica queda apagada en el sitio publicado mientras no exista un colector propio. Es lo
  mismo que ya pasaba de hecho, pero ahora es una decisión que el pipeline hace cumplir.
- La CSP en report-only todavía no bloquea nada: es una mitigación a medias, registrada como
  pendiente (T-04b).
- Quedan fuera de este ADR, porque se hacen en la configuración de GitHub y Google Cloud y no en
  el repositorio:
  - la protección de `master` (T-09);
  - mover la credencial de Firebase al environment `firebase-hosting` y rotarla (T-08).

  Están asignadas en el modelo de amenazas.
