# Despliegue reproducible del sitio web de MAPSUTB en cualquier máquina con
# Docker (p. ej. el servidor del laboratorio). Ver ADR 0007 y arc42 §7.
#
#   docker compose -f infra/docker-compose.yml up --build
#
# Etapa 1: compila la app Flutter para web.
FROM ghcr.io/cirruslabs/flutter:3.47.4 AS build
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get --enforce-lockfile
COPY . .
# Secretos por build-arg (tomados de .env por docker compose; ver ADR 0009).
ARG GOOGLE_MAPS_API_KEY=""
ARG GA_MEASUREMENT_ID=""
ARG GA_API_SECRET=""
RUN flutter build web --release \
      --dart-define=GOOGLE_MAPS_API_KEY="$GOOGLE_MAPS_API_KEY" \
      --dart-define=GA_MEASUREMENT_ID="$GA_MEASUREMENT_ID" \
      --dart-define=GA_API_SECRET="$GA_API_SECRET"

# Etapa 2: sirve los estáticos con nginx (logs de acceso en JSON).
FROM nginx:1.27-alpine
COPY infra/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost/health || exit 1
