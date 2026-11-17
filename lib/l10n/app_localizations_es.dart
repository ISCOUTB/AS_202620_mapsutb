// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get zones => 'Zonas';

  @override
  String get map => 'Mapa';

  @override
  String get location => 'Ubicaci?n';

  @override
  String get loadZonesError => 'No se pudieron cargar las zonas.';

  @override
  String get loadMapError => 'No se pudo cargar el mapa del campus.';

  @override
  String get retry => 'Reintentar';

  @override
  String get searchHint => 'Buscar zona, espacio o sal?n';

  @override
  String get clearSearch => 'Borrar b?squeda';

  @override
  String get howToGetThere => 'C?mo llegar';

  @override
  String get noSpaces => 'Esta zona no tiene espacios registrados.';

  @override
  String get spaces => 'Espacios';

  @override
  String get noSpacesOnFloor => 'Sin espacios registrados en este piso.';

  @override
  String get otherSpaces => 'Otros espacios';

  @override
  String get mapUnavailable => 'Mapa no disponible.';

  @override
  String noResults(Object query) {
    return 'Sin resultados para ?$query?';
  }

  @override
  String get searchTip =>
      'Prueba con el nombre del bloque, del espacio o el n?mero del sal?n.';

  @override
  String get destinationPrompt => '?A d?nde vas?';

  @override
  String get avoidStairs => 'Evitar escaleras';

  @override
  String get manualStartUseGps => 'Partida marcada a mano ? Usar mi GPS';

  @override
  String get baseMapOffline =>
      'Sin conexi?n al mapa base: la ruta sigue siendo v?lida, sale de los caminos guardados en la app.';

  @override
  String get osmAttribution => 'colaboradores de OpenStreetMap';

  @override
  String get noType => 'Sin tipo';

  @override
  String get auditorium => 'Auditorio';

  @override
  String get library => 'Biblioteca';

  @override
  String get cafeteria => 'Cafeter?a';

  @override
  String get building => 'Edificio';

  @override
  String get laboratory => 'Laboratorio';

  @override
  String get office => 'Oficina';

  @override
  String get institutionalOffice => 'Oficina institucional';

  @override
  String get parking => 'Parqueadero';

  @override
  String get classroom => 'Sal?n';

  @override
  String get service => 'Servicio';

  @override
  String get commonArea => 'Zona com?n';

  @override
  String floorCount(int count) {
    return '$count pisos';
  }

  @override
  String floorCountOne(int count) {
    return '$count piso';
  }

  @override
  String spaceCount(int count) {
    return '$count espacios';
  }

  @override
  String spaceCountOne(int count) {
    return '$count espacio';
  }

  @override
  String get whereAmI => '?D?nde estoy?';

  @override
  String get waitingLocation => 'Esperando tu ubicaci?n?';

  @override
  String get noLocationPermission => 'Sin permiso de ubicaci?n.';

  @override
  String get locationOff => 'La ubicaci?n del dispositivo est? apagada.';

  @override
  String get noGpsSignal => 'No hay se?al GPS suficiente.';

  @override
  String get retryLocation => 'Revisa tu ubicaci?n y vuelve a intentarlo.';

  @override
  String get outsideCampus => 'Est?s fuera del campus';

  @override
  String nearZone(Object zone) {
    return 'Est?s cerca de $zone';
  }

  @override
  String distanceMeters(int meters) {
    return 'a $meters m';
  }

  @override
  String get routeChoose => 'Elige un destino o toca una zona del mapa.';

  @override
  String get routeWait => 'Esperando tu ubicaci?n?';

  @override
  String get routeOutside =>
      'Est?s fuera del campus: la ruta se calcula desde los caminos del campus.';

  @override
  String get routeNoStairs => 'No hay ruta sin escaleras hasta ese destino.';

  @override
  String get routeNone => 'No hay ruta hasta ese destino.';

  @override
  String routeMeters(int minutes, int meters) {
    return '$minutes min ? $meters m';
  }

  @override
  String get manualStart => 'Toca el mapa para marcar tu punto de partida.';

  @override
  String get simulatedLocation =>
      '(Ubicaci?n simulada para demostraci?n: no es tu posici?n real)';
}
