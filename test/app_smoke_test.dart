import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mapsutb/main.dart';

/// Prueba de humo del esqueleto arquitectónico.
///
/// No valida lógica de negocio (aún no existe): valida que la app
/// compone y arranca correctamente sobre la estructura de carpetas
/// definida en el ADR 0001, para que el equipo pueda empezar la
/// semana 4 construyendo sobre una base que ya corre en verde.
void main() {
  testWidgets('MapsUtbApp arranca y muestra el Scaffold raíz', (tester) async {
    await tester.pumpWidget(const MapsUtbApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('MAPSUTB — esqueleto de arquitectura'), findsOneWidget);
  });
}
