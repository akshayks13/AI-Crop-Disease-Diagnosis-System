# Stage 1: Build the Flutter Web App
FROM ghcr.io/cirruslabs/flutter:3.19.0 AS build

WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy the rest of the code
COPY . .

# Create the .env file in assets for the build (if needed by build process or runtime)
# Ideally this is mounted or copied, but for build we need it.
# We will rely on existing assets/.env or create a dummy one if it doesn't exist to pass build
# But user said they have assets/.env now.

# Build for web
RUN flutter config --enable-web
RUN flutter build web --release

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy build output to Nginx html directory
COPY --from=build /app/build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
