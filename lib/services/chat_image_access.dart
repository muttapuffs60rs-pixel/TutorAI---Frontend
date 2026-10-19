import 'dart:math';

String newChatImagePath(String userId) {
  if (!RegExp(r'^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$').hasMatch(userId)) {
    throw ArgumentError('A signed-in user is required');
  }
  final random = Random.secure();
  final name = List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  return 'chat_uploads/$userId/$name.jpg';
}

Map<String, String> privateChatImageHeaders({
  required String url,
  required String storageUrl,
  required String? accessToken,
}) {
  final expected = Uri.tryParse(storageUrl);
  final target = Uri.tryParse(url);
  if (target == null || expected == null || !target.hasAuthority || !expected.hasAuthority ||
      target.scheme != 'https' || target.origin != expected.origin ||
      target.userInfo.isNotEmpty || target.hasQuery || target.hasFragment ||
      !target.path.startsWith('/storage/v1/object/authenticated/chat-images/') ||
      accessToken == null || accessToken.isEmpty) {
    return {};
  }
  return {'Authorization': 'Bearer $accessToken'};
}
