import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatcart_ui/blocs/session_bloc.dart';

class TestUser extends Fake implements User {
  @override
  final String uid;
  TestUser(this.uid);
}

Future<void> flush() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('login and logout remain responsive during stalled presence work',
      () async {
    final users = StreamController<User?>();
    final stalled = Completer<void>();
    var cancellations = 0, signOuts = 0;
    users.onCancel = () {
      cancellations++;
    };
    final bloc = SessionBloc.withDependencies(
        currentUser: null,
        users: users.stream,
        signOut: () async {
          signOuts++;
          users.add(null);
        },
        startPresence: (_) => stalled.future,
        stopPresence: () async {},
        startDevices: (_) async {},
        stopDevices: () async {});
    users.add(TestUser('first'));
    await flush();
    expect(bloc.state.user?.uid, 'first');
    bloc.add(SessionThemeChanged(ThemeMode.dark));
    await flush();
    expect(bloc.state.theme, ThemeMode.dark);
    bloc.add(SessionSignOut());
    await flush();
    expect(signOuts, 1);
    expect(bloc.state.user, isNull);
    users.add(TestUser('second'));
    await flush();
    expect(bloc.state.user?.uid, 'second');
    stalled.complete();
    await flush();
    await bloc.close();
    expect(cancellations, 1);
    await users.close();
  });
  test('a failed sign-out retains the session and exposes the error', () async {
    final bloc = SessionBloc.withDependencies(
        currentUser: TestUser('first'),
        users: const Stream.empty(),
        signOut: () async {
          throw StateError('offline');
        },
        startPresence: (_) async {},
        stopPresence: () async {},
        startDevices: (_) async {},
        stopDevices: () async {});
    bloc.add(SessionSignOut());
    await flush();
    expect(bloc.state.user?.uid, 'first');
    expect(bloc.state.error, isA<StateError>());
    await bloc.close();
  });
}
