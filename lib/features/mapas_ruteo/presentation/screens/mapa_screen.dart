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

  /// Alguna tesela del mapa base no cargó (arc42 §11, MF-01/MF-02).
  bool _sinMapaBase = false;

  /// Por qué el sensor no da posición (MF-04); null si la está dando.
  MotivoSinUbicacion? _sinUbicacion;

  /// Punto de partida que el usuario marcó tocando el mapa, cuando el GPS no
  /// sirve: sin permiso, sin señal o fuera del campus. Tiene prioridad sobre
  /// el GPS hasta que el usuario vuelva a «Usar mi GPS».
  Ubicacion? _origenManual;

  /// Último destino cuya ruta ya se midió, para registrar una muestra por
  /// destino y no en cada actualización del GPS.
  String? _destinoMedido;

  @override
  void initState() {
    super.initState();
    _destino = widget.destinoInicial;
    _datos = _cargar();
    _sub = widget.ubicacionService.ubicacionStream.listen(
      (u) => setState(() {
        _posicion = u;
        _sinUbicacion = null;
      }),
      onError: (Object e) {
        if (e is UbicacionNoDisponible) setState(() => _sinUbicacion = e.motivo);
      },
    );
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
    final pos = _origenManual ?? _posicion;
    final gps = _posicion;
    final gpsUtil = gps != null && _enCampus(grafo, gps);
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
          onMapaBaseFalla: _avisarSinMapaBase,
          onMapaTocado: gpsUtil && _origenManual == null ? null : _marcarOrigen,
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
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(estado.mensaje, key: const Key('resumen_ruta'), style: Theme.of(context).textTheme.titleMedium),
              if (_origenManual != null)
                TextButton.icon(
                  key: const Key('usar_gps'),
                  onPressed: () => setState(() => _origenManual = null),
                  icon: const Icon(Icons.my_location),
                  label: const Text('Partida marcada a mano · Usar mi GPS'),
                ),
              if (_sinMapaBase)
                const Text(
                  'Sin conexión al mapa base: la ruta sigue siendo válida, sale de los caminos guardados en la app.',
                  key: Key('aviso_sin_mapa_base'),
                ),
            ]),
          ),
        ),
      ),
    ]);
  }

  /// Llega una vez por tesela fallida: solo el primer aviso redibuja.
  void _avisarSinMapaBase() {
    if (_sinMapaBase || !mounted) return;
    Log.warn('mapa_base_sin_teselas');
    setState(() => _sinMapaBase = true);
  }

  bool _enCampus(GrafoPeatonal grafo, Ubicacion u) {
    final cercano = grafo.nodoMasCercano(u.lat, u.lng);
    return cercano != null && cercano.$2 <= MapaScreen.maxDistanciaAlCampusM;
  }

  void _marcarOrigen(double lat, double lng) {
    setState(() => _origenManual = Ubicacion(lat: lat, lng: lng, timestamp: DateTime.now()));
  }

  static const _tocaElMapa = 'Toca el mapa para marcar tu punto de partida.';

  _EstadoRuta _calcularRuta(GrafoPeatonal grafo, String? destino) {
    final pos = _origenManual ?? _posicion;
    if (destino == null) return const _EstadoRuta(null, 'Elige un destino o toca una zona del mapa.');
    if (pos == null) {
      return switch (_sinUbicacion) {
        MotivoSinUbicacion.permisoDenegado => const _EstadoRuta(null, 'Sin permiso de ubicación. $_tocaElMapa'),
        MotivoSinUbicacion.servicioApagado => const _EstadoRuta(null, 'La ubicación del dispositivo está apagada. $_tocaElMapa'),
        MotivoSinUbicacion.sinSenal => const _EstadoRuta(null, 'No hay señal GPS suficiente. $_tocaElMapa'),
        null => const _EstadoRuta(null, 'Esperando tu ubicación…'),
      };
    }
    if (!_enCampus(grafo, pos)) {
      return const _EstadoRuta(null, 'Estás fuera del campus: la ruta se calcula desde los caminos del campus. $_tocaElMapa');
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
