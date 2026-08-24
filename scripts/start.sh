#!/usr/bin/env bash
# Arranque de un solo comando para el esqueleto de MAPSUTB.
# Uso: ./scripts/start.sh
set -euo pipefail

echo "==> Resolviendo dependencias (flutter pub get)"
flutter pub get

echo "==> Ejecutando pruebas automatizadas"
flutter test

echo "==> Levantando la app (flutter run)"
flutter run
