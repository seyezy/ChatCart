# Flutter Flavors — ChatCart v1.0.0

ChatCart ships with three environments.

| Flavor | Android ID | iOS Bundle ID | Env file | Suggested backend |
|---|---|---|---|---|
| development | `com.chatcart.app.dev` | `com.chatcart.app.dev` | `.env.development` | local/dev Laravel |
| staging | `com.chatcart.app.stg` | `com.chatcart.app.stg` | `.env.staging` | staging Laravel |
| production | `com.chatcart.app` | `com.chatcart.app` | `.env.production` | production Laravel |

## Run
```bash
cd Flutter_App
flutter pub get
flutter run --flavor development -t lib/main_development.dart
flutter run --flavor staging -t lib/main_staging.dart
flutter run --flavor production -t lib/main_production.dart
```

## Build Android
```bash
flutter build apk --flavor development -t lib/main_development.dart --release
flutter build apk --flavor staging -t lib/main_staging.dart --release
flutter build appbundle --flavor production -t lib/main_production.dart --release
```

Android uses a single base `applicationId = com.chatcart.app`, with `.dev` and `.stg` application ID suffixes. Production has no suffix.

## iOS
Create shared Xcode schemes named `development`, `staging`, and `production`, and set the corresponding bundle IDs above. Templates are supplied in `Flutter_App/ios_flavors/`.

## Environment files
The Flutter `.env.*` files are compiled into the application package. Treat them as public client configuration. Do **not** place database passwords, Laravel `APP_KEY`, Firebase service account keys, Stripe secret keys, SMTP passwords, or any server-side secret in these files.
