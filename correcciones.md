# Correcciones · Primer corte (S5)

Respuesta trazable a los hallazgos publicados en `revisiones/2026-2/AS_202620_mapsutb/` (S1 a S4)
y a la revisión preliminar de S5, según exige `fichas/semana-05-corte1.md` del kit de revisión
[`ISCOUTB/AS_202620_feedback`](https://github.com/ISCOUTB/AS_202620_feedback).

Cada fila cita la ruta, el commit o la ausencia real que permite verificarla. Donde el hallazgo
sigue abierto, se declara así: este documento es un índice de verificación, no evidencia por sí
mismo, y una autoevaluación de "Cumple" sin evidencia no cuenta.

## Corrección más urgente: etiqueta `corte-1`

**Hallazgo (S2, S3, S4 y preliminar S5):** la etiqueta `corte-1` apuntaba al commit de la semana 1
(`7e56ad3`, 2026-08-09, "ficha del problema"), señalado en cuatro revisiones consecutivas sin
corregirse.

**Acción realizada:** se movió la etiqueta al último commit real anterior al cierre de S5
(2026-09-07T05:00:00Z): `f40775d` (2026-09-06T22:35:28-05:00, "Create FeedbackS4"), que sí
contiene el corte vertical, arc42 y C4 vigentes. Se hizo `git tag -f corte-1 f40775d` y
`git push origin corte-1 --force` el 2026-09-07.

**Estado:** corregida. **Nota:** esta corrección se aplicó después del horario habitual de la
pasada definitiva de S5 (lunes 06:00 COT); si la revisión publicada ya corrió sobre la etiqueta
vieja, hace falta pedir un re-barrido al docente — moverla no reescribe una evaluación ya
publicada.

## Hallazgos de S1

| Hallazgo | Acción / motivo | Evidencia | Estado |
|---|---|---|---|
| Sin tensiones de calidad declaradas en la ficha del problema | No se agregó una sección de tensiones a `docs/ficha-problema.md` | — | Pendiente |
| Estructura no montada en S1 (`docs/arc42/`, `docs/adr/`, `docs/c4/`) | Se creó `docs/adr/` en S3 y `docs/Arc42/`, `docs/C4/` en S4, pero con mayúsculas en el nombre de carpeta, no según la convención en minúsculas | `git ls-tree -r --name-only corte-1` → `docs/Arc42/`, `docs/C4/`, `docs/adr/` | Parcial |
| Contribución: 2 de 4 integrantes sin aparición al cierre S1 (incluida Isabel Sofia Paez Matallana) | Sin acción distinta a seguir trabajando; la cuenta de Isabel apareció más adelante | `git shortlog -sne HEAD` en `corte-1`: `i-matallana` con commits acumulados (ADR 0002, conversión adoc→md) | Corregida (para el estado actual; no aplica retroactivamente a la nota de S1, que no se reabre) |

## Hallazgos de S2

| Hallazgo | Acción / motivo | Evidencia | Estado |
|---|---|---|---|
| `docs/arc42.md` como archivo único en vez de `docs/arc42/`; sin `docs/adr/` ni `docs/c4/` | Se migró a AsciiDoc por secciones en `docs/Arc42/01..12` y diagramas en `docs/C4/C1-C3.md`, pero con mayúsculas en la carpeta | `docs/Arc42/01_introduction_and_goals.adoc` … `12_glossary.adoc` en `corte-1` | Parcial (contenido presente, nombre de carpeta sigue sin convención) |
| Enlace roto `docs/escenarios_calidad.md` → `./02_arbol_utilidad.md` | No verificado en esta pasada si se corrigió el enlace | — | Pendiente de confirmar |
| Árbol de utilidad sin impacto/riesgo ni vínculo a los escenarios | Sin acción documentada | `docs/arbol_utilidad.md` | Pendiente |
| Escenarios sin formato de seis partes | Sin acción documentada fuera del escenario A-01 de `docs/aspectos.md` | `docs/escenarios_calidad.md` | Pendiente |
| `docs/ia.md` sin entradas nuevas en S2 | Se agregaron entradas fechadas 28/08, 29/08 y 30/08 sobre la decisión de descartar ARCore, pero corresponden a trabajo de S3/S4, no cierran retroactivamente el hallazgo de S2 | `docs/ia.md` en `corte-1` | No aplica retroactivo; ver S3/S4 |

## Hallazgos de S3

| Hallazgo | Acción / motivo | Evidencia | Estado |
|---|---|---|---|
| Sin matriz comparativa de los tres estilos arquitectónicos contra el árbol de utilidad | El ADR 0001 declina explícitamente esa comparación (compara patrones de diseño, no estilos); no se agregó la matriz que pide la ficha | `docs/adr/0001-patrones-de-diseno.md` | Pendiente (rechazada de facto, sin justificación técnica explícita en el ADR) |
| `docs/aspectos.md` desactualizado ("Sin ADR aún"), sin enlace al ADR 0001; alcance de A-01 sigue describiendo realidad aumentada ya descartada | No se tocó `docs/aspectos.md` desde su versión inicial | `git show corte-1:docs/aspectos.md` — fila A-01 idéntica a S1: "Por definir", "Sin ADR aún", "Aún no iniciado" | **Pendiente, sin corregir** |
| Estructura de paquetes del ADR no materializada (`lib/` solo tenía `main.dart`) | Se crearon y llenaron `lib/repositories/zona_repository.dart`, `lib/services/ubicacion_service.dart`, `lib/features/zonas/`, `lib/features/mapas_ruteo/` | `git ls-tree -r --name-only corte-1 \| grep ^lib/` | Corregida |
| `docs/ia.md` sin entradas del trabajo de S3 | Se agregaron entradas 28-30/08 sobre la decisión de arquitectura y APIs | `docs/ia.md` en `corte-1`, entradas 28/08, 29/08, 30/08 | Corregida |
| Prueba de humo sin CI ni evidencia de verde | Sin workflow agregado | `git ls-tree -r --name-only corte-1 \| grep .github/workflows` → vacío | **Pendiente, sin corregir** |
| Isabel Sofia Paez Matallana sin aparición; toda la S3 la empujó una sola cuenta | Ver corrección de S1 | `i-matallana` en el historial acumulado | Corregida (para el estado actual) |

## Hallazgos de S4

| Hallazgo | Acción / motivo | Evidencia | Estado |
|---|---|---|---|
| `docs/Arc42/` y `docs/C4/` con mayúsculas | Sin renombrar | árbol de `corte-1` | Pendiente |
| Sección 05 de arc42 conserva plantilla `arc42help` sin sustituir | No verificado en esta pasada si se limpió | `docs/Arc42/05_building_block_view.md` | Pendiente de confirmar |
| Contenedores C2 "Contenido Panorámico 360°" y "Plano del Campus" sin código ni assets | No se agregó código ni assets para esos contenedores | `docs/C4/C2.md` vs. árbol de `corte-1` | Pendiente |
| Fila A-01 de `docs/aspectos.md` desactualizada y con celdas sin enlaces | Sin corregir (ver hallazgo de S3, mismo archivo, sin cambios) | `docs/aspectos.md` | **Pendiente, sin corregir** |
| ADR 0001 editado tras su aceptación en vez de crear ADR 0002 para el cambio de alcance | Se creó `docs/adr/0002.md`, pero (a) el nombre no sigue la convención `NNNN-titulo-en-kebab-case.md` y (b) el ADR 0001 se conserva editado, no restaurado a su versión aceptada | `git ls-tree -r --name-only corte-1 \| grep adr` → `0002.md` sin título | Parcial (existe un ADR nuevo, pero con nombre fuera de convención y sin revertir la edición del 0001) |
| Sin etiqueta `corte-1` (o mal ubicada) | Ver corrección arriba | tag `corte-1` → `f40775d` | Corregida (2026-09-07, ver nota de sincronización arriba) |
| Sin CI con runs públicos | Sin workflow agregado | `.github/workflows/` ausente en `corte-1` | **Pendiente, sin corregir** |

## Tabla obligatoria de seguimiento de correcciones

| Origen | Hallazgo o fila | Respuesta en `correcciones.md` | Evidencia contrastada | Resultado |
|---|---|---|---|---|
| S2/S3/S4/S5 preliminar | Etiqueta `corte-1` sobre el commit de S1 | Movida a `f40775d` y empujada | `git log -1 --format='%H %cI %s' corte-1` | Verificada |
| S1/S3 | Contribución/aparición de Isabel Sofia Paez Matallana | Aparece como `i-matallana` con commits acumulados | `git shortlog -sne HEAD` | Verificada |
| S3 | Estructura de paquetes del ADR no materializada | `lib/repositories/`, `lib/services/`, `lib/features/` con código real | `git ls-tree -r --name-only corte-1` | Verificada |
| S1/S2/S4 | Nombres de carpeta `docs/arc42/` y `docs/c4/` fuera de convención (mayúsculas) | Sin renombrar | árbol de `corte-1` | Pendiente |
| S3/S4 | `docs/aspectos.md` desactualizado, sin ADR enlazado, alcance de RA ya descartado | Sin editar desde S1 | `git show corte-1:docs/aspectos.md` | Pendiente |
| S3/S4 | Sin CI ni prueba en verde verificable | Sin workflow agregado | `.github/workflows/` ausente | Pendiente |
| S3 | Sin matriz comparativa de estilos arquitectónicos | ADR 0001 declina la comparación sin justificación técnica explícita | `docs/adr/0001-patrones-de-diseno.md` | Rechazada sin fundamento explícito |
| S4 | ADR 0001 editado tras aceptarse; ADR 0002 con nombre fuera de convención | `docs/adr/0002.md` creado, pero mal nombrado; 0001 sigue editado | árbol de `corte-1` | Parcial |
| S4 | Contenedores C2 sin código (panorámicas, plano) | Sin implementar | `docs/C4/C2.md` vs. árbol | Pendiente |

## Resumen honesto

De las correcciones anunciadas o exigibles en S1-S4, se cerraron con evidencia real: la etiqueta
`corte-1`, la aparición de todos los integrantes en el historial, y la estructura de paquetes de
`lib/` según el ADR. Las demás —nombres de carpeta en minúscula, `docs/aspectos.md`, CI/pruebas en
verde, la matriz de estilos, y la convención de nombres de ADR— siguen abiertas y se declaran así
sin maquillaje, porque una fila sin evidencia real se marca "No cumple" de todas formas y una
afirmación falsa aquí es peor que dejarla pendiente.
