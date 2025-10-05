dart run dsx_compiler:dsxc src/main.dsx -o gen
dart compile js -O4 -o web/app.js bin/bootstrap.dart
dhttpd --path web --port 8080
