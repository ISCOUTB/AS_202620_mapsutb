// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get zones => 'Zones';

  @override
  String get map => 'Map';

  @override
  String get location => 'Location';

  @override
  String get loadZonesError => 'Could not load the zones.';

  @override
  String get loadMapError => 'Could not load the campus map.';

  @override
  String get retry => 'Retry';

  @override
  String get searchHint => 'Search zone, space, or classroom';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get howToGetThere => 'Directions';

  @override
  String get noSpaces => 'No spaces are registered in this zone.';

  @override
  String get spaces => 'Spaces';

  @override
  String get noSpacesOnFloor => 'No spaces are registered on this floor.';

  @override
  String get otherSpaces => 'Other spaces';

  @override
  String get mapUnavailable => 'Map unavailable.';

  @override
  String noResults(Object query) {
    return 'No results for ?$query?';
  }

  @override
  String get searchTip =>
      'Try a building name, space name, or classroom number.';

  @override
  String get destinationPrompt => 'Where are you going?';

  @override
  String get avoidStairs => 'Avoid stairs';

  @override
  String get manualStartUseGps => 'Starting point marked manually ? Use my GPS';

  @override
  String get baseMapOffline =>
      'Base map connection unavailable. The route remains valid and uses paths saved in the app.';

  @override
  String get osmAttribution => 'OpenStreetMap contributors';

  @override
  String get noType => 'Unclassified';

  @override
  String get auditorium => 'Auditorium';

  @override
  String get library => 'Library';

  @override
  String get cafeteria => 'Cafeteria';

  @override
  String get building => 'Building';

  @override
  String get laboratory => 'Laboratory';

  @override
  String get office => 'Office';

  @override
  String get institutionalOffice => 'Institutional office';

  @override
  String get parking => 'Parking';

  @override
  String get classroom => 'Classroom';

  @override
  String get service => 'Service';

  @override
  String get commonArea => 'Common area';

  @override
  String floorCount(int count) {
    return '$count floors';
  }

  @override
  String floorCountOne(int count) {
    return '$count floor';
  }

  @override
  String spaceCount(int count) {
    return '$count spaces';
  }

  @override
  String spaceCountOne(int count) {
    return '$count space';
  }

  @override
  String get whereAmI => 'Where am I?';

  @override
  String get waitingLocation => 'Waiting for your location?';

  @override
  String get noLocationPermission => 'Location permission denied.';

  @override
  String get locationOff => 'Device location is turned off.';

  @override
  String get noGpsSignal => 'No sufficient GPS signal.';

  @override
  String get retryLocation => 'Check your location and try again.';

  @override
  String get outsideCampus => 'You are outside the campus';

  @override
  String nearZone(Object zone) {
    return 'You are near $zone';
  }

  @override
  String distanceMeters(int meters) {
    return '$meters m away';
  }

  @override
  String get routeChoose => 'Choose a destination or tap a zone on the map.';

  @override
  String get routeWait => 'Waiting for your location?';

  @override
  String get routeOutside =>
      'You are outside campus. Routes follow campus paths.';

  @override
  String get routeNoStairs =>
      'No stair-free route is available to that destination.';

  @override
  String get routeNone => 'No route is available to that destination.';

  @override
  String routeMeters(int minutes, int meters) {
    return '$minutes min ? $meters m';
  }

  @override
  String get manualStart => 'Tap the map to mark your starting point.';

  @override
  String get simulatedLocation =>
      '(Simulated location for demonstration; this is not your real position)';
}
