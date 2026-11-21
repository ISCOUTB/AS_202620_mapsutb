import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guarda el idioma que eligió el usuario y avisa a la app cuando cambia.
///
/// - `locale.value == null` significa que el usuario todavía no ha elegido
///   (primera vez que se abre la app).
/// - Se carga una sola vez en `main()` antes de `runApp`.
class AjustesIdioma {
  AjustesIdioma._();
  static final AjustesIdioma instancia = AjustesIdioma._();

  static const _clave = 'idioma';

  /// Idiomas disponibles en la interfaz.
  static const soportados = <Locale>[Locale('es'), Locale('en'), Locale('fr')];

  /// Idioma actual; la app escucha este valor para reconstruirse.
  final ValueNotifier<Locale?> locale = ValueNotifier<Locale?>(null);

  bool get yaElegido => locale.value != null;

  Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final codigo = prefs.getString(_clave);
    if (codigo != null && soportados.any((l) => l.languageCode == codigo)) {
      locale.value = Locale(codigo);
    }
  }

  Future<void> elegir(Locale nuevo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, nuevo.languageCode);
    locale.value = nuevo;
  }
}