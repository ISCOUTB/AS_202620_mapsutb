import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mapsutb/adapters/analytics_adapter.dart';
import 'package:mapsutb/adapters/mapa_widget.dart';
import 'package:mapsutb/core/log.dart';
import 'package:mapsutb/models/evento_analitica.dart';
import 'package:mapsutb/models/ubicacion.dart';
import 'package:mapsutb/models/zona.dart';
import 'package:mapsutb/repositories/zona_repository.dart';
import 'package:mapsutb/routing/grafo.dart';
import 'package:mapsutb/routing/mapa_repository.dart';
import 'package:mapsutb/routing/servicio_ruteo.dart';
import 'package:mapsutb/services/ubicacion_service.dart';

/// Pantalla de mapa (A-01, ADR 0012 y 0013): zonas del campus sobre el mapa
/// base, posición del usuario y ruta a pie hasta la zona elegida.
class MapaScreen extends StatefulWidget {
  const MapaScreen({
    super.key,
    required this.zonaRepository,
    required this.mapaRepository,
    required this.ubicacionService,
    this.destinoInicial,
    this.analytics = const AnalyticsAdapterNulo(),
    this.mostrarTeselas = true,
  });

  final ZonaRepository zonaRepository;
  final MapaRepository mapaRepository;
  final UbicacionService ubicacionService;
  final String? destinoInicial;
  final AnalyticsAdapter analytics;
  final bool mostrarTeselas;

  /// Más lejos que esto del camino más cercano, el usuario no está en el campus.
  static const maxDistanciaAlCampusM = 300.0;

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  late Future<(List<Zona>, GrafoPeatonal)> _datos;
  StreamSubscription<Ubicacion>? _sub;
  Ubicacion? _posicion;
  String? _destino;
  bool _evitarEscaleras = false;

  /// Último destino cuya ruta ya se midió, para registrar una muestra por
  /// destino y no en cada actualización del GPS.
  String? _destinoMedido;

  @override
  void initState() {
    super.initState();
    _destino = widget.destinoInicial;
    _datos = _cargar();
    _sub = widget.ubicacionService.ubicacionStream.listen((u) {
      setState(() {
        _posicion = u;
      });
    });
  }

  Future<(List<Zona>, GrafoPeatonal)> _cargar() async {
    final zonas = await widget.zonaRepository.obtenerPuntos();
    final grafo = await widget.mapaRepository.obtenerGrafo();
    return (zonas, grafo);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _elegirDestino(String? id) {
    setState(() {
      _destino = id;
      _destinoMedido = null; // vuelve a medir para el destino nuevo
    });
    if (id != null) {
      widget.analytics.registrarEvento(EventoAnalitica(nombre: 'solicitud_ruta', parametros: {'zona_destino': id})).ignore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(List<Zona>, GrafoPeatonal)>(
      future: _datos,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('No se pudo cargar el mapa del campus.'),
              TextButton(
                onPressed: () => setState(() {
                  _datos = _cargar();
                }),
                child: const Text('Reintentar'),
              ),
            ]),
          );
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final (zonas, grafo) = snapshot.data!;
        return _contenido(zonas, grafo);
      },
    );
  }

  Widget _contenido(List<Zona> todas, GrafoPeatonal grafo) {
    // Medición de la parte de pantalla del Escenario 2: desde que la pantalla
    // tiene destino y posición hasta que el frame con la ruta está presentado.
    // No incluye la espera del sensor GPS, que el escenario mide aparte.
    final reloj = Stopwatch()..start();
    final zonas = todas.where((z) => z.tieneCoordenadas && grafo.entradas.containsKey(z.id)).toList();
    final destino = zonas.any((z) => z.id == _destino) ? _destino : null;
    final estado = _calcularRuta(grafo, destino);
    final ruta = estado.ruta;
    if (ruta != null && destino != _destinoMedido) {
      _destinoMedido = destino;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Log.info('ruta_mostrada', {
          'zona_destino': destino,
          'metros': ruta.metros.round(),
          'evitar_escaleras': _evitarEscaleras,
          'duracion_ms': reloj.elapsedMilliseconds,
        });
      });
    }
    final pos = _posicion;
    Zona? centro;
    if (destino != null) {
      centro = zonas.firstWhere((z) => z.id == destino);
    } else if (zonas.isNotEmpty) {
      centro = zonas.first;
    }

    return Stack(children: [
      Positioned.fill(
        child: MapaWidget(
          latCentro: centro?.lat ?? 10.3700,
          lngCentro: centro?.lng ?? -75.4655,
          lugares: [for (final z in zonas) LugarEnMapa(id: z.id, etiqueta: z.nombre, lat: z.lat, lng: z.lng)],
          ruta: ruta?.geometria ?? const [],
          posicion: pos == null ? null : [pos.lat, pos.lng],
          lugarSeleccionado: destino,
          onLugarTocado: _elegirDestino,
          mostrarTeselas: widget.mostrarTeselas,
        ),
      ),
      Positioned(
        left: 12,
        right: 12,
        top: 12,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              DropdownButton<String>(
                key: const Key('destino'),
                isExpanded: true,
                value: destino,
                hint: const Text('¿A dónde vas?'),
                underline: const SizedBox.shrink(),
                items: [for (final z in zonas) DropdownMenuItem(value: z.id, child: Text(z.nombre))],
                onChanged: _elegirDestino,
              ),
              FilterChip(
                key: const Key('evitar_escaleras'),
                label: const Text('Evitar escaleras'),
                selected: _evitarEscaleras,
                onSelected: (v) => setState(() => _evitarEscaleras = v),
              ),
            ]),
          ),
        ),
      ),
      Positioned(
        left: 12,
        right: 12,
        bottom: 24,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(estado.mensaje, key: const Key('resumen_ruta'), style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
      ),
    ]);
  }

  _EstadoRuta _calcularRuta(GrafoPeatonal grafo, String? destino) {
    final pos = _posicion;
    if (destino == null) return const _EstadoRuta(null, 'Elige un destino o toca una zona del mapa.');
    if (pos == null) return const _EstadoRuta(null, 'Esperando tu ubicación…');
    final cercano = grafo.nodoMasCercano(pos.lat, pos.lng);
    if (cercano == null || cercano.$2 > MapaScreen.maxDistanciaAlCampusM) {
      return const _EstadoRuta(null, 'Estás fuera del campus: la ruta se calcula desde los caminos del campus.');
    }
    final ruta = ServicioRuteo(grafo).rutaDesdePosicion(pos.lat, pos.lng, destino, evitarEscaleras: _evitarEscaleras);
    if (ruta == null) {
      return _EstadoRuta(null, _evitarEscaleras
          ? 'No hay ruta sin escaleras hasta ese destino.'
          : 'No hay ruta hasta ese destino.');
    }
    final minutos = (ruta.tiempoCaminando.inSeconds / 60).ceil();
    final n = ruta.tramosConEscaleras;
    final plural = n == 1 ? '' : 's';
    final escaleras = n == 0 ? 'sin escaleras' : '$n tramo$plural con escaleras';
    return _EstadoRuta(ruta, '$minutos min · ${ruta.metros.round()} m · $escaleras');
  }
}

class _EstadoRuta {
  const _EstadoRuta(this.ruta, this.mensaje);
  final Ruta? ruta;
  final String mensaje;
}
