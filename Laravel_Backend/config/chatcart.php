<?php
return [
 'version' => env('CHATCART_VERSION', '1.0.0'),
 'firebase_credentials' => env('FIREBASE_CREDENTIALS'),
 'firebase_project_id' => env('FIREBASE_PROJECT_ID'),
 'fcm_topic' => env('FCM_TOPIC', 'chatcart-production'),
 'commission_percent' => (float) env('DEFAULT_COMMISSION_PERCENT', 5),
];
