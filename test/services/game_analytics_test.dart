// test/services/game_analytics_test.dart
//
// Unit tests for GameAnalytics deserialization.
// Run: flutter test test/services/game_analytics_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_preethi/services/game_analytics.dart';

void main() {
  group('GameAnalytics.fromJson', () {
    final full = {
      'gameId': 'variation_g',
      'lessonId': 'forces_03',
      'score': 92,
      'mistakes': 1,
      'attempts': 2,
      'durationSeconds': 134,
      'completed': true,
      'actions': {'dropped': 3, 'reset': 1},
    };

    test('parses all fields', () {
      final a = GameAnalytics.fromJson(full);
      expect(a.gameId,          'variation_g');
      expect(a.lessonId,        'forces_03');
      expect(a.score,           92);
      expect(a.mistakes,        1);
      expect(a.attempts,        2);
      expect(a.durationSeconds, 134);
      expect(a.completed,       true);
      expect(a.actions,         {'dropped': 3, 'reset': 1});
    });

    test('handles missing optional fields with defaults', () {
      final a = GameAnalytics.fromJson({});
      expect(a.gameId,          '');
      expect(a.lessonId,        '');
      expect(a.score,           0);
      expect(a.mistakes,        0);
      expect(a.attempts,        1); // defaults to 1
      expect(a.durationSeconds, 0);
      expect(a.completed,       false);
      expect(a.actions,         isEmpty);
    });

    test('handles numeric fields as num', () {
      final a = GameAnalytics.fromJson({...full, 'score': 87.5, 'mistakes': 2.0});
      expect(a.score,    87);
      expect(a.mistakes, 2);
    });
  });
}
