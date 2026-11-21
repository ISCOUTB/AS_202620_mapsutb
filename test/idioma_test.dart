import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapsutb/core/ajustes_idioma.dart';
import 'package:mapsutb/features/idioma/presentation/seleccion_idioma_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AjustesIdioma', () {
    test('cargar y elegir persisten en SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'idioma': 'en'});
      final ajustes = AjustesIdioma.instancia;
      await ajustes.cargar();

      expect(ajustes.locale.value, const Locale('en'));
      expect(ajustes.yaElegido, isTrue);

      await ajustes.elegir(const Locale('es'));
      expect(ajustes.locale.value, const Locale('es'));
    });
  });

  group('SeleccionIdiomaScreen', () {
    testWidgets('muestra opciones de idioma y permite seleccionar uno',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      bool llamado = false;

      await tester.pumpWidget(MaterialApp(
        home: SeleccionIdiomaScreen(
          siguiente: (_) {
            llamado = true;
            return const SizedBox();
          },
        ),
      ));

      await tester.pump();
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      await tester.tap(find.text('English'));
      await tester.pump();

      await tester.tap(find.text('Continuar'));
      await tester.pump();
    });
  });
}
