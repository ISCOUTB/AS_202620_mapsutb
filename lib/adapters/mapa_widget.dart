import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Un lugar que se dibuja en el mapa (por ejemplo, una zona del campus).
class LugarEnMapa {
  const LugarEnMapa({
    required this.id,
    required this.etiqueta,
    required this.lat,
    required this.lng,
  });

  final String id;
  final String etiqueta;
  final double lat;
  final double lng;
}

/// Adapter del mapa base (ADR 0002, ADR 0012): aísla al resto de la app de
/// flutter_map y de las teselas de OpenStreetMap. Fuera de este archivo nadie
/// usa tipos de flutter_map ni de latlong2; solo coordenadas como números.
class MapaWidget extends StatelessWidget {
  const MapaWidget({
    super.key,
    required this.latCentro,
    required this.lngCentro,
    this.lugares = const [],
    this.ruta = const [],
    this.posicion,
    this.lugarSeleccionado,
    this.onLugarTocado,
    this.mostrarTeselas = true,
  });

  static const _azul = Color(0xFF093AD8);
  static const _esmeralda = Color(0xFF028C5C);
  static const _lima = Color(0xFF71EC37);
  static const _navy = Color(0xFF032742);

  final double latCentro;
  final double lngCentro;
  final List<LugarEnMapa> lugares;

  /// Puntos [lat, lng] de la ruta a dibujar.
  final List<List<double>> ruta;

  /// Posición del usuario como [lat, lng].
  final List<double>? posicion;
  final String? lugarSeleccionado;
  final ValueChanged<String>? onLugarTocado;

  /// Las pruebas lo apagan para no pedir teselas por red.
  final bool mostrarTeselas;

  @override
  Widget build(BuildContext context) {
    final pos = posicion;
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(latCentro, lngCentro),
        initialZoom: 17.5,
        minZoom: 15,
        maxZoom: 19.5,
      ),
      children: [
        if (mostrarTeselas)
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.mapsutb',
          ),
        if (ruta.length >= 2)
          PolylineLayer(polylines: [
            Polyline(
              points: [for (final p in ruta) LatLng(p[0], p[1])],
              strokeWidth: 6,
              color: _esmeralda,
              borderStrokeWidth: 2,
              borderColor: Colors.white,
            ),
          ]),
        MarkerLayer(markers: [
          for (final l in lugares)
            Marker(
              point: LatLng(l.lat, l.lng),
              width: 120,
              height: 46,
              alignment: Alignment.topCenter,
              child: _Pin(
                lugar: l,
                seleccionado: l.id == lugarSeleccionado,
                onTap: onLugarTocado == null ? null : () => onLugarTocado!(l.id),
              ),
            ),
          if (pos != null)
            Marker(
              point: LatLng(pos[0], pos[1]),
              width: 26,
              height: 26,
              child: Container(
                key: const Key('posicion_usuario'),
                decoration: BoxDecoration(
                  color: _lima,
                  shape: BoxShape.circle,
                  border: Border.all(color: _navy, width: 3),
                ),
              ),
            ),
        ]),
        const SimpleAttributionWidget(
          source: Text('© colaboradores de OpenStreetMap'),
        ),
      ],
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.lugar, required this.seleccionado, this.onTap});

  final LugarEnMapa lugar;
  final bool seleccionado;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = seleccionado ? MapaWidget._esmeralda : MapaWidget._azul;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
            child: Text(
              lugar.etiqueta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          Icon(Icons.location_on, color: color, size: 20),
        ],
      ),
    );
  }
}
