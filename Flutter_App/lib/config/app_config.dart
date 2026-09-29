import 'package:flutter_dotenv/flutter_dotenv.dart';

enum ChatCartEnvironment { development, staging, production }

class AppConfig {
  AppConfig._();

  static late ChatCartEnvironment current;

  static String get flavor => current.name;
  static String get envFile => '.env.$flavor';
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';
  static String get appName => dotenv.env['APP_NAME'] ?? 'ChatCart';
  static String get fcmTopic => dotenv.env['FCM_TOPIC'] ?? 'chatcart-$flavor';
  static bool get isProduction => current == ChatCartEnvironment.production;

  static Future<void> load(ChatCartEnvironment environment) async {
    current = environment;
    await dotenv.load(fileName: envFile);
  }
}
