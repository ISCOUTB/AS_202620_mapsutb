# Levantamiento de datos del campus — MAPSUTB

Cómo se obtienen los datos geográficos del Campus Tecnológico de la UTB que alimentan el
contexto de **Ruteo** (grafo peatonal) y las coordenadas del **Catálogo de lugares**
(`assets/data/zonas.json`). La decisión de fuentes está en
[ADR 0011](./adr/0011-fuente-datos-geograficos-osm.md).

## 1. Fuentes y herramientas

| # | Fuente o herramienta | Qué aporta | Formato | Dónde queda |
|---|---|---|---|---|
| 1 | **OpenStreetMap** (editor iD en openstreetmap.org, sobre imagen satelital Bing/Esri) | Geometría base: andenes (`highway=footway`), escaleras (`highway=steps`), vías de servicio, contornos y nombres de edificios | OSM XML (API 0.6) | Público en OSM bajo ODbL; edición inicial: changeset [189774414](https://www.openstreetmap.org/changeset/189774414) (2026-09-30, 320 cambios) |
| 2 | **Registro de coordenadas** (`web/herramientas/coordenadas.html`) | Puntos sueltos tomados en sitio: entradas por zona, cruces, escaleras, rampas, puertas; con precisión y promediado de lecturas | GeoJSON, CSV | Celular del integrante → `C:\mapsutb-campo\exportaciones\` |
| 3 | **Grabar recorrido** (`web/herramientas/recorrido.html`) | Recorrido continuo con hora UTC, altitud del GPS, precisión, velocidad y contexto declarado (zona → piso → espacio); puntos; marcas de sincronización con el video | GPX, GeoJSON, JSON completo | Celular → `C:\mapsutb-campo\exportaciones\` |
| 4 | **GPS Logger** (app Android) | Traza GPS de respaldo en segundo plano, independiente del navegador | GPX / KML / CSV | Celular → `C:\mapsutb-campo\gpslogger\` |
| 5 | **Videos de las gafas Ray-Ban Meta** (clips de ~5 min) | Evidencia visual de cada tramo: escaleras, puertas, rejas, tramos techados, letreros de edificios; validación de lo trazado | MP4 | `C:\mapsutb-campo\videos\` (no se publica) |

Las dos herramientas web están publicadas en el mismo Firebase Hosting del sistema
(`https://mapsutb.web.app/herramientas/…`) porque el navegador solo entrega el GPS a páginas
con HTTPS. No tienen servidor: los datos quedan en el celular hasta que se exportan.

## 2. Qué se usa de cada fuente

| Dato del modelo | Fuente principal | Fuente de validación |
|---|---|---|
| Forma de los caminos | OpenStreetMap (trazado sobre imagen satelital) | Recorridos GPS (3 y 4) y videos |
| Conexión entre caminos (topología) | OpenStreetMap | Videos: lo que se ve conectado al caminar |
| Entradas de cada zona | Puntos tipo *Entrada* (2 y 3) | Videos (letrero o puerta a la vista) |
| Escaleras, rampas, ascensores, rejas | Puntos (2 y 3) y OSM (`highway=steps`) | Videos |
| Piso dentro de un edificio | Contexto declarado en *Grabar recorrido* | Videos (letreros de piso, escaleras) |
| Altitud | GPS del celular (dato informativo) | — |

**El piso no se deduce de la altitud del GPS:** su error vertical (±10–30 m) supera la altura de
un piso (3–4 m) y el barómetro del celular no es accesible desde el navegador. La altitud se
guarda solo como dato.

## 3. Procedimiento en campo

1. **Antes de salir:** trazar en OSM lo visible desde la imagen satelital y guardar el cambio.
2. **Por cada clip de las gafas (~5 min):**
   1. *Grabar recorrido* → **Iniciar** o **Continuar**; GPS Logger grabando en segundo plano.
   2. Iniciar el video de las gafas → abrir **Pantalla de sincronización** → mirarla con las
      gafas → **Marcar SYNC**.
   3. Caminar el tramo. Al entrar a un edificio o cambiar de piso, actualizar **Dónde estoy**.
      Registrar un punto en cada entrada, cruce, escalera, rampa, ascensor, puerta y salón.
   4. Antes de que termine el clip: **Marcar SYNC** otra vez.
3. **Al terminar:** exportar *JSON completo* y *GPX* de *Grabar recorrido*, el GeoJSON de
   *Registro de coordenadas* y el archivo de GPS Logger; copiar todo, con los videos, a
   `C:\mapsutb-campo\`, y anotar en `notas.txt` el orden de los clips y lo que faltó.

Recomendaciones que se siguieron: pantalla encendida y la página en primer plano (con la
pantalla apagada el navegador deja de leer el GPS), puntos tomados con el indicador en verde
(≤ 8 m) cuando es posible, y grabación en horas de poco movimiento para captar menos personas.

## 4. Procesamiento (incremental)

Cada procesamiento relee **toda** la carpeta, así que agregar datos de una nueva salida solo
exige copiarlos y volver a ejecutarlo:

1. Unir recorridos, puntos y marcas SYNC de todas las exportaciones, por hora UTC y sin duplicados.
2. Emparejar los registros del mismo lugar hechos con herramientas distintas (menos de 90 s y
   40 m de diferencia): se conserva el de la herramienta web, que trae tipo y zona, y la distancia
   entre ambos queda como medida del error del GPS.
3. Sincronizar cada video con su par de marcas SYNC (destello visible en el video + hora
   registrada) y asignar a cada instante su coordenada, zona y piso.
3. Descargar de OSM el área del campus y compararla con los recorridos y los videos: tramos
   confirmados, tramos caminados que no están trazados, tramos trazados que nadie recorrió.
4. Conectar cada entrada registrada al andén más cercano (hoy hay 14 extremos de andén sin
   conexión que, en su mayoría, llegan a puertas).
5. Generar `grafo.json` (nodos, tramos, distancias, escaleras, pisos) y las coordenadas de
   `zonas.json`, más una **lista de pendientes**: zonas sin entrada, pisos sin recorrer,
   tramos sin validar. Esa lista guía la siguiente salida.

### Cómo ejecutarlo

```bash
python -m pip install defusedxml          # una vez
python scripts/campo/analizar_campo.py "C:\mapsutb-campo"                  # informe y mapa
python scripts/campo/analizar_campo.py "C:\mapsutb-campo" --escribir-repo  # además, grafo.json y coordenadas
```

- Resultados privados en `C:\mapsutb-campo\resultados\`: `informe.md`, `mapa.svg`,
  `datos_unificados.json` y la descarga de OSM usada.
- Lo que el análisis no puede deducir (qué polígono de OSM es cada zona, correcciones de zona
  de un punto) lo confirma el equipo y queda en
  [`scripts/campo/correspondencias.json`](../scripts/campo/correspondencias.json), que se aplica
  en cada ejecución.
- Con `--escribir-repo` se regeneran [`assets/data/grafo.json`](../assets/data/grafo.json)
  (ODbL) y las coordenadas de `assets/data/zonas.json`; `test/grafo_test.dart` valida su
  integridad en el CI.

## 5. Privacidad y licencias

- **Videos y recorridos crudos no se publican:** contienen personas y la ubicación de los
  integrantes con hora exacta. Viven en `C:\mapsutb-campo\` (fuera del repositorio) o en un
  Drive del equipo. Si una imagen llega a la app (por ejemplo, al tour), se difuminan caras y
  placas antes (Ley 1581 de 2012).
- **Al repositorio solo va lo derivado:** el grafo y las coordenadas de las zonas.
- **Lo derivado de OSM queda bajo ODbL:** se atribuye “© colaboradores de OpenStreetMap” y el
  grafo se comparte con la misma licencia (ADR 0011).
- **No se usó Google Earth ni Google Maps para trazar:** sus términos prohíben crear datos de
  navegación a partir de su contenido, también en proyectos académicos (ADR 0011).

## 6. Estado del levantamiento

| Fecha | Qué se hizo | Resultado |
|---|---|---|
| 2026-09-30 | Trazado en OSM (changeset 189774414) | 47 andenes y escaleras (~2,3 km); edificios A1–A5, Zona T y biblioteca con nombre; 0 entradas etiquetadas; 14 extremos de andén sin conexión; sin nombre en OSM: EDA2, Contenedores, Quid, Alcatraz |
| 2026-10-01 | Recorrido con gafas, herramientas web y GPS Logger | 74 puntos (salida de la mañana) y una sesión de 21 min con 828 muestras, 6 marcas SYNC y 5 videos (2,3 GB). Desfase de las gafas medido con el destello: −0,48 s |
| 2026-10-02 | Segundo procesamiento (traza de GPS Logger del recorrido de la mañana) | 2.549 muestras y 112 lugares. **25 lugares quedaron medidos dos veces** (herramienta web y GPS Logger a la vez): diferencia mediana 5,8 m en exterior y 16,5 m dentro de edificios (máxima 38,4 m), lo que confirma con datos que el GPS no sirve para ubicar espacios interiores. De 13 tramos fuera de lo trazado, 8 son deriva dentro del A2 y 5 son posibles caminos por trazar en exterior |
| 2026-10-01 | Primer procesamiento | 91 % del recorrido a ≤ 10 m de lo trazado; 28 de 47 andenes recorridos; 3 tramos fuera de lo trazado (bajada interior por escaleras, cruce por parqueadero, corredor techado). Grafo: 78 nodos, 90 tramos, 3,33 km; 10 de 11 zonas con coordenada y entrada provisional conectada. Pendiente: Contenedores, entradas reales de cada edificio, pisos declarados y confirmar si el polígono de Alcatraz incluye a EDA2 |
