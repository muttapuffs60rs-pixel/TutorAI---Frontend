import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

String newChatRequestId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Fail visibly if a successful HTTP response never supplies an answer.
Stream<String> readTutorReply(Stream<List<int>> bytes,
    {Duration idleTimeout = const Duration(seconds: 100)}) async* {
  var hasAnswer = false;
  await for (final chunk in bytes.timeout(idleTimeout).transform(utf8.decoder)) {
    if (chunk.trim().isNotEmpty) hasAnswer = true;
    yield chunk;
  }
  if (!hasAnswer) throw StateError('The tutor returned an empty answer.');
}

/// Retry transport/admission failures with the same body and idempotency key.
/// Never retry an AI stream after it has started delivering an answer.
Future<http.StreamedResponse> sendChatWithRetry({
  required http.Client client,
  required Uri endpoint,
  required String token,
  required Map<String, dynamic> payload,
  Future<void> Function(Duration)? pause,
  Duration? responseTimeout,
}) async {
  final wait = pause ?? (duration) => Future<void>.delayed(duration);
  final body = jsonEncode(payload);
  final headerTimeout = responseTimeout ??
      (payload['image_url'] is String && (payload['image_url'] as String).isNotEmpty
          ? const Duration(seconds: 120) : const Duration(seconds: 60));
  if (payload['client_request_id'] == null) {
    throw ArgumentError('A stable request ID is required for retries.');
  }
  for (var attempt = 0; attempt < 4; attempt++) {
    final abort = Completer<void>();
    Timer? timeout;
    try {
      final request = http.AbortableRequest('POST', endpoint, abortTrigger: abort.future)
        ..headers['Content-Type'] = 'application/json'
        ..headers['Authorization'] = 'Bearer $token'
        ..body = body;
      timeout = Timer(headerTimeout, () {
        if (!abort.isCompleted) abort.complete();
      });
      final response = await client.send(request).timeout(headerTimeout);
      timeout.cancel();
      final retryable = ([502, 503, 504].contains(response.statusCode) &&
          response.headers['x-chat-error'] != 'image_unavailable') ||
          (response.statusCode == 409 && response.headers['x-chat-error'] == 'request_pending');
      if (!retryable || attempt == 3) return response;
      await response.stream.drain<void>();
      final seconds = int.tryParse(response.headers['retry-after'] ?? '') ?? (attempt + 1);
      await wait(Duration(seconds: seconds.clamp(1, 5)));
    } on http.ClientException {
      if (attempt == 3) rethrow;
      await wait(Duration(seconds: attempt + 1));
    } on TimeoutException {
      if (!abort.isCompleted) abort.complete();
      if (attempt == 3) rethrow;
      await wait(Duration(seconds: attempt + 1));
    } finally {
      timeout?.cancel();
    }
  }
  throw StateError('Retry attempts exhausted');
}
