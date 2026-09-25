# ADR 0007 — Publicar la app como sitio web estático en Firebase Hosting

## Estado

- **Estado**: Aceptado
- **Fecha**: 2026-09-25
- **Decisores**: Equipo MAPSUTB, por recomendación del docente

## Contexto

La evidencia S8 exige que el sistema esté **desplegado y accesible desde fuera de la red de la
universidad**, con un health check consultable y la infraestructura versionada. MAPSUTB es un
monolito Flutter sin backend propio (ADR 0004): no hay API ni base de datos que alojar, solo la
app. Distribuirla por tiendas (Play Store / App Store) exige cuentas de pago y revisión, y no da
una URL que un evaluador abra desde el navegador.

Flutter compila la misma base de código a web (`flutter build web`), lo que produce un sitio
**estático** (HTML + JS + assets, incluido `zonas.json`). La pieza que se decide aquí es, por
tanto, **dónde se aloja ese sitio estático**.

Restricciones que aplican (arc42 §2): presupuesto cero y ninguna cuenta personal con tarjeta. El
docente recomendó Firebase como plataforma del proyecto (hosting, analítica y datos).

## Decisión

Alojar el sitio en **Firebase Hosting, plan Spark**, en un proyecto de Firebase del equipo
(`mapsutb`). Lo publica el workflow
[`.github/workflows/deploy.yml`](../../.github/workflows/deploy.yml) en cada push a `master`:
compila, ejecuta las pruebas, genera `health.json` con el commit desplegado, publica con la acción
oficial `FirebaseExtended/action-hosting-deploy` y verifica que `<URL>/health.json` responde 200
con ese commit. La configuración del hosting está en [`firebase.json`](../../firebase.json).

- **URL**: `https://mapsutb.web.app/`
- **Health check**: `https://mapsutb.web.app/health.json`
  (`{"status":"ok","servicio":"mapsutb-web","commit":"…","desplegado":"…"}`, sin caché)

Firebase Hosting solo sirve estáticos, así que el health check es estático: responde 200 si el
último despliegue se publicó completo e indica qué commit está en línea.

Como alternativa reproducible fuera de Firebase se versiona también
[`infra/Dockerfile`](../../infra/Dockerfile) + [`infra/docker-compose.yml`](../../infra/docker-compose.yml)
(nginx, `/health`, logs JSON), que levanta el mismo sitio en el servidor del laboratorio o en
cualquier máquina con Docker.

## Capa gratuita verificada

Verificada el 2026-09-25 en [firebase.google.com/pricing](https://firebase.google.com/pricing):
plan Spark **sin método de pago**; Hosting con 10 GB de almacenamiento y **360 MB/día** de
transferencia. El sitio pesa unos pocos MB; el punto de ruptura (la transferencia diaria) está
calculado en [`docs/costos.md`](../costos.md).

## Alternativas consideradas

### A. Firebase Hosting (elegida)

- **A favor:** gratis y sin tarjeta; HTTPS y CDN incluidos; **reversión en un paso** (la consola y
  `firebase hosting:clone` restauran cualquier versión anterior publicada sin recompilar); canales
  de vista previa por rama o PR; y concentra en un solo proyecto de Firebase las piezas que el
  docente recomendó (hosting, Google Analytics y, más adelante, Firestore).
- **En contra:** 360 MB/día de transferencia es el límite más estrecho de las opciones evaluadas;
  exige guardar una cuenta de servicio como secret (`FIREBASE_SERVICE_ACCOUNT`, ADR 0009).

### B. GitHub Pages (descartada)

- **Motivo técnico del descarte:** también es gratis, sin tarjeta y con más ancho de banda
  (100 GB/mes), pero no tiene reversión a una versión publicada anterior (hay que revertir el
  commit y recompilar) ni canales de vista previa, y deja la analítica y los datos en otra
  plataforma distinta de la recomendada.

### C. Servidor del laboratorio con Docker + nginx (descartada como entorno público, conservada como reproducible)

- **Motivo técnico del descarte:** el servidor está en la red de la universidad y el criterio de
  S8 exige acceso **desde fuera** de ella; exponerlo requiere gestión de red que el equipo no
  controla. Se conserva `infra/` como vía para desplegar sin depender de Firebase.

## Consecuencias

**Positivas**

- URL pública estable y verificable desde fuera de la universidad, con HTTPS.
- Infraestructura como código: `deploy.yml` + `firebase.json` (entorno público) e `infra/`
  (entorno Docker).
- Cada despliegue queda ligado a un commit y a un run de Actions; revertir es restaurar una
  versión en Firebase.

**Negativas / riesgos aceptados**

- La versión web es una demostración de la app móvil: el GPS es simulado y, sin
  `GOOGLE_MAPS_API_KEY` (ADR 0009), Geocoding y Static Maps quedan ocultos.
- El health check no detecta fallos en tiempo de ejecución del JavaScript; eso lo cubre en parte
  la sonda de disponibilidad (ADR 0008).
- Si el tráfico pasa de ~360 MB/día, Firebase deja de servir el sitio hasta el día siguiente
  (el plan Spark corta, no cobra); ver `docs/costos.md`.

## Referencias

- [`docs/arc42/07_deployment_view.adoc`](../arc42/07_deployment_view.adoc) — vista de despliegue.
- [`docs/costos.md`](../costos.md) — costo mensual y punto de ruptura.
- [ADR 0004](./0004-adoptar-monolito-como-estilo-arquitectonico.md) — monolito sin backend.
