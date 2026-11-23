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

  @override
  String get accionReintentar => 'Retry';

  @override
  String get zonasCategoriaEstudio => 'Classrooms and study facilities';

  @override
  String get zonasCategoriaRecreacion => 'Recreation, social and rest areas';

  @override
  String get zonasExplora => 'Explore the campus';

  @override
  String get zonasCargando => 'Loading facilities…';

  @override
  String get zonasBuscarLugar => 'Search places';

  @override
  String get zonasBorrarBusqueda => 'Clear search';

  @override
  String get zonasVolverCategorias => 'Back to categories';

  @override
  String get zonasErrorCarga => 'Couldn\'t load the zones.';

  @override
  String get detalleComoLlegar => 'Get directions';

  @override
  String get detallePisos => 'Floors';

  @override
  String get detalleEspacios => 'Spaces';

  @override
  String get detalleOtrosEspacios => 'Other spaces';

  @override
  String get detalleTodosEspacios => 'All spaces';

  @override
  String get detalleSinOtrosEspacios => 'No other spaces registered.';

  @override
  String get detalleSinEspaciosPiso => 'No spaces registered on this floor.';

  @override
  String get detalleZonaSinEspacios => 'This zone has no registered spaces.';

  @override
  String get detalleEspacioSeleccionado => 'Selected space';

  @override
  String get detalleDescripcion => 'Description';

  @override
  String get detalleSinDescripcion =>
      'There\'s no description for this classroom yet.';

  @override
  String get detalleMapaNoDisponible => 'Map not available.';

  @override
  String cantidadLugares(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n places',
      one: '1 place',
    );
    return '$_temp0';
  }

  @override
  String cantidadInstalaciones(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n facilities available',
      one: '1 facility available',
    );
    return '$_temp0';
  }

  @override
  String cantidadPisos(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n floors',
      one: '1 floor',
    );
    return '$_temp0';
  }

  @override
  String cantidadEspacios(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n spaces',
      one: '1 space',
    );
    return '$_temp0';
  }

  @override
  String cantidadSalones(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n classrooms',
      one: '1 classroom',
    );
    return '$_temp0';
  }

  @override
  String get tipoEdificio => 'Building';

  @override
  String get tipoZonaComun => 'Common area';

  @override
  String get tipoServicio => 'Service';

  @override
  String get tipoBiblioteca => 'Library';

  @override
  String get tipoSalon => 'Classroom';

  @override
  String get tipoLaboratorio => 'Laboratory';

  @override
  String get tipoOficina => 'Office';

  @override
  String get tipoCafeteria => 'Cafeteria';

  @override
  String get tipoAuditorio => 'Auditorium';
}
