import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatCartFirebaseOptions {
  ChatCartFirebaseOptions._();
  static String _v(String key) => dotenv.env[key] ?? '';
  static bool get isConfigured => _v('FIREBASE_API_KEY').isNotEmpty && _v('FIREBASE_PROJECT_ID').isNotEmpty && _v('FIREBASE_MESSAGING_SENDER_ID').isNotEmpty;

  static FirebaseOptions get currentPlatform {
    if (!isConfigured) throw StateError('Firebase values are missing from the active flavor .env file.');
    final isApple = defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;
    final appId = isApple ? _v('FIREBASE_IOS_APP_ID') : _v('FIREBASE_ANDROID_APP_ID');
    if (appId.isEmpty) throw StateError('Firebase app id is missing for the current platform.');
    return FirebaseOptions(
      apiKey: _v('FIREBASE_API_KEY'),
      appId: appId,
      messagingSenderId: _v('FIREBASE_MESSAGING_SENDER_ID'),
      projectId: _v('FIREBASE_PROJECT_ID'),
      storageBucket: _v('FIREBASE_STORAGE_BUCKET').isEmpty ? null : _v('FIREBASE_STORAGE_BUCKET'),
      databaseURL: _v('FIREBASE_DATABASE_URL').isEmpty ? null : _v('FIREBASE_DATABASE_URL'),
      iosBundleId: isApple ? _v('FIREBASE_IOS_BUNDLE_ID') : null,
    );
  }
}
