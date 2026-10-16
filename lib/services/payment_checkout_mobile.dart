import 'dart:async';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentCheckout {
  final Razorpay _gateway = Razorpay();
  Completer<Map<String, dynamic>>? _pending;

  PaymentCheckout() {
    _gateway.on(Razorpay.EVENT_PAYMENT_SUCCESS, (
      PaymentSuccessResponse response,
    ) {
      if (_pending?.isCompleted ?? true) return;
      _pending!.complete({
        'razorpay_payment_id': response.paymentId,
        'razorpay_order_id': response.orderId,
        'razorpay_signature': response.signature,
      });
    });
    _gateway.on(Razorpay.EVENT_PAYMENT_ERROR, (
      PaymentFailureResponse response,
    ) {
      if (_pending?.isCompleted ?? true) return;
      _pending!.completeError(
        Exception(response.message ?? 'Payment cancelled.'),
      );
    });
  }

  Future<Map<String, dynamic>> open(Map<String, dynamic> options) {
    _pending = Completer<Map<String, dynamic>>();
    try {
      _gateway.open(options);
    } catch (error) {
      _pending!.completeError(error);
    }
    return _pending!.future;
  }

  void dispose() {
    _gateway.clear();
    if (!(_pending?.isCompleted ?? true)) {
      _pending!.completeError(Exception('Checkout closed.'));
    }
  }
}
