# Despliegue reproducible del sitio web de MAPSUTB en cualquier máquina con
# Docker (p. ej. el servidor del laboratorio). Ver ADR 0007 y arc42 §7.
#
#   docker compose -f infra/docker-compose.yml up --build
#
# Etapa 1: compila la app Flutter para web con la MISMA versión de Flutter que
# el CI (.github/workflows/ci.yml). Se instala desde el tag oficial porque no
# hay imagen publicada para esa versión.
FROM debian:bookworm-slim AS build
RUN apt-get update \
 && apt-get install -y --no-install-recommends git curl unzip xz-utils ca-certificates \
 && rm -rf /var/lib/apt/lists/*
ARG FLUTTER_VERSION=3.47.4
RUN git clone --quiet --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:${PATH}"
RUN flutter config --no-analytics --enable-web && flutter precache --web
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get --enforce-lockfile
COPY . .
# Secretos por build-arg (tomados de .env por docker compose; ver ADR 0009).
ARG GOOGLE_MAPS_API_KEY=""
ARG GA_MEASUREMENT_ID=""
ARG GA_API_SECRET=""
# Commit que contiene la imagen: queda en /health.json para saber qué versión
# está en línea tras un despliegue o una reversión (ADR 0010).
ARG COMMIT="local"
RUN flutter build web --release \
      --dart-define=GOOGLE_MAPS_API_KEY="$GOOGLE_MAPS_API_KEY" \
      --dart-define=GA_MEASUREMENT_ID="$GA_MEASUREMENT_ID" \
      --dart-define=GA_API_SECRET="$GA_API_SECRET" \
 && printf '{"status":"ok","servicio":"mapsutb-web","commit":"%s"}\n' "$COMMIT" > build/web/health.json

# Etapa 2: sirve los estáticos con nginx (logs de acceso en JSON).
FROM nginx:1.27-alpine
COPY infra/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost/health || exit 1
