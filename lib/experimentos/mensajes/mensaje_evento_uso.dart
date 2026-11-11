import 'dart:math';

/// Contrato v1 del mensaje «evento de uso» del taller de mensajes (S12).
///
/// **Prototipo aislado.** Ninguna pantalla ni servicio de la app importa
/// `lib/experimentos/`: la analítica real sigue saliendo como máximo una vez
/// por `AnalyticsAdapter` (ADR 0016). La decisión de no incorporar esta cola
/// al sistema está en ADR 0019; el esquema y el criterio de compatibilidad,
/// en `docs/api/eventos-uso.asyncapi.yaml`.
///
/// Criterio de compatibilidad:
/// * **Compatible** (sigue en v1): agregar un campo opcional o un parámetro
///   nuevo. El consumidor ignora lo que no conoce (lector tolerante).
/// * **Incompatible** (exige v2): quitar o renombrar un campo obligatorio,
///   cambiar su tipo o su significado. Un consumidor v1 rechaza otra versión
///   y el mensaje va directo a la cola de fallidos, sin reintentos, porque
///   reintentar no lo arregla.
class MensajeEventoUso {
  const MensajeEventoUso({
    required this.idMensaje,
    required this.idCorrelacion,
    required this.nombre,
    required this.emitidoEn,
    this.parametros = const {},
    this.version = versionContrato,
  });

  /// Crea un mensaje nuevo con un `id_mensaje` aleatorio de 128 bits.
  factory MensajeEventoUso.nuevo({
    required String nombre,
    required String idCorrelacion,
    Map<String, Object?> parametros = const {},
  }) =>
      MensajeEventoUso(
        idMensaje: nuevoId(),
        idCorrelacion: idCorrelacion,
        nombre: nombre,
        parametros: parametros,
        emitidoEn: DateTime.now().toUtc(),
      );

  /// Lector tolerante: ignora los campos que no conoce y rechaza con
  /// [ContratoIncompatible] otra versión o un campo obligatorio ausente o de
  /// otro tipo.
  factory MensajeEventoUso.fromJson(Map<String, Object?> json) {
    final version = json['version'];
    if (version is! int) {
      throw const ContratoIncompatible('version ausente o no entera');
    }
    if (version != versionContrato) {
      throw ContratoIncompatible('versión $version no soportada por el consumidor v$versionContrato');
    }
    final emitidoEn = DateTime.tryParse(_texto(json, 'emitido_en'));
    if (emitidoEn == null) {
      throw const ContratoIncompatible('emitido_en no es una fecha ISO 8601');
    }
    final parametros = json['parametros'];
    if (parametros != null && parametros is! Map) {
      throw const ContratoIncompatible('parametros no es un objeto');
    }
    return MensajeEventoUso(
      version: version,
      idMensaje: _texto(json, 'id_mensaje'),
      idCorrelacion: _texto(json, 'id_correlacion'),
      nombre: _texto(json, 'nombre'),
      parametros: parametros == null ? const {} : Map<String, Object?>.from(parametros as Map),
      emitidoEn: emitidoEn,
    );
  }

  static const versionContrato = 1;

  /// Campos obligatorios de la v1, en el orden del esquema.
  static const camposObligatorios = ['version', 'id_mensaje', 'id_correlacion', 'nombre', 'emitido_en'];

  final int version;

  /// Clave de deduplicación: el mismo evento reenviado conserva este id.
  final String idMensaje;

  /// Identifica la acción del usuario que originó el evento; viaja en cada
  /// línea de log del productor, la cola y el consumidor.
  final String idCorrelacion;

  /// Nombre del evento, el mismo de `EventoAnalitica` (p. ej. `solicitud_ruta`).
  final String nombre;
  final Map<String, Object?> parametros;
  final DateTime emitidoEn;

  Map<String, Object?> toJson() => {
        'version': version,
        'id_mensaje': idMensaje,
        'id_correlacion': idCorrelacion,
        'nombre': nombre,
        'parametros': parametros,
        'emitido_en': emitidoEn.toUtc().toIso8601String(),
      };

  static String nuevoId() {
    final azar = Random.secure();
    return List.generate(16, (_) => azar.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  static String _texto(Map<String, Object?> json, String campo) {
    final valor = json[campo];
    if (valor is String && valor.isNotEmpty) return valor;
    throw ContratoIncompatible('$campo ausente o no es texto');
  }
}

/// El mensaje no cumple el contrato que entiende el consumidor.
class ContratoIncompatible implements Exception {
  const ContratoIncompatible(this.motivo);
  final String motivo;

  @override
  String toString() => 'ContratoIncompatible: $motivo';
}
