# ADR 0008 — Medir la disponibilidad del despliegue con una sonda programada en GitHub Actions

## Estado

- **Estado**: Aceptado
- **Fecha**: 2026-09-25
- **Decisores**: Equipo MAPSUTB

## Contexto

S8 pide **una métrica consultable ligada a un escenario de calidad**. El despliegue público es un
sitio estático en Firebase Hosting (ADR 0007): no hay servidor propio donde exponer un endpoint
`/metrics` ni leer logs de acceso. La analítica de uso (Measurement Protocol, ADR 0005) mide
comportamiento del usuario, no la operación del entorno.

La métrica se liga al **Escenario 6 — Disponibilidad del despliegue web**
(`docs/escenarios_calidad.md`): disponibilidad ≥ 99 % y p95 del health check < 1 s en una ventana
de 7 días.

## Decisión

Una **sonda externa programada** —
[`.github/workflows/sonda-disponibilidad.yml`](../../.github/workflows/sonda-disponibilidad.yml) +
[`scripts/sonda_disponibilidad.py`](../../scripts/sonda_disponibilidad.py) — que cada hora:

1. pide la URL pública y `health.json`, midiendo código HTTP y tiempo;
2. agrega la muestra como una línea JSON a `disponibilidad.jsonl`;
3. recalcula `resumen.json` (`disponibilidad_pct`, `latencia_p95_ms`, `cumple`) sobre 7 días;
4. publica ambos archivos en la rama `metricas`.

Consulta pública de la métrica:
`https://raw.githubusercontent.com/ISCOUTB/AS_202620_mapsutb/metricas/resumen.json`

La sonda nunca falla porque el sitio esté caído (eso es una muestra, no un error), para no poner
en rojo el pipeline por un problema del proveedor.

## Capa gratuita verificada

GitHub Actions es gratuito y sin límite de minutos en repositorios públicos; ~720 ejecuciones de
~15 s al mes. Sin tarjeta.

## Alternativas consideradas

### A. Sonda en GitHub Actions con resultados en una rama (elegida)

- **A favor:** sin cuentas ni proveedores nuevos; el código de la sonda y la métrica están
  versionados y son auditables; el histórico queda en git.
- **En contra:** los `schedule` de Actions pueden retrasarse varios minutos en horas de alta carga,
  y GitHub desactiva los workflows programados tras 60 días sin actividad en el repositorio.
  Resolución horaria: no detecta caídas de minutos.

### B. Servicio de uptime externo (p. ej. UptimeRobot, plan gratuito) (descartada)

- **Motivo técnico del descarte:** da mejor resolución (cada 5 min) y página de estado, pero la
  configuración vive en el panel de un tercero, fuera del repositorio: no es infraestructura como
  código ni se puede auditar desde el commit calificado, y agrega una cuenta más.

### C. Métricas del navegador vía GA4 (descartada)

- **Motivo técnico del descarte:** mediría carga percibida por usuarios reales, pero exige
  credenciales de GA4 en el build (ADR 0009) y la consulta requiere acceso a la propiedad de
  Analytics, no es pública.

## Consecuencias

- La métrica es pública, versionada y reproducible (`python scripts/sonda_disponibilidad.py <url> <dir>`).
- La rama `metricas` acumula un commit por hora del bot de Actions; no toca `master`.
- Si se necesita alertar (nivel sobresaliente del segundo corte), el mismo workflow puede abrir un
  issue cuando `cumple` pase a `false`.
