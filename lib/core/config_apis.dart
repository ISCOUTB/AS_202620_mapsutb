/// Credenciales de las APIs externas, inyectadas en tiempo de compilación
/// con `--dart-define` para que nunca queden versionadas en el repositorio:
///
/// ```bash
/// flutter run \
///   --dart-define=GOOGLE_MAPS_API_KEY=... \
///   --dart-define=GA_MEASUREMENT_ID=G-... \
///   --dart-define=GA_API_SECRET=...
/// ```
///
/// Si una credencial no se define, la funcionalidad que depende de ella
/// se desactiva (ver `main.dart`) en vez de fallar al arrancar.
///
/// Advertencia: todo valor pasado con `--dart-define` queda embebido en el
/// binario y puede extraerse. Es aceptable para la API key de Google Maps
/// (restringirla por paquete/huella en Google Cloud Console), pero el
/// `api_secret` del Measurement Protocol solo permite enviar eventos, no
/// leerlos: el riesgo es que un tercero inyecte eventos falsos. Si eso se
/// vuelve un problema, el envío debe moverse a un backend propio.
class ConfigApis {
  const ConfigApis._();

  static const googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  static const gaMeasurementId = String.fromEnvironment('GA_MEASUREMENT_ID');
  static const gaApiSecret = String.fromEnvironment('GA_API_SECRET');

  static bool get tieneGoogleMaps => googleMapsApiKey.isNotEmpty;
  static bool get tieneAnalytics =>
      gaMeasurementId.isNotEmpty && gaApiSecret.isNotEmpty;
}
