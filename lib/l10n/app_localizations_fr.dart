// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get navZonas => 'Zones';

  @override
  String get navMapa => 'Carte';

  @override
  String get navConfiguracion => 'Paramètres';

  @override
  String get configTitulo => 'Paramètres';

  @override
  String get configNotificaciones => 'Notifications';

  @override
  String get configNotificacionesWeb =>
      'Les notifications sont désactivées sur la version web.';

  @override
  String get configIdioma => 'Langue';

  @override
  String get configAcercaDe => 'À propos';

  @override
  String get acercaDeDescripcion =>
      'Carte interactive et système de guidage piétonnier pour le campus de l\'UTB.';
}
