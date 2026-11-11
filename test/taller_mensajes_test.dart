import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapsutb/core/log.dart';
import 'package:mapsutb/experimentos/mensajes/cola_eventos.dart';
import 'package:mapsutb/experimentos/mensajes/consumidor_conteo.dart';
import 'package:mapsutb/experimentos/mensajes/mensaje_evento_uso.dart';

/// Taller de mensajes y consistencia (S12): prototipo aislado de una cola
/// con entrega al menos una vez para los eventos de uso (ADR 0019,
/// docs/taller-mensajes.md). Las dos pruebas que pide la ficha son
/// «duplicado: …» y «fallo recuperable: …».
void main() {
  late List<Map<String, dynamic>> logs;
  late List<Duration> esperas;

  setUp(() {
    logs = [];
    esperas = [];
    Log.salida = (linea) => logs.add(jsonDecode(linea) as Map<String, dynamic>);
  });

  tearDown(() => Log.salida = debugPrint);

  MensajeEventoUso evento(String id, {String correlacion = 'accion-1'}) => MensajeEventoUso(
        idMensaje: id,
        idCorrelacion: correlacion,
        nombre: 'solicitud_ruta',
        parametros: const {'zona_destino': 'zona_t'},
        emitidoEn: DateTime.utc(2026, 11, 11, 14),
      );

  ColaEventos colaCon(ConsumidorEventos consumidor) =>
      ColaEventos(consumidor: consumidor, esperar: (espera) async => esperas.add(espera));

  group('contrato del mensaje v1', () {
    test('ida y vuelta por JSON conserva todos los campos', () {
      final json = evento('m-1').toJson();
      expect(json.keys.toSet(), {...MensajeEventoUso.camposObligatorios, 'parametros'});

      final leido = MensajeEventoUso.fromJson(jsonDecode(jsonEncode(json)) as Map<String, Object?>);
      expect(leido.idMensaje, 'm-1');
      expect(leido.idCorrelacion, 'accion-1');
      expect(leido.parametros, {'zona_destino': 'zona_t'});
      expect(leido.emitidoEn, DateTime.utc(2026, 11, 11, 14));
    });

    test('cambio compatible: un campo nuevo se ignora y el mensaje se procesa', () async {
      final consumidor = ConsumidorConteo();
      final cola = colaCon(consumidor);
      cola.publicarCrudo(jsonEncode({...evento('m-1').toJson(), 'plataforma': 'web'}));
      await cola.drenar();

      expect(consumidor.conteo, {'solicitud_ruta': 1});
      expect(cola.fallidos, isEmpty);
    });

    test('cambio incompatible: otra versión va a fallidos sin reintentos', () async {
      final consumidor = ConsumidorConteo();
      final cola = colaCon(consumidor);
      cola.publicarCrudo(jsonEncode({...evento('m-2').toJson(), 'version': 2}));
      await cola.drenar();

      expect(consumidor.conteo, isEmpty);
      expect(cola.fallidos.single.motivo, startsWith('contrato_incompatible'));
      expect(cola.fallidos.single.intentos, 1);
      expect(esperas, isEmpty);
    });

    test('cambio incompatible: falta un campo obligatorio', () {
      final json = evento('m-3').toJson()..remove('id_mensaje');
      expect(() => MensajeEventoUso.fromJson(json), throwsA(isA<ContratoIncompatible>()));
    });

    test('cada mensaje nuevo recibe un id distinto de 128 bits', () {
      final a = MensajeEventoUso.nuevo(nombre: 'solicitud_ruta', idCorrelacion: 'x');
      final b = MensajeEventoUso.nuevo(nombre: 'solicitud_ruta', idCorrelacion: 'x');
      expect(a.idMensaje, hasLength(32));
      expect(a.idMensaje, isNot(b.idMensaje));
    });
  });

  group('duplicados', () {
    test('duplicado: el mismo mensaje entregado dos veces se cuenta una sola vez', () async {
      final consumidor = ConsumidorConteo();
      final cola = colaCon(consumidor);
      final mensaje = evento('m-1');
      cola.publicar(mensaje);
      // El productor no recibió confirmación y reenvía el mismo mensaje.
      cola.publicar(mensaje);
      await cola.drenar();

      expect(consumidor.conteo, {'solicitud_ruta': 1});
      expect(consumidor.duplicadosDescartados, 1);
      expect(cola.metricas.entregados, 2, reason: 'el duplicado también se confirma');
      expect(logs.map((l) => l['evento']), contains('mensaje_duplicado_descartado'));
    });

    test('duplicado: se perdió la confirmación y el reintento no cuenta dos veces', () async {
      final consumidor = _ConsumidorInestable(confirmacionesPerdidas: 1);
      final cola = colaCon(consumidor);
      cola.publicar(evento('m-1'));
      await cola.drenar();

      expect(consumidor.interno.conteo, {'solicitud_ruta': 1});
      expect(consumidor.interno.duplicadosDescartados, 1);
      expect(cola.metricas.reintentos, 1);
      expect(cola.fallidos, isEmpty);
    });
  });

  group('reintentos y cola de fallidos', () {
    test('fallo recuperable: se reintenta con espera creciente y se entrega una vez', () async {
      final consumidor = _ConsumidorInestable(fallosAntes: 2);
      final cola = colaCon(consumidor);
      cola.publicar(evento('m-1'));
      await cola.drenar();

      expect(esperas, const [Duration(milliseconds: 200), Duration(milliseconds: 400)]);
      expect(consumidor.interno.conteo, {'solicitud_ruta': 1});
      expect(cola.metricas.reintentos, 2);
      expect(cola.metricas.entregados, 1);
      expect(cola.fallidos, isEmpty);
    });

    test('agotados los 4 intentos, el mensaje queda en la cola de fallidos', () async {
      final consumidor = _ConsumidorInestable(fallosAntes: 99);
      final cola = colaCon(consumidor);
      cola.publicar(evento('m-1'));
      cola.publicar(evento('m-2'));
      await cola.drenar();

      expect(cola.fallidos.map((f) => f.idMensaje), ['m-1', 'm-2']);
      expect(cola.fallidos.first.intentos, 4);
      expect(cola.fallidos.first.motivo, startsWith('reintentos_agotados'));
      expect(esperas.take(3), const [
        Duration(milliseconds: 200),
        Duration(milliseconds: 400),
        Duration(milliseconds: 800),
      ]);
      expect(cola.pendientes, 0);
      expect(cola.metricas.publicados, cola.metricas.entregados + cola.metricas.aFallidos);
    });

    test('un error no recuperable va a fallidos sin reintentar', () async {
      final cola = colaCon(_ConsumidorRoto());
      cola.publicar(evento('m-1'));
      await cola.drenar();

      expect(cola.fallidos.single.motivo, startsWith('error_no_recuperable'));
      expect(esperas, isEmpty);
    });

    test('la espera crece ×2 hasta el tope de 5 s', () {
      const politica = PoliticaReintentos();
      expect([for (var i = 1; i <= 7; i++) politica.esperaTras(i).inMilliseconds],
          [200, 400, 800, 1600, 3200, 5000, 5000]);
    });
  });

  test('trazabilidad: el id de correlación sigue al mensaje del productor al consumidor', () async {
    final consumidor = _ConsumidorInestable(fallosAntes: 1);
    final cola = colaCon(consumidor);
    cola.publicar(evento('m-1', correlacion: 'accion-42'));
    cola.publicar(evento('m-2', correlacion: 'otra-accion'));
    await cola.drenar();

    final traza = logs.where((l) => l['id_correlacion'] == 'accion-42').toList();
    expect(traza.map((l) => l['evento']), [
      'mensaje_publicado',
      'mensaje_reintento',
      'mensaje_procesado',
      'mensaje_entregado',
    ]);
    expect(traza.every((l) => l['id_mensaje'] == 'm-1'), isTrue);
  });
}

/// Falla de forma recuperable [fallosAntes] veces antes de procesar, y
/// pierde la confirmación [confirmacionesPerdidas] veces después de procesar.
class _ConsumidorInestable implements ConsumidorEventos {
  _ConsumidorInestable({this.fallosAntes = 0, this.confirmacionesPerdidas = 0});

  int fallosAntes;
  int confirmacionesPerdidas;
  final interno = ConsumidorConteo();

  @override
  Future<void> procesar(MensajeEventoUso mensaje) async {
    if (fallosAntes > 0) {
      fallosAntes--;
      throw const FalloTransitorio('colector_no_disponible');
    }
    await interno.procesar(mensaje);
    if (confirmacionesPerdidas > 0) {
      confirmacionesPerdidas--;
      throw const FalloTransitorio('confirmacion_perdida');
    }
  }
}

class _ConsumidorRoto implements ConsumidorEventos {
  @override
  Future<void> procesar(MensajeEventoUso mensaje) async => throw StateError('esquema de la base cambió');
}
