# Taller aplicado de despliegue — MAPSUTB

Comparación de dos alternativas de despliegue para **una pieza concreta** del sistema, bajo la
condición operativa **necesidad de reversión**. La decisión queda en
[ADR 0010](./adr/0010-reversion-sitio-web.md).

## 1. Condición operativa

**Necesidad de reversión:** si un despliegue sale mal, el equipo tiene que poder volver a la
versión anterior rápido y sin depender de recompilar.

La condición asignada al equipo no aparece publicada en el repositorio del curso
(`EQUIPOS.md`, planilla y revisiones de `AS_202620_mapsutb`, consultados el 2026-09-27) y el
docente no la especificó en clase. **El equipo la declaró** porque es la que más pesa en su
caso: hoy se despliega en cada push a `master` (22 commits en la semana del 20 al 27 de
septiembre), sin revisión previa en un entorno de pruebas, y la sustentación del segundo corte
se hace sobre el entorno desplegado. Si el docente confirma otra condición, este documento se
rehace sobre esa.

El escenario de calidad que la hace medible es el
[Escenario 7 — Reversión del sitio web](./escenarios_calidad.md#escenario-7--reversión-del-sitio-web):
volver a la versión anterior en **5 minutos o menos** desde que se decide, **sin recompilar**, y
comprobarlo con el commit que publica el health check.

## 2. Pieza

La pieza es el **sitio web estático de MAPSUTB**: el resultado de `flutter build web` (HTML, JS,
`assets/data/zonas.json`) más `health.json`, que dice qué commit está en línea. No se compara el
sistema entero: el CI, SonarCloud, la sonda de disponibilidad y las APIs de Google quedan fuera.

## 3. Supuestos

| Supuesto | Valor | De dónde sale |
|---|---|---|
| Volumen | 6.000 visitas/mes; ≈ 240 MB/día de transferencia en promedio | [`docs/costos.md`](./costos.md) |
| Concurrencia | < 20 usuarios simultáneos | Sitio estático, público del campus |
| Tamaño de datos | `main.dart.js` 2,2 MB; build completo estimado en ~30 MB por versión | Medido en el despliegue; el total incluye CanvasKit y fuentes |
| Frecuencia de despliegue | ~3 por día hábil (22 commits a `master` del 20 al 27/09) | `git log` |
| Frecuencia de reversión | Rara (≤ 1 por semana), pero crítica el día de una sustentación o de la inducción | Criterio del equipo |
| Quién revierte | Cualquier integrante, desde fuera de la universidad | El equipo no tiene acceso remoto garantizado a la red del laboratorio |

## 4. Alternativas

Las dos sirven los **mismos artefactos**, construidos con la misma versión de Flutter que el CI.

### A. Firebase Hosting, plan Spark

| | |
|---|---|
| Dónde corre | CDN de Google; proyecto `mapsutb`; https://mapsutb.web.app/ |
| Cómo se despliega | [`.github/workflows/deploy.yml`](../.github/workflows/deploy.yml) + [`firebase.json`](../firebase.json), en cada push a `master` |
| Qué conserva | **Cada versión publicada queda guardada** en Firebase como una versión inmutable |
| Cómo se revierte | Se vuelve a publicar la versión anterior sin recompilar: consola de Firebase (*Hosting → historial → Revertir*) o el workflow [`reversion-firebase.yml`](../.github/workflows/reversion-firebase.yml), que llama a la API de Hosting con [`scripts/revertir_hosting.py`](../scripts/revertir_hosting.py) |
| Desde dónde | Cualquier lugar con navegador o acceso a GitHub |
| Sin tarjeta | **Sí.** La página de precios dice *"No payment method needed"* para Spark ([firebase.google.com/pricing](https://firebase.google.com/pricing), 2026-09-25), y el proyecto `mapsutb` se creó y despliega sin método de pago registrado |
| Costo al volumen supuesto | USD 0 |
| Punto de ruptura | Transferencia: 360 MB/día (≈ 120 primeras visitas en un mismo día). Almacenamiento: 10 GB, ≈ 330 versiones guardadas de ~30 MB; al ritmo actual (~15 despliegues por semana), unas 22 semanas antes de tener que borrar versiones viejas |

### B. Servidor del laboratorio con Docker + nginx

| | |
|---|---|
| Dónde corre | Servidor del laboratorio de la universidad (o cualquier máquina con Docker) |
| Cómo se despliega | [`infra/Dockerfile`](../infra/Dockerfile) + [`infra/docker-compose.yml`](../infra/docker-compose.yml) + [`infra/nginx.conf`](../infra/nginx.conf); cada imagen se etiqueta con su commit: `IMAGE_TAG=$(git rev-parse HEAD) docker compose -f infra/docker-compose.yml up -d --build` |
| Qué conserva | Las imágenes `mapsutb-web:<commit>` que **alguien haya construido y no haya borrado** en ese servidor |
| Cómo se revierte | `IMAGE_TAG=<commit-anterior> docker compose -f infra/docker-compose.yml up -d --no-build`; si la imagen no está, hay que recompilarla con `--build` desde ese commit |
| Desde dónde | Una sesión en el servidor, dentro de la red de la universidad |
| Sin tarjeta | **Sí.** Infraestructura de la universidad; Docker e nginx son software libre |
| Costo al volumen supuesto | USD 0 para el equipo |
| Punto de ruptura | No hay cuota de transferencia; el límite es el disco del servidor (~30 MB por imagen de sitio, más ~1,5 GB de la etapa de compilación en caché) y la disponibilidad de la máquina, que el equipo no controla |

## 5. Arranque en frío

**No aplica.** Ninguna de las dos alternativas es una función: Firebase Hosting sirve archivos
estáticos desde su CDN y nginx es un proceso que queda corriendo. No hay arranque por petición
que contrastar con un p95.

## 6. Medición

Procedimiento reproducible: los dos workflows se ejecutan a mano desde *Actions → Run workflow*
y dejan el resultado en el resumen del run y como artefacto JSON. En ambos, el tiempo va desde la
orden de revertir hasta que `health.json` responde con el commit anterior.

| Alternativa | Revertir | Restaurar | Si la versión anterior no se conservó | Run |
|---|---|---|---|---|
| A. Firebase Hosting | **0,4 s** (0,3 s de API + 0,1 s hasta verse en línea) | 0,5 s | No ocurre: Firebase guarda todas las versiones | [36351911654](https://github.com/ISCOUTB/AS_202620_mapsutb/actions/runs/36351911654) |
| B. Docker + nginx | **0,58 s** | 0,55 s | Recompilar: 33 s con caché de Docker; 86 s sin caché (incluye instalar Flutter) | [36352036757](https://github.com/ISCOUTB/AS_202620_mapsutb/actions/runs/36352036757) |

- A se midió contra el sitio real: revirtió de `61c2c36` a `f195643` y lo restauró.
- B se midió en un runner de GitHub Actions, como sustituto del servidor del laboratorio: mismas
  órdenes de Docker, otra máquina. En el servidor real los tiempos de recompilación dependen de su
  hardware y de si la caché sigue ahí.
- Los tiempos se miden desde una sola ubicación (el runner). Un navegador que ya tenía
  `main.dart.js` en caché puede necesitar recargar para ver la versión revertida; `health.json` e
  `index.html` se sirven sin caché (`firebase.json`, `infra/nginx.conf`).
- La primera medición de B **falló** y sirvió: la imagen base del Dockerfile de S8
  (`ghcr.io/cirruslabs/flutter:3.47.4`) no existe. El Dockerfile nunca se había construido.
  Se corrigió instalando Flutter desde su tag oficial (commit `3ffbe8e`).

**Contra el umbral del Escenario 7 (≤ 5 min, sin recompilar):** las dos cumplen *cuando la versión
anterior está guardada*. La diferencia está en esa condición: en A se cumple siempre; en B depende
de que alguien haya conservado la imagen en el servidor y de tener acceso a él.

## 7. Costo

| | A. Firebase Hosting | B. Laboratorio + Docker |
|---|---|---|
| Costo mensual al volumen supuesto | USD 0 | USD 0 |
| Qué se rompe primero | La cuota diaria de transferencia (360 MB/día) en un pico de inducción | La disponibilidad del servidor y el acceso a la red interna |
| Qué pasa al romperse | El sitio deja de servirse hasta el día siguiente; no hay cobro | El sitio no responde fuera de la universidad |
| Cómo se sigue sin tarjeta | Reducir el tamaño del build y cachear estáticos | Pedir al laboratorio exposición pública y respaldo de imágenes |

## 8. Procedimiento de reversión

### Si un despliegue sale mal (alternativa elegida, A)

1. Confirmar el problema: `curl -s https://mapsutb.web.app/health.json` muestra el commit en línea.
2. Revertir, por cualquiera de estas dos vías:
   - *GitHub → Actions → "Reversión medida (Firebase Hosting)" → Run workflow*, con
     **Restaurar** desmarcado; o
   - *Firebase console → Hosting → Historial de versiones →* la versión anterior *→ Revertir*.
3. Verificar: `health.json` muestra el commit anterior (en la medición tardó menos de 1 s).
4. Corregir en `master` con un commit nuevo (`git revert <commit>` o un arreglo). El siguiente push
   vuelve a desplegar por el flujo normal.
5. Registrar qué pasó en el issue o en la sección de riesgos de arc42 §11.

### Si la alternativa elegida falla o se encarece

1. **Firebase no está disponible o se agotó la cuota diaria:** levantar el mismo sitio con la
   alternativa B en cualquier máquina con Docker:
   `IMAGE_TAG=$(git rev-parse HEAD) docker compose -f infra/docker-compose.yml up -d --build`
   (86 s medidos desde cero) y comunicar la URL temporal.
2. **Firebase pasa a exigir tarjeta o cambia el plan gratuito:** mover el despliegue a B de forma
   permanente o a GitHub Pages (descartada en ADR 0007 por no tener reversión sin recompilar), con
   un ADR nuevo que reemplace al 0010.

### Si se usa la alternativa B

1. `docker images mapsutb-web` para ver qué commits están guardados.
2. `IMAGE_TAG=<commit-anterior> docker compose -f infra/docker-compose.yml up -d --no-build`.
3. `curl http://localhost:8080/health` muestra el commit anterior.
4. Si la imagen no está: `git checkout <commit-anterior>` y el mismo comando con `--build`.

## 9. Decisión

**Alternativa A, Firebase Hosting**, porque bajo la necesidad de reversión es la única en la que
la versión anterior **siempre** está disponible y se puede revertir **desde cualquier lugar** en
menos de un segundo. B es igual de rápida solo si alguien conservó la imagen y está dentro de la
red de la universidad. Detalle y consecuencias en
[ADR 0010](./adr/0010-reversion-sitio-web.md), que complementa al
[ADR 0007](./adr/0007-hosting-web-firebase-hosting.md).

## 10. Evidencia del proyecto

Todo lo citado es del repositorio y de ejecuciones reales, no capturas de un tutorial:

- Prototipos versionados: `.github/workflows/deploy.yml`, `firebase.json`, `.firebaserc`, `infra/`.
- Procedimientos de reversión ejecutables: `.github/workflows/reversion-firebase.yml`,
  `.github/workflows/reversion-docker.yml`, `scripts/revertir_hosting.py`.
- Mediciones: runs [36351911654](https://github.com/ISCOUTB/AS_202620_mapsutb/actions/runs/36351911654)
  y [36352036757](https://github.com/ISCOUTB/AS_202620_mapsutb/actions/runs/36352036757), con
  el JSON de resultados como artefacto.
- Costo y supuestos de volumen: `docs/costos.md`.
