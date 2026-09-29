# ChatCart

Flutter chat and marketplace app with Firebase services and a Laravel API/admin dashboard.

## Project folders

- `Flutter_App/`: mobile app, Bloc state management, shimmer loaders, tests, Firebase rules and functions.
- `Laravel_Backend/`: API, admin dashboard, migrations and demo seeders.
- `Documentation/`: setup, Firebase, flavors and deployment guides.
- `Demo/`, `Checklists/`, `License_Setup/`: demo and release guidance.
- `Figma_Plugin/`, `Presentations/`, `Sales_Landing_Page/`: design and marketing assets.

## Flutter setup

Use Flutter 3.41.6 (the SDK used for local verification), Android SDK and Java 17 or a compatible Android Studio JDK.

1. Copy each `Flutter_App/.env.<flavor>.example` to `.env.<flavor>` for development, staging and production. All three files are declared as assets.
2. Fill the Firebase values for each environment. Add Android Firebase configuration to `android/app/src/<flavor>/google-services.json` and follow the iOS instructions in `ios_flavors/README.md`.
3. Run `flutter pub get` from `Flutter_App`.
4. Run `flutter run --flavor development -t lib/main_development.dart` or select a flavor in VS Code Run and Debug. Update the local SDK path in `.vscode/settings.json` for your machine.

Other entry points are `main_staging.dart` and `main_production.dart`. See [flavor configuration](Documentation/FLUTTER_FLAVORS.md), [Bloc architecture](Documentation/FLUTTER_BLOC.md) and [loading states](Documentation/LOADING_STATES.md).

## Laravel setup

Use PHP 8.3+ with required Composer extensions, Composer and MySQL/MariaDB.

1. Run `composer install` from `Laravel_Backend`.
2. Copy the appropriate `.env.*.example` to `.env`; configure the database and an external Firebase Admin service-account path.
3. Run `php artisan key:generate`, `php artisan migrate --seed`, and `php artisan storage:link`.
4. Run `php artisan serve --host=127.0.0.1 --port=8000` and, when needed, `php artisan queue:work`.

See [Laravel deployment](Documentation/LARAVEL_DEPLOYMENT.md) for administrator provisioning and full setup. The development demo seeder is restricted to the `chatcart_dev` database; it creates sample records and downloads sample images. Runtime uploads and database contents are not checked in.

## Checks

From `Flutter_App`, run `flutter test` and `flutter analyze`.

## Configuration and secrets

Real environment files, Firebase client configuration, Admin SDK keys, signing keys, generated credentials, logs, uploaded data, dependencies and build output are excluded from Git. Supply your own configuration after cloning. Never commit private keys or production credentials.

See [README_FIRST.md](README_FIRST.md) for the original package overview.
