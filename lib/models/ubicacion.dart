class Ubicacion {
  final double lat;
  final double lng;
  final DateTime timestamp;

  Ubicacion({
    required this.lat,
    required this.lng,
    required this.timestamp,
  });

  @override
  String toString() =>
      'lat: ${lat.toStringAsFixed(5)}, lng: ${lng.toStringAsFixed(5)}';
}
