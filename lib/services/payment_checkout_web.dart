import 'dart:js_interop';

@JS('arivoraCheckout.open')
external JSPromise<JSAny?> _open(JSAny? options);

@JS('arivoraCheckout.close')
external void _close();

class PaymentCheckout {
  Future<Map<String, dynamic>> open(Map<String, dynamic> options) async {
    final result = (await _open(options.jsify()).toDart).dartify();
    return Map<String, dynamic>.from(result as Map);
  }

  void dispose() => _close();
}
