# Evidencia S13 · Modelado de amenazas y plan de mitigación

Entregada el **2026-11-11**, después del cierre de la semana 13 (2026-11-01). El estado que cerró
la semana (`03e331d`) no tenía nada de esto. Lo que sigue es trabajo posterior al cierre, en la
rama `s12-s14`, fusionada a `master`.

## Matriz de la ficha

| Criterio | Dónde está |
|---|---|
| Tabla de amenazas anclada en elementos del C4 | [`docs/modelo-amenazas.md`](./modelo-amenazas.md): 15 amenazas (T-01 a T-14 y T-04b). La columna «Elemento afectado» de cada una nombra un contenedor o sistema externo de [C2](./c4/C2.md) o una pieza de despliegue de [arc42 §7](./arc42/07_deployment_view.adoc); la tabla «Elementos analizados» los enumera con su frontera de confianza. No es una lista OWASP genérica: cada amenaza cita el archivo o la configuración donde ocurre. |
| Priorización por probabilidad e impacto | Columnas P, I y Prioridad (P×I, en escala del 1 al 3). La tabla está ordenada: 2 altas, 9 medias y 4 bajas. |
| Mitigación con dueño y estado | Columnas «Mitigación asignada», «Dueño» y «Estado». Los dueños se reparten por área entre los cuatro integrantes. Estados: 8 hechas (T-04 con la CSP aún en observación), 4 pendientes (T-04b, T-08, T-09 y T-12) y 4 aceptadas, de las cuales T-05 queda hecha en lo propio y con riesgo residual aceptado. |
| El plan ataca primero lo priorizado | Sección [«Plan: qué se atacó primero»](./modelo-amenazas.md#plan-qué-se-atacó-primero). Las dos altas (T-01 y T-02) se hicieron primero y quedaron en el ADR 0020. Ninguna baja se trabajó antes que una alta o media. Las medias pendientes (T-08 y T-09) requieren permisos de administración de GitHub y de Google Cloud, no un commit, y quedan asignadas con su mitigación parcial. |
| Análisis de dependencias ejecutado en el pipeline | Paso «Análisis de dependencias — OSV-Scanner» de [`ci.yml`](../.github/workflows/ci.yml): OSV-Scanner v2.7.0, verificado por SHA-256, sobre `pubspec.lock`. Falla el pipeline si encuentra una vulnerabilidad. Run en verde: [43034881403](https://github.com/ISCOUTB/AS_202620_mapsutb/actions/runs/43034881403). Además, [`dependabot.yml`](../.github/dependabot.yml) cubre pub y GitHub Actions. |
| Hallazgos revisados y decididos | [«Análisis de dependencias»](./modelo-amenazas.md#análisis-de-dependencias): 85 paquetes y 0 vulnerabilidades conocidas. Cada hallazgo de `flutter pub outdated` tiene su decisión: actualizar `geolocator`, evaluar quitar `cupertino_icons` (sin uso), dejar las transitivas al ciclo de Dependabot y aceptar las fijadas por el SDK. Las acciones atrasadas quedan fijadas por SHA. |
| Privacidad: datos personales tratados y su base | [«Privacidad»](./modelo-amenazas.md#privacidad-qué-datos-personales-se-tratan-y-con-qué-base), contrastada con el código. El `git grep` de la ficha no encuentra modelos con nombre, correo ni documento. Hay cinco tratamientos: posición GPS, dirección derivada (apagada), IP y navegador ante terceros, eventos de uso (apagados) y recorridos de campo. Cada uno con su base (Ley 1581 de 2012) y su conservación. El aviso para el usuario está en el [README](../README.md#privacidad). |
| Riesgos del componente generativo | No aplica: no hay componente generativo ([ADR 0014](./adr/0014-sin-componente-generativo.md)). Está declarado en el modelo. |
| arc42 §8: arquitectura de seguridad | [`08_concepts.adoc`](./arc42/08_concepts.adoc#arquitectura-de-seguridad), sección «Arquitectura de seguridad»: superficie y fronteras de confianza, con el control de cada una. |
| arc42 §11: amenazas aceptadas y su motivo | [`11_technical_risks.adoc`](./arc42/11_technical_risks.adoc#amenazas-aceptadas), sección «Amenazas de seguridad aceptadas»: T-05, T-10, T-11 y T-13. |
| ADR de las mitigaciones que cambian la estructura | [ADR 0020](./adr/0020-mitigaciones-de-seguridad-estructurales.md): acciones fijadas por SHA, build público sin `GA_API_SECRET`, OSV-Scanner bloqueante y cabeceras de seguridad. Compara con imponer la CSP de entrada, con un proxy de analítica, con fijar por versión y con Dependabot solo. |

## Qué cambió en el sistema

- **Seis workflows** con las acciones fijadas por commit (T-01).
- **`deploy.yml`:**
  - guardia que falla si `GA_API_SECRET` existe (T-02);
  - verificación de las cabeceras de seguridad después de publicar (T-04).
- **`ci.yml`:** OSV-Scanner bloqueante y `flutter pub outdated` informativo (T-03).
- **`firebase.json`:** `nosniff`, `X-Frame-Options`, `Referrer-Policy`, `Permissions-Policy` y CSP
  en report-only (T-04, T-05 y T-07).
- **`.github/dependabot.yml`** nuevo (T-01 y T-03).
- **README:** sección «Privacidad».

## Secretos

El 2026-11-11 se barrió el historial completo: 1.320 commits de todas las ramas. Se buscaron claves
de Google, llaves privadas, `private_key`, `api_secret=`, tokens de SonarCloud y de GitHub, y
measurement ids de GA4, con **0 coincidencias**. Los secrets del repositorio son solo
`FIREBASE_SERVICE_ACCOUNT` y `SONAR_TOKEN`; los de Google Maps y GA4 no están configurados, lo que
coincide con el bundle publicado. Dos hallazgos de configuración quedan como amenazas pendientes,
con dueño:

- la credencial de Firebase es un secret de repositorio y no del environment (T-08);
- `master` no tiene protección de rama (T-09).
