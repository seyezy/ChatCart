import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  String? _verificationId;
  int? _resendToken;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : auth = auth ?? FirebaseAuth.instance,
        firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => auth.authStateChanges();
  User? get currentUser => auth.currentUser;

  Future<void> sendPhoneCode({
    required String phoneNumber,
    required void Function() codeSent,
  }) async {
    final completer = Completer<void>();
    await auth.setSettings(
      appVerificationDisabledForTesting: false,
    );
    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: _resendToken,
      verificationCompleted: (credential) async {
        try {
          final result = await auth.signInWithCredential(credential);
          await _ensureUser(result.user);
          if (!completer.isCompleted) completer.complete();
        } on Object catch (error, stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
        }
      },
      verificationFailed: (error) {
        if (!completer.isCompleted) completer.completeError(error);
      },
      codeSent: (verificationId, token) {
        _verificationId = verificationId;
        _resendToken = token;
        codeSent();
        if (!completer.isCompleted) completer.complete();
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
    return completer.future;
  }

  Future<UserCredential> verifySmsCode(String smsCode) async {
    final id = _verificationId;
    if (id == null) {
      throw FirebaseAuthException(
        code: 'missing-verification-id',
        message: 'Request a verification code first.',
      );
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: id,
      smsCode: smsCode,
    );
    final result = await auth.signInWithCredential(credential);
    await _ensureUser(result.user);
    return result;
  }

  Future<void> signOut() => auth.signOut();

  Future<void> _ensureUser(User? user) async {
    if (user == null) return;
    final ref = firestore.collection('users').doc(user.uid);
    final existing = await ref.get();
    await ref.set({
      'uid': user.uid,
      'displayName': user.displayName ?? 'ChatCart User',
      'phone': user.phoneNumber ?? '',
      'photoUrl': user.photoURL,
      'updatedAt': FieldValue.serverTimestamp(),
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
