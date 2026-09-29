import 'dart:async';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../firebase/chatcart_services.dart';

class SessionState {
  final User? user;
  final ThemeMode theme;
  final Object? error;
  const SessionState({this.user, this.theme = ThemeMode.system, this.error});
}

sealed class SessionEvent {}

class SessionUserChanged extends SessionEvent {
  final User? user;
  SessionUserChanged(this.user);
}

class SessionLifecycleChanged extends SessionEvent {
  final AppLifecycleState lifecycle;
  SessionLifecycleChanged(this.lifecycle);
}

class SessionSignOut extends SessionEvent {}

class SessionThemeChanged extends SessionEvent {
  final ThemeMode theme;
  SessionThemeChanged(this.theme);
}

class _SessionError extends SessionEvent {
  final Object error;
  _SessionError(this.error);
}

class _SynchronizeServices extends SessionEvent {}

/// Authentication is emitted immediately; optional device/presence work is
/// serialized separately so an offline database cannot hold up login/logout.
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  late final StreamSubscription<User?> _auth;
  final Future<void> Function(String) _startPresence, _startDevices;
  final Future<void> Function() _stopPresence, _stopDevices;
  String? _serviceUid;
  bool _foreground = true;

  factory SessionBloc(ChatCartServices services) =>
      SessionBloc.withDependencies(
        currentUser: services.auth.currentUser,
        users: services.auth.authStateChanges,
        signOut: services.auth.signOut,
        startPresence: services.presence.start,
        stopPresence: services.presence.stop,
        startDevices: services.devices.start,
        stopDevices: services.devices.stop,
      );

  SessionBloc.withDependencies({
    required User? currentUser,
    required Stream<User?> users,
    required Future<void> Function() signOut,
    required Future<void> Function(String) startPresence,
    required Future<void> Function() stopPresence,
    required Future<void> Function(String) startDevices,
    required Future<void> Function() stopDevices,
  })  : _startPresence = startPresence,
        _stopPresence = stopPresence,
        _startDevices = startDevices,
        _stopDevices = stopDevices,
        super(SessionState(user: currentUser)) {
    on<SessionUserChanged>((event, emit) {
      emit(SessionState(user: event.user, theme: state.theme));
      add(_SynchronizeServices());
    });
    on<SessionLifecycleChanged>((event, emit) {
      _foreground = event.lifecycle == AppLifecycleState.resumed;
      add(_SynchronizeServices());
    });
    on<SessionSignOut>((event, emit) async {
      try {
        await signOut();
      } catch (error) {
        if (!emit.isDone) {
          emit(
              SessionState(user: state.user, theme: state.theme, error: error));
        }
      }
    }, transformer: droppable());
    on<SessionThemeChanged>((event, emit) =>
        emit(SessionState(user: state.user, theme: event.theme)));
    on<_SessionError>((event, emit) => emit(SessionState(
        user: state.user, theme: state.theme, error: event.error)));
    on<_SynchronizeServices>((event, emit) async {
      final uid = state.user?.uid;
      if (_serviceUid != uid) {
        await _bounded(_stopPresence);
        await _bounded(_stopDevices);
        _serviceUid = uid;
      }
      if (isClosed || state.user?.uid != uid || uid == null) return;
      await _bounded(_foreground ? () => _startPresence(uid) : _stopPresence);
      if (!isClosed && state.user?.uid == uid) {
        await _bounded(() => _startDevices(uid));
      }
    }, transformer: sequential());
    _auth = users.listen((user) {
      if (!isClosed) add(SessionUserChanged(user));
    }, onError: (Object error) {
      if (!isClosed) add(_SessionError(error));
    });
  }

  Future<void> _bounded(Future<void> Function() work) async {
    try {
      await work().timeout(const Duration(seconds: 8));
    } catch (error) {
      debugPrint('Optional session service unavailable: $error');
    }
  }

  @override
  Future<void> close() async {
    await _auth.cancel();
    await super.close();
    await _bounded(_stopPresence);
    await _bounded(_stopDevices);
  }
}
