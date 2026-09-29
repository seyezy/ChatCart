import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../firebase/chatcart_services.dart';
import '../models/backend_models.dart';

class KycState {
  final String documentType;
  final XFile? document, selfie;
  final SellerKycStatus? status;
  final bool loading, submitting;
  final String? error;
  final bool submitted;
  const KycState(
      {this.documentType = 'National ID',
      this.document,
      this.selfie,
      this.status,
      this.loading = true,
      this.submitting = false,
      this.error,
      this.submitted = false});
  KycState copy(
          {String? documentType,
          XFile? document,
          XFile? selfie,
          SellerKycStatus? status,
          bool? loading,
          bool? submitting,
          String? error,
          bool submitted = false}) =>
      KycState(
          documentType: documentType ?? this.documentType,
          document: document ?? this.document,
          selfie: selfie ?? this.selfie,
          status: status ?? this.status,
          loading: loading ?? this.loading,
          submitting: submitting ?? this.submitting,
          error: error,
          submitted: submitted);
}

sealed class KycEvent {}

class KycRequested extends KycEvent {}

class KycDocumentTypeChanged extends KycEvent {
  final String value;
  KycDocumentTypeChanged(this.value);
}

class KycImagePicked extends KycEvent {
  final bool selfie;
  KycImagePicked(this.selfie);
}

class KycSubmitted extends KycEvent {
  final String legalName, businessName, country, documentNumber;
  KycSubmitted(
      {required this.legalName,
      required this.businessName,
      required this.country,
      required this.documentNumber});
}

class KycBloc extends Bloc<KycEvent, KycState> {
  KycBloc(ChatCartServices services) : super(const KycState()) {
    on<KycRequested>((event, emit) async {
      emit(state.copy(loading: true));
      try {
        final status = await services.backend.kycStatus();
        if (!emit.isDone) emit(state.copy(status: status, loading: false));
      } catch (error) {
        if (!emit.isDone) {
          emit(state.copy(loading: false, error: error.toString()));
        }
      }
    }, transformer: restartable());
    on<KycDocumentTypeChanged>((event, emit) {
      if (!state.submitting) emit(state.copy(documentType: event.value));
    });
    on<KycImagePicked>((event, emit) async {
      if (state.submitting) return;
      try {
        final file = await services.storage.pickImage(
            source: event.selfie ? ImageSource.camera : ImageSource.gallery);
        if (!emit.isDone && file != null && !state.submitting) {
          emit(event.selfie
              ? state.copy(selfie: file)
              : state.copy(document: file));
        }
      } catch (error) {
        if (!emit.isDone) emit(state.copy(error: error.toString()));
      }
    }, transformer: droppable());
    on<KycSubmitted>((event, emit) async {
      final uid = services.auth.currentUser?.uid;
      if (uid == null) {
        emit(state.copy(error: 'Sign in is required.'));
        return;
      }
      if (event.legalName.trim().isEmpty ||
          event.country.trim().isEmpty ||
          event.documentNumber.trim().isEmpty ||
          state.document == null ||
          state.selfie == null) {
        emit(state.copy(error: 'Complete all required KYC fields and images.'));
        return;
      }
      final draft = state;
      emit(state.copy(submitting: true));
      try {
        final doc = await services.storage.uploadKycImage(
            userId: uid, file: draft.document!, kind: 'identity');
        final selfie = await services.storage
            .uploadKycImage(userId: uid, file: draft.selfie!, kind: 'selfie');
        await services.backend.submitKyc(
            legalName: event.legalName.trim(),
            businessName: event.businessName.trim(),
            country: event.country.trim(),
            documentType: draft.documentType,
            documentNumber: event.documentNumber.trim(),
            documentUrls: [doc],
            selfieUrl: selfie);
        if (!emit.isDone) {
          emit(state.copy(submitting: false, submitted: true));
          add(KycRequested());
        }
      } catch (error) {
        if (!emit.isDone) {
          emit(state.copy(submitting: false, error: error.toString()));
        }
      }
    }, transformer: droppable());
  }
}
