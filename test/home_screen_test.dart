import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mapsutb/core/barra_navegacion.dart';
import 'package:mapsutb/core/bg_widget.dart';
import 'package:mapsutb/features/home/presentation/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  group('HomeScreen', () {
    testWidgets('arranca con la barra superior y permite cambiar de pestaña',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: HomeScreen(),
      ));
      await tester.pump();

      expect(find.text('MAPSUTB'), findsOneWidget);
      expect(find.byType(BarraNavegacion), findsOneWidget);
      expect(find.byType(FondoMenu), findsOneWidget);

      // Cambiar a pestaña Configuración
      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Configuración'), findsWidgets);

      // Cambiar a pestaña Zonas
      await tester.tap(find.byIcon(Icons.apartment_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    });
  });
}
