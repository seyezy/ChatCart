# Laravel Backend Deployment — ChatCart v1.0.0

ChatCart uses Laravel 13 and PHP 8.3+. Laravel + MySQL owns business/administrative data; Firebase owns authentication, realtime chat, presence, media and push transport.

## Server requirements
- PHP 8.3+
- Composer 2.x
- MySQL 8+ or compatible MariaDB
- HTTPS-enabled domain/subdomain
- PHP extensions required by Laravel
- A Firebase service-account JSON stored outside the public directory

## Production deployment
```bash
cd Laravel_Backend
composer install --no-dev --optimize-autoloader
cp .env.production.example .env
php artisan key:generate
php artisan migrate --seed --force
php artisan storage:link
php artisan optimize
```

Point the web server document root to `Laravel_Backend/public`. Never point it to the project root.

## Web installer
After `composer install`, browse to `/install`. The wizard can select development, staging or production, configure MySQL, Firebase server credentials, run migrations/seeds and create the first administrator. After installation, an `installed.lock` file blocks the wizard.

## Separate environments
For real teams, deploy three independent Laravel environments:
- development: local/dev host + development database + development Firebase project
- staging: staging host + staging database + staging Firebase project
- production: production host + production database + production Firebase project

Never point development/staging to the production database or production Firebase service account.
