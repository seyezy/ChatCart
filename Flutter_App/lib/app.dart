import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/session_bloc.dart';
import 'blocs/phone_auth_bloc.dart';
import 'blocs/chat_bloc.dart';
import 'blocs/resource_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show appFlavor;

import 'config/app_config.dart';
import 'firebase/chatcart_firebase_options.dart';
import 'firebase/chatcart_services.dart';
import 'screens/screens.dart';
import 'screens/production_screens.dart';
import 'theme/chatcart_theme.dart';

Future<void> runChatCart(ChatCartEnvironment environment) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (appFlavor != null && appFlavor != environment.name) {
    throw StateError('The Dart entry point and native flavor must match.');
  }
  await AppConfig.load(environment);
  await _initializeFirebase();
  runApp(const ChatCartApp());
}

Future<void> _initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  await Firebase.initializeApp(
      options: ChatCartFirebaseOptions.currentPlatform);
}

class ChatCartApp extends StatelessWidget {
  const ChatCartApp({super.key});
  @override
  Widget build(BuildContext context) => MultiBlocProvider(providers: [
        BlocProvider(
            create: (_) => SessionBloc(ChatCartServices.instance), lazy: false),
        BlocProvider(
            create: (_) =>
                PhoneAuthBloc.fromService(ChatCartServices.instance.auth)),
        BlocProvider(create: (_) => ChatActionsBloc(ChatCartServices.instance)),
      ], child: const _ChatCartAppView());
}

class _ChatCartAppView extends StatefulWidget {
  const _ChatCartAppView();
  @override
  State<_ChatCartAppView> createState() => _ChatCartAppViewState();
}

class _ChatCartAppViewState extends State<_ChatCartAppView> {
  final navigator = GlobalKey<NavigatorState>();
  final messenger = GlobalKey<ScaffoldMessengerState>();
  late final AppLifecycleListener lifecycle;
  @override
  void initState() {
    super.initState();
    final session = context.read<SessionBloc>();
    lifecycle = AppLifecycleListener(
        onStateChange: (state) => session.add(SessionLifecycleChanged(state)));
  }

  @override
  void dispose() {
    lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
          listeners: [
            BlocListener<SessionBloc, SessionState>(
              listenWhen: (previous, current) =>
                  current.error != null && previous.error != current.error,
              listener: (context, state) => messenger.currentState
                  ?.showSnackBar(
                      SnackBar(content: Text(state.error.toString()))),
            ),
            BlocListener<SessionBloc, SessionState>(
                listenWhen: (previous, current) =>
                    previous.user?.uid != current.user?.uid,
                listener: (context, state) {
                  if (state.user == null) {
                    navigator.currentState
                        ?.pushNamedAndRemoveUntil('/auth', (_) => false);
                  }
                }),
            BlocListener<ChatActionsBloc, ResourceState<ChatDestination>>(
                listener: (context, state) {
              if (state.error != null) {
                messenger.currentState?.showSnackBar(
                    SnackBar(content: Text(state.error.toString())));
              }
              final destination = state.data;
              if (state.succeeded &&
                  destination != null &&
                  context.read<SessionBloc>().state.user != null) {
                navigator.currentState?.pushNamed('/conversation',
                    arguments: ConversationArgs(
                        conversationId: destination.conversationId,
                        peerUid: destination.peerUid,
                        peerName: destination.peerName));
              }
            }),
          ],
          child: BlocBuilder<SessionBloc, SessionState>(
              buildWhen: (previous, current) => previous.theme != current.theme,
              builder: (context, state) => MaterialApp(
                    navigatorKey: navigator,
                    scaffoldMessengerKey: messenger,
                    debugShowCheckedModeBanner: false,
                    title: AppConfig.appName,
                    theme: ChatCartTheme.light(),
                    darkTheme: ChatCartTheme.dark(),
                    themeMode: state.theme,
                    initialRoute: '/onboarding',
                    routes: {
                      '/': (_) => const SplashScreen(),
                      '/onboarding': (_) => const OnboardingScreen(),
                      '/auth': (_) => const AuthScreen(),
                      '/phone': (_) => const PhoneLoginScreen(),
                      '/otp': (_) => const OtpScreen(),
                      '/home': (_) => const ChatHomeScreen(),
                      '/conversation': (_) => const ConversationScreen(),
                      '/market': (_) => const MarketplaceScreen(),
                      '/product': (_) => const ProductDetailsScreen(),
                      '/profile': (_) => const ProfileScreen(),
                      '/checkout': (_) => const CheckoutScreen(),
                      '/orders': (_) => const OrdersScreen(),
                      '/seller-kyc': (_) => const SellerKycScreen(),
                      '/support': (_) => const SupportScreen(),
                      '/announcements': (_) => const AnnouncementsScreen(),
                      '/devices': (_) => const DevicesScreen(),
                    },
                  )));
}
