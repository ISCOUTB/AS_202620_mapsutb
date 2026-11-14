# ADR 0017 — Posición real con `geolocator`, filtrada, y punto de partida marcado a mano cuando el GPS no sirve

## Estado

- **Estado**: Aceptado
- **Fecha**: 2026-10-13
- **Decisores**: Equipo MAPSUTB
- **Complementa**: [ADR 0002](./0002-patrones-de-diseno-sin-realidad-aumentada.md) (Observer para la
  ubicación) y [ADR 0016](./0016-no-extraer-modulos-por-ahora.md) (modos de fallo), sin cambiar sus
  decisiones

## Contexto

Hasta ahora la posición era simulada (`UbicacionServiceSimulado`): cada segundo emitía un punto
aleatorio a unos ±33 m de un punto fijo del campus. En el mapa, el punto saltaba, la ruta cambiaba
de nodo de partida y la cámara se reencuadraba con cada salto. Además, las revisiones S9 y S10
pedían distinguir el resultado con GPS simulado de la precisión en campo: con el simulador, el
Escenario 2 no se podía probar de punta a punta.

Los modos de fallo del sensor quedaron pendientes en la semana 11 (arc42 §11, MF-04 a MF-06): sin
señal, lecturas viejas y lecturas con ruido.

## Decisión

1. **`UbicacionServiceGps`** (`lib/services/ubicacion_service_gps.dart`) lee la posición con
   [`geolocator`](https://pub.dev/packages/geolocator) 14. Es un Flutter Favorite de Baseflow y
   soporta web, Android e iOS; en la web usa la API de geolocalización del navegador, que exige
   HTTPS (Firebase Hosting ya lo da). Implementa la misma interfaz `UbicacionService`, así que las
   pantallas no cambian de contrato (Observer, ADR 0002).
2. **`FiltroUbicacion`** decide qué lecturas se usan:
   - descarta las de **más de 10 s** de antigüedad (MF-05);
   - descarta las de **precisión peor que 30 m** (MF-06). Los edificios están a ~20 m entre sí, y
     el levantamiento midió una mediana de 5,8 m en exteriores y de 16,5 m dentro de edificios;
   - no emite las que se movieron **menos de 5 m**: es ruido, no el usuario caminando (MF-06).
3. **Sin señal** (sin permiso, ubicación apagada o 15 s sin una lectura válida), el Stream emite el
   error `UbicacionNoDisponible` con el motivo y sigue abierto (MF-04). La pantalla dice el motivo.
4. **Punto de partida a mano:** si el GPS no sirve (sin posición o fuera del campus), el usuario
   toca el mapa para marcar dónde está, y la ruta sale desde ahí hasta que elija «Usar mi GPS».
5. La cámara se reencuadra cuando cambia el destino, no cada vez que la ruta empieza en otro nodo.
6. El simulador queda para demostraciones (`--dart-define=UBICACION_SIMULADA=true`), con ruido de
   ±1 m en vez de ±33 m, y la pantalla de Ubicación avisa que es simulado.

## Alternativas consideradas

### A. `geolocator` con filtro propio y partida a mano (elegida)

- **A favor:** una sola dependencia, mantenida, con soporte web; el filtro y el vigía de señal son
  código propio que se prueba sin GPS (`test/ubicacion_gps_test.dart`); la partida a mano mantiene
  la app útil sin GPS, por ejemplo para quien la evalúa desde fuera del campus.
- **En contra:** agrega 16 paquetes al `pubspec.lock`: las implementaciones por plataforma de
  `geolocator` y lo que necesitan en Linux y Windows (`dbus`, `geoclue`, `package_info_plus`…).
  En la web solo entra `geolocator_web`.

### B. API de geolocalización del navegador directa con `dart:js_interop` (descartada)

- **Motivo técnico:** cero dependencias, pero solo funciona en web, y la app también compila para
  móvil (ADR 0004). Habría que mantener una implementación por plataforma: justo lo que resuelve
  `geolocator`.

### C. Dejar el simulador con un punto fijo (descartada)

- **Motivo técnico:** arregla el salto del punto pero deja el Escenario 2 sin poder medirse en el
  campus, y cada ruta parte del mismo lugar, sin importar dónde esté el usuario.

### D. Suavizar las lecturas (media móvil o filtro de Kalman) (descartada por ahora)

- **Motivo técnico:** con 5 m de desplazamiento mínimo y 30 m de precisión máxima, el ruido ya no
  mueve el punto. Un filtro de Kalman agrega retraso y parámetros que habría que calibrar con datos
  de campo que todavía no hay. Se revisa si en campo el punto sigue saltando.

## Consecuencias

- El sitio pide permiso de ubicación al abrir el mapa o la pestaña Ubicación. Si se niega, el mapa
  lo dice y deja marcar la partida a mano.
- Fuera del campus la app sigue siendo usable: marca «fuera del campus» y permite elegir la partida.
- **El margen de 10 m del Escenario 2 sigue sin medirse con la app en el campus:** este ADR lo
  hace posible, no lo demuestra. La medición en campo queda pendiente del equipo.
- Pruebas: `test/ubicacion_gps_test.dart` (filtro, vigía de señal, errores del sensor) y
  `test/mapa_test.dart` / `test/ubicacion_test.dart` (mensajes y partida a mano).
