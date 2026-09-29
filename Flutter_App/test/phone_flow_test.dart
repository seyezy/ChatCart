import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatcart_ui/blocs/phone_auth_bloc.dart';
import 'package:chatcart_ui/screens/screens.dart';

void main() {
  testWidgets('phone and OTP routes share Bloc state and navigate once', (tester) async {
    var requested = 0, verified = 0;
    await tester.pumpWidget(BlocProvider(
      create: (_) => PhoneAuthBloc(sendCode: (number, sent) async {
        requested++; expect(number, '+16505550101'); sent(); return false;
      }, verifyCode: (code) async { verified++; expect(code, '123456'); }),
      child: MaterialApp(initialRoute: '/phone', routes: {
        '/phone': (_) => const PhoneLoginScreen(),
        '/otp': (_) => const OtpScreen(),
        '/home': (_) => const Scaffold(body: Text('Authenticated home')),
      }),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid phone number'), findsOneWidget);
    expect(requested, 0);
    await tester.enterText(find.byType(TextField), '+16505550101');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Enter verification code'), findsOneWidget);
    final fields = find.byType(TextField);
    for(var i=0;i<6;i++) { await tester.enterText(fields.at(i), '${i+1}'); }
    await tester.tap(find.widgetWithText(ElevatedButton, 'Verify'));
    await tester.pumpAndSettle();
    expect(find.text('Authenticated home'), findsOneWidget);
    expect(requested, 1); expect(verified, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
