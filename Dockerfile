# Official Dart image: https://hub.docker.com/_/dart
# Specify the Dart SDK base image version using dart:<version> (ex: dart:2.12)
FROM dart:stable AS build

WORKDIR /shelf_jwt_auth
COPY shelf_jwt_auth/ .

WORKDIR /common
COPY common/ .

# Resolve app dependencies.
WORKDIR /server
COPY /server/pubspec.* ./
RUN dart pub get

# Copy app source code and AOT compile it.
COPY /server/. .
# Ensure packages are still up-to-date if anything has changed
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

# Build minimal serving image from AOT-compiled `/server` and required system
# libraries and configuration files stored in `/runtime/` from the build stage.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /server/bin/server /server/bin/

# Start server.
EXPOSE 8080
CMD ["/server/bin/server"]
