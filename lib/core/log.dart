import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Logs estructurados de la app: una línea JSON por evento, con `ts`,
/// `nivel` y `evento` fijos más los campos propios de cada caso (arc42 §8,
/// observabilidad). En web salen a la consola del navegador; en móvil, a
/// `adb logcat` / la consola de Xcode.
///
/// ```json
/// {"ts":"2026-09-25T22:08:03.615Z","nivel":"error","evento":"geocoding_error","status":"HTTP_503","duracion_ms":412}
/// ```
class Log {
  const Log._();

  /// Destino de las líneas; las pruebas lo reemplazan para inspeccionarlas.
  @visibleForTesting
  static void Function(String linea) salida = debugPrint;

  static void info(String evento, [Map<String, Object?> campos = const {}]) =>
      _emitir('info', evento, campos);

  static void warn(String evento, [Map<String, Object?> campos = const {}]) =>
      _emitir('warn', evento, campos);

  static void error(String evento, [Map<String, Object?> campos = const {}]) =>
      _emitir('error', evento, campos);

  static void _emitir(String nivel, String evento, Map<String, Object?> campos) {
    salida(jsonEncode(
      {
        'ts': DateTime.now().toUtc().toIso8601String(),
        'nivel': nivel,
        'evento': evento,
        ...campos,
      },
      // Valores no serializables (excepciones, objetos) van como texto.
      toEncodable: (valor) => valor.toString(),
    ));
  }
}
