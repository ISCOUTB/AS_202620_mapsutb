import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/log.dart';
import '../models/evento_analitica.dart';

/// Aísla al resto de la app del Measurement Protocol de Firebase/Google
/// Analytics (ADR 0001/0002, patrón Adapter). Se comunica directamente
/// por HTTPS contra el endpoint público de recolección — deliberadamente
/// NO usa el SDK/paquete oficial de Firebase, para no agregar
/// dependencias nativas (google-services.json, configuración por
/// plataforma) a un proyecto que hasta ahora no tenía backend propio ni
/// SDKs adicionales más allá de Maps y Geocoding (ver ADR 0005).
///
/// Contrato consumido: docs/api/apis-externas.openapi.yaml (sección
/// Measurement Protocol). La correspondencia entre ese contrato y esta
/// implementación se valida en
/// test/analytics_adapter_contract_test.dart (ficha S7, criterio 3).
abstract class AnalyticsAdapter {
  /// Registra un evento de uso.
  ///
  /// Un fallo de red (sin conexión, timeout) se absorbe en silencio: la
  /// analítica nunca debe bloquear ni afectar el flujo principal (ver
  /// Escenario 3, docs/escenarios_calidad.md). En cambio, una respuesta
  /// fuera de contrato (status distinto de 204) se reporta como
  /// [AnalyticsException] para que la prueba de contrato la detecte; quien
  /// llame desde la UI debe descartar ese error (p. ej. con
  /// `Future.ignore()`) para no interrumpir la navegación.
  Future<void> registrarEvento(EventoAnalitica evento);
}

/// Implementación vacía, usada cuando no hay credenciales de Measurement
/// Protocol configuradas (ver `ConfigApis`).
class AnalyticsAdapterNulo implements AnalyticsAdapter {
  const AnalyticsAdapterNulo();

  @override
  Future<void> registrarEvento(EventoAnalitica evento) async {}
}

class AnalyticsAdapterHttp implements AnalyticsAdapter {
  AnalyticsAdapterHttp({
    required String measurementId,
    required String apiSecret,
    required String clientId,
    http.Client? client,
  })  : _measurementId = measurementId,
        _apiSecret = apiSecret,
        _clientId = clientId,
        _client = client ?? http.Client();

  static const _baseUrl = 'https://www.google-analytics.com/mp/collect';

  final String _measurementId;
  final String _apiSecret;
  final String _clientId;
  final http.Client _client;

  @override
  Future<void> registrarEvento(EventoAnalitica evento) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'measurement_id': _measurementId,
      'api_secret': _apiSecret,
    });

    final cuerpo = jsonEncode({
      'client_id': _clientId,
      'events': [
        {
          'name': evento.nombre,
          'params': evento.parametros,
        }
      ],
    });

    try {
      final respuesta = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: cuerpo,
      );

      // El Measurement Protocol responde 204 sin cuerpo cuando acepta el
      // evento (docs/api/apis-externas.openapi.yaml). No se valida más
      // allá del código de estado: no hay confirmación de procesamiento
      // por diseño del proveedor.
      if (respuesta.statusCode != 204) {
        Log.error('analitica_fuera_de_contrato', {
          'evento_analitica': evento.nombre,
          'status_http': respuesta.statusCode,
        });
        throw AnalyticsException(respuesta.statusCode);
      }
    } on AnalyticsException {
      rethrow;
    } catch (e) {
      // La analítica es de mejor esfuerzo: un fallo de red no debe
      // interrumpir el flujo principal de la app (Escenario 3).
      Log.warn('analitica_fallo_red', {
        'evento_analitica': evento.nombre,
        'error': e,
      });
      return;
    }
  }
}

class AnalyticsException implements Exception {
  AnalyticsException(this.statusCode);
  final int statusCode;

  @override
  String toString() =>
      'AnalyticsException: Measurement Protocol respondió statusCode=$statusCode';
}
