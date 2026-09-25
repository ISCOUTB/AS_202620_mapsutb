import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapsutb/core/log.dart';

/// Los logs deben ser estructurados: cada línea es un objeto JSON con
/// `ts`, `nivel` y `evento`, más los campos propios del evento.
void main() {
  late List<String> lineas;

  setUp(() {
    lineas = [];
    Log.salida = lineas.add;
  });

  tearDown(() => Log.salida = debugPrint);

  test('emite una línea JSON con los campos fijos y los del evento', () {
    Log.info('zonas_cargadas', {'cantidad': 11, 'duracion_ms': 42});

    final linea = jsonDecode(lineas.single) as Map<String, dynamic>;
    expect(linea['nivel'], 'info');
    expect(linea['evento'], 'zonas_cargadas');
    expect(linea['cantidad'], 11);
    expect(linea['duracion_ms'], 42);
    expect(DateTime.parse(linea['ts'] as String).isUtc, isTrue);
  });

  test('warn y error marcan su nivel y serializan valores no JSON como texto',
      () {
    Log.warn('analitica_fallo_red', {'error': Exception('sin conexión')});
    Log.error('geocoding_error', {'status': 'HTTP_503'});

    final warn = jsonDecode(lineas[0]) as Map<String, dynamic>;
    final error = jsonDecode(lineas[1]) as Map<String, dynamic>;
    expect(warn['nivel'], 'warn');
    expect(warn['error'], contains('sin conexión'));
    expect(error['nivel'], 'error');
    expect(error['status'], 'HTTP_503');
  });
}
