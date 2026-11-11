import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import '../../core/log.dart';
import 'mensaje_evento_uso.dart';

/// Cola en memoria del taller de mensajes (S12): desacopla al productor
/// (la app, al registrar un evento de uso) del consumidor (un colector que
/// cuenta eventos). Prototipo aislado; ver ADR 0019.
///
/// Garantía: **al menos una vez.** Un mensaje solo sale de la cola cuando el
/// consumidor lo confirma. Si el consumidor falla de forma recuperable
/// ([FalloTransitorio]) se reintenta con espera creciente; si se agotan los
/// intentos o el fallo no es recuperable, el mensaje pasa a [fallidos]
/// (cola de mensajes fallidos) en vez de perderse. La consecuencia es que
/// el consumidor puede recibir el mismo mensaje más de una vez, y por eso
/// tiene que ser idempotente (ver `ConsumidorConteo`).
class ColaEventos {
  ColaEventos({
    required ConsumidorEventos consumidor,
    this.politica = const PoliticaReintentos(),
    Esperar? esperar,
  })  : _consumidor = consumidor,
        _esperar = esperar ?? ((espera) => Future<void>.delayed(espera));

  final ConsumidorEventos _consumidor;
  final PoliticaReintentos politica;

  /// Sustituible en pruebas para no esperar de verdad y registrar las esperas.
  final Esperar _esperar;

  final _pendientes = Queue<String>();

  /// Cola de mensajes fallidos: lo que no se pudo entregar, con el motivo,
  /// para revisarlo o reinyectarlo a mano. Nunca se descarta en silencio.
  final fallidos = <MensajeFallido>[];
  final metricas = MetricasCola();

  int get pendientes => _pendientes.length;

  /// Lado del productor: serializa con el contrato v1 y encola.
  void publicar(MensajeEventoUso mensaje) => publicarCrudo(jsonEncode(mensaje.toJson()));

  /// Encola un cuerpo ya serializado; sirve también para simular un
  /// productor con otra versión del contrato.
  void publicarCrudo(String cuerpo) {
    _pendientes.add(cuerpo);
    metricas.publicados++;
    Log.info('mensaje_publicado', {..._ids(cuerpo), 'pendientes': _pendientes.length});
  }

  /// Entrega en orden todo lo pendiente.
  Future<void> drenar() async {
    while (_pendientes.isNotEmpty) {
      await _entregar(_pendientes.removeFirst());
    }
  }

  Future<void> _entregar(String cuerpo) async {
    final ids = _ids(cuerpo);
    final MensajeEventoUso mensaje;
    try {
      mensaje = MensajeEventoUso.fromJson(jsonDecode(cuerpo) as Map<String, Object?>);
    } on ContratoIncompatible catch (e) {
      // Reintentar no cambia el contrato: directo a fallidos.
      _aFallidos(cuerpo, ids, 1, 'contrato_incompatible: ${e.motivo}');
      return;
    } catch (e) {
      _aFallidos(cuerpo, ids, 1, 'cuerpo_ilegible: $e');
      return;
    }

    for (var intento = 1;; intento++) {
      try {
        await _consumidor.procesar(mensaje);
        metricas.entregados++;
        Log.info('mensaje_entregado', {...ids, 'intento': intento});
        return;
      } on FalloTransitorio catch (e) {
        if (intento >= politica.maxIntentos) {
          _aFallidos(cuerpo, ids, intento, 'reintentos_agotados: ${e.motivo}');
          return;
        }
        final espera = politica.esperaTras(intento);
        metricas.reintentos++;
        Log.warn('mensaje_reintento', {
          ...ids,
          'intento': intento,
          'espera_ms': espera.inMilliseconds,
          'motivo': e.motivo,
        });
        await _esperar(espera);
      } catch (e) {
        // Un error que no es transitorio no se arregla reintentando.
        _aFallidos(cuerpo, ids, intento, 'error_no_recuperable: $e');
        return;
      }
    }
  }

  void _aFallidos(String cuerpo, Map<String, Object?> ids, int intentos, String motivo) {
    fallidos.add(MensajeFallido(
      cuerpo: cuerpo,
      idMensaje: ids['id_mensaje'],
      idCorrelacion: ids['id_correlacion'],
      intentos: intentos,
      motivo: motivo,
    ));
    metricas.aFallidos++;
    Log.error('mensaje_a_fallidos', {...ids, 'intentos': intentos, 'motivo': motivo});
  }

  /// Ids para el log, incluso de un cuerpo que no cumple el contrato.
  static Map<String, Object?> _ids(String cuerpo) {
    try {
      final json = jsonDecode(cuerpo);
      if (json is Map) {
        return {'id_mensaje': json['id_mensaje'], 'id_correlacion': json['id_correlacion']};
      }
    } on FormatException {
      // Cuerpo que ni siquiera es JSON: se registra sin ids.
    }
    return const {'id_mensaje': null, 'id_correlacion': null};
  }
}

typedef Esperar = Future<void> Function(Duration espera);

/// Lado del consumidor: confirma devolviendo normalmente; lanza
/// [FalloTransitorio] cuando vale la pena reintentar.
abstract class ConsumidorEventos {
  Future<void> procesar(MensajeEventoUso mensaje);
}

/// Fallo recuperable del consumidor (no disponible, tiempo agotado,
/// confirmación perdida): la cola reintenta.
class FalloTransitorio implements Exception {
  const FalloTransitorio(this.motivo);
  final String motivo;

  @override
  String toString() => 'FalloTransitorio: $motivo';
}

/// 4 intentos en total; esperas de 200, 400 y 800 ms entre ellos
/// (exponencial ×2, con tope de 5 s).
class PoliticaReintentos {
  const PoliticaReintentos({
    this.maxIntentos = 4,
    this.esperaInicial = const Duration(milliseconds: 200),
    this.factor = 2,
    this.esperaMaxima = const Duration(seconds: 5),
  });

  final int maxIntentos;
  final Duration esperaInicial;
  final num factor;
  final Duration esperaMaxima;

  /// Espera antes del intento siguiente al número [intentoFallido] (desde 1).
  Duration esperaTras(int intentoFallido) {
    final ms = esperaInicial.inMilliseconds * pow(factor, intentoFallido - 1);
    return Duration(milliseconds: min(ms.round(), esperaMaxima.inMilliseconds));
  }
}

class MensajeFallido {
  const MensajeFallido({
    required this.cuerpo,
    required this.idMensaje,
    required this.idCorrelacion,
    required this.intentos,
    required this.motivo,
  });

  final String cuerpo;
  final Object? idMensaje;
  final Object? idCorrelacion;
  final int intentos;
  final String motivo;
}

/// Contadores para seguir la cola: publicados = entregados + fallidos +
/// pendientes cuando no hay nada en vuelo.
class MetricasCola {
  int publicados = 0;
  int entregados = 0;
  int reintentos = 0;
  int aFallidos = 0;
}
