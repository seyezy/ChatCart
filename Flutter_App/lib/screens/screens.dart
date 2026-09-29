import '../widgets/shimmer_loader.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/resource_bloc.dart';
import '../blocs/phone_auth_bloc.dart';
import '../blocs/session_bloc.dart';
import '../blocs/chat_bloc.dart';
import '../widgets/resource_view.dart';
import 'package:flutter/material.dart';
import '../firebase/chatcart_services.dart';
import '../models/chat_models.dart';
import '../theme/chatcart_theme.dart';
import '../widgets/chatcart_widgets.dart';
import 'production_screens.dart';

final _svc = ChatCartServices.instance;

class ConversationArgs {
  final String conversationId;
  final String peerUid;
  final String peerName;
  const ConversationArgs(
      {required this.conversationId,
      required this.peerUid,
      required this.peerName});
}

class ProductArgs {
  final String productId;
  const ProductArgs(this.productId);
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
          body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
        const ChatCartLogo(),
        const SizedBox(height: 20),
        Text('ChatCart',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Chat. Connect. Shop.',
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500)),
      ])));
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  final items = const [
    (
      Icons.forum_rounded,
      'Connect Instantly',
      'Message your friends and family privately and in groups.'
    ),
    (
      Icons.storefront_rounded,
      'Shop with Confidence',
      'Discover useful products, great deals and trusted sellers.'
    ),
    (
      Icons.shield_rounded,
      'Secure & Private',
      'Your conversations and account stay protected with privacy-first controls.'
    ),
  ];

  @override
  Widget build(BuildContext context) => BlocProvider(
      create: (_) => SelectionBloc<int>(0),
      child: BlocBuilder<SelectionBloc<int>, int>(builder: (context, page) {
        final item = items[page];
        return Scaffold(
            body: SafeArea(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    child: Column(children: [
                      Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                              onPressed: () => Navigator.pushReplacementNamed(
                                  context, '/auth'),
                              child: const Text('Skip'))),
                      const Spacer(),
                      Container(
                          width: 280,
                          height: 260,
                          decoration: BoxDecoration(
                              color: page == 0
                                  ? Colors.transparent
                                  : Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(32)),
                          child: page == 0
                              ? const Center(child: ChatCartLogo(size: 160))
                              : Icon(item.$1,
                                  size: 132,
                                  color:
                                      Theme.of(context).colorScheme.primary)),
                      const SizedBox(height: 32),
                      Text(item.$2,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(item.$3,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              height: 1.5,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withValues(alpha: .68))),
                      const SizedBox(height: 28),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                              3,
                              (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  width: i == page ? 20 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                      color: i == page
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context).dividerColor,
                                      borderRadius:
                                          BorderRadius.circular(99))))),
                      const Spacer(),
                      ElevatedButton(
                          onPressed: () {
                            if (page < 2) {
                              context
                                  .read<SelectionBloc<int>>()
                                  .add(SelectionChanged(page + 1));
                            } else {
                              Navigator.pushReplacementNamed(context, '/auth');
                            }
                          },
                          child: Text(page == 2 ? 'Get Started' : 'Next'))
                    ]))));
      }));
}

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      body: SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                const Spacer(),
                const ChatCartLogo(size: 144),
                const SizedBox(height: 18),
                const Text('ChatCart',
                    style:
                        TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                Text('Chat. Connect. Shop.',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary)),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/phone'),
                    icon: const Icon(Icons.phone),
                    label: const Text('Continue with Phone'),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                    'By continuing, you agree to our Terms of Service and Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
              ]))));
}

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});
  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final controller = TextEditingController();
  @override
  void initState() {
    super.initState();
    context.read<PhoneAuthBloc>().add(PhoneReset());
  }

  void _continue() =>
      context.read<PhoneAuthBloc>().add(PhoneRequested(controller.text));
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<PhoneAuthBloc, PhoneState>(listener: (context, state) {
        if (ModalRoute.of(context)?.isCurrent != true) return;
        if (state.stage == PhoneStage.authenticated) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
        }
        if (state.stage == PhoneStage.codeSent) {
          Navigator.pushNamed(context, '/otp');
        }
      }, builder: (context, state) {
        final busy = state.busy;
        final error = state.error;
        return Scaffold(
            appBar: AppBar(),
            body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Welcome back! 👋',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      const Text('Login to continue to ChatCart.'),
                      const SizedBox(height: 32),
                      TextField(
                          controller: controller,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                              prefixIcon: const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: Text('🇳🇬  +234')),
                              hintText: 'Phone number',
                              errorText: error)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                          onPressed: busy ? null : _continue,
                          child: busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Continue')),
                      const SizedBox(height: 28),
                      const Row(children: [
                        Expanded(child: Divider()),
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('Firebase phone authentication',
                                style: TextStyle(fontSize: 12))),
                        Expanded(child: Divider())
                      ]),
                    ])));
      });
}

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final fields = List.generate(6, (_) => TextEditingController());
  final focus = List.generate(6, (_) => FocusNode());
  void _verify() => context
      .read<PhoneAuthBloc>()
      .add(OtpSubmitted(fields.map((e) => e.text).join()));
  @override
  void dispose() {
    for (final controller in fields) {
      controller.dispose();
    }
    for (final node in focus) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<PhoneAuthBloc, PhoneState>(listener: (context, state) {
        if (ModalRoute.of(context)?.isCurrent != true) return;
        if (state.stage == PhoneStage.authenticated) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
        }
      }, builder: (context, state) {
        final busy = state.busy;
        final error = state.error;
        return Scaffold(
            appBar: AppBar(),
            body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Enter verification code',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      const Text('Enter the 6-digit code sent by Firebase.'),
                      const SizedBox(height: 32),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                              6,
                              (i) => SizedBox(
                                  width: 48,
                                  height: 56,
                                  child: TextField(
                                      controller: fields[i],
                                      focusNode: focus[i],
                                      textAlign: TextAlign.center,
                                      maxLength: 1,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          counterText: ''),
                                      onChanged: (v) {
                                        if (v.isNotEmpty && i < 5) {
                                          focus[i + 1].requestFocus();
                                        }
                                      })))),
                      if (error != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(error,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error))),
                      const SizedBox(height: 24),
                      Center(
                          child: Text('SMS verification',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w700))),
                      const SizedBox(height: 32),
                      ElevatedButton(
                          onPressed: busy ? null : _verify,
                          child: busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Verify'))
                    ])));
      });
}

