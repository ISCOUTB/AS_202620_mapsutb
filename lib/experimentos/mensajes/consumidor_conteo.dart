import '../../core/log.dart';
import 'cola_eventos.dart';
import 'mensaje_evento_uso.dart';

/// Consumidor idempotente del taller de mensajes (S12): cuenta eventos de
/// uso por nombre, como lo haría un colector propio. Prototipo aislado;
/// ver ADR 0019.
///
/// **Deduplicación por `id_mensaje`.** Con entrega al menos una vez, el mismo
/// mensaje puede llegar dos veces (el productor reenvía, o se perdió la
/// confirmación y la cola reintenta). El segundo se confirma sin contarlo.
/// Aquí el registro de vistos y el conteo cambian juntos en memoria; en un
/// colector real tendrían que guardarse en la misma transacción.
class ConsumidorConteo implements ConsumidorEventos {
  final _procesados = <String>{};
  final conteo = <String, int>{};
  int duplicadosDescartados = 0;

  @override
  Future<void> procesar(MensajeEventoUso mensaje) async {
    final ids = {'id_mensaje': mensaje.idMensaje, 'id_correlacion': mensaje.idCorrelacion};
    if (!_procesados.add(mensaje.idMensaje)) {
      duplicadosDescartados++;
      Log.info('mensaje_duplicado_descartado', ids);
      return;
    }
    conteo.update(mensaje.nombre, (n) => n + 1, ifAbsent: () => 1);
    Log.info('mensaje_procesado', {...ids, 'evento_uso': mensaje.nombre});
  }
}
