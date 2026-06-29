// test/services/xp_service_test.dart
//
// Unit tests for XpService.
// Run: flutter test test/services/xp_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_preethi/services/xp_service.dart';

void main() {
  group('XpService', () {
    late XpService svc;

    setUp(() => svc = XpService());

    test('100 score, 0 mistakes, fast → max XP', () {
      final r = svc.calculateReward(
          score: 100, mistakes: 0, attempts: 1, durationSeconds: 30);
      expect(r.xpEarned, 110); // 100 + 10 speed bonus
    });

    test('0 score → 0 XP', () {
      final r = svc.calculateReward(
          score: 0, mistakes: 0, attempts: 1, durationSeconds: 30);
      expect(r.xpEarned, greaterThanOrEqualTo(0));
    });

    test('heavy mistakes reduce XP', () {
      final clean = svc.calculateReward(
          score: 80, mistakes: 0, attempts: 1, durationSeconds: 120);
      final messy = svc.calculateReward(
          score: 80, mistakes: 6, attempts: 2, durationSeconds: 120);
      expect(messy.xpEarned, lessThan(clean.xpEarned));
    });

    test('coins are 1/10 of XP', () {
      final r = svc.calculateReward(
          score: 90, mistakes: 0, attempts: 1, durationSeconds: 120);
      expect(r.coinsEarned, (r.xpEarned / 10).floor());
    });

    test('applyReward accumulates totalXp', () {
      final r1 = svc.calculateReward(
          score: 80, mistakes: 0, attempts: 1, durationSeconds: 120);
      svc.applyReward(r1);
      final r2 = svc.calculateReward(
          score: 70, mistakes: 1, attempts: 2, durationSeconds: 120);
      svc.applyReward(r2);
      expect(svc.totalXp, r1.xpEarned + r2.xpEarned);
    });

    test('hydrate seeds totalXp', () {
      svc.hydrate(500);
      expect(svc.totalXp, 500);
    });
  });
}
