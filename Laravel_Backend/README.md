# ChatCart Laravel Backend v1.0.0

Laravel 13 + MySQL backend for the ChatCart Flutter application. Firebase remains responsible for client authentication, realtime chat, presence, media storage and FCM. Laravel is the authoritative API/admin backend for marketplace business data, reports, KYC, orders, transactions, commissions, refunds, support, announcements, devices, RBAC and settings.

## Requirements
- PHP 8.3+
- Composer 2.x
- MySQL 8+ / MariaDB 10.6+
- PHP extensions required by Laravel
- Firebase service-account JSON

## Install
```bash
composer install --no-dev --optimize-autoloader
cp .env.production.example .env
php artisan key:generate
php artisan migrate --seed --force
php artisan storage:link
php artisan optimize
```

Serve the application from the `public/` directory. Do not expose `.env` or the project root.
