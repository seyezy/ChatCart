import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/backend_models.dart';

typedef PlaceOrder = Future<ChatCartOrder> Function(String productId,
    int quantity, Map<String, String> address, String payment);

class CheckoutState {
  final int quantity;
  final String payment;
  final bool busy;
  final ChatCartOrder? order;
  final String? error;
  const CheckoutState(
      {this.quantity = 1,
      this.payment = 'bank_transfer',
      this.busy = false,
      this.order,
      this.error});
}

sealed class CheckoutEvent {}

class QuantityChanged extends CheckoutEvent {
  final int quantity;
  QuantityChanged(this.quantity);
}

class PaymentChanged extends CheckoutEvent {
  final String payment;
  PaymentChanged(this.payment);
}

class OrderSubmitted extends CheckoutEvent {
  final String productId;
  final Map<String, String> address;
  OrderSubmitted(this.productId, Map<String, String> address)
      : address = Map.unmodifiable(address);
}

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  CheckoutBloc(PlaceOrder placeOrder) : super(const CheckoutState()) {
    on<QuantityChanged>((event, emit) {
      if (!state.busy && state.order == null) {
        emit(CheckoutState(
            quantity: event.quantity.clamp(1, 99), payment: state.payment));
      }
    });
    on<PaymentChanged>((event, emit) {
      if (!state.busy &&
          state.order == null &&
          const ['bank_transfer', 'pay_on_delivery'].contains(event.payment)) {
        emit(CheckoutState(quantity: state.quantity, payment: event.payment));
      }
    });
    on<OrderSubmitted>((event, emit) async {
      if (state.busy || state.order != null) return;
      final quantity = state.quantity;
      final payment = state.payment;
      if (['line1', 'city', 'phone']
          .any((key) => (event.address[key] ?? '').trim().isEmpty)) {
        emit(CheckoutState(
            quantity: quantity,
            payment: payment,
            error: 'Enter a complete delivery address and phone number.'));
        return;
      }
      emit(CheckoutState(quantity: quantity, payment: payment, busy: true));
      try {
        final order =
            await placeOrder(event.productId, quantity, event.address, payment);
        if (!emit.isDone) {
          emit(CheckoutState(
              quantity: quantity, payment: payment, order: order));
        }
      } catch (error) {
        if (!emit.isDone) {
          emit(CheckoutState(
              quantity: quantity, payment: payment, error: error.toString()));
        }
      }
    }, transformer: droppable());
  }
}
