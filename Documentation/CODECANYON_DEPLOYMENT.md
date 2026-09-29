# CodeCanyon Deployment & Buyer Guide — ChatCart v1.0.0

## What buyers receive
- Flutter mobile application with development/staging/production flavors
- Three Flutter `.env` templates
- Laravel 13 REST API + admin dashboard
- MySQL migrations and sample seed data
- Firebase rules and functions
- Editable Figma generator
- Installation wizard
- Documentation and presentation assets

## Buyer setup sequence
1. Create development/staging/production Firebase projects (or equivalent isolated Firebase configurations).
2. Upload Laravel backend and run `composer install`.
3. Open `/install` and configure the selected server environment.
4. Copy the Laravel API URL and Firebase public configuration into the matching Flutter `.env` file.
5. Configure Android/iOS package identifiers.
6. Run `flutter pub get`.
7. Test with `flutter run --flavor development -t lib/main_development.dart`.
8. Build staging for QA.
9. Build production with `flutter build appbundle --flavor production -t lib/main_production.dart --release`.
10. Configure production signing, store metadata, privacy policy, terms and support links.

## CodeCanyon author checklist
Before submitting the item, run:
```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --flavor development -t lib/main_development.dart --release
flutter build apk --flavor staging -t lib/main_staging.dart --release
flutter build appbundle --flavor production -t lib/main_production.dart --release
```

Also test a clean Laravel install:
```bash
composer install
php artisan test
php artisan migrate:fresh --seed
./vendor/bin/pint --test
```

Do not include real `.env`, database credentials, Firebase service accounts, keystores, signing passwords or payment secrets in the CodeCanyon ZIP.
