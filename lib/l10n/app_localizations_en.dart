// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navZonas => 'Zones';

  @override
  String get navMapa => 'Map';

  @override
  String get navConfiguracion => 'Settings';

  @override
  String get configTitulo => 'Settings';

  @override
  String get configNotificaciones => 'Notifications';

  @override
  String get configNotificacionesWeb =>
      'Notifications are disabled on the web version.';

  @override
  String get configIdioma => 'Language';

  @override
  String get configAcercaDe => 'About';

  @override
  String get acercaDeDescripcion =>
      'Interactive map and pedestrian routing system for the UTB campus.';
}