class ChatHomeScreen extends StatelessWidget {
  const ChatHomeScreen({super.key});

  Future<void> _newChat(BuildContext context, String uid) async {
    await showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (_) => SizedBox(
            height: 520,
            child: ResourceView<List<ChatUser>>(
              sourceKey: uid,
              source: () => _svc.chat.watchUsers(exceptUid: uid),
              builder: (context, snap) {
                if (snap.isLoading) {
                  return const ShimmerLoader();
                }
                if (snap.hasError) return _ErrorState(snap.error.toString());
                final users = snap.data ?? const <ChatUser>[];
                return Column(children: [
                  const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('New chat',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800))),
                  Expanded(
                      child: users.isEmpty
                          ? const Center(child: Text('No other users yet.'))
                          : ListView.builder(
                              itemCount: users.length,
                              itemBuilder: (_, i) {
                                final u = users[i];
                                return ListTile(
                                    leading: ChatAvatar(
                                        _initials(u.displayName),
                                        online: false,
                                        photoUrl: u.photoUrl),
                                    title: Text(u.displayName),
                                    subtitle: Text(u.phone),
                                    onTap: () {
                                      final bloc =
                                          context.read<ChatActionsBloc>();
                                      Navigator.pop(context);
                                      bloc.add(ActionRequested(ChatRequest(u.id,
                                          peerName: u.displayName)));
                                    });
                              }))
                ]);
              },
            )));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionBloc>().state.user;
    if (user == null) {
      return _AuthRequired(
          onLogin: () => Navigator.pushNamedAndRemoveUntil(
              context, '/auth', (_) => false));
    }
    return AppShell(
        title: 'Chats',
        navIndex: 0,
        actions: [
          IconButton(
              onPressed: () {}, icon: const Icon(Icons.camera_alt_outlined)),
          IconButton(
              onPressed: () => _newChat(context, user.uid),
              icon: const Icon(Icons.add))
        ],
        onNav: (i) {
          if (i == 2) Navigator.pushReplacementNamed(context, '/market');
          if (i == 4) Navigator.pushReplacementNamed(context, '/profile');
        },
        child: Column(children: [
          const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                  decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search',
                      isDense: true))),
          SizedBox(
              height: 40,
              child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: ['All', 'Unread', 'Groups', 'Archived']
                      .map((e) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                              selected: e == 'All',
                              onSelected: (_) {},
                              label: Text(e))))
                      .toList())),
          Expanded(
              child: ResourceView<List<ChatConversation>>(
                  sourceKey: user.uid,
                  source: () => _svc.chat.watchConversations(user.uid),
                  builder: (context, snap) {
                    if (snap.isLoading) {
                      return const ShimmerLoader();
                    }
                    if (snap.hasError) {
                      return _ErrorState(snap.error.toString());
                    }
                    final conversations = snap.data ?? const [];
                    if (conversations.isEmpty) {
                      return Center(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.forum_outlined, size: 54),
                        const SizedBox(height: 12),
                        const Text('No conversations yet'),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                            onPressed: () => _newChat(context, user.uid),
                            icon: const Icon(Icons.add),
                            label: const Text('Start a chat'))
                      ]));
                    }
                    return ListView.separated(
                        itemCount: conversations.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 76),
                        itemBuilder: (_, i) => _ConversationTile(
                            conversation: conversations[i],
                            currentUid: user.uid));
                  }))
        ]));
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatConversation conversation;
  final String currentUid;
  const _ConversationTile(
      {required this.conversation, required this.currentUid});
  @override
  Widget build(BuildContext context) {
    final peerUid = conversation.participants
        .firstWhere((id) => id != currentUid, orElse: () => currentUid);
    return ResourceView<ChatUser?>(
        sourceKey: peerUid,
        source: () => _svc.chat.watchUser(peerUid),
        builder: (context, snap) {
          final peer = snap.data;
          final name = peer?.displayName ?? 'ChatCart User';
          return ListTile(
            onTap: () => Navigator.pushNamed(context, '/conversation',
                arguments: ConversationArgs(
                    conversationId: conversation.id,
                    peerUid: peerUid,
                    peerName: name)),
            leading: ResourceView<bool>(
                sourceKey: peerUid,
                source: () => _svc.presence.watchOnline(peerUid),
                builder: (_, online) => ChatAvatar(_initials(name),
                    online: online.data ?? false, photoUrl: peer?.photoUrl)),
            title:
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
                conversation.lastMessage.isEmpty
                    ? 'New conversation'
                    : conversation.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            trailing: Text(_time(conversation.updatedAt),
                style: const TextStyle(fontSize: 11)),
          );
        });
  }
}

