# ADR 0018 — Los datos del campus son archivos de solo lectura derivados de OpenStreetMap, sin base de datos

## Estado

- **Estado**: Aceptado
- **Fecha**: 2026-10-25
- **Decisores**: Equipo MAPSUTB
- **Relación**: cierra la decisión de datos que quedó pendiente en S8 (Firestore se pospuso a la
  semana 12, ver `docs/ia.md`, entrada del 25/09/2026). Se apoya en el
  [ADR 0011](./0011-fuente-datos-geograficos-osm.md) (fuente de los datos) y en la alternativa D del
  [ADR 0016](./0016-no-extraer-modulos-por-ahora.md) (servir los datos fuera de la app), sin
  cambiar ninguno de los dos.

## Contexto

MAPSUTB maneja cinco decisiones de datos. Para elegir cuál documentar como la más costosa de
revertir se estimó qué habría que rehacer para deshacer cada una:

| Decisión de datos | Dónde vive | Qué cuesta revertirla |
|---|---|---|
| Caché HTTP: HTML, JS y JSON se revalidan en cada carga ([ADR 0015](./0015-cache-del-sitio-revalidar.md)) | `firebase.json` | Una línea y un despliegue de 0,4 s (ADR 0010). No se pierde ningún dato. |
| Analítica como máximo una vez ([ADR 0016](./0016-no-extraer-modulos-por-ahora.md)) | `lib/adapters/analytics_adapter.dart` | Un adaptador y su prueba (MF-15). Los eventos ya perdidos no importan para el producto. |
| Posición del usuario solo en memoria, nunca persistida ([ADR 0017](./0017-gps-real-geolocator-filtro.md)) | `lib/services/ubicacion_service_gps.dart` | Técnicamente barato, pero persistirla convierte a la app en un sistema que guarda ubicaciones de personas, con todo lo que eso exige en privacidad. Si se mantiene, revertirla no cuesta nada. |
| Grafo en memoria durante la sesión | `lib/routing/mapa_repository.dart` | Quitar un campo. |
| **Datos del campus: archivos de solo lectura derivados de OSM, con los ids de OSM como claves** | `assets/data/zonas.json`, `assets/data/grafo.json` | Ver «Por qué es la más costosa de revertir». |

Hoy los datos del campus son dos archivos que viajan dentro de la app. `zonas.json` tiene 11 zonas,
85 espacios y 114 salones. `grafo.json` tiene 78 nodos, 90 tramos y 10 entradas de zona. La app
**nunca los escribe**: los genera `scripts/campo/analizar_campo.py` a partir de OpenStreetMap y del
levantamiento de campo, y cambian solo con un commit y un despliegue. Esta forma de guardarlos nunca
se había registrado como decisión propia. La pregunta abierta desde S8 era si debían pasar a
Firestore.

## Decisión

1. **Sin base de datos para los datos del campus.** Siguen siendo archivos JSON de solo lectura
   empaquetados en la app. Se descarta Firestore para ellos.
2. **Un solo conjunto versionado.** `zonas.json` y `grafo.json` cambian en el mismo commit y salen
   en el mismo despliegue. La única escritura sobre ellos es el despliegue (arc42 §8, tabla
   operación → garantía).
3. **Las claves se mantienen tal como están.** Los nodos del grafo usan el id del nodo de OSM
   (`n1021551490`), y cada entrada une un id de zona de `zonas.json` con uno de esos nodos. El id de
   zona es la única clave compartida entre los contextos Catálogo y Ruteo (ADR 0006).
4. **Salvaguardas para que una reversión futura cueste menos:**
   - todo acceso pasa por `ZonaRepository` y `MapaRepository`. Si mañana hay base de datos, solo
     cambian esas dos clases, y las pantallas, `ServicioRuteo` e `IndiceBusqueda` no se tocan;
   - el grafo se puede regenerar: `analizar_campo.py` relee todos los datos de campo y OSM, así que
     cambiar el formato de salida no obliga a volver al campus;
   - `grafo.json` declara `version`, `licencia` y `fuente`, de modo que un cambio de esquema o de
     fuente queda visible en el propio archivo.

## Por qué es la más costosa de revertir

Revertirla puede significar tres cosas, y ninguna se resuelve con un cambio de configuración:

1. **Dejar la licencia ODbL: no se puede hacer hacia atrás.** El grafo y las coordenadas derivados
   de OSM ya están publicados en un repositorio público y en un sitio público bajo ODbL
   (ADR 0011). Lo publicado sigue bajo esa licencia aunque se cambie de fuente. Cualquier versión
   futura que siga derivando de esos datos también queda bajo ODbL.
