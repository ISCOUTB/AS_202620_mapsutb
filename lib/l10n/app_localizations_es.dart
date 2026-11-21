// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get navZonas => 'Zonas';

  @override
  String get navMapa => 'Mapa';

  @override
  String get navConfiguracion => 'Configuración';

  @override
  String get configTitulo => 'Configuración';

  @override
  String get configNotificaciones => 'Notificaciones';

  @override
  String get configNotificacionesWeb =>
      'Las notificaciones están desactivadas en la versión web.';

  @override
  String get configIdioma => 'Idioma';

  @override
  String get configAcercaDe => 'Acerca de';

  @override
  String get acercaDeDescripcion =>
      'Mapa interactivo y sistema de ruteo peatonal para el campus de la UTB.';
}
