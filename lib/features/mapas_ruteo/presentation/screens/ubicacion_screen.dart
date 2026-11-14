import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapsutb/adapters/geocoding_adapter.dart';
import 'package:mapsutb/models/ubicacion.dart';
import 'package:mapsutb/models/zona.dart';
import 'package:mapsutb/repositories/zona_repository.dart';
import 'package:mapsutb/services/ubicacion_service.dart';

/// Pestaña Ubicación: dónde está el usuario dentro del campus, dicho con el
/// nombre de la zona más cercana y no con coordenadas.
class UbicacionScreen extends StatefulWidget {
  final UbicacionService service;
  final GeocodingAdapter? geocoding;

  /// Zonas para decir «Estás cerca de …». Sin él solo se muestran las coordenadas.
  final ZonaRepository? zonaRepository;

  const UbicacionScreen({super.key, required this.service, this.geocoding, this.zonaRepository});

  /// Más lejos que esto de cualquier zona, el usuario no está en el campus
  /// (el mismo umbral que usa la pantalla de mapa).
  static const maxDistanciaAlCampusM = 300.0;

  @override
  State<UbicacionScreen> createState() => _UbicacionScreenState();
}

class _UbicacionScreenState extends State<UbicacionScreen> {
  StreamSubscription<Ubicacion>? _subscription;
  Ubicacion? _ubicacionActual;
  String? _direccion;
  bool _geocodificando = false;
  UbicacionNoDisponible? _sinUbicacion;
  List<Zona> _zonas = const [];

  @override
  void initState() {
    super.initState();
    _subscription = widget.service.ubicacionStream.listen(
      (ubicacion) => setState(() {
        _ubicacionActual = ubicacion;
        _sinUbicacion = null;
      }),
      onError: (Object e) {
        if (e is UbicacionNoDisponible) setState(() => _sinUbicacion = e);
      },
    );
    _cargarZonas();
  }

  Future<void> _cargarZonas() async {
    final repo = widget.zonaRepository;
    if (repo == null) return;
    try {
      final zonas = await repo.obtenerPuntos();
      if (mounted) setState(() => _zonas = zonas.where((z) => z.tieneCoordenadas).toList());
    } catch (_) {
      // Sin catálogo se muestran solo las coordenadas; el error ya quedó en el log.
    }
  }

  /// Zona con coordenadas más cercana a [u] y su distancia en metros.
  (Zona, double)? _zonaCercana(Ubicacion u) {
    (Zona, double)? mejor;
    for (final z in _zonas) {
      final d = FiltroUbicacion.distanciaM(u.lat, u.lng, z.lat, z.lng);
      if (mejor == null || d < mejor.$2) mejor = (z, d);
    }
    return mejor;
  }

  Future<void> _geocodificar(GeocodingAdapter geocoding) async {
    final ubicacion = _ubicacionActual;
    if (ubicacion == null) return;
    setState(() => _geocodificando = true);
    String resultado;
    try {
      final direccion = await geocoding.geocodificarInversa(
        lat: ubicacion.lat,
        lng: ubicacion.lng,
      );
      resultado = direccion.texto;
    } catch (_) {
      // Mensaje de error controlado ante red caída o respuesta inválida
      // (Escenario 3, ADR 0005).
      resultado = 'No se pudo obtener la dirección. Revisa tu conexión.';
    }
    if (!mounted) return;
    setState(() {
      _direccion = resultado;
      _geocodificando = false;
    });
  }

  static String _textoSinUbicacion(UbicacionNoDisponible fallo) => switch (fallo.motivo) {
        MotivoSinUbicacion.permisoDenegado =>
          'Sin permiso de ubicación: actívalo para este sitio en el navegador.',
        MotivoSinUbicacion.servicioApagado => 'La ubicación del dispositivo está apagada.',
        MotivoSinUbicacion.sinSenal => 'No hay señal GPS suficiente (sal a un espacio abierto).',
        MotivoSinUbicacion.precisionBaja =>
          'Tu ubicación es demasiado imprecisa (± ${fallo.precisionM?.round() ?? '?'} m): '
              'un computador suele ubicarse por Wi-Fi. Usa el celular en el campus.',
      };

  /// Título y detalle: «Estás cerca de A2» / «a 40 m · ± 8 m».
  (String, String?) _dondeEstas(Ubicacion u) {
    final precision = u.precisionM == null ? null : '± ${u.precisionM!.round()} m';
    final cercana = _zonaCercana(u);
    if (cercana == null) return (u.toString(), precision);
    final (zona, metros) = cercana;
    if (metros > UbicacionScreen.maxDistanciaAlCampusM) return ('Estás fuera del campus', precision);
    final detalle = ['a ${metros.round()} m', if (precision != null) precision].join(' · ');
    return ('Estás cerca de ${zona.nombre}', detalle);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ubicacion = _ubicacionActual;
    final geocoding = widget.geocoding;
    final tema = Theme.of(context);
    final (titulo, detalle) = ubicacion == null ? ('Esperando tu ubicación…', null) : _dondeEstas(ubicacion);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.my_location, size: 64),
            const SizedBox(height: 16),
            Text(titulo, key: const Key('donde_estas'), style: tema.textTheme.headlineSmall, textAlign: TextAlign.center),
            if (detalle != null) Text(detalle, key: const Key('detalle_ubicacion')),
            if (ubicacion != null && _zonas.isNotEmpty)
              Text(ubicacion.toString(), key: const Key('coordenadas'), style: tema.textTheme.bodySmall),
            if (_sinUbicacion case final fallo?)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_textoSinUbicacion(fallo), key: const Key('sin_ubicacion'), textAlign: TextAlign.center),
              ),
            if (geocoding != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: ubicacion == null || _geocodificando
                    ? null
                    : () => _geocodificar(geocoding),
                icon: const Icon(Icons.place),
                label: const Text('¿Dónde estoy?'),
              ),
              if (_direccion != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_direccion!, textAlign: TextAlign.center),
                ),
            ],
            if (widget.service is UbicacionServiceSimulado) ...[
              const SizedBox(height: 24),
              Text(
                '(Ubicación simulada para demostración: no es tu posición real)',
                textAlign: TextAlign.center,
                // onSurfaceVariant y no gris fijo: el gris sobre blanco no llegaba a 4,5:1.
                style: TextStyle(color: tema.colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