2. **Cambiar de fuente obliga a rehacer el mapa desde cero.** Los 78 nodos y las 10 entradas usan
   ids de OSM, y `scripts/campo/correspondencias.json` asigna las zonas a edificios por su id de way
   en OSM. Una fuente nueva cambia todas esas claves. Las pruebas no se rompen por los ids, porque
   `test/grafo_test.dart` verifica la estructura y no valores fijos, pero tendrían que pasar de
   nuevo sobre un grafo distinto. Además, no hay otra
   fuente legal: los términos de Google Maps y Earth prohíben crear datos de navegación con su
   contenido (ADR 0011, alternativa B), y el GPS solo tiene 5–10 m de error (alternativa C). Habría
   que volver a trazar los caminos y repetir el levantamiento: las salidas del 01 y el 02/10/2026,
   cinco videos de las gafas (2,3 GB), los recorridos de la herramienta web, la traza de GPS Logger
   (1.721 muestras) y su análisis.
3. **Pasar a una base de datos cambia el flujo principal.** Hoy la ruta sale sin red, porque el
   cálculo es local y los datos están en la app (Escenario 2, arc42 §2). Con los datos en Firestore
   o servidos aparte, el flujo principal suma una descarga con los tres modos de fallo de S11
   (ADR 0016, alternativa D). Además:
   - hay que decidir qué hacer sin conexión, con una copia local y un control de versiones entre app
     y datos;
   - la garantía de consistencia baja de «instantánea de una versión» (arc42 §8) a lecturas
     independientes por documento, salvo que se usen transacciones;
   - entra un SDK nativo que el proyecto evitó a propósito (ADR 0005 y el comentario de
     `AnalyticsAdapterHttp`);
   - hay que escribir reglas de seguridad para la base de datos;
   - cambian C4 L2, arc42 §7 y §8, y las pruebas de repositorios que hoy leen los archivos reales.

Las otras cuatro decisiones de la tabla se revierten en el código propio, sin perder datos, en un
despliegue. Esta toca una licencia que ya no se puede retirar, un trabajo de campo que no se puede
regenerar y el diseño sin conexión del flujo principal.

## Alternativas consideradas

### A. Archivos de solo lectura en la app, derivados de OSM (elegida)

- **A favor:** la ruta sale sin red; las dos lecturas del sitio cuestan un 304 cuando nada cambió
  (ADR 0015); no hay reglas de seguridad ni cuotas de lectura que vigilar; los datos se revisan en
  el mismo pull request que el código que los usa.
- **En contra:** corregir un dato (una entrada mal ubicada, un camino cerrado por obras) exige un
  despliegue; una pestaña abierta conserva la versión anterior hasta recargar.

### B. Firestore como fuente de zonas y grafo (descartada)

- **Motivo técnico:** la app no escribe estos datos, así que una base de datos no aporta nada en
  escritura y sí quita el funcionamiento sin conexión del flujo principal. Además, cada pantalla
  pagaría lecturas por documento contra la cuota diaria del plan Spark. Firestore se reconsidera
  cuando aparezca una **escritura en tiempo de ejecución**, como rutas favoritas o reportes de obras.

### C. Los mismos JSON servidos aparte del bundle, en Hosting (descartada por ahora)

- **Motivo técnico:** es la alternativa D del ADR 0016. Su única ventaja es cambiar el grafo sin
  desplegar la app, y hoy no se da: el grafo cambia en el mismo commit que el código.

### D. Otra fuente geográfica (descartada)

- **Motivo:** Google Maps y Earth lo prohíben en sus términos, y el GPS solo sirve como validación
  (ADR 0011).

## Consecuencias

**Positivas**

- La consistencia de los datos del campus se reduce a una regla: una versión por despliegue, leída
  una vez por sesión (arc42 §8).
- No se añade ningún almacén ni broker nuevo al C4 L2.

**Negativas / riesgos aceptados**

- En web, una pestaña abierta antes de un despliegue sigue con los datos anteriores hasta recargar.
  Para que no combine zonas viejas con un grafo nuevo, la app lee los dos archivos al arrancar
  (`lib/main.dart`). Si aun así una entrada no existe, la pantalla de mapa dice «No hay ruta hasta
  ese destino» en vez de fallar.
- Las correcciones de datos dependen de un despliegue del equipo.

## Cuándo revisar esta decisión

- Si la app necesita escribir datos en tiempo de ejecución (favoritos, reportes, horarios).
- Si el grafo tiene que cambiar más rápido que la app, por ejemplo por cierres temporales.
- Si aparece una fuente institucional de datos del campus con licencia compatible.
