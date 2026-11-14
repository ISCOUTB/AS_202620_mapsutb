# Evidencia S14 · Medición de atributos de calidad

Entregada el **2026-11-11**, después del cierre de la semana 14 (2026-11-08). La medición usa
muestras tomadas durante las seis semanas anteriores, pero el análisis, los artefactos y la
incorporación de la revisión entre pares son de esta fecha.

## Escenario medido y su umbral

**Escenario 6: disponibilidad del despliegue web** (DI-03 en
[arc42 §10](./arc42/10_quality_requirements.adoc#esc-disponibilidad) y en
[`escenarios_calidad.md`](./escenarios_calidad.md)). Es el umbral declarado desde la S8, sin
cambios:

> Un usuario o evaluador fuera de la red de la universidad abre la URL pública en cualquier
> momento: el sitio y `/health.json` responden HTTP 200, con **disponibilidad ≥ 99 %** y **p95 del
> health check menor a 1 s**, en una **ventana de 7 días**.

Se eligió este escenario y no el 2, que se midió en la S9 y S10, porque es el único que se puede
medir sobre el **entorno desplegado** con varias repeticiones independientes. Además, el docente
pide que el proyecto final se demuestre sobre el sistema publicado.

## Procedimiento

Hay dos mediciones, las dos sobre `https://mapsutb.web.app/`:

| | Medición A: sonda (principal) | Medición B: cliente (complementaria) |
|---|---|---|
| Herramienta | [`sonda_disponibilidad.py`](../scripts/sonda_disponibilidad.py), lanzada por [`sonda-disponibilidad.yml`](../.github/workflows/sonda-disponibilidad.yml) (ADR 0008), más [`analizar_disponibilidad.py`](../scripts/medicion/analizar_disponibilidad.py) para el análisis | [`medir_cliente.py`](../scripts/medicion/medir_cliente.py) |
| Carga | 1 petición a `/` y 1 a `/health.json` cada hora (`cron: 17 * * * *`) | 60 pares de peticiones secuenciales, con 2 s de pausa |
| Desde dónde | Ejecutores de GitHub Actions (centro de datos de GitHub, fuera de Colombia) | Computador de un integrante, Windows 11, fuera de GitHub |
| Periodo | 2026-09-30 00:00 → 2026-11-11 00:00 UTC | 2026-11-11, 13:58:44 → 14:01:02 UTC |
| Repeticiones | **6 ventanas consecutivas de 7 días** (984 muestras) | 60 muestras |
| Conexión | Nueva en cada petición (`urllib`, tiempo límite de 15 s) | Nueva en cada petición, `Cache-Control: no-cache`; incluye DNS, TCP y TLS |
| Cálculo | Por ventana: disponibilidad = muestras con los dos 200 / muestras; p95 por rango más cercano sobre **todas** las muestras, también las fallidas | p50, p95 y máximo |

Al analizar las muestras corrigí un sesgo: `resumen.json` calcula el p95 solo sobre las muestras
disponibles. Así, un tiempo agotado de 15 s desaparecería del percentil en vez de empeorarlo. El
análisis de la S14 lo incluye. En este periodo no cambia el resultado porque no hubo ninguna caída,
pero el método queda correcto. Las pruebas del script
([`test_analizar_disponibilidad.py`](../scripts/medicion/test_analizar_disponibilidad.py)) cubren
ese caso y corren en el CI (paso «Pruebas del análisis de disponibilidad (S14)»).

### Cómo repetirla

```bash
git fetch origin metricas
git show origin/metricas:disponibilidad.jsonl > disponibilidad.jsonl
python scripts/medicion/analizar_disponibilidad.py disponibilidad.jsonl --hasta 2026-11-11
python scripts/medicion/medir_cliente.py https://mapsutb.web.app/ 60 cliente.jsonl --pausa 2
```

Los artefactos de esta medición están versionados en [`docs/medicion/`](./medicion/):

- `disponibilidad-2026-11-11.jsonl`: instantánea de las 1.095 muestras de la sonda;
- `s14-sonda-ventanas.txt`: salida del análisis;
- `s14-cliente-2026-11-11.jsonl` y `s14-cliente-resumen.json`: las 60 muestras del cliente y su
  resumen.

Con `--hasta 2026-11-11` y la instantánea, cualquiera obtiene los mismos números. Con la rama
`metricas` viva obtiene ventanas más recientes.

## Resultado frente al umbral

**Medición A, por ventana** (salida de `analizar_disponibilidad.py`):

| Ventana (UTC) | Muestras / esperadas | Caídas | Disponibilidad | p95 health | máx. health | p95 sitio | ¿Cumple? |
|---|---|---|---|---|---|---|---|
| 2026-09-30 → 2026-10-07 | 150 / 168 | 0 | 100 % | 194 ms | 295 ms | 278 ms | sí |
| 2026-10-07 → 2026-10-14 | 167 / 168 | 0 | 100 % | 208 ms | 815 ms | 244 ms | sí |
| 2026-10-14 → 2026-10-21 | 168 / 168 | 0 | 100 % | 265 ms | 972 ms | 254 ms | sí |
| 2026-10-21 → 2026-10-28 | 167 / 168 | 0 | 100 % | 199 ms | 344 ms | 230 ms | sí |
| 2026-10-28 → 2026-11-04 | 167 / 168 | 0 | 100 % | 213 ms | 655 ms | 234 ms | sí |
| 2026-11-04 → 2026-11-11 | 165 / 168 | 0 | 100 % | 209 ms | 330 ms | 200 ms | sí |
| **Periodo completo** | **984 / 1.008** | **0** | **100 %** | **212 ms** | **972 ms** | **249 ms** | **sí** |

**Medición B:** 60 de 60 disponibles; health p50 203 ms, **p95 266 ms**, máximo 312 ms; página
principal p50 110 ms, p95 141 ms.

| Medida | Umbral | Obtenido | Conclusión |
|---|---|---|---|
| Disponibilidad en 7 días | ≥ 99 % | 100 % en las 6 ventanas | **Cumple** |
| p95 del health en 7 días | < 1.000 ms | Entre 194 y 265 ms por ventana (A); 266 ms (B) | **Cumple**, con un margen de casi 4× |

**Conclusión: el Escenario 6 se cumple**, con estas condiciones:

- **Resolución de una hora.** Una caída de menos de una hora entre dos muestras no se vería. Con
  168 muestras por ventana, cada muestra perdida equivale a 0,6 puntos de disponibilidad; el umbral
  del 99 % tolera solo una muestra fallida por semana.
- **Hay huecos.** Faltan 24 de las 1.008 muestras esperadas, 18 de ellas en la primera semana.
  Las ejecuciones programadas de GitHub no garantizan la hora, y eso es una limitación del
  instrumento, no del sitio. Se asume que en esas horas no hubo caídas sin registrar.
- **El peor tiempo observado** fue 972 ms, el 2026-10-20 a la 01:00 UTC. Estuvo cerca del umbral, pero fue una
  muestra aislada y no movió el p95.

## Entorno de la medición

**Desplegado**, en los dos casos: el sitio público de Firebase Hosting, el mismo que usa un
evaluador, y no un servidor local. Lo que cambia es el punto de origen. A mide desde la red de
GitHub y B desde el computador de un integrante. Las dos coinciden en el orden de magnitud: p95 de
212 y 266 ms. En B, el health (`no-store`, que va hasta el origen de Firebase) es más lento que la
página principal (`no-cache`, que la CDN revalida). Es lo esperado según la política de caché
(arc42 §8).

**No se midió desde la red móvil del campus.** Queda como lo que se ignora (arc42 §11).

## Revisión entre pares

Se incorporó a [arc42 §11, «Lo que señaló la revisión entre pares»](./arc42/11_technical_risks.adoc#revision-pares),
con el estado de cada punto:

| Señalamiento | Estado |
|---|---|
| El proyecto está bien | No pide cambios |
| Crear una pequeña base de datos para actualizar ubicaciones o nombres | **Asumido**: choca con el ADR 0018; el motivo y el disparador de revisión están en §11 |
| Desplegar en Dokploy | **Pendiente**: es el camino a la URL bajo `iscoutb.dev`; necesita un ADR antes del final |

La misma sección separa lo que se **conoce**, lo que se **asume** y lo que se **ignora** después
de la medición.

## Tabla de aspectos

El escenario medido no tenía aspecto propio. Se agregó **A-05, publicación y disponibilidad del
sitio**, en [`docs/aspectos.md`](./aspectos.md). Su columna de evidencia apunta a esta medición, y
la fila es recorrible: requisito, C4 y §7, ADR 0007 a 0010, 0015 y 0020, código, pruebas y
evidencia. La [§10](./arc42/10_quality_requirements.adoc) también registra el resultado en DI-03.

## Matriz de la ficha

| Criterio | Dónde está |
|---|---|
| Escenario medido con el umbral de arc42 §10 | [Escenario medido](#escenario-medido-y-su-umbral): DI-03, ≥ 99 % y p95 < 1 s en 7 días, sin cambio de umbral |
| Procedimiento: herramienta, carga, repeticiones | [Procedimiento](#procedimiento): 6 ventanas (984 muestras) y 60 muestras de cliente |
| Medición reproducible | Scripts en `scripts/medicion/`, datos en `docs/medicion/` y comandos en [Cómo repetirla](#cómo-repetirla) |
| Resultado frente al umbral, con conclusión | [Resultado](#resultado-frente-al-umbral): cumple, con las condiciones de resolución y huecos |
| Entorno declarado | [Entorno](#entorno-de-la-medición): desplegado, desde GitHub Actions y desde un cliente |
| arc42 §11 con lo señalado por los pares | [`11_technical_risks.adoc`](./arc42/11_technical_risks.adoc#revision-pares) |
| Estado de cada señalamiento | Columna «Estado»: asumido o pendiente |
| Evidencia del aspecto medido | Fila A-05 de [`aspectos.md`](./aspectos.md) |

## Antes del proyecto final

Lista corta de lo que falta, según la ficha S16:

1. **URL bajo `iscoutb.dev`:** decidir sobre Dokploy y escribir su ADR (pendiente de los pares y
   del docente).
2. **C4 niveles 1 a 3:** revisar que C1, C2 y C3 coincidan con el código actual. C2 no dibuja el
   pipeline ni la sonda, que viven en §7.
3. **Tabla de aspectos de punta a punta:** A-04 (tour) sigue diferida y A-01 tiene pendiente la
   medición con GPS real en el campus (RT-08).
4. **Amenazas pendientes T-08 y T-09:** proteger `master` y mover la credencial de Firebase. Las
   dos requieren permisos de administración.
5. **Imponer la CSP (T-04b),** después de revisar la consola del sitio publicado.