class ConversationScreen extends StatelessWidget {
  const ConversationScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = context.watch<SessionBloc>().state.user?.uid;
    final args =
        ModalRoute.of(context)?.settings.arguments as ConversationArgs?;
    if (uid == null) {
      return _AuthRequired(
          onLogin: () => Navigator.pushNamedAndRemoveUntil(
              context, '/auth', (_) => false));
    }
    if (args == null) {
      return const Scaffold(
          body: Center(child: Text('Open a conversation from Chats.')));
    }
    return BlocProvider(
        key: ValueKey((uid, args.conversationId)),
        create: (_) => ConversationBloc(_svc,
            uid: uid, conversationId: args.conversationId),
        child: _ConversationBody(args: args, uid: uid));
  }
}

class _ConversationBody extends StatefulWidget {
  final ConversationArgs args;
  final String uid;
  const _ConversationBody({required this.args, required this.uid});
  @override
  State<_ConversationBody> createState() => _ConversationBodyState();
}

class _ConversationBodyState extends State<_ConversationBody> {
  final text = TextEditingController();
  void _send() => context.read<ConversationBloc>().add(MessageSent(text.text));
  void _sendImage() => context.read<ConversationBloc>().add(ImageSent());
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ConversationBloc, ConversationState>(
          listener: (context, state) {
        if (state.sentText != null && text.text == state.sentText) text.clear();
        if (state.error != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.error!)));
        }
      }, builder: (context, state) {
        final a = widget.args;
        final uid = widget.uid;
        final uploading = state.uploading;
        return Scaffold(
            appBar: AppBar(
                titleSpacing: 0,
                title: Row(children: [
                  ResourceView<bool>(
                      sourceKey: a.peerUid,
                      source: () => _svc.presence.watchOnline(a.peerUid),
                      builder: (_, online) => ChatAvatar(_initials(a.peerName),
                          size: 36, online: online.data ?? false)),
                  const SizedBox(width: 10),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.peerName,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                        ResourceView<bool>(
                            sourceKey: (a.conversationId, a.peerUid),
                            source: () => _svc.typing.watchTyping(
                                conversationId: a.conversationId,
                                otherUid: a.peerUid),
                            builder: (_, typing) => Text(
                                typing.data == true ? 'typing…' : 'ChatCart',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: typing.data == true
                                        ? Theme.of(context).colorScheme.primary
                                        : null)))
                      ])
                ]),
                actions: [
                  IconButton(
                      onPressed: () {}, icon: const Icon(Icons.call_outlined)),
                  IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.videocam_outlined)),
                  PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'report') {
                          ReportActions.reportUser(context,
                              uid: a.peerUid, name: a.peerName);
                        }
                      },
                      itemBuilder: (_) => const [
                            PopupMenuItem(
                                value: 'report',
                                child: Row(children: [
                                  Icon(Icons.flag_outlined),
                                  SizedBox(width: 10),
                                  Text('Report user')
                                ]))
                          ])
                ]),
            body: Column(children: [
              Expanded(child: Builder(builder: (context) {
                final snap = ResourceState<List<ChatMessage>>(
                    data: state.messages,
                    isLoading: state.loading,
                    error: state.loadError);
                if (snap.isLoading) {
                  return const ShimmerLoader(
                      layout: SkeletonLayout.conversation);
                }
                if (snap.hasError) return _ErrorState(snap.error.toString());
                final messages = snap.data ?? const [];
                return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (_, i) => _MessageBubble(
                        message: messages[i],
                        sent: messages[i].senderId == uid,
                        onLongPress: messages[i].senderId == uid
                            ? null
                            : () => ReportActions.reportMessage(context,
                                conversationId: a.conversationId,
                                messageId: messages[i].id)));
              })),
              if (uploading) const LinearProgressIndicator(minHeight: 2),
              SafeArea(
                  top: false,
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                      child: Row(children: [
                        IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.emoji_emotions_outlined)),
                        Expanded(
                            child: TextField(
                                controller: text,
                                minLines: 1,
                                maxLines: 5,
                                onChanged: (v) {
                                  context
                                      .read<ConversationBloc>()
                                      .add(TypingChanged(v.trim().isNotEmpty));
                                },
                                onSubmitted: (_) => _send(),
                                decoration: const InputDecoration(
                                    hintText: 'Type a message...',
                                    isDense: true))),
                        IconButton(
                            onPressed: uploading ? null : _sendImage,
                            icon: const Icon(Icons.attach_file)),
                        IconButton(
                            onPressed: state.sending ? null : _send,
                            icon: const Icon(Icons.send_rounded,
                                color: ChatCartColors.brand500)),
                      ])))
            ]));
      });
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool sent;
  final VoidCallback? onLongPress;
  const _MessageBubble(
      {required this.message, required this.sent, this.onLongPress});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onLongPress: onLongPress,
      child: Align(
          alignment: sent ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 290),
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: sent
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: .16)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(sent ? 16 : 4),
                    bottomRight: Radius.circular(sent ? 4 : 16))),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (message.type == 'image' && message.mediaUrl != null)
                ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(message.mediaUrl!,
                        width: 220,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(
                            width: 220,
                            height: 140,
                            child: Center(
                                child: Icon(Icons.broken_image_outlined))))),
              if (message.text.isNotEmpty)
                Padding(
                    padding:
                        EdgeInsets.only(top: message.type == 'image' ? 8 : 0),
                    child: Text(message.text)),
              const SizedBox(height: 3),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_time(message.createdAt),
                    style: TextStyle(
                        fontSize: 9,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: .55))),
                if (sent)
                  Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(Icons.done_all,
                          size: 14,
                          color: message.readBy.length > 1
                              ? ChatCartColors.brand500
                              : Theme.of(context).disabledColor))
              ])
            ]),
          )));
}

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
      create: (_) => SelectionBloc<String>('All'),
      child: BlocBuilder<SelectionBloc<String>, String>(
          builder: (context, category) => AppShell(
              title: 'Marketplace',
              navIndex: 2,
              actions: [
                IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.shopping_cart_outlined))
              ],
              onNav: (i) {
                if (i == 0) Navigator.pushReplacementNamed(context, '/home');
                if (i == 4) Navigator.pushReplacementNamed(context, '/profile');
              },
              child: Column(children: [
                const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: TextField(
                        decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Search products or categories',
                            isDense: true))),
                SizedBox(
                    height: 82,
                    child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          ('All', Icons.apps),
                          ('Electronics', Icons.devices),
                          ('Fashion', Icons.checkroom),
                          ('Home', Icons.home_outlined),
                          ('Beauty', Icons.spa_outlined)
                        ]
                            .map((x) => InkWell(
                                onTap: () => context
                                    .read<SelectionBloc<String>>()
                                    .add(SelectionChanged(x.$1)),
                                child: SizedBox(
                                    width: 76,
                                    child: Column(children: [
                                      CircleAvatar(
                                          radius: 22,
                                          backgroundColor: category == x.$1
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: .10),
                                          child: Icon(x.$2,
                                              color: category == x.$1
                                                  ? Colors.white
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                              size: 20)),
                                      const SizedBox(height: 5),
                                      Text(x.$1,
                                          style: const TextStyle(fontSize: 10))
                                    ]))))
                            .toList())),
                const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Featured Deals',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)))),
                Expanded(
                    child: ResourceView<List<MarketplaceProduct>>(
                        sourceKey: category,
                        source: () =>
                            _svc.marketplace.watchProducts(category: category),
                        builder: (context, snap) {
                          if (snap.isLoading) {
                            return const ShimmerLoader(
                                layout: SkeletonLayout.products);
                          }
                          if (snap.hasError) {
                            return _ErrorState(snap.error.toString());
                          }
                          final products = snap.data ?? const [];
                          if (products.isEmpty) {
                            return const Center(
                                child:
                                    Text('No products in this category yet.'));
                          }
                          return GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: .72),
                              itemCount: products.length,
                              itemBuilder: (_, i) {
                                final p = products[i];
                                return ProductCard(
                                    title: p.title,
                                    price: p.formattedPrice,
                                    icon: Icons.shopping_bag_outlined,
                                    imageUrl: p.imageUrls.isNotEmpty
                                        ? p.imageUrls.first
                                        : null,
                                    onTap: () => Navigator.pushNamed(
                                        context, '/product',
                                        arguments: ProductArgs(p.id)));
                              });
                        }))
              ]))));
}

