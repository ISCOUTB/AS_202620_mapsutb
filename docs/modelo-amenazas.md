# Modelo de amenazas y plan de mitigación (S13)

Hecho el 2026-11-11, después del cierre de la semana 13 (2026-11-01). Se usa STRIDE sobre el **C4
del propio sistema**, con dos fuentes:

- los contenedores y relaciones de [C2](./c4/C2.md);
- las piezas de despliegue de [arc42 §7](./arc42/07_deployment_view.adoc): pipeline, secretos y
  Firebase Hosting.

Todo lo que aquí se da por **hecho** quedó verificado en el código, en la configuración o en el
sitio publicado ese mismo día. La arquitectura de seguridad que resulta está en
[arc42 §8](./arc42/08_concepts.adoc#arquitectura-de-seguridad). Las amenazas aceptadas, con su
motivo, están en [arc42 §11](./arc42/11_technical_risks.adoc#amenazas-aceptadas). Las mitigaciones
que cambian la estructura tienen su [ADR 0020](./adr/0020-mitigaciones-de-seguridad-estructurales.md).

## Elementos analizados y fronteras de confianza

| Elemento (C4 / arc42 §7) | Qué es | Frontera de confianza |
|---|---|---|
| **App** (C2, `Container`) | Sitio web Flutter servido por Firebase Hosting; corre en el navegador del usuario | Navegador del usuario ↔ Internet |
| **Datos de zonas** y **Plano del campus** (C2, `ContainerDb`) | `zonas.json` y `grafo.json`, de solo lectura, publicados con la app (ADR 0018) | Solo cambian con un despliegue |
| **Sensor de ubicación** (C2, `System_Ext`) | GPS del dispositivo, vía `geolocator` | Permiso del navegador |
| **OpenStreetMap (teselas)** (C2) | Servidor de teselas de terceros | Internet |
| **Measurement Protocol** (C2) | Analítica GA4; **hoy apagada** en producción: el build no tiene `GA_*` | Internet |
| **Google Geocoding / Static Maps** (C2) | **Hoy apagadas**: no hay key (ADR 0009) | Internet |
| **Pipeline de despliegue** (arc42 §7) | GitHub Actions: `ci.yml` y `deploy.yml` | Repositorio público ↔ secretos del repositorio |
| **Cuenta de servicio de Firebase** (arc42 §7) | Secret `FIREBASE_SERVICE_ACCOUNT` que publica en Hosting | Secretos de GitHub ↔ Google Cloud |
| **Firebase Hosting** (arc42 §7) | CDN que sirve el sitio, con plan Spark sin tarjeta | Internet |

MAPSUTB no tiene backend propio, cuentas de usuario ni base de datos. Por eso no aparecen amenazas
de inyección SQL, de robo de sesión ni de escalamiento entre usuarios: no hay superficie para ellas.

## Tabla de amenazas priorizadas

Prioridad = probabilidad × impacto, cada una en una escala del 1 (baja) al 3 (alta).
**Alta** va de 6 a 9, **media** de 3 a 4 y **baja** de 1 a 2. La tabla está ordenada por
prioridad, y ese orden fue el orden de trabajo (ver [Plan](#plan-qué-se-atacó-primero)).

Los dueños se reparten por área:

- **Carlos Galvis:** CI y despliegue.
- **Carlos Manrique:** datos y ruteo.
- **Nerlis Otero:** ubicación y herramientas de campo.
- **Isabel Paez:** analítica y privacidad.

| ID | STRIDE | Elemento afectado | Amenaza | P | I | Prioridad | Mitigación asignada | Dueño | Estado |
|---|---|---|---|---|---|---|---|---|---|
| T-01 | Tampering, Elevation | Pipeline de despliegue | Una acción de terceros con etiqueta móvil (`FirebaseExtended/action-hosting-deploy@v0`, `actions/checkout@v4`) se compromete y, con el secret de Firebase, publica un sitio alterado: rutas o zonas falsas. | 2 | 3 | **6 Alta** | Todas las acciones quedaron fijadas por SHA en los seis workflows, y Dependabot propone las actualizaciones como PR revisables. | Carlos Galvis | **Hecho**, 2026-11-11 |
| T-02 | Spoofing, Tampering | App → Measurement Protocol | Todo lo que entra con `--dart-define` queda legible en `main.dart.js`. Si se configura `GA_API_SECRET`, cualquiera puede enviar eventos falsos a GA4 a nombre de la app. | 3 | 2 | **6 Alta** | Hay una guardia en `deploy.yml` que hace fallar el despliegue si `GA_API_SECRET` existe. Se verificó que el bundle publicado no contiene el endpoint ni un measurement id. Si se quiere analítica, que pase por un colector propio (ADR 0019 y 0020). | Isabel Paez | **Hecho**, 2026-11-11 |
| T-03 | Tampering (cadena de suministro) | App: dependencias de `pubspec.lock` | Una dependencia con una vulnerabilidad conocida llega al bundle publicado. | 2 | 2 | **4 Media** | Hay un paso de OSV-Scanner en CI que falla el pipeline, más Dependabot para pub. Los hallazgos se revisan en [Análisis de dependencias](#análisis-de-dependencias). | Carlos Galvis | **Hecho**, 2026-11-11 |
| T-04 | Tampering, Information disclosure | App en Firebase Hosting | El sitio solo enviaba HSTS. Se podía enmarcar en otra página (clickjacking), el navegador podía adivinar tipos de contenido y ninguna CSP limitaba el origen de los scripts. | 2 | 2 | **4 Media** | Se agregaron en `firebase.json` las cabeceras `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy` y `Permissions-Policy`. La CSP va en modo *report-only*. El despliegue verifica las cabeceras. | Carlos Galvis | **Hecho**, con la CSP en observación; **imponerla queda pendiente** (ver T-04b) |
| T-05 | Denial of service | App → OpenStreetMap (teselas) | OSM bloquea las peticiones de la app si incumplen su política de uso de teselas (Referer válido, sin uso masivo), y el mapa base se queda vacío. | 2 | 2 | **4 Media** | `Referrer-Policy: strict-origin-when-cross-origin` sigue enviando el origen, que OSM exige; nunca se usa `no-referrer`. Si el mapa queda vacío, aparece el aviso «Sin conexión al mapa base» (MF-01). La ruta funciona sin teselas. | Carlos Manrique | **Hecho** y riesgo residual **aceptado** (§11) |
| T-06 | Information disclosure | Repositorio público (historial) | Una credencial versionada por error queda pública para siempre en el historial. | 1 | 3 | 3 Media | Se barrió el historial completo (1.320 commits de todas las ramas) en busca de claves de Google (`AIza…`), llaves privadas, `"private_key"`, `api_secret=`, tokens de Sonar y GitHub y measurement ids `G-…`: **0 coincidencias**. Las credenciales entran solo por secrets (ADR 0009). | Carlos Galvis | **Hecho**, 2026-11-11 |
| T-07 | Information disclosure | Sensor de ubicación → App | La posición exacta del usuario es un dato personal y podría filtrarse a terceros o quedar guardada. | 1 | 3 | 3 Media | La posición vive solo en memoria y no se persiste (ADR 0017). Ningún evento ni log la envía fuera del dispositivo; los eventos llevan solo el id de zona. `Permissions-Policy: geolocation=(self)` impide que un iframe de terceros la pida. Geocoding inverso, que enviaría coordenadas a Google, está apagado. | Nerlis Otero | **Hecho** |
| T-08 | Elevation of privilege | Cuenta de servicio de Firebase | La clave JSON de larga duración está en un secret **de repositorio**, no del environment `firebase-hosting`, que además no tiene reglas de protección. Cualquier workflow de una rama del repo podría usarla para publicar sin pasar por `master`. | 1 | 3 | 3 Media | Pasar el secret al environment `firebase-hosting` y limitarlo a `master`, rotar la clave y, a futuro, usar Workload Identity Federation (sin clave). Requiere permisos de administración del repo y de Google Cloud. | Carlos Galvis | **Pendiente** |
| T-09 | Tampering | Datos de zonas / Plano del campus | `master` **no tiene protección de rama**, verificado con la API de GitHub el 2026-11-11. Un push directo con un `grafo.json` alterado se despliega solo y puede llevar a alguien por un camino que no existe. | 1 | 3 | 3 Media | Activar la protección de `master`: PR obligatorio con CI verde y una revisión. Mientras tanto, `grafo_test.dart` valida la estructura del grafo real en cada CI y el despliegue corre `flutter test` antes de publicar. | Carlos Manrique | **Pendiente** (mitigación parcial vigente) |
| T-10 | Denial of service | Firebase Hosting (plan Spark) | Tráfico automatizado agota la cuota gratuita (10 GB al mes de transferencia) y el sitio deja de servir hasta el siguiente periodo. | 1 | 3 | 3 Media | La sonda horaria lo detectaría en una hora (DI-03). Existe el despliegue alternativo con Docker (ADR 0010) y los límites están documentados en `docs/costos.md`. | Isabel Paez | **Aceptado** (§11) |
| T-11 | Information disclosure | App → Firebase Hosting y OSM | Para servir el sitio y las teselas, Google y la Fundación OSM reciben la IP, el user agent y el área del mapa consultada. | 3 | 1 | 3 Media | No se envían identificadores persistentes; el `client_id` de la analítica es por sesión. El aviso de privacidad del README lo declara. | Isabel Paez | **Aceptado** (§11) |
| T-04b | Tampering | App en Firebase Hosting | La CSP en *report-only* avisa pero no bloquea. | 1 | 2 | 2 Baja | Revisar la consola del sitio publicado y, si no hay violaciones, pasar a `Content-Security-Policy`. | Carlos Galvis | **Pendiente** |
| T-12 | Tampering | Herramientas de campo (`web/herramientas/*.html`) | Insertan los nombres de las zonas con `innerHTML`. Si `zonas.json` llegara alterado (T-09), podría ejecutar script en el navegador del integrante. | 1 | 2 | 2 Baja | Cambiar `innerHTML` por `textContent` o `createElement`. Depende de T-09. | Nerlis Otero | **Pendiente** |
| T-13 | Spoofing | Sensor de ubicación | El usuario falsifica su posición (ubicación simulada del sistema operativo). | 2 | 1 | 2 Baja | No aplica mitigación: el único afectado es quien la falsifica, porque la ruta es solo suya. | Nerlis Otero | **Aceptado** (§11) |
| T-14 | Repudiation | Pipeline de despliegue | No poder demostrar qué versión estaba publicada ni quién la publicó. | 1 | 1 | 1 Baja | `health.json` expone el commit desplegado, Actions guarda quién lanzó cada despliegue y la sonda registra cada hora la respuesta. | Carlos Galvis | **Hecho** (ya existía, ADR 0007 y 0008) |

## Plan: qué se atacó primero

El orden de trabajo del 2026-11-11 siguió la prioridad:

1. **Altas (T-01 y T-02): hechas primero.** Se fijaron las acciones por SHA en los seis workflows y
   se agregó la guardia de `GA_API_SECRET` en `deploy.yml`. Las dos están en el ADR 0020 porque
   cambian cómo se construye y publica el sistema.
2. **Medias con mitigación dentro del repositorio (T-03 a T-07): hechas.** Son OSV-Scanner,
   Dependabot, las cabeceras, el Referer conservado, el barrido de secretos y la
   `Permissions-Policy`.
3. **Medias que dependen de permisos de administración (T-08 y T-09): pendientes.** Proteger
   `master` y mover el secret al environment se hacen desde la configuración de GitHub y de Google
   Cloud, no desde un commit. Quedan asignadas, con la mitigación parcial que ya existe.
4. **Medias aceptadas (T-10 y T-11):** el motivo de aceptarlas está en arc42 §11.
5. **Bajas (T-04b, T-12 y T-13):** quedan para después. Ninguna baja se hizo antes que una alta o
   media.

## Análisis de dependencias

**Herramienta:** OSV-Scanner v2.7.0 (Google), en el paso «Análisis de dependencias — OSV-Scanner»
de [`ci.yml`](../.github/workflows/ci.yml). El binario se verifica por SHA-256 antes de ejecutarlo.
Contrasta las 85 versiones exactas de `pubspec.lock` con la base OSV, que incluye los avisos de
GitHub y de pub.dev. Si encuentra una vulnerabilidad, el pipeline falla. Además, `flutter pub
outdated` lista lo que está atrasado aunque no tenga vulnerabilidad, y Dependabot abre cada semana
los PR de pub y de GitHub Actions.

**Resultado** (run [43034881403](https://github.com/ISCOUTB/AS_202620_mapsutb/actions/runs/43034881403),
rama `s12-s14`, 2026-11-11): `Scanned pubspec.lock file and found 85 packages — No issues found`.
**Ninguna vulnerabilidad conocida.** Hallazgos de `pub outdated` y lo que se decidió con cada uno:

| Hallazgo | Tipo | Decisión |
|---|---|---|
| `geolocator` 14.1.1 → 14.1.2 (directa) | Parche | **Actualizar** con el PR de Dependabot cuando pase el CI. Es la dependencia que toca la ubicación (T-07). Dueña: Nerlis Otero. |
| `cupertino_icons` 1.0.9 → 2.0.0 (directa) | Mayor | **No actualizar; evaluar quitarla.** La plantilla de Flutter la agrega, pero `lib/` no usa ningún `CupertinoIcons`. Quitarla reduce la superficie sin cambiar nada visible. Dueño: Carlos Galvis. |
| 14 transitivas con parche o menor disponible (`archive`, `crypto`, `web`, `jni`, `objective_c`, `geolocator_android`, `geolocator_apple`…) | Parche/menor | **Dejarlas al ciclo de Dependabot.** Ninguna tiene aviso de seguridad. `crypto` y `web` sí llegan al sitio publicado; las de Android, iOS y Linux no entran en el build web. |
| `dbus`, `gsettings` y `material_color_utilities` fijadas a una versión anterior | Restringidas por el SDK | **Aceptado.** Las fija Flutter 3.47.4; cambian al actualizar Flutter. `dbus` y `gsettings` solo existen para el escritorio Linux, que no se publica. |
| Acciones de GitHub en versiones mayores anteriores (`checkout` v4 contra v7, `setup-python` v5 contra v7, `action-hosting-deploy` v0 contra v0.11.0) | Mayor | **Fijadas por SHA en la versión que ya funcionaba.** Se suben con un PR de Dependabot revisado, no de forma automática. Es lo que evita T-01. |

El análisis estático de SonarCloud es otra cosa, porque revisa el código propio, no las
dependencias, y sigue en el pipeline desde el segundo corte.

## Privacidad: qué datos personales se tratan y con qué base

Se comprobó contra el código: no hay modelos con nombre, correo, teléfono ni documento.
`git grep` de esos términos fuera de `docs/` solo encuentra el correo del bot de Actions, el
nombre de una dependencia universitaria y el tipo `Direccion` del geocoding. MAPSUTB no tiene
cuentas de usuario. Aun así, trata estos datos:

| Dato | Dónde se trata | Para qué | Base | Conservación |
|---|---|---|---|---|
| **Posición GPS** del usuario | En memoria del navegador (`UbicacionServiceGps`) | Dibujar «Estás aquí» y calcular el origen de la ruta | **Autorización del titular** (Ley 1581 de 2012, art. 9): el navegador pide permiso de ubicación antes de leerla, y sin permiso la app funciona con partida marcada a mano | Mientras la pestaña está abierta. No se guarda ni se envía (ADR 0017). |
| **Dirección derivada de la posición** (`Direccion`) | Google Geocoding, solo si hay key | Mostrar «¿Dónde estoy?» como dirección legible | Autorización del titular, porque la consulta la inicia el usuario | **Apagada en producción**: no hay key (ADR 0009). Si se activa, las coordenadas salen hacia Google y hay que actualizar el aviso. |
| **IP, user agent y Referer** | Firebase Hosting (Google) y servidores de teselas de OSM | Servir el sitio y el mapa base | Necesidad técnica para prestar el servicio que el usuario pide; son terceros con su propia política | La que fija cada tercero; MAPSUTB no la recibe ni la guarda. |
| **Eventos de uso** (`client_id` aleatorio por sesión, id de zona) | Measurement Protocol de GA4 | Priorizar mejoras | Seudónimos sin identificador persistente | **Apagado en producción** (T-02). |
| **Recorridos de campo** de los integrantes | `localStorage` del celular de cada integrante (`web/herramientas/`), exportados a mano | Levantar coordenadas y el grafo | Consentimiento del propio integrante, que es quien mide | En su celular hasta que los exporta; al repo solo llegan coordenadas de lugares, no trayectos con hora. |

**Datos sensibles** (Ley 1581, art. 5): ninguno. **Menores de edad:** la app no pregunta la edad ni
guarda nada que lo exija. El aviso para el usuario está en el [README](../README.md#privacidad).

## Componente generativo

No aplica: MAPSUTB no incorpora ningún componente generativo
([ADR 0014](./adr/0014-sin-componente-generativo.md)). No hay prompts, contexto ni salida de un
modelo que modelar (inyección, fuga, envenenamiento). Si se incorpora uno, este documento tiene que
ampliarse antes.
