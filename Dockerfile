# Flutter Docker image for development (web mode) and APK build
# На Mac M1/M2 возможен segfault — используйте локально: flutter run
FROM cirrusci/flutter:stable

# Flutter не рекомендует запуск от root
RUN useradd -m -s /bin/bash flutteruser

WORKDIR /app

# Copy pubspec first for layer caching
COPY pubspec.yaml ./
RUN chown flutteruser:flutteruser pubspec.yaml

USER flutteruser
RUN flutter pub get

USER root
COPY . .
RUN chown -R flutteruser:flutteruser /app

USER flutteruser
RUN dart run build_runner build --delete-conflicting-outputs || true

EXPOSE 8080
ENV API_BASE_URL=http://host.docker.internal:8000

# Default: run Flutter web (переопределяется в docker-compose)
CMD ["flutter", "run", "--web-hostname", "0.0.0.0", "--web-port", "8080", "--dart-define=API_BASE_URL=http://host.docker.internal:8000"]
