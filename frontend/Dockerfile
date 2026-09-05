# syntax=docker/dockerfile:1

# ghcr.io/cirruslabs/flutter publishes tags with a lag behind Flutter stable
# (3.44.0 was the newest when this was written, while the project pins 3.47.2).
# The SDK inside the image is a git checkout, so the exact pinned tag is
# checked out before building. FLUTTER_VERSION must match pubspec.yaml.
FROM ghcr.io/cirruslabs/flutter:3.44.0 AS build
ARG FLUTTER_VERSION=3.47.2
# Needs network access to github.com and storage.googleapis.com and about 2 GB of
# free disk; on small servers pull the published images instead (see README).
RUN set -eu; \
    root="$(dirname "$(dirname "$(readlink -f "$(command -v flutter)")")")"; \
    git config --global --add safe.directory "$root"; \
    git -C "$root" fetch --depth 1 origin "refs/tags/${FLUTTER_VERSION}:refs/tags/${FLUTTER_VERSION}"; \
    git -C "$root" checkout -q "${FLUTTER_VERSION}"; \
    flutter --version; \
    flutter config --no-analytics --enable-web >/dev/null
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
# --wasm compiles to WebAssembly (with the JavaScript build as the fallback for
# browsers without wasm-gc); --no-web-resources-cdn keeps the renderer local so
# the app makes no external requests.
RUN flutter build web --wasm --release --no-web-resources-cdn

FROM caddy:2-alpine
RUN addgroup -S -g 10001 web && adduser -S -u 10001 -G web web \
    && mkdir -p /srv /config /data \
    && chown -R web:web /srv /config /data
COPY --from=deploy --chown=web:web Caddyfile /etc/caddy/Caddyfile
COPY --from=build --chown=web:web /app/build/web /srv
USER web
EXPOSE 80
