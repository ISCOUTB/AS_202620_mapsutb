class Ubicacion {
  final double lat;
  final double lng;
  final DateTime timestamp;

  /// Radio de error que declara el sensor, en metros (null si no lo da).
  final double? precisionM;

  Ubicacion({
    required this.lat,
    required this.lng,
    required this.timestamp,
    this.precisionM,
  });

  @override
  String toString() =>
      'lat: ${lat.toStringAsFixed(5)}, lng: ${lng.toStringAsFixed(5)}';
}
