# Stage 1: Build the Flutter Web App
FROM ghcr.io/cirruslabs/flutter:3.38.1 AS build

WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Remove tflite_flutter dependency for web build to avoid FFI errors
RUN sed -i '/tflite_flutter:/d' pubspec.yaml

# Get dependencies
RUN flutter pub get

# Copy the rest of the code
COPY . .

# Re-apply removal of dependency (since COPY . . overwrites pubspec.yaml)
RUN sed -i '/tflite_flutter:/d' pubspec.yaml
# Overwrite the mobile service with the web-compatible dummy
RUN cp lib/core/services/ml_service_stub.dart lib/core/services/ml_service_mobile.dart

# Create the .env file in assets for the build (if needed by build process or runtime)
# Ideally this is mounted or copied, but for build we need it.
# We will rely on existing assets/.env or create a dummy one if it doesn't exist to pass build
# But user said they have assets/.env now.

# Build for web
# BASE_URL is injected at build time via --dart-define so String.fromEnvironment works.
ARG BASE_URL=http://localhost:8000
RUN flutter config --enable-web
RUN flutter build web --release --dart-define=BASE_URL=$BASE_URL

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy build output to Nginx html directory
COPY --from=build /app/build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
