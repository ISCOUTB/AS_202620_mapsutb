import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapsutb/adapters/geocoding_adapter.dart';
import 'package:mapsutb/models/ubicacion.dart';
import 'package:mapsutb/services/ubicacion_service.dart';

class UbicacionScreen extends StatefulWidget {
  final UbicacionService service;
  final GeocodingAdapter? geocoding;
  const UbicacionScreen({super.key, required this.service, this.geocoding});

  @override
  State<UbicacionScreen> createState() => _UbicacionScreenState();
}

class _UbicacionScreenState extends State<UbicacionScreen> {
  StreamSubscription<Ubicacion>? _subscription;
  Ubicacion? _ubicacionActual;
  int _actualizaciones = 0;
  String? _direccion;
  bool _geocodificando = false;

  @override
  void initState() {
    super.initState();
    _subscription = widget.service.ubicacionStream.listen((ubicacion) {
      setState(() {
        _ubicacionActual = ubicacion;
        _actualizaciones++;
      });
    });
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

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ubicacion = _ubicacionActual;
    final geocoding = widget.geocoding;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.my_location, size: 64),
          const SizedBox(height: 16),
          Text(
            ubicacion == null ? 'Esperando señal...' : ubicacion.toString(),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text('Actualizaciones recibidas: $_actualizaciones'),
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
                padding: const EdgeInsets.fromLTRB(32, 8, 32, 0),
                child: Text(_direccion!, textAlign: TextAlign.center),
              ),
          ],
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              '(Servicio de ubicación simulado — patrón Observer, '
              'Stream<Ubicacion>, sin GPS real todavía)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
