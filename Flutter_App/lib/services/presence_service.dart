import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

class PresenceService {
  final FirebaseDatabase database;
  DatabaseReference? _statusRef;
  StreamSubscription<DatabaseEvent>? _connectionSub;
  String? _activeUid;

  PresenceService({FirebaseDatabase? database})
      : database = database ?? FirebaseDatabase.instance;

  Future<void> start(String uid) async {
    if (_activeUid == uid && _connectionSub != null) return;
    await _connectionSub?.cancel();
    _activeUid = uid;
    _statusRef = database.ref('status/$uid');
    final connected = database.ref('.info/connected');
    _connectionSub = connected.onValue.listen((event) async {
      if (event.snapshot.value != true || _statusRef == null) return;
      final ref = _statusRef!;
      await ref.onDisconnect().set({
        'state': 'offline',
        'lastChanged': ServerValue.timestamp,
      });
      await ref.set({
        'state': 'online',
        'lastChanged': ServerValue.timestamp,
      });
    });
  }

  Stream<bool> watchOnline(String uid) => database
      .ref('status/$uid/state')
      .onValue
      .map((event) => event.snapshot.value == 'online')
      .distinct();

  Future<void> stop() async {
    final ref = _statusRef;
    if (ref != null) {
      await ref.onDisconnect().cancel();
      await ref.set({
        'state': 'offline',
        'lastChanged': ServerValue.timestamp,
      });
    }
    await _connectionSub?.cancel();
    _connectionSub = null;
    _statusRef = null;
    _activeUid = null;
  }
}

class TypingService {
  final FirebaseDatabase database;
  final Map<String, Timer> _timers = {};

  TypingService({FirebaseDatabase? database})
      : database = database ?? FirebaseDatabase.instance;

  DatabaseReference _ref(String conversationId, String uid) =>
      database.ref('typing/$conversationId/$uid');

  String _timerKey(String conversationId, String uid) => '$conversationId::$uid';

  Future<void> setTyping({
    required String conversationId,
    required String uid,
    required bool typing,
  }) async {
    final key = _timerKey(conversationId, uid);
    _timers.remove(key)?.cancel();
    final ref = _ref(conversationId, uid);
    if (!typing) {
      await ref.remove();
      return;
    }

    await ref.set(ServerValue.timestamp);
    _timers[key] = Timer(const Duration(seconds: 4), () {
      _timers.remove(key);
      unawaited(ref.remove());
    });
  }

  Stream<bool> watchTyping({
    required String conversationId,
    required String otherUid,
  }) {
    return _ref(conversationId, otherUid).onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! num) return false;
      return DateTime.now().millisecondsSinceEpoch - value.toInt() < 6000;
    }).distinct();
  }
}
