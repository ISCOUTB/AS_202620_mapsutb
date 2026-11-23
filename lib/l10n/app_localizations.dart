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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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

  /// No description provided for @navZonas.
  ///
  /// In es, this message translates to:
  /// **'Zonas'**
  String get navZonas;

  /// No description provided for @navMapa.
  ///
  /// In es, this message translates to:
  /// **'Mapa'**
  String get navMapa;

  /// No description provided for @navConfiguracion.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get navConfiguracion;

  /// No description provided for @configTitulo.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get configTitulo;

  /// No description provided for @configNotificaciones.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get configNotificaciones;

  /// No description provided for @configNotificacionesWeb.
  ///
  /// In es, this message translates to:
  /// **'Las notificaciones están desactivadas en la versión web.'**
  String get configNotificacionesWeb;

  /// No description provided for @configIdioma.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get configIdioma;

  /// No description provided for @configAcercaDe.
  ///
  /// In es, this message translates to:
  /// **'Acerca de'**
  String get configAcercaDe;

  /// No description provided for @acercaDeDescripcion.
  ///
  /// In es, this message translates to:
  /// **'Mapa interactivo y sistema de ruteo peatonal para el campus de la UTB.'**
  String get acercaDeDescripcion;

  /// No description provided for @accionReintentar.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get accionReintentar;

  /// No description provided for @zonasCategoriaEstudio.
  ///
  /// In es, this message translates to:
  /// **'Salones e instalaciones de estudio'**
  String get zonasCategoriaEstudio;

  /// No description provided for @zonasCategoriaRecreacion.
  ///
  /// In es, this message translates to:
  /// **'Recreación, interacción y zonas de descanso'**
  String get zonasCategoriaRecreacion;

  /// No description provided for @zonasExplora.
  ///
  /// In es, this message translates to:
  /// **'Explora el campus'**
  String get zonasExplora;

  /// No description provided for @zonasCargando.
  ///
  /// In es, this message translates to:
  /// **'Cargando instalaciones…'**
  String get zonasCargando;

  /// No description provided for @zonasBuscarLugar.
  ///
  /// In es, this message translates to:
  /// **'Buscar lugar'**
  String get zonasBuscarLugar;

  /// No description provided for @zonasBorrarBusqueda.
  ///
  /// In es, this message translates to:
  /// **'Borrar búsqueda'**
  String get zonasBorrarBusqueda;

  /// No description provided for @zonasVolverCategorias.
  ///
  /// In es, this message translates to:
  /// **'Volver a categorías'**
  String get zonasVolverCategorias;

  /// No description provided for @zonasErrorCarga.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las zonas.'**
  String get zonasErrorCarga;

  /// No description provided for @detalleComoLlegar.
  ///
  /// In es, this message translates to:
  /// **'Cómo llegar'**
  String get detalleComoLlegar;

  /// No description provided for @detallePisos.
  ///
  /// In es, this message translates to:
  /// **'Pisos'**
  String get detallePisos;

  /// No description provided for @detalleEspacios.
  ///
  /// In es, this message translates to:
  /// **'Espacios'**
  String get detalleEspacios;

  /// No description provided for @detalleOtrosEspacios.
  ///
  /// In es, this message translates to:
  /// **'Otros espacios'**
  String get detalleOtrosEspacios;

  /// No description provided for @detalleTodosEspacios.
  ///
  /// In es, this message translates to:
  /// **'Todos los espacios'**
  String get detalleTodosEspacios;

  /// No description provided for @detalleSinOtrosEspacios.
  ///
  /// In es, this message translates to:
  /// **'No hay otros espacios registrados.'**
  String get detalleSinOtrosEspacios;

  /// No description provided for @detalleSinEspaciosPiso.
  ///
  /// In es, this message translates to:
  /// **'Sin espacios registrados en este piso.'**
  String get detalleSinEspaciosPiso;

  /// No description provided for @detalleZonaSinEspacios.
  ///
  /// In es, this message translates to:
  /// **'Esta zona no tiene espacios registrados.'**
  String get detalleZonaSinEspacios;

  /// No description provided for @detalleEspacioSeleccionado.
  ///
  /// In es, this message translates to:
  /// **'Espacio seleccionado'**
  String get detalleEspacioSeleccionado;

  /// No description provided for @detalleDescripcion.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get detalleDescripcion;

  /// No description provided for @detalleSinDescripcion.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay descripción para este salón.'**
  String get detalleSinDescripcion;

  /// No description provided for @detalleMapaNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'Mapa no disponible.'**
  String get detalleMapaNoDisponible;

  /// No description provided for @cantidadLugares.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 lugar} other{{n} lugares}}'**
  String cantidadLugares(int n);

  /// No description provided for @cantidadInstalaciones.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 instalación disponible} other{{n} instalaciones disponibles}}'**
  String cantidadInstalaciones(int n);

  /// No description provided for @cantidadPisos.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 piso} other{{n} pisos}}'**
  String cantidadPisos(int n);

  /// No description provided for @cantidadEspacios.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 espacio} other{{n} espacios}}'**
  String cantidadEspacios(int n);

  /// No description provided for @cantidadSalones.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 salón} other{{n} salones}}'**
  String cantidadSalones(int n);

  /// No description provided for @tipoEdificio.
  ///
  /// In es, this message translates to:
  /// **'Edificio'**
  String get tipoEdificio;

  /// No description provided for @tipoZonaComun.
  ///
  /// In es, this message translates to:
  /// **'Zona común'**
  String get tipoZonaComun;

  /// No description provided for @tipoServicio.
  ///
  /// In es, this message translates to:
  /// **'Servicio'**
  String get tipoServicio;

  /// No description provided for @tipoBiblioteca.
  ///
  /// In es, this message translates to:
  /// **'Biblioteca'**
  String get tipoBiblioteca;

  /// No description provided for @tipoSalon.
  ///
  /// In es, this message translates to:
  /// **'Salón'**
  String get tipoSalon;

  /// No description provided for @tipoLaboratorio.
  ///
  /// In es, this message translates to:
  /// **'Laboratorio'**
  String get tipoLaboratorio;

  /// No description provided for @tipoOficina.
  ///
  /// In es, this message translates to:
  /// **'Oficina'**
  String get tipoOficina;

  /// No description provided for @tipoCafeteria.
  ///
  /// In es, this message translates to:
  /// **'Cafetería'**
  String get tipoCafeteria;

  /// No description provided for @tipoAuditorio.
  ///
  /// In es, this message translates to:
  /// **'Auditorio'**
  String get tipoAuditorio;
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
