import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatcart_ui/blocs/resource_bloc.dart';
import 'package:chatcart_ui/blocs/phone_auth_bloc.dart';
import 'package:chatcart_ui/blocs/checkout_bloc.dart';
import 'package:chatcart_ui/models/backend_models.dart';
import 'package:chatcart_ui/widgets/resource_view.dart';

Future<void> flush() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('queries cancel subscriptions on reload and close, recover from errors',
      () async {
    var subscriptions = 0, cancellations = 0;
    final sources = <StreamController<int>>[];
    final bloc = ResourceBloc<int>(() {
      subscriptions++;
      final stream = StreamController<int>(onCancel: () {
        cancellations++;
      });
      sources.add(stream);
      return stream.stream;
    });
    bloc.add(const ResourceRequested());
    await flush();
    sources.first.addError(StateError('offline'));
    await flush();
    expect(bloc.state.hasError, isTrue);
    final refreshed = bloc.refresh();
    await flush();
    expect(subscriptions, 2);
    expect(cancellations, 1);
    sources.first.add(99);
    sources.last.add(7);
    await refreshed;
    await flush();
    expect(bloc.state.data, 7);
    expect(bloc.state.hasError, isFalse);
    await bloc.close();
    expect(cancellations, 2);
    for (final source in sources) {
      await source.close();
    }
  });

  test('a stale future cannot replace a refreshed query', () async {
    final first = Completer<int>(), second = Completer<int>();
    var calls = 0;
    final bloc = ResourceBloc<int>(
        () => Stream.fromFuture(calls++ == 0 ? first.future : second.future));
    bloc.add(const ResourceRequested());
    await flush();
    final refreshed = bloc.refresh();
    await flush();
    second.complete(2);
    await refreshed;
    await flush();
    first.complete(1);
    await flush();
    expect(bloc.state.data, 2);
    await bloc.close();
  });

  test('commands ignore double submits and allow retry after failure',
      () async {
    var calls = 0;
    var pending = Completer<String>();
    final bloc = ActionBloc<String, String>((input) {
      calls++;
      return pending.future;
    });
    bloc.add(const ActionRequested('one'));
    bloc.add(const ActionRequested('two'));
    await flush();
    expect(calls, 1);
    expect(bloc.state.isLoading, isTrue);
    pending.completeError(StateError('offline'));
    await flush();
    expect(bloc.state.hasError, isTrue);
    pending = Completer<String>();
    bloc.add(const ActionRequested('retry'));
    await flush();
    pending.complete('done');
    await flush();
    expect(calls, 2);
    expect(bloc.state.data, 'done');
    await bloc.close();
  });

  test('closing a command suppresses its late completion', () async {
    final pending = Completer<int>();
    final bloc = ActionBloc<int, int>((_) => pending.future);
    final states = <ResourceState<int>>[];
    final subscription = bloc.stream.listen(states.add);
    bloc.add(const ActionRequested(1));
    await flush();
    final closed = bloc.close();
    await flush();
    pending.complete(5);
    await closed;
    expect(states.where((s) => s.succeeded), isEmpty);
    await subscription.cancel();
  });

  test('phone login validates, normalizes and supports OTP retry', () async {
    String? sentNumber;
    var attempts = 0;
    final bloc = PhoneAuthBloc(sendCode: (number, sent) async {
      sentNumber = number;
      sent();
      return false;
    }, verifyCode: (_) async {
      if (attempts++ == 0) throw StateError('Invalid OTP');
    });
    bloc.add(PhoneRequested('abc'));
    await flush();
    expect(sentNumber, isNull);
    expect(bloc.state.error, isNotNull);
    bloc.add(PhoneRequested('0801 234 5678'));
    await flush();
    expect(sentNumber, '+2348012345678');
    expect(bloc.state.stage, PhoneStage.codeSent);
    bloc.add(OtpSubmitted('123'));
    await flush();
    expect(attempts, 0);
    bloc.add(OtpSubmitted('123456'));
    await flush();
    expect(bloc.state.stage, PhoneStage.failure);
    bloc.add(OtpSubmitted('123456'));
    await flush();
    expect(bloc.state.stage, PhoneStage.authenticated);
    await bloc.close();
  });

  test('phone callbacks after disposal do not add events', () async {
    late void Function() callback;
    final bloc = PhoneAuthBloc(
        sendCode: (_, sent) async {
          callback = sent;
          return false;
        },
        verifyCode: (_) async {});
    bloc.add(PhoneRequested('+16505550101'));
    await flush();
    await bloc.close();
    callback();
  });

  test('checkout clamps quantity and captures a single immutable order',
      () async {
    final pending = Completer<ChatCartOrder>();
    var calls = 0;
    Map<String, String>? captured;
    final bloc = CheckoutBloc((id, qty, address, payment) {
      calls++;
      captured = address;
      expect(qty, 3);
      expect(payment, 'pay_on_delivery');
      return pending.future;
    });
    bloc.add(QuantityChanged(0));
    await flush();
    expect(bloc.state.quantity, 1);
    bloc.add(QuantityChanged(1000));
    await flush();
    expect(bloc.state.quantity, 99);
    bloc.add(PaymentChanged('unsupported'));
    await flush();
    expect(bloc.state.payment, 'bank_transfer');
    bloc.add(OrderSubmitted('product', {}));
    await flush();
    expect(calls, 0);
    expect(bloc.state.error, isNotNull);
    bloc.add(QuantityChanged(3));
    bloc.add(PaymentChanged('pay_on_delivery'));
    await flush();
    final address = {
      'line1': '1 Demo Street',
      'city': 'Lagos',
      'phone': '+16505550101'
    };
    final event = OrderSubmitted('product', address);
    address['city'] = 'Changed';
    bloc.add(event);
    bloc.add(event);
    await flush();
    bloc.add(QuantityChanged(8));
    await flush();
    expect(bloc.state.quantity, 3);
    expect(calls, 1);
    expect(captured!['city'], 'Lagos');
    pending.complete(ChatCartOrder.fromJson({'id': 1, 'order_no': 'TEST-1'}));
    await flush();
    expect(bloc.state.order?.orderNo, 'TEST-1');
    expect(bloc.state.busy, isFalse);
    bloc.add(QuantityChanged(2));
    bloc.add(event);
    await flush();
    expect(calls, 1);
    expect(bloc.state.order?.orderNo, 'TEST-1');
    await bloc.close();
  });

  testWidgets(
      'query rebuild keeps subscription; key change and removal cancel it',
      (tester) async {
    var subscriptions = 0, cancellations = 0;
    final streams = <StreamController<int>>[];
    Widget view(String key) => MaterialApp(
        home: ResourceView<int>(
            sourceKey: key,
            source: () {
              subscriptions++;
              final stream = StreamController<int>(onCancel: () {
                cancellations++;
              });
              streams.add(stream);
              return stream.stream;
            },
            builder: (_, state) => Text('${state.data ?? 0}')));
    await tester.pumpWidget(view('first'));
    await tester.pump();
    streams.first.add(1);
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
    await tester.pumpWidget(view('first'));
    await tester.pump();
    expect(subscriptions, 1);
    await tester.pumpWidget(view('second'));
    await tester.pump();
    expect(subscriptions, 2);
    expect(cancellations, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(cancellations, 2);
    await tester.runAsync(() async {
      for (final stream in streams) {
        await stream.close();
      }
    });
  });
}
