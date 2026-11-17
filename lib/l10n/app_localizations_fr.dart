// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get zones => 'Zones';

  @override
  String get map => 'Carte';

  @override
  String get location => 'Localisation';

  @override
  String get loadZonesError => 'Impossible de charger les zones.';

  @override
  String get loadMapError => 'Impossible de charger la carte du campus.';

  @override
  String get retry => 'R?essayer';

  @override
  String get searchHint => 'Rechercher une zone, un espace ou une salle';

  @override
  String get clearSearch => 'Effacer la recherche';

  @override
  String get howToGetThere => 'Itin?raire';

  @override
  String get noSpaces => 'Aucun espace n?est enregistr? dans cette zone.';

  @override
  String get spaces => 'Espaces';

  @override
  String get noSpacesOnFloor => 'Aucun espace n?est enregistr? ? cet ?tage.';

  @override
  String get otherSpaces => 'Autres espaces';

  @override
  String get mapUnavailable => 'Carte indisponible.';

  @override
  String noResults(Object query) {
    return 'Aucun r?sultat pour ? $query ?';
  }

  @override
  String get searchTip =>
      'Essayez le nom du b?timent, de l?espace ou le num?ro de la salle.';

  @override
  String get destinationPrompt => 'O? allez-vous ?';

  @override
  String get avoidStairs => '?viter les escaliers';

  @override
  String get manualStartUseGps =>
      'D?part indiqu? manuellement ? Utiliser mon GPS';

  @override
  String get baseMapOffline =>
      'Carte de base hors ligne. L?itin?raire reste valide et suit les chemins enregistr?s dans l?application.';

  @override
  String get osmAttribution => 'contributeurs OpenStreetMap';

  @override
  String get noType => 'Non class?';

  @override
  String get auditorium => 'Auditorium';

  @override
  String get library => 'Biblioth?que';

  @override
  String get cafeteria => 'Caf?t?ria';

  @override
  String get building => 'B?timent';

  @override
  String get laboratory => 'Laboratoire';

  @override
  String get office => 'Bureau';

  @override
  String get institutionalOffice => 'Bureau institutionnel';

  @override
  String get parking => 'Parking';

  @override
  String get classroom => 'Salle de cours';

  @override
  String get service => 'Service';

  @override
  String get commonArea => 'Espace commun';

  @override
  String floorCount(int count) {
    return '$count ?tages';
  }

  @override
  String floorCountOne(int count) {
    return '$count ?tage';
  }

  @override
  String spaceCount(int count) {
    return '$count espaces';
  }

  @override
  String spaceCountOne(int count) {
    return '$count espace';
  }

  @override
  String get whereAmI => 'O? suis-je ?';

  @override
  String get waitingLocation => 'En attente de votre position?';

  @override
  String get noLocationPermission => 'Autorisation de localisation refus?e.';

  @override
  String get locationOff => 'La localisation de l?appareil est d?sactiv?e.';

  @override
  String get noGpsSignal => 'Signal GPS insuffisant.';

  @override
  String get retryLocation => 'V?rifiez votre position et r?essayez.';

  @override
  String get outsideCampus => 'Vous ?tes hors du campus';

  @override
  String nearZone(Object zone) {
    return 'Vous ?tes pr?s de $zone';
  }

  @override
  String distanceMeters(int meters) {
    return '? $meters m';
  }

  @override
  String get routeChoose =>
      'Choisissez une destination ou touchez une zone sur la carte.';

  @override
  String get routeWait => 'En attente de votre position?';

  @override
  String get routeOutside =>
      'Vous ?tes hors du campus. L?itin?raire suit les chemins du campus.';

  @override
  String get routeNoStairs =>
      'Aucun itin?raire sans escaliers vers cette destination.';

  @override
  String get routeNone => 'Aucun itin?raire disponible vers cette destination.';

  @override
  String routeMeters(int minutes, int meters) {
    return '$minutes min ? $meters m';
  }

  @override
  String get manualStart =>
      'Touchez la carte pour indiquer votre point de d?part.';

  @override
  String get simulatedLocation =>
      '(Position simul?e pour la d?monstration ; ce n?est pas votre position r?elle)';
}
