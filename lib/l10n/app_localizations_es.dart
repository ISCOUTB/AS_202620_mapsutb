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

  @override
  String get accionReintentar => 'Reintentar';

  @override
  String get zonasCategoriaEstudio => 'Salones e instalaciones de estudio';

  @override
  String get zonasCategoriaRecreacion =>
      'Recreación, interacción y zonas de descanso';

  @override
  String get zonasExplora => 'Explora el campus';

  @override
  String get zonasCargando => 'Cargando instalaciones…';

  @override
  String get zonasBuscarLugar => 'Buscar lugar';

  @override
  String get zonasBorrarBusqueda => 'Borrar búsqueda';

  @override
  String get zonasVolverCategorias => 'Volver a categorías';

  @override
  String get zonasErrorCarga => 'No se pudieron cargar las zonas.';

  @override
  String get detalleComoLlegar => 'Cómo llegar';

  @override
  String get detallePisos => 'Pisos';

  @override
  String get detalleEspacios => 'Espacios';

  @override
  String get detalleOtrosEspacios => 'Otros espacios';

  @override
  String get detalleTodosEspacios => 'Todos los espacios';

  @override
  String get detalleSinOtrosEspacios => 'No hay otros espacios registrados.';

  @override
  String get detalleSinEspaciosPiso => 'Sin espacios registrados en este piso.';

  @override
  String get detalleZonaSinEspacios =>
      'Esta zona no tiene espacios registrados.';

  @override
  String get detalleEspacioSeleccionado => 'Espacio seleccionado';

  @override
  String get detalleDescripcion => 'Descripción';

  @override
  String get detalleSinDescripcion => 'Aún no hay descripción para este salón.';

  @override
  String get detalleMapaNoDisponible => 'Mapa no disponible.';

  @override
  String cantidadLugares(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n lugares',
      one: '1 lugar',
    );
    return '$_temp0';
  }

  @override
  String cantidadInstalaciones(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n instalaciones disponibles',
      one: '1 instalación disponible',
    );
    return '$_temp0';
  }

  @override
  String cantidadPisos(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pisos',
      one: '1 piso',
    );
    return '$_temp0';
  }

  @override
  String cantidadEspacios(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n espacios',
      one: '1 espacio',
    );
    return '$_temp0';
  }

  @override
  String cantidadSalones(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n salones',
      one: '1 salón',
    );
    return '$_temp0';
  }

  @override
  String get tipoEdificio => 'Edificio';

  @override
  String get tipoZonaComun => 'Zona común';

  @override
  String get tipoServicio => 'Servicio';

  @override
  String get tipoBiblioteca => 'Biblioteca';

  @override
  String get tipoSalon => 'Salón';

  @override
  String get tipoLaboratorio => 'Laboratorio';

  @override
  String get tipoOficina => 'Oficina';

  @override
  String get tipoCafeteria => 'Cafetería';

  @override
  String get tipoAuditorio => 'Auditorio';
}
