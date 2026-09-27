# ADR 0010 — Revertir el sitio web republicando versiones guardadas en Firebase Hosting

## Estado

- **Estado**: Aceptado
- **Fecha**: 2026-09-27
- **Decisores**: Equipo MAPSUTB
- **Complementa**: [ADR 0007](./0007-hosting-web-firebase-hosting.md) (plataforma del sitio), sin
  reemplazarlo

## Contexto

Condición operativa del taller de despliegue: **necesidad de reversión**. El docente no la
publicó; el equipo la declaró (ver [`docs/taller-despliegue.md`](../taller-despliegue.md) §1).
El sitio web se despliega en cada push a `master`, unas tres veces por día hábil, sin entorno de
pruebas intermedio, y la sustentación del segundo corte se hace sobre ese entorno. Un despliegue
roto el día equivocado deja al equipo sin sistema que mostrar.

Escenario que la mide: [Escenario 7](../escenarios_calidad.md#escenario-7--reversión-del-sitio-web),
volver a la versión anterior en ≤ 5 min, sin recompilar, verificable en `health.json`.

Pieza: el **sitio web estático** (build de Flutter web + `health.json`). Alternativas comparadas
con el mismo nivel de detalle en `docs/taller-despliegue.md` §4:

- **A. Firebase Hosting (plan Spark):** guarda cada versión publicada; revertir es volver a
  publicar la anterior.
- **B. Servidor del laboratorio con Docker + nginx:** revertir es levantar la imagen del commit
  anterior, si se conservó.

## Decisión

El sitio se sigue sirviendo desde **Firebase Hosting (A)**, y la reversión oficial es **volver a
publicar la versión anterior guardada**, sin recompilar, por una de estas dos vías:

- el workflow [`reversion-firebase.yml`](../../.github/workflows/reversion-firebase.yml) (API de
  Hosting con la cuenta de servicio del ADR 0009), o
- la consola de Firebase (*Hosting → historial de versiones → Revertir*).

El entorno Docker (B) queda como **plan de contingencia** si Firebase falla o se agota su cuota,
con imágenes etiquetadas por commit (`infra/docker-compose.yml`, `IMAGE_TAG`).

## Medición que la respalda

| | Revertir | Restaurar | Sin la versión guardada |
|---|---|---|---|
| A. Firebase Hosting | 0,4 s | 0,5 s | No ocurre |
| B. Docker + nginx | 0,58 s | 0,55 s | 33–86 s recompilando |

Runs: [A](https://github.com/ISCOUTB/AS_202620_mapsutb/actions/runs/36351911654) ·
[B](https://github.com/ISCOUTB/AS_202620_mapsutb/actions/runs/36352036757).

Las dos cumplen el Escenario 7 cuando la versión anterior está guardada. Lo que decide es
**cuándo** está guardada y **quién** puede revertir:

- En A, Firebase conserva automáticamente cada versión y cualquier integrante revierte desde
  fuera de la universidad.
- En B, la versión existe solo si alguien construyó y no borró esa imagen en el servidor, y
  revertir exige estar dentro de la red de la universidad. Si la imagen falta, se incumple la
  condición "sin recompilar".

## Alternativa descartada

**B como entorno principal**, por el motivo técnico anterior: su reversión depende de un estado
manual del servidor (imágenes conservadas) y de acceso a la red interna, que el equipo no
controla. Además, el entorno público debe ser accesible desde fuera de la universidad (evidencia
S8), cosa que el servidor del laboratorio no garantiza.

## Capa gratuita verificada

Plan Spark sin método de pago ([firebase.google.com/pricing](https://firebase.google.com/pricing),
consultado el 2026-09-25); el proyecto `mapsutb` opera sin tarjeta. Las versiones guardadas
cuentan contra los 10 GB de almacenamiento: con ~30 MB por versión caben unas 330, alrededor de
22 semanas al ritmo actual.

## Consecuencias

**Positivas**

- La reversión es una acción de menos de un segundo, repetible y medida, que no depende de
  recompilar ni de la red de la universidad.
- `health.json` con el commit permite verificar cualquier despliegue o reversión.
- El Dockerfile de contingencia ahora sí construye; antes fallaba con una imagen base inexistente,
  y la medición lo detectó.

**Negativas / riesgos aceptados**

- Firebase no borra versiones viejas por su cuenta en la configuración actual: en unas 22 semanas
  hay que configurar la retención de versiones (por ejemplo, conservar las últimas 50).
- Revertir el sitio no revierte `master`: el siguiente push vuelve a desplegar. El procedimiento
  (`docs/taller-despliegue.md` §8) exige corregir `master` antes del siguiente push.
- Un navegador con `main.dart.js` en caché puede necesitar recargar para ver la versión revertida.
