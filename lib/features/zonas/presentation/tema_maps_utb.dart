import 'package:flutter/material.dart';

/// Paleta de Maps UTB (docs/manual_identidad_visual.md y la propuesta
/// aprobada en docs/diseno/propuesta-interfaz.html). Son los mismos hex que
/// usa `MapaWidget` para pines, ruta y "tú estás aquí".
///
/// Vive en la feature de zonas porque hoy solo la consumen estas pantallas y
/// el tema global; si otra feature la necesita, se mueve a `lib/core/`.
abstract final class ColoresMapsUtb {
  /// Azul Maps UTB: encabezados, botones y navegación activa.
  static const azul = Color(0xFF093AD8);

  /// Tinte suave del azul para fondos de chips, etiquetas e indicadores.
  static const azulSuave = Color(0xFFEAF0FF);

  /// Navy: texto principal.
  static const navy = Color(0xFF032742);

  /// Esmeralda: solo ruta activa y confirmaciones.
  static const esmeralda = Color(0xFF028C5C);

  /// Verde lima: solo "tú estás aquí".
  static const lima = Color(0xFF71EC37);

  /// Celeste: información y servicios.
  static const celeste = Color(0xFF0FC5EF);

  /// Morado: biblioteca y detalles puntuales.
  static const morado = Color(0xFF5817D3);

  /// Fondo de la app y superficie de tarjetas.
  static const fondo = Color(0xFFF3F5FB);
  static const superficie = Colors.white;

  /// Texto secundario. La propuesta usa #7A889C para metadatos, pero sobre
  /// blanco da 3,6:1; este tono (el "ink-2" de la propuesta) da 6,8:1.
  static const textoSecundario = Color(0xFF4A5C75);

  /// Borde fino de tarjetas, chips y campos (la propuesta prefiere bordes
  /// de 1 px a sombras).
  static const linea = Color(0xFFE1E6F2);
}

/// Tema global de la app: al definirlo una vez, las pantallas existentes
/// toman la identidad visual sin reescribirlas. Montserrat queda pendiente
/// (hay que empaquetarla en assets/fonts/ y declararla en pubspec.yaml);
/// mientras tanto se usa la fuente del sistema.
ThemeData temaMapsUtb() {
  final esquema = ColorScheme.fromSeed(seedColor: ColoresMapsUtb.azul).copyWith(
    primary: ColoresMapsUtb.azul,
    onPrimary: Colors.white,
    primaryContainer: ColoresMapsUtb.azulSuave,
    onPrimaryContainer: ColoresMapsUtb.azul,
    surface: ColoresMapsUtb.superficie,
    onSurface: ColoresMapsUtb.navy,
    onSurfaceVariant: ColoresMapsUtb.textoSecundario,
    outlineVariant: ColoresMapsUtb.linea,
  );
  const radioCampos = BorderRadius.all(Radius.circular(12));
  const radioTarjetas = BorderRadius.all(Radius.circular(14));

  return ThemeData(
    colorScheme: esquema,
    scaffoldBackgroundColor: ColoresMapsUtb.fondo,
    appBarTheme: const AppBarTheme(
      backgroundColor: ColoresMapsUtb.azul,
      foregroundColor: Colors.white,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      // Encabezado azul con esquinas redondeadas, como en la UTB App.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
    ),
    cardTheme: const CardThemeData(
      color: ColoresMapsUtb.superficie,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: radioTarjetas,
        side: BorderSide(color: ColoresMapsUtb.linea),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: radioTarjetas),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: radioCampos),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: ColoresMapsUtb.superficie,
      prefixIconColor: ColoresMapsUtb.azul,
      border: OutlineInputBorder(
        borderRadius: radioCampos,
        borderSide: BorderSide(color: ColoresMapsUtb.linea),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radioCampos,
        borderSide: BorderSide(color: ColoresMapsUtb.linea),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radioCampos,
        borderSide: BorderSide(color: ColoresMapsUtb.azul, width: 1.5),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: ColoresMapsUtb.superficie,
      indicatorColor: ColoresMapsUtb.azulSuave,
    ),
  );
}
