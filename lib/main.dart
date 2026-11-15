import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/ajustes_idioma.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/idioma/presentation/seleccion_idioma_screen.dart';
import 'features/splash/presentation/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(); // días y meses de todos los idiomas (es, en…)
  await AjustesIdioma.instancia.cargar(); // idioma guardado (null la primera vez)
  runApp(const MapsUtbApp());
}

const _ubicacionSimulada =
    bool.fromEnvironment('UBICACION_SIMULADA');

class MapsUtbApp extends StatelessWidget {
  const MapsUtbApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Se reconstruye cuando el usuario elige o cambia el idioma.
    return ValueListenableBuilder<Locale?>(
      valueListenable: AjustesIdioma.instancia.locale,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'MAPSUTB',
          debugShowCheckedModeBanner: false,
          locale: locale, // null solo antes de elegir (usa el del dispositivo)
          supportedLocales: AjustesIdioma.soportados,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            textTheme: GoogleFonts.interTextTheme(
              Theme.of(context).textTheme,
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF093AD8),
            ),
            useMaterial3: true,
          ),
          home: SplashScreen(
            // Primera vez: pantalla de idioma obligatoria. Después: directo al home.
            siguiente: (_) => AjustesIdioma.instancia.yaElegido
                ? const HomeScreen()
                : SeleccionIdiomaScreen(siguiente: (_) => const HomeScreen()),
          ),
        );
      },
    );
  }
}