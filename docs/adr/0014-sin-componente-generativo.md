# ADR 0014 — No incorporar un componente generativo en la app (por ahora)

## Estado

- **Estado**: Aceptado
- **Fecha**: 2026-10-01 (propuesto) · 2026-10-02 (aceptado por el equipo)
- **Decisores**: Equipo MAPSUTB

## Contexto

La evidencia S9 pide, si el sistema incorpora un componente generativo (un modelo de lenguaje o
similar), su evaluación, costo por operación, latencia y comportamiento ante fallo; y si se
decide no incorporarlo, un ADR que lo justifique.

La IA generativa se usa en el **desarrollo** de MAPSUTB (registrado en `docs/ia.md`), pero la
pregunta aquí es si la **app** debe llevar un componente generativo en ejecución. Casos de uso
posibles: búsqueda en lenguaje natural ("¿dónde queda el laboratorio de química?"), indicaciones
de ruta redactadas o un asistente conversacional para visitantes.

## Decisión

**No incorporar un componente generativo en esta versión.** El equipo revisó la propuesta el
2026-10-02 y la confirmó con los motivos de abajo.

## Motivos, contra las restricciones del proyecto

- **Costo y tarjeta (arc42 §2):** las API de modelos de lenguaje cobran por uso y exigen un medio
  de pago; el proyecto opera en USD 0 y sin tarjeta.
- **Funcionamiento sin conexión:** el catálogo y el ruteo funcionan sin red; un modelo remoto no.
- **Los casos de uso se resuelven sin generación:** la búsqueda de un salón es una búsqueda de
  texto sobre `zonas.json` (85 espacios), y las indicaciones de ruta salen del grafo (tramos,
  escaleras, distancias), con resultados exactos y verificables.
- **Riesgo de respuestas inventadas:** un asistente que indique un salón o un camino equivocado
  incumple el Escenario 4 (llegar sin ayuda en menos de 2 minutos).

## Alternativas consideradas

- **Asistente conversacional con un modelo remoto:** descartado por costo, red y respuestas
  no verificables.
- **Modelo pequeño en el dispositivo:** descartado por tamaño de la app y esfuerzo frente al
  beneficio.

## Consecuencias

- La app no tiene contenedor externo de IA en el C4 nivel 2.
- Se reevalúa si aparece un caso de uso que la búsqueda de texto y el grafo no cubran; en ese
  caso, un ADR nuevo debe incluir evaluación, costo por operación, latencia y comportamiento ante
  fallo del proveedor.
