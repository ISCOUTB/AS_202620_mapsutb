# ADR 0006 — Reajuste de los límites de contexto: Zona, Espacio y punto de interés

## Estado

Aceptado (2026-09-21).

## Contexto

La entrega de la Semana 6 (`dominio_y_modularidad.md`) mapeó el dominio de MAPSUTB en
cuatro contextos delimitados — **Catálogo de lugares**, **Posicionamiento**, **Ruteo** y
**Tour 360°** — y detectó dos no conformidades de nombres que cruzan ese mapa:

1. El glosario (`docs/arc42/12_glossary.adoc`) define **Zona** como *"clasificación manual
   de un espacio del campus (por ejemplo, salón, laboratorio u oficina)"*. En el código,
   sin embargo, `Zona` (`lib/models/zona.dart`) es el nivel **superior** de la jerarquía
   (`tipo` ∈ `edificio`, `cafeteria`, `parqueadero`, `zona_comun`) y contiene una lista de
   `Espacio` (`lib/models/espacio.dart`), cuyo campo `tipo` sí acepta `salon`,
   `laboratorio`, `oficina`. Lo que el glosario llama "Zona" es, en el código, la clase
   `Espacio`.
2. "Punto de interés" aparece en ocho documentos y en el propio C4 de componentes como un
   componente compuesto — `ZonaRepository / PuntoInteresRepository`
   (`docs/arc42/05_building_block_view.md`) — pero no existe ninguna clase `PuntoDeInteres`
   ni `PuntoInteresRepository` en `lib/models/` ni en `lib/repositories/`. El glosario lo
   define como *"ubicación específica dentro de una zona, con coordenadas propias"*, pero
   ni `Espacio` ni `Salon` tienen campo de coordenadas — solo `Zona` lo tiene — y el uso en
   la práctica es inconsistente (`aspectos.md` usa "ZONA T", un `Zona` completo, como
   ejemplo de punto de interés).

Este ADR no revierte ni reemplaza al ADR 0001 ni al ADR 0002 (que siguen vigentes en su
decisión de patrones: Repository, Adapter, Observer). Fija el límite de nombres del
contexto **Catálogo de lugares** sobre el que esos ADR ya operan, y por eso se registra
como una decisión nueva en vez de editar un ADR ya aceptado.

## Decisión

1. **"Zona" se redefine al nivel real del código**: el nodo superior de la jerarquía del
   campus (`tipo` ∈ `edificio`, `cafeteria`, `parqueadero`, `zona_comun`), con `pisos` y
   `espacios` opcionales. El glosario incorpora una entrada propia para **"Espacio"** (el
   nivel intermedio/hoja: `salon`, `laboratorio`, `oficina`, contenido por un `Piso` o
   directamente por una `Zona`), que hasta ahora no existía.
2. **"Punto de interés" deja de ser un término independiente** y pasa a ser el nombre de
   uso común para "el destino navegable concreto que un usuario selecciona" — en el código
   esto es siempre un `Espacio` o un `Salon` (el nivel hoja), nunca un `Zona` completo. El
   glosario documenta esta equivalencia en vez de mantener una tercera clase fantasma.
3. **Se elimina el componente fantasma `PuntoInteresRepository`** de todos los diagramas y
   vistas descriptivas (C4, arc42 §4, §5, §6). El componente real, único y ya implementado
   es `ZonaRepository` (`lib/repositories/zona_repository.dart`): sirve tanto `Zona` como
   `Espacio`/`Salon` desde el mismo archivo `assets/data/zonas.json`, así que no hay dos
   repositorios ni dos escritores — solo un nombre que sobraba en la documentación.
4. El mapa de contextos de la Semana 6 se traslada a `docs/arc42/08_concepts.adoc` como
   concepto transversal de dominio, y cada contexto queda enlazado a su aspecto en
   `docs/aspectos.md` cuando existe uno (ver esa sección para el detalle del enlace y los
   contextos que aún no tienen aspecto propio).

## Alternativas consideradas

### A. Mantener "Zona" y "Punto de interés" como están y solo documentar la inconsistencia (descartada)

Es lo que hacía la entrega de la Semana 6: señalar la no conformidad sin resolverla.
Se descarta como decisión final porque el problema no es de documentación sino de
vocabulario compartido: mientras el glosario y el código no usen los mismos nombres, la
tabla de aspectos, el C4 y el código seguirán señalando componentes que no existen.

### B. Crear la clase `PuntoDeInteres` en el código para que coincida con el glosario (descartada)

Alinear el código al glosario en vez del glosario al código. Se descarta porque
duplicaría el modelo: `PuntoDeInteres` tendría los mismos campos que `Espacio`/`Salon`
(nombre, tipo, coordenadas heredadas de su `Zona`), y el equipo ya declaró en la no
conformidad #3 de la Semana 6 que evitar dos escritores sobre el mismo árbol de datos es
un objetivo explícito para el corte 2.

### C. Definir "punto de interés" como sinónimo de "Zona" en vez de "Espacio" (descartada)

Es la lectura que sugiere el ejemplo "ZONA T" en `aspectos.md`. Se descarta porque el
requisito RF-01 pide guiar al usuario hacia un destino navegable concreto (un salón, una
oficina), y `Zona` puede contener varios `Espacio` — usarla como punto de interés dejaría
sin resolver a cuál de sus espacios internos apunta la ruta.

## Consecuencias de la decisión

**Positivas**

- El glosario, el C4 y el código usan el mismo vocabulario para el contexto Catálogo de
  lugares; deja de haber un componente (`PuntoInteresRepository`) documentado que no
  existe en `lib/`.
- La tabla de aspectos y el mapa de contextos de arc42 §8 quedan enlazados explícitamente,
  cerrando el pendiente de trazabilidad de la Semana 6.
- Ruteo y Tour 360° (corte 2) heredan una definición sin ambigüedad de "punto de interés"
  antes de escribir `MapaRepository` y `TourRepository` contra ella.

**Negativas / riesgo aceptado**

- Hay que corregir manualmente las ocho referencias documentales a
  `ZonaRepository/PuntoInteresRepository` (05_building_block_view.md, 06_runtime_view.md,
  04_solution_strategy.adoc, C3.md, glosario) para que no queden desincronizadas con esta
  decisión.
- Los ADR 0001 y 0002, que nombran `PuntoInteresRepository` en su texto original, no se
  editan (quedan como registro histórico de la decisión que tomaron en su momento); este
  ADR es la referencia vigente para el nombre correcto del componente.

## Referencias

- [`dominio_y_modularidad.md`](../../dominio_y_modularidad.md) — mapa de contextos y no
  conformidades #1 y #2 que originan esta decisión.
- [`docs/arc42/08_concepts.adoc`](../arc42/08_concepts.adoc) — mapa de contextos trasladado
  aquí como concepto transversal.
- [`docs/aspectos.md`](../aspectos.md) — enlace entre cada contexto y su aspecto.
- [ADR 0001](0001-patrones-de-diseno.md), [ADR 0002](0002-patrones-de-diseno-sin-realidad-aumentada.md) —
  deciden Repository/Adapter/Observer; no se editan por esta decisión.