class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as ProductArgs?;
    if (args == null) {
      return const Scaffold(
          body: Center(child: Text('Select a product from Marketplace.')));
    }
    return ResourceView<MarketplaceProduct?>(
        sourceKey: args.productId,
        source: () => _svc.marketplace.watchProduct(args.productId),
        builder: (context, snap) {
          if (snap.isLoading) {
            return const Scaffold(
                body: ShimmerLoader(layout: SkeletonLayout.product));
          }
          if (snap.hasError) {
            return Scaffold(body: _ErrorState(snap.error.toString()));
          }
          final p = snap.data;
          if (p == null) {
            return const Scaffold(
                body: Center(
                    child: Text('This product is no longer available.')));
          }
          return Scaffold(
              appBar: AppBar(actions: [
                IconButton(
                    onPressed: () {}, icon: const Icon(Icons.favorite_border)),
                IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.ios_share_outlined)),
                IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.shopping_cart_outlined))
              ]),
              body: Column(children: [
                Expanded(
                    child: ListView(children: [
                  Container(
                      height: 300,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(24)),
                      child: p.imageUrls.isEmpty
                          ? Icon(Icons.shopping_bag_outlined,
                              size: 150,
                              color: Theme.of(context).colorScheme.primary)
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.network(p.imageUrls.first,
                                  fit: BoxFit.cover))),
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.title,
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Text(p.formattedPrice,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Row(children: [
                              const Icon(Icons.star_rounded,
                                  color: Colors.amber, size: 18),
                              Text(' ${p.rating.toStringAsFixed(1)}')
                            ]),
                            const SizedBox(height: 20),
                            const Text('Description',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Text(
                                p.description.isEmpty
                                    ? 'No description supplied.'
                                    : p.description,
                                style: TextStyle(
                                    height: 1.5,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withValues(alpha: .72))),
                            const SizedBox(height: 18),
                            ResourceView<ChatUser?>(
                                sourceKey: p.sellerId,
                                source: () => _svc.chat.watchUser(p.sellerId),
                                builder: (_, userSnap) {
                                  final seller = userSnap.data;
                                  return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: ChatAvatar(
                                          _initials(
                                              seller?.displayName ?? 'Seller'),
                                          online: true,
                                          photoUrl: seller?.photoUrl),
                                      title: Text(
                                          seller?.displayName ??
                                              'ChatCart Seller',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700)),
                                      subtitle:
                                          const Text('Marketplace seller'),
                                      trailing: TextButton(
                                          onPressed: () =>
                                              _messageSeller(context, p),
                                          child: const Text('Message')));
                                })
                          ]))
                ])),
                Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        border: Border(
                            top: BorderSide(
                                color: Theme.of(context).dividerColor))),
                    child: Row(children: [
                      Expanded(
                          child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52)),
                              onPressed: () => Navigator.pushNamed(
                                  context, '/checkout',
                                  arguments: CheckoutArgs(p.id)),
                              child: const Text('Checkout'))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: ElevatedButton(
                              onPressed: () => Navigator.pushNamed(
                                  context, '/checkout',
                                  arguments: CheckoutArgs(p.id)),
                              child: const Text('Buy Now')))
                    ]))
              ]));
        });
  }

  void _messageSeller(BuildContext context, MarketplaceProduct p) {
    if (context.read<SessionBloc>().state.user == null) {
      Navigator.pushNamed(context, '/auth');
      return;
    }
    context
        .read<ChatActionsBloc>()
        .add(ActionRequested(ChatRequest(p.sellerId, product: p)));
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final current = context.watch<SessionBloc>().state.user;
    if (current == null) {
      return _AuthRequired(
          onLogin: () => Navigator.pushNamedAndRemoveUntil(
              context, '/auth', (_) => false));
    }
    return AppShell(
        title: 'Profile',
        navIndex: 4,
        actions: [
          IconButton(
              onPressed: () {}, icon: const Icon(Icons.settings_outlined))
        ],
        onNav: (i) {
          if (i == 0) Navigator.pushReplacementNamed(context, '/home');
          if (i == 2) Navigator.pushReplacementNamed(context, '/market');
        },
        child: ResourceView<ChatUser?>(
            sourceKey: current.uid,
            source: () => _svc.chat.watchUser(current.uid),
            builder: (context, snap) {
              if (snap.isLoading) {
                return const ShimmerLoader(layout: SkeletonLayout.profile);
              }
              final profile = snap.data;
              final name = profile?.displayName ??
                  current.displayName ??
                  'ChatCart User';
              final phone = profile?.phone ?? current.phoneNumber ?? '';
              return ListView(padding: const EdgeInsets.all(16), children: [
                Center(
                    child: ChatAvatar(_initials(name),
                        size: 88,
                        online: true,
                        photoUrl: profile?.photoUrl ?? current.photoURL)),
                const SizedBox(height: 12),
                Center(
                    child: Text(name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800))),
                const SizedBox(height: 4),
                Center(
                    child: Text(phone,
                        style: TextStyle(
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withValues(alpha: .65)))),
                const SizedBox(height: 20),
                Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Theme.of(context)
                                .dividerColor
                                .withValues(alpha: .55))),
                    child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _Stat('—', 'Chats'),
                          _Stat('—', 'Groups'),
                          _Stat('—', 'Listings'),
                          _Stat('—', 'Orders')
                        ])),
                const SizedBox(height: 18),
                ...[
                  (Icons.storefront_outlined, 'My Listings', ''),
                  (Icons.receipt_long_outlined, 'My Orders', '/orders'),
                  (
                    Icons.verified_user_outlined,
                    'Seller Verification',
                    '/seller-kyc'
                  ),
                  (Icons.campaign_outlined, 'Announcements', '/announcements'),
                  (Icons.devices_outlined, 'Devices & Sessions', '/devices'),
                  (Icons.favorite_border, 'Saved Items', ''),
                  (Icons.account_balance_wallet_outlined, 'My Wallet', ''),
                  (Icons.location_on_outlined, 'Address Book', ''),
                  (Icons.credit_card_outlined, 'Payment Methods', ''),
                  (Icons.notifications_none, 'Notifications', ''),
                  (Icons.lock_outline, 'Privacy & Security', ''),
                  (Icons.contrast, 'Appearance', ''),
                  (Icons.help_outline, 'Help & Support', '/support')
                ].map((x) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(x.$1),
                    title: Text(x.$2),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: x.$3.isEmpty
                        ? null
                        : () => Navigator.pushNamed(context, x.$3))),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                    onPressed: () =>
                        context.read<SessionBloc>().add(SessionSignOut()),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'))
              ]);
            }));
  }
}

