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

  @override
  String get accionReintentar => 'Réessayer';

  @override
  String get zonasCategoriaEstudio =>
      'Salles de classe et installations d\'étude';

  @override
  String get zonasCategoriaRecreacion =>
      'Loisirs, interaction et zones de détente';

  @override
  String get zonasExplora => 'Explorez le campus';

  @override
  String get zonasCargando => 'Chargement des installations…';

  @override
  String get zonasBuscarLugar => 'Rechercher un lieu';

  @override
  String get zonasBorrarBusqueda => 'Effacer la recherche';

  @override
  String get zonasVolverCategorias => 'Retour aux catégories';

  @override
  String get zonasErrorCarga => 'Impossible de charger les zones.';

  @override
  String get detalleComoLlegar => 'Itinéraire';

  @override
  String get detallePisos => 'Étages';

  @override
  String get detalleEspacios => 'Espaces';

  @override
  String get detalleOtrosEspacios => 'Autres espaces';

  @override
  String get detalleTodosEspacios => 'Tous les espaces';

  @override
  String get detalleSinOtrosEspacios => 'Aucun autre espace enregistré.';

  @override
  String get detalleSinEspaciosPiso => 'Aucun espace enregistré à cet étage.';

  @override
  String get detalleZonaSinEspacios =>
      'Cette zone n\'a aucun espace enregistré.';

  @override
  String get detalleEspacioSeleccionado => 'Espace sélectionné';

  @override
  String get detalleDescripcion => 'Description';

  @override
  String get detalleSinDescripcion =>
      'Aucune description pour cette salle pour le moment.';

  @override
  String get detalleMapaNoDisponible => 'Carte non disponible.';

  @override
  String cantidadLugares(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n lieux',
      one: '1 lieu',
    );
    return '$_temp0';
  }

  @override
  String cantidadInstalaciones(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n installations disponibles',
      one: '1 installation disponible',
    );
    return '$_temp0';
  }

  @override
  String cantidadPisos(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n étages',
      one: '1 étage',
    );
    return '$_temp0';
  }

  @override
  String cantidadEspacios(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n espaces',
      one: '1 espace',
    );
    return '$_temp0';
  }

  @override
  String cantidadSalones(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n salles',
      one: '1 salle',
    );
    return '$_temp0';
  }

  @override
  String get tipoEdificio => 'Bâtiment';

  @override
  String get tipoZonaComun => 'Zone commune';

  @override
  String get tipoServicio => 'Service';

  @override
  String get tipoBiblioteca => 'Bibliothèque';

  @override
  String get tipoSalon => 'Salle de classe';

  @override
  String get tipoLaboratorio => 'Laboratoire';

  @override
  String get tipoOficina => 'Bureau';

  @override
  String get tipoCafeteria => 'Cafétéria';

  @override
  String get tipoAuditorio => 'Auditorium';
}
