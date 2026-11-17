import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr')
  ];

  /// No description provided for @zones.
  ///
  /// In es, this message translates to:
  /// **'Zonas'**
  String get zones;

  /// No description provided for @map.
  ///
  /// In es, this message translates to:
  /// **'Mapa'**
  String get map;

  /// No description provided for @location.
  ///
  /// In es, this message translates to:
  /// **'Ubicaci?n'**
  String get location;

  /// No description provided for @loadZonesError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las zonas.'**
  String get loadZonesError;

  /// No description provided for @loadMapError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el mapa del campus.'**
  String get loadMapError;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @searchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar zona, espacio o sal?n'**
  String get searchHint;

  /// No description provided for @clearSearch.
  ///
  /// In es, this message translates to:
  /// **'Borrar b?squeda'**
  String get clearSearch;

  /// No description provided for @howToGetThere.
  ///
  /// In es, this message translates to:
  /// **'C?mo llegar'**
  String get howToGetThere;

  /// No description provided for @noSpaces.
  ///
  /// In es, this message translates to:
  /// **'Esta zona no tiene espacios registrados.'**
  String get noSpaces;

  /// No description provided for @spaces.
  ///
  /// In es, this message translates to:
  /// **'Espacios'**
  String get spaces;

  /// No description provided for @noSpacesOnFloor.
  ///
  /// In es, this message translates to:
  /// **'Sin espacios registrados en este piso.'**
  String get noSpacesOnFloor;

  /// No description provided for @otherSpaces.
  ///
  /// In es, this message translates to:
  /// **'Otros espacios'**
  String get otherSpaces;

  /// No description provided for @mapUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Mapa no disponible.'**
  String get mapUnavailable;

  /// No description provided for @noResults.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados para ?{query}?'**
  String noResults(Object query);

  /// No description provided for @searchTip.
  ///
  /// In es, this message translates to:
  /// **'Prueba con el nombre del bloque, del espacio o el n?mero del sal?n.'**
  String get searchTip;

  /// No description provided for @destinationPrompt.
  ///
  /// In es, this message translates to:
  /// **'?A d?nde vas?'**
  String get destinationPrompt;

  /// No description provided for @avoidStairs.
  ///
  /// In es, this message translates to:
  /// **'Evitar escaleras'**
  String get avoidStairs;

  /// No description provided for @manualStartUseGps.
  ///
  /// In es, this message translates to:
  /// **'Partida marcada a mano ? Usar mi GPS'**
  String get manualStartUseGps;

  /// No description provided for @baseMapOffline.
  ///
  /// In es, this message translates to:
  /// **'Sin conexi?n al mapa base: la ruta sigue siendo v?lida, sale de los caminos guardados en la app.'**
  String get baseMapOffline;

  /// No description provided for @osmAttribution.
  ///
  /// In es, this message translates to:
  /// **'colaboradores de OpenStreetMap'**
  String get osmAttribution;

  /// No description provided for @noType.
  ///
  /// In es, this message translates to:
  /// **'Sin tipo'**
  String get noType;

  /// No description provided for @auditorium.
  ///
  /// In es, this message translates to:
  /// **'Auditorio'**
  String get auditorium;

  /// No description provided for @library.
  ///
  /// In es, this message translates to:
  /// **'Biblioteca'**
  String get library;

  /// No description provided for @cafeteria.
  ///
  /// In es, this message translates to:
  /// **'Cafeter?a'**
  String get cafeteria;

  /// No description provided for @building.
  ///
  /// In es, this message translates to:
  /// **'Edificio'**
  String get building;

  /// No description provided for @laboratory.
  ///
  /// In es, this message translates to:
  /// **'Laboratorio'**
  String get laboratory;

  /// No description provided for @office.
  ///
  /// In es, this message translates to:
  /// **'Oficina'**
  String get office;

  /// No description provided for @institutionalOffice.
  ///
  /// In es, this message translates to:
  /// **'Oficina institucional'**
  String get institutionalOffice;

  /// No description provided for @parking.
  ///
  /// In es, this message translates to:
  /// **'Parqueadero'**
  String get parking;

  /// No description provided for @classroom.
  ///
  /// In es, this message translates to:
  /// **'Sal?n'**
  String get classroom;

  /// No description provided for @service.
  ///
  /// In es, this message translates to:
  /// **'Servicio'**
  String get service;

  /// No description provided for @commonArea.
  ///
  /// In es, this message translates to:
  /// **'Zona com?n'**
  String get commonArea;

  /// No description provided for @floorCount.
  ///
  /// In es, this message translates to:
  /// **'{count} pisos'**
  String floorCount(int count);

  /// No description provided for @floorCountOne.
  ///
  /// In es, this message translates to:
  /// **'{count} piso'**
  String floorCountOne(int count);

  /// No description provided for @spaceCount.
  ///
  /// In es, this message translates to:
  /// **'{count} espacios'**
  String spaceCount(int count);

  /// No description provided for @spaceCountOne.
  ///
  /// In es, this message translates to:
  /// **'{count} espacio'**
  String spaceCountOne(int count);

  /// No description provided for @whereAmI.
  ///
  /// In es, this message translates to:
  /// **'?D?nde estoy?'**
  String get whereAmI;

  /// No description provided for @waitingLocation.
  ///
  /// In es, this message translates to:
  /// **'Esperando tu ubicaci?n?'**
  String get waitingLocation;

  /// No description provided for @noLocationPermission.
  ///
  /// In es, this message translates to:
  /// **'Sin permiso de ubicaci?n.'**
  String get noLocationPermission;

  /// No description provided for @locationOff.
  ///
  /// In es, this message translates to:
  /// **'La ubicaci?n del dispositivo est? apagada.'**
  String get locationOff;

  /// No description provided for @noGpsSignal.
  ///
  /// In es, this message translates to:
  /// **'No hay se?al GPS suficiente.'**
  String get noGpsSignal;

  /// No description provided for @retryLocation.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu ubicaci?n y vuelve a intentarlo.'**
  String get retryLocation;

  /// No description provided for @outsideCampus.
  ///
  /// In es, this message translates to:
  /// **'Est?s fuera del campus'**
  String get outsideCampus;

  /// No description provided for @nearZone.
  ///
  /// In es, this message translates to:
  /// **'Est?s cerca de {zone}'**
  String nearZone(Object zone);

  /// No description provided for @distanceMeters.
  ///
  /// In es, this message translates to:
  /// **'a {meters} m'**
  String distanceMeters(int meters);

  /// No description provided for @routeChoose.
  ///
  /// In es, this message translates to:
  /// **'Elige un destino o toca una zona del mapa.'**
  String get routeChoose;

  /// No description provided for @routeWait.
  ///
  /// In es, this message translates to:
  /// **'Esperando tu ubicaci?n?'**
  String get routeWait;

  /// No description provided for @routeOutside.
  ///
  /// In es, this message translates to:
  /// **'Est?s fuera del campus: la ruta se calcula desde los caminos del campus.'**
  String get routeOutside;

  /// No description provided for @routeNoStairs.
  ///
  /// In es, this message translates to:
  /// **'No hay ruta sin escaleras hasta ese destino.'**
  String get routeNoStairs;

  /// No description provided for @routeNone.
  ///
  /// In es, this message translates to:
  /// **'No hay ruta hasta ese destino.'**
  String get routeNone;

  /// No description provided for @routeMeters.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min ? {meters} m'**
  String routeMeters(int minutes, int meters);

  /// No description provided for @manualStart.
  ///
  /// In es, this message translates to:
  /// **'Toca el mapa para marcar tu punto de partida.'**
  String get manualStart;

  /// No description provided for @simulatedLocation.
  ///
  /// In es, this message translates to:
  /// **'(Ubicaci?n simulada para demostraci?n: no es tu posici?n real)'**
  String get simulatedLocation;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
