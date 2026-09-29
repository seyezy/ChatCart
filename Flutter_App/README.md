# ChatCart Flutter App v1.0.0

Three flavors are included:

| Flavor | Android applicationId | iOS bundle ID | Env file |
|---|---|---|---|
| development | `com.chatcart.app.dev` | `com.chatcart.app.dev` | `.env.development` |
| staging | `com.chatcart.app.stg` | `com.chatcart.app.stg` | `.env.staging` |
| production | `com.chatcart.app` | `com.chatcart.app` | `.env.production` |

## Run
```bash
flutter pub get
flutter run --flavor development -t lib/main_development.dart
flutter run --flavor staging -t lib/main_staging.dart
flutter run --flavor production -t lib/main_production.dart
```

## Build
```bash
flutter build apk --flavor production -t lib/main_production.dart --release
flutter build appbundle --flavor production -t lib/main_production.dart --release
```

The `.env.*` files contain public client configuration only. Never put Laravel `APP_KEY`, Firebase service-account JSON, database passwords, payment secret keys, or other server secrets in Flutter assets.
