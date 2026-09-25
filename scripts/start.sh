#!/usr/bin/env bash
# Arranque de un solo comando para el esqueleto de MAPSUTB.
# Uso: ./scripts/start.sh
set -euo pipefail

echo "==> Resolviendo dependencias (flutter pub get)"
flutter pub get

echo "==> Ejecutando pruebas automatizadas"
flutter test

# Credenciales opcionales desde .env (ver .env.example); sin él, la app
# arranca igual y oculta lo que depende de cada API.
DEFINES=()
if [[ -f .env ]]; then
  DEFINES=(--dart-define-from-file=.env)
fi

echo "==> Levantando la app (flutter run)"
flutter run ${DEFINES[@]+"${DEFINES[@]}"}
