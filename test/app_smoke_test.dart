import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mapsutb/features/splash/presentation/splash_screen.dart';
import 'package:mapsutb/main.dart';

/// Prueba de humo de la app.
///
/// Valida que la app compone y arranca correctamente sobre la
/// estructura de carpetas definida en el ADR 0001, para que el
/// equipo pueda seguir construyendo sobre una base que ya corre en
/// verde.
void main() {
  testWidgets('MapsUtbApp arranca y muestra el Scaffold raíz', (tester) async {
    await tester.pumpWidget(const MapsUtbApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