class _Stat extends StatelessWidget {
  final String n, l;
  const _Stat(this.n, this.l);
  @override
  Widget build(BuildContext c) => Column(children: [
        Text(n, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(l, style: const TextStyle(fontSize: 11))
      ]);
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState(this.message);
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.cloud_off_outlined,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            const Text('Could not load data',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12))
          ])));
}

class _AuthRequired extends StatelessWidget {
  final VoidCallback onLogin;
  const _AuthRequired({required this.onLogin});
  @override
  Widget build(BuildContext context) => Scaffold(
      body: Center(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const ChatCartLogo(),
                const SizedBox(height: 20),
                const Text('Sign in to use ChatCart',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                ElevatedButton(
                    onPressed: onLogin, child: const Text('Continue'))
              ]))));
}

String _initials(String name) {
  final p = name.trim().split(RegExp(r'\s+'));
  if (p.isEmpty || p.first.isEmpty) return 'CC';
  return p.take(2).map((e) => e[0].toUpperCase()).join();
}

String _time(DateTime? date) {
  if (date == null) return '';
  final now = DateTime.now();
  if (now.difference(date).inDays == 0) {
    final h = date.hour % 12 == 0 ? 12 : date.hour % 12;
    return '$h:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
  }
  if (now.difference(date).inDays == 1) return 'Yesterday';
  return '${date.day}/${date.month}/${date.year}';
}
