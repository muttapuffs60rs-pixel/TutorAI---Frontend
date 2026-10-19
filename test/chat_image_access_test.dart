import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_preethi/services/chat_image_access.dart';

void main() {
  const owner = '00000000-0000-0000-0000-000000000001';
  const origin = 'https://example.supabase.co';
  const url = '$origin/storage/v1/object/authenticated/chat-images/chat_uploads/$owner/image.jpg';

  test('private uploads use random names inside the authenticated owner directory', () {
    final paths = List.generate(100, (_) => newChatImagePath(owner));
    expect(paths.toSet().length, 100);
    expect(paths.every((p) => RegExp('^chat_uploads/$owner/[a-f0-9]{32}\\.jpg\$').hasMatch(p)), isTrue);
    expect(() => newChatImagePath('../other-user'), throwsArgumentError);
  });

  test('private previews use the current access token', () {
    expect(privateChatImageHeaders(url: url, storageUrl: origin, accessToken: 'new-session'),
        {'Authorization': 'Bearer new-session'});
    expect(privateChatImageHeaders(url: url, storageUrl: origin, accessToken: null), isEmpty);
  });

  test('message URLs cannot send the student token to another origin or public URL', () {
    for (final candidate in [
      url.replaceFirst('example.supabase.co', 'evil.test'),
      url.replaceFirst('https:', 'http:'),
      url.replaceFirst('/authenticated/', '/public/'),
      '$url?redirect=https://evil.test',
      '$url#fragment',
      url.replaceFirst('https://', 'https://user:password@'),
      'file:///image.jpg',
    ]) {
      expect(privateChatImageHeaders(url: candidate, storageUrl: origin, accessToken: 'secret'), isEmpty);
    }
  });
}
