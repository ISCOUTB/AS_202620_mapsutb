# MAPSUTB: Mapa Interactivo de Ubicación con Realidad Aumentada

# 4. Estrategia de solución

## 4.1 Resumen de decisiones clave

- **Patrón arquitectural:** monolito — una sola app Flutter, sin backend propio por ahora.
- **Tecnología:** Flutter (un solo código base para Android/iOS).
- **Mapa del campus:** alojado de forma local (activos propios del proyecto), no un SDK externo de mapas.
- **Ruteo:** aproximado, no exacto (sin cálculo *turn-by-turn* sobre red vial real).
- **Dependencia externa:** una sola — ARCore Geospatial API, para el anclaje de RA a coordenadas GPS reales.
- **Patrones de diseño internos:** Adapter, Repository, Strategy, Observer (detalle en [ADR 0001](./adr/0001-patrones-de-diseno.md)).
- **Proceso:** ADRs para decisiones estructurales; uso de IA generativa documentado en [`ia.md`](./ia.md); equipo de 4 estudiantes, un semestre académico.

## 4.2 Decisiones tecnológicas

| Decisión | Elección | Motivación |
|---|---|---|
| Framework de la app | Flutter | Un solo código base multiplataforma, dado el tamaño del equipo (ver `restricciones.md`) |
| Backend | Ninguno por ahora | El alcance actual no lo requiere; toda la lógica corre en el cliente |
| Origen del mapa del campus | Activos locales del proyecto | Elimina la dependencia de Maps SDK, Places, Directions, Geocoding y Street View |
| Anclaje de realidad aumentada | ARCore Geospatial API | Única forma viable de anclar RA a coordenadas reales sin infraestructura propia (beacons, SLAM) — ver `restricciones.md` |

## 4.3 Decisión de descomposición de alto nivel

El patrón arquitectural (monolito) ya está resuelto y no se compara aquí
contra alternativas (ver corte anterior de este documento). Lo que se
decide en este corte es cómo se organiza el código **dentro** de ese
monolito, mediante cuatro patrones de diseño — no arquitecturales —, cada
uno resolviendo un problema puntual del proyecto:

| Problema de diseño | Patrón elegido |
|---|---|
| Aislar la única dependencia externa (ARCore Geospatial API) | Adapter |
| Servir el mapa del campus alojado localmente | Repository |
| Acceso a datos de zonas y puntos de interés | Repository |
| Ruteo aproximado dentro del mapa local | Strategy |
| Ubicación en tiempo real hacia UI y RA | Observer (`Stream` de Dart) |

El detalle de cada decisión, las alternativas descartadas y sus
consecuencias están en
[`docs/adr/0001-patrones-de-diseno.md`](./adr/0001-patrones-de-diseno.md)
(sección 9 de arc42, *Decisiones de arquitectura*). La ubicación de estos
patrones en el código fuente (`adapters/`, `repositories/`,
`strategies/`, `services/`, `features/`) se detallará como vista de
bloques de construcción en la sección 5.

## 4.4 Enfoque de solución por objetivo de calidad

| Objetivo de calidad | Escenario | Enfoque de solución | Enlace al detalle |
|---|---|---|---|
| Precisión de geolocalización y ruteo | Escenario 2 (`escenarios_calidad.md`): ruta calculada y mostrada en exteriores | Patrón **Strategy** para el cálculo de ruta aproximada sobre el mapa local, sin depender de un servicio externo de ruteo | ADR 0001, problema 4 |
| Precisión de geolocalización y ruteo | A-01 (`aspectos.md`): indicación de RA en ≤ 3 s | Patrón **Adapter** para ARCore Geospatial API + **Observer** para propagar la ubicación en tiempo real sin *polling* | ADR 0001, problemas 1 y 5 |
| Disponibilidad / confiabilidad | Escenario 3: conexión interrumpida o degradada | El mapa y las rutas ya no dependen de red (activos locales); el único punto de falla externo queda aislado detrás del adaptador de ARCore, que puede fallar de forma controlada sin caer la app | ADR 0001, problema 1 |
| Mantenibilidad | Clasificación manual de zonas fácil de actualizar (`arbol_utilidad.md`) | Patrón **Repository** (`ZonaRepository`) centraliza el punto de cambio | ADR 0001, problema 3 |
| Fidelidad de contenido | Escenario 5: validación de puntos capturados contra el espacio real | Patrón **Repository** (`MapaRepository`, `PuntoInteresRepository`) aísla el formato de los activos del mapa de quien los consume, facilitando su corrección | ADR 0001, problema 2 |
| Rendimiento | Escenario 1: carga de escena panorámica < 3 s | Pendiente — no se resuelve con un patrón de diseño de este ADR; queda para la vista de conceptos transversales (sección 8) | Por definir |
| Usabilidad | Escenario 4: usuario nuevo se ubica en < 2 min sin ayuda | Pendiente — decisión de diseño de interacción, fuera del alcance de este ADR | Por definir |
| Portabilidad | — | Cubierta por la decisión tecnológica de usar Flutter (ver 4.2) | — |

> **Nota de consistencia:** el cambio hacia mapa local y ruteo aproximado
> deja desalineados `c4_contexto.md`, `restricciones.md` y
> `ficha-problema.md`, que todavía listan Maps SDK, Directions, Geocoding
> y Places como dependencias activas. Se recomienda actualizarlos en el
> siguiente corte para que el contexto del sistema (sección 3) sea
> consistente con esta estrategia de solución.

## 4.5 Decisiones organizacionales

- El equipo (4 estudiantes) trabaja bajo el calendario de un semestre académico — ver [`ficha-problema.md`](docs/ficha-problema.md) y [`restricciones.md`](./restricciones.md).
- Las decisiones estructurales se registran como ADR en `docs/adr/`, empezando por [0001](./adr/0001-patrones-de-diseno.md).
- El uso de IA generativa como herramienta de apoyo se registra de forma trazable en [`ia.md`](docs/ia.md): qué se pidió, qué se aceptó y qué se rechazó.

## 4.6 Esqueleto ejecutable

Como resultado de esta estrategia, el repositorio incluye:

- Estructura de carpetas vacía (`adapters/`, `repositories/`,
  `strategies/`, `services/`, más una por módulo funcional dentro de
  `features/`) que impone el estilo definido en el ADR 0001, lista para
  que cada módulo empiece a llenarse sin necesidad de decidir diseño de
  nuevo.
- Arranque con un solo comando, documentado en el `README.md` del
  repositorio (`./scripts/start.sh`).
- Una prueba automatizada en verde (`test/app_smoke_test.dart`) que valida
  que la app arranca correctamente, sin lógica de negocio todavía.
