# Evidencia S12 — Estrategia de datos y eventos

Cómo se garantiza la consistencia de cada operación real, qué se cachea y qué lo invalida, y cuál
es la decisión de datos más costosa de revertir.

## Matriz de la ficha

| Criterio | Dónde está |
|---|---|
| Tabla operación → garantía con operaciones reales | [arc42 §8, «Consistencia de los datos»](./arc42/08_concepts.adoc): siete operaciones del código. Son el despliegue, la lectura de zonas, la lectura del grafo, la coherencia entre ambos, el cálculo de la ruta, la posición y el evento de analítica. Cada una declara su garantía: fuerte, instantánea por sesión, fuerte por archivo y eventual entre archivos, última lectura gana, o como máximo una vez. |
| Dos operaciones verificadas contra la implementación | Misma sección, «Dos operaciones contrastadas con el código». La instantánea del grafo está en `lib/routing/mapa_repository.dart:27-39` y se prueba en `test/ruteo_test.dart:226`. La analítica como máximo una vez está en `lib/adapters/analytics_adapter.dart:86-112` y se prueba en MF-15 (`test/modos_de_fallo_test.dart:175`). |
| Caché: qué, dónde y cuánto | arc42 §8, «Caché»: ocho filas, desde la caché HTTP del sitio y CanvasKit hasta la caché de assets de Flutter, el grafo en memoria, el service worker (no hay), las teselas de OSM y la app instalada. |
| Invalidación tras escritura | arc42 §8, «Política de invalidación tras una escritura». La única escritura es el despliegue, y la cadena es ETag → recarga → cachés en memoria vacías. **Corregido esta semana:** una lectura fallida de `zonas.json` o `grafo.json` quedaba en la caché de Flutter, y en web «Reintentar» no servía hasta recargar. Ahora los repositorios hacen `evict`, y las pruebas «una lectura fallida no queda en caché» están en `test/zonas_test.dart` y `test/ruteo_test.dart`. |
| Garantías de eventos | No hay flujo por eventos propio ni broker. El evento de analítica es como máximo una vez y asume que se pierde ante un fallo de red (arc42 §8, ADR 0016). |
| ADR de la decisión de datos más costosa de revertir | [ADR 0018](./adr/0018-datos-del-campus-solo-lectura-derivados-de-osm.md): los datos del campus son archivos de solo lectura derivados de OSM, sin base de datos. |
| Razón y costo de reversión | ADR 0018, sección «Contexto»: una tabla con las cinco decisiones de datos y lo que cuesta revertir cada una. La sección «Por qué es la más costosa de revertir» explica los tres costos: la licencia ODbL no se puede retirar, las claves vienen de OSM y no hay otra fuente legal, y una base de datos haría perder el funcionamiento sin conexión. |
| Almacenes y brokers en C4 L2 | [`docs/c4/C2.md`](./c4/C2.md): los dos almacenes JSON como `ContainerDb` con su tecnología, y la sección «Almacenes y brokers» explica por qué no hay base de datos ni broker. |
| arc42 §8: consistencia y caché | [`docs/arc42/08_concepts.adoc`](./arc42/08_concepts.adoc), las dos secciones nuevas. |

## Otros cambios de la semana

- `lib/main.dart`: el grafo se lee al arrancar, junto con las zonas. Así se acorta la ventana en la
  que una pestaña podría combinar dos versiones de los datos (arc42 §8, coherencia entre zonas y
  grafo).
- Sonar #55 y #56 (`lib/features/busqueda/indice_busqueda.dart`): `buscar()` separa la
  coincidencia, el rango y el orden, sin cambiar el comportamiento. Las pruebas de
  `test/indice_busqueda_test.dart` siguen igual.
- Registro de IA: [`docs/ia.md`](./ia.md), entrada del 25/10/2026, con lo que se rechazó y su
  motivo.

## CI

La rama `s12-datos` pasó el análisis, las pruebas de contrato, la suite completa y SonarCloud con
el Quality Gate en
[run 40199365723](https://github.com/ISCOUTB/AS_202620_mapsutb/actions/runs/40199365723).
El run de `master` con el commit final queda en la pestaña Actions del repositorio.
