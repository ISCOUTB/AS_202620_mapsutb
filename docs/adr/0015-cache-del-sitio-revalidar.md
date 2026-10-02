# ADR 0015 — El sitio revalida HTML, JS y JSON en lugar de servirlos desde la caché del navegador

## Estado

- **Estado**: Aceptado
- **Fecha**: 2026-10-02
- **Decisores**: Equipo MAPSUTB
- **Complementa**: [ADR 0007](./0007-hosting-web-firebase-hosting.md) (plataforma) y
  [ADR 0010](./0010-reversion-sitio-web.md) (reversión), sin cambiar sus decisiones

## Contexto

Al medir la app publicada el 2026-10-02 se encontró que el navegador ejecutaba un `main.dart.js`
de su propia caché (556.664 bytes) mientras el servidor ya servía otro (557.963 bytes): una
función desplegada minutos antes no aparecía. Firebase Hosting aplicaba su caché por defecto
(`max-age=3600`) y **Flutter web no incluye un hash en el nombre de `main.dart.js`**, así que el
navegador no tenía forma de saber que el archivo había cambiado.

Esto afecta a dos decisiones ya tomadas:

- **ADR 0010 (reversión):** revertir el sitio tarda 0,4 s en el servidor, pero quien ya tenía la
  app abierta seguía viendo la versión defectuosa hasta una hora después. La reversión medida
  describía el servidor, no lo que ve el usuario.
- **ADR 0007 (despliegue):** un despliegue correcto no llegaba a los usuarios actuales.

## Decisión

En [`firebase.json`](../../firebase.json), servir **`**/*.@(html|js|json)` con
`Cache-Control: no-cache`**: el navegador puede guardar una copia, pero debe revalidarla contra el
servidor antes de usarla. Con el ETag que Firebase ya envía, la revalidación responde `304 Not
Modified` sin volver a descargar el archivo, así que el costo es un viaje de ida y vuelta pequeño
y no transferencia (relevante para el límite de 360 MB/día del plan Spark, `docs/costos.md`).

`/health.json` mantiene `no-store` (no se guarda nunca). El resto de los archivos —CanvasKit,
fuentes, imágenes— conserva la caché por defecto: sus nombres sí cambian entre versiones.

## Alternativas consideradas

### A. Revalidar html, js y json con `no-cache` (elegida)

- **A favor:** una línea de configuración; el despliegue y la reversión llegan en la siguiente
  carga de la página; no exige cambiar el build.
- **En contra:** una petición de revalidación por archivo en cada carga (respuesta 304, sin cuerpo).

### B. Poner un hash en el nombre de los archivos del build (descartada por ahora)

- **Motivo técnico:** es la solución ideal (caché larga y segura), pero `flutter build web` no
  renombra `main.dart.js`; habría que añadir un paso propio que lo renombre y reescriba el
  `index.html` en cada despliegue, con más piezas que mantener que las que justifica el tamaño del
  sitio.

### C. Dejarlo como estaba (descartada)

- **Motivo técnico:** contradice el Escenario 7 (reversión en ≤ 5 min *verificable*): el servidor
  revertía en 0,4 s pero el usuario seguía con la versión anterior hasta una hora.

## Consecuencias

- Los despliegues y las reversiones llegan a los usuarios en la siguiente carga de la página.
- La corrección **no alcanza a las copias ya guardadas** con la política anterior: esos navegadores
  siguen con la versión vieja hasta que expire (hasta una hora desde que la descargaron).
- La verificación de una reversión debería hacerse en una ventana nueva o con recarga forzada
  mientras queden copias con la política anterior.
