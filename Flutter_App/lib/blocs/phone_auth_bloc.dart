import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/auth_service.dart';

enum PhoneStage { idle, sending, codeSent, verifying, authenticated, failure }

class PhoneState {
  final PhoneStage stage;
  final String? error;
  const PhoneState(this.stage, [this.error]);
  bool get busy => stage == PhoneStage.sending || stage == PhoneStage.verifying;
}

sealed class PhoneEvent {}

class PhoneReset extends PhoneEvent {}

class PhoneRequested extends PhoneEvent {
  final String number;
  PhoneRequested(this.number);
}

class PhoneCodeSent extends PhoneEvent {}

class OtpSubmitted extends PhoneEvent {
  final String code;
  OtpSubmitted(this.code);
}

class PhoneAuthBloc extends Bloc<PhoneEvent, PhoneState> {
  PhoneAuthBloc(
      {required Future<bool> Function(String, void Function()) sendCode,
      required Future<void> Function(String) verifyCode})
      : super(const PhoneState(PhoneStage.idle)) {
    on<PhoneReset>((event, emit) {
      if (!state.busy) emit(const PhoneState(PhoneStage.idle));
    });
    on<PhoneCodeSent>((event, emit) {
      if (state.stage == PhoneStage.sending) {
        emit(const PhoneState(PhoneStage.codeSent));
      }
    });
    on<PhoneRequested>((event, emit) async {
      if (state.busy) return;
      var number = event.number.replaceAll(RegExp(r'\s+'), '');
      if (!RegExp(r'^\+?\d{7,15}$').hasMatch(number)) {
        emit(
            const PhoneState(PhoneStage.failure, 'Enter a valid phone number'));
        return;
      }
      if (!number.startsWith('+')) {
        if (number.startsWith('0')) number = number.substring(1);
        number = '+234$number';
      }
      emit(const PhoneState(PhoneStage.sending));
      try {
        final signedIn = await sendCode(number, () {
          if (!isClosed) add(PhoneCodeSent());
        });
        if (!emit.isDone && signedIn) {
          emit(const PhoneState(PhoneStage.authenticated));
        }
      } catch (error) {
        if (!emit.isDone) {
          emit(PhoneState(PhoneStage.failure, error.toString()));
        }
      }
    }, transformer: droppable());
    on<OtpSubmitted>((event, emit) async {
      if (state.busy) return;
      if (!RegExp(r'^\d{6}$').hasMatch(event.code)) {
        emit(const PhoneState(
            PhoneStage.failure, 'Enter the complete 6-digit code'));
        return;
      }
      emit(const PhoneState(PhoneStage.verifying));
      try {
        await verifyCode(event.code);
        if (!emit.isDone) emit(const PhoneState(PhoneStage.authenticated));
      } catch (error) {
        if (!emit.isDone) {
          emit(PhoneState(PhoneStage.failure, error.toString()));
        }
      }
    }, transformer: droppable());
  }

  factory PhoneAuthBloc.fromService(AuthService auth) => PhoneAuthBloc(
        sendCode: (number, sent) async {
          await auth.sendPhoneCode(phoneNumber: number, codeSent: sent);
          return auth.currentUser != null;
        },
        verifyCode: (code) async {
          await auth.verifySmsCode(code);
        },
      );
}
