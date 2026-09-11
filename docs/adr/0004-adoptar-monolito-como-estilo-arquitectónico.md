# ADR 0004 — Adoptar monolito como estilo arquitectónico

## Estado

- **Estado**: Aceptado
- **Fecha**: 2026-09-11
- **Decisores**: Equipo MAPSUTB

## Contexto

El estilo arquitectural **monolito** se asumió como decidido desde el inicio del proyecto — así lo
dan por hecho el ADR 0001 ("El patrón arquitectural del proyecto ya está decidido: monolito") y
`docs/arc42/04_solution_strategy.adoc` ("El patrón arquitectural (monolito) ya está resuelto y no
se compara aquí contra alternativas"). Ninguno de los dos documenta **contra qué otros estilos se
comparó** ni con qué criterio — la ficha del problema pide explícitamente esa comparación y hasta
ahora no existía.

Este ADR documenta, de forma retroactiva, esa comparación: monolito frente a los otros dos estilos
arquitectónicos típicamente considerados para un proyecto de este tipo (cliente-servidor con
backend propio, y microservicios), evaluados contra el [árbol de utilidad](../arbol_utilidad.md) y
las restricciones ya registradas en
[`02_architecture_constraints.adoc`](../arc42/02_architecture_constraints.adoc): equipo de 4
estudiantes, un semestre académico, sin presupuesto institucional para infraestructura.

## Decisión

Se adopta **monolito**: una única app Flutter, sin backend propio, que resuelve toda su lógica en
el cliente y depende únicamente de dos APIs externas en la nube (Google Maps SDK y Google Geocoding
API — ver ADR 0001, ADR 0002 y ADR 0003 para el resto de decisiones estructurales derivadas de
esta).

## Matriz comparativa contra el árbol de utilidad

| Atributo de calidad | Monolito (elegido) | Cliente-servidor (backend propio) | Microservicios |
|---|---|---|---|
| Usabilidad | Favorable: todo el tiempo del equipo va a UI/UX en vez de a infraestructura de backend. | Neutral: la UX no depende del estilo, pero compite por tiempo del equipo con el mantenimiento del backend. | Neutral/desfavorable: mismo punto que cliente-servidor, agravado por la complejidad operativa adicional. |
| Rendimiento | Favorable: sin llamadas de red entre componentes internos; solo dos APIs externas puntuales. | Desfavorable: cada operación que hoy es local (ruteo, zonas, tour) pasaría por una ida y vuelta cliente-servidor adicional. | Desfavorable: a la latencia cliente-servidor se suma la latencia entre servicios internos (varios saltos de red por operación). |
| Disponibilidad / confiabilidad | Favorable: solo dos dependencias de red (Maps SDK, Geocoding); todo lo demás son activos locales que no pueden caerse. | Desfavorable: el backend propio es un punto de falla adicional que el equipo tendría que alojar y mantener disponible, sin presupuesto institucional para ello (ver restricciones organizacionales). | Muy desfavorable: cada servicio adicional es un punto de falla más, y la orquestación entre ellos (descubrimiento de servicios, resiliencia) excede lo que un equipo de 4 personas puede operar en un semestre. |
| Precisión de geolocalización y ruteo | Neutral: Dijkstra sobre el grafo peatonal local ya cumple los umbrales aceptados (≤5 s, error ≤10 m — ver `escenarios_calidad.md`). | Teóricamente favorable (permitiría algoritmos de ruteo más pesados en servidor), pero ya evaluado y descartado en `ficha_problema.md` ("Un backend propio... incrementaría la complejidad de desarrollo y el tiempo de entrega"): la ganancia no justifica el costo. | Mismo trade-off que cliente-servidor, con overhead adicional de coordinación entre servicios y sin beneficio extra sobre esa alternativa para este caso. |
| Portabilidad | Favorable: una sola pieza (la app) que compilar y portar entre Android/iOS vía Flutter. | Desfavorable: además de portar la app, hay que desplegar y mantener el backend en algún entorno. | Desfavorable: múltiples servicios que desplegar, versionar y mantener portables, muy por encima de la necesidad real del proyecto. |
| Mantenibilidad | Favorable: un solo repositorio y codebase; los patrones Repository/Adapter (ADR 0001) ya centralizan los puntos de cambio dentro de él. | Neutral/desfavorable: dos codebases (app + backend) que coordinar y versionar entre sí. | Desfavorable: cada servicio con su propio ciclo de vida, versión y monitoreo — overhead de coordinación injustificado a esta escala. |
| Fidelidad de contenido | Neutral | Neutral | Neutral — este atributo depende de la calidad del contenido capturado (fotos, clasificación de zonas), no del estilo arquitectónico. |

## Alternativas consideradas

### A. Monolito (elegida)

Una única app Flutter sin backend propio; toda la lógica corre en el cliente, con solo dos
dependencias externas puntuales (Maps SDK, Geocoding).

- **A favor:** es la opción viable dentro de las restricciones organizacionales ya documentadas —
  equipo de 4 estudiantes, un semestre, sin presupuesto para infraestructura propia (ver
  `02_architecture_constraints.adoc`). Minimiza los puntos de falla y el trabajo de mantenimiento
  fuera del código de la app.
- **En contra:** cualquier lógica que en el futuro se vuelva costosa de ejecutar en el cliente (por
  ejemplo, un ruteo más exacto tipo "turn-by-turn") requeriría revisar esta decisión.

### B. Cliente-servidor con backend propio (descartada)

Un backend propio (por ejemplo, para servir el ruteo, las zonas o el contenido del tour) del que la
app Flutter sería cliente.

- **Consecuencia de no elegirla:** un backend adicional es infraestructura que el equipo tendría
  que alojar, desplegar y mantener disponible sin presupuesto institucional asignado — condición ya
  registrada como restricción organizacional. El propio `ficha_problema.md` documenta esta tensión
  específica para el caso del ruteo y prioriza la simplicidad.

### C. Microservicios (descartada)

Varios servicios independientes (por ejemplo, ruteo, zonas, tour como servicios separados).

- **Consecuencia de no elegirla:** hereda todas las desventajas de la opción B y las agrava con
  overhead de orquestación (descubrimiento de servicios, comunicación entre ellos, despliegues
  independientes) que un equipo de 4 estudiantes no puede operar de forma realista dentro de un
  semestre. Es el estilo con menor ajuste a las restricciones organizacionales del proyecto.

## Consecuencias de la decisión

**Positivas**

- Formaliza con criterio explícito (árbol de utilidad + restricciones organizacionales) una
  decisión que hasta ahora se daba por hecha sin comparación documentada.
- Consistente con todas las decisiones estructurales ya tomadas (ADR 0001, 0002, 0003), que asumen
  monolito como punto de partida.

**Negativas / riesgos aceptados**

- Si el alcance del proyecto creciera de forma importante (por ejemplo, autenticación de usuarios,
  panel administrativo institucional para zonas), esta decisión tendría que revisarse — se
  recomienda documentar esa revisión como un ADR nuevo, no editando este.

## Referencias

- [`docs/arbol_utilidad.md`](../arbol_utilidad.md)
- [`docs/arc42/02_architecture_constraints.adoc`](../arc42/02_architecture_constraints.adoc)
- [`docs/arc42/04_solution_strategy.adoc`](../arc42/04_solution_strategy.adoc)
- [`docs/ficha_problema.md`](../ficha_problema.md)
- [`docs/adr/0001-patrones-de-diseno.md`](./0001-patrones-de-diseno.md)

