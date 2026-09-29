import 'dart:async';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../firebase/chatcart_services.dart';
import '../models/chat_models.dart';
import 'resource_bloc.dart';

class ChatRequest {
  final String peerUid;
  final String? peerName;
  final MarketplaceProduct? product;
  const ChatRequest(this.peerUid, {this.peerName, this.product});
}

class ChatDestination {
  final String conversationId, peerUid, peerName;
  const ChatDestination(this.conversationId, this.peerUid, this.peerName);
}

class ChatActionsBloc extends ActionBloc<ChatRequest, ChatDestination> {
  ChatActionsBloc(ChatCartServices services)
      : super((request) async {
          final uid = services.auth.currentUser?.uid;
          if (uid == null) throw StateError('Sign in is required.');
          if (uid == request.peerUid) throw StateError('This is your listing.');
          final peer = await services.chat.getUser(request.peerUid);
          final id = await services.chat
              .ensureDirectConversation(uid, request.peerUid);
          final product = request.product;
          if (product != null) {
            await services.chat.sendText(
                conversationId: id,
                senderId: uid,
                text: 'Hi, I’m interested in ${product.title}.',
                productId: product.id);
          }
          return ChatDestination(id, request.peerUid,
              request.peerName ?? peer?.displayName ?? 'ChatCart User');
        });
}

class ConversationState {
  final List<ChatMessage> messages;
  final bool loading, sending, uploading;
  final Object? loadError;
  final String? error, sentText;
  const ConversationState(
      {this.messages = const [],
      this.loading = true,
      this.sending = false,
      this.uploading = false,
      this.loadError,
      this.error,
      this.sentText});
  ConversationState copy(
          {List<ChatMessage>? messages,
          bool? loading,
          bool? sending,
          bool? uploading,
          Object? loadError,
          String? error,
          String? sentText}) =>
      ConversationState(
          messages:
              messages == null ? this.messages : List.unmodifiable(messages),
          loading: loading ?? this.loading,
          sending: sending ?? this.sending,
          uploading: uploading ?? this.uploading,
          loadError: loadError,
          error: error,
          sentText: sentText);
}

sealed class ConversationEvent {}

class ConversationMessagesChanged extends ConversationEvent {
  final List<ChatMessage> messages;
  ConversationMessagesChanged(this.messages);
}

class ConversationFailed extends ConversationEvent {
  final Object error;
  ConversationFailed(this.error);
}

class MessageSent extends ConversationEvent {
  final String text;
  MessageSent(this.text);
}

class ImageSent extends ConversationEvent {}

class TypingChanged extends ConversationEvent {
  final bool typing;
  TypingChanged(this.typing);
}

class ConversationRead extends ConversationEvent {}

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final ChatCartServices services;
  final String uid, conversationId;
  late final StreamSubscription<List<ChatMessage>> _messages;
  ConversationBloc(this.services,
      {required this.uid, required this.conversationId})
      : super(const ConversationState()) {
    on<ConversationMessagesChanged>((event, emit) {
      emit(state.copy(messages: event.messages, loading: false));
      if (event.messages.any((m) => m.senderId != uid && !m.readByUser(uid))) {
        add(ConversationRead());
      }
    });
    on<ConversationFailed>((event, emit) =>
        emit(state.copy(loading: false, loadError: event.error)));
    on<ConversationRead>((event, emit) async {
      try {
        await services.chat
            .markConversationRead(conversationId: conversationId, uid: uid);
      } catch (error) {
        if (!emit.isDone) emit(state.copy(error: error.toString()));
      }
    }, transformer: droppable());
    on<MessageSent>((event, emit) async {
      final text = event.text.trim();
      if (text.isEmpty) return;
      emit(state.copy(sending: true));
      try {
        await services.chat.sendText(
            conversationId: conversationId, senderId: uid, text: text);
        if (!emit.isDone) {
          emit(state.copy(sending: false, sentText: event.text));
          add(TypingChanged(false));
        }
      } catch (error) {
        if (!emit.isDone) {
          emit(state.copy(sending: false, error: error.toString()));
        }
      }
    }, transformer: droppable());
    on<ImageSent>((event, emit) async {
      emit(state.copy(uploading: true));
      try {
        final file =
            await services.storage.pickImage(source: ImageSource.gallery);
        if (emit.isDone) return;
        if (file != null) {
          final url = await services.storage.uploadChatImage(
              conversationId: conversationId, userId: uid, file: file);
          await services.chat.sendImage(
              conversationId: conversationId, senderId: uid, imageUrl: url);
        }
        if (!emit.isDone) emit(state.copy(uploading: false));
      } catch (error) {
        if (!emit.isDone) {
          emit(state.copy(uploading: false, error: error.toString()));
        }
      }
    }, transformer: droppable());
    on<TypingChanged>((event, emit) async {
      try {
        await services.typing
            .setTyping(
                conversationId: conversationId, uid: uid, typing: event.typing)
            .timeout(const Duration(seconds: 5));
      } catch (_) {/* Presence must not prevent sending a message. */}
    }, transformer: restartable());
    _messages = services.chat.watchMessages(conversationId).listen(
      (messages) {
        if (!isClosed) add(ConversationMessagesChanged(messages));
      },
      onError: (Object error) {
        if (!isClosed) add(ConversationFailed(error));
      },
    );
  }
  @override
  Future<void> close() async {
    await _messages.cancel();
    await super.close();
    try {
      await services.typing
          .setTyping(conversationId: conversationId, uid: uid, typing: false)
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }
}
