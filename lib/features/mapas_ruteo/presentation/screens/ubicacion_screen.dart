import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapsutb/models/ubicacion.dart';
import 'package:mapsutb/services/ubicacion_service.dart';

class UbicacionScreen extends StatefulWidget {
  final UbicacionService service;
  const UbicacionScreen({super.key, required this.service});

  @override
  State<UbicacionScreen> createState() => _UbicacionScreenState();
}

class _UbicacionScreenState extends State<UbicacionScreen> {
  StreamSubscription<Ubicacion>? _subscription;
  Ubicacion? _ubicacionActual;
  int _actualizaciones = 0;

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

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ubicacion = _ubicacionActual;
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
