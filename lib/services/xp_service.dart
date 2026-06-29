/// xp_service.dart
/// Owns all XP, coin, and reward business logic.
/// The simulation engine never calls this directly.
library;

import 'package:flutter/foundation.dart';

class XpResult {
  final int xpEarned;
  final int coinsEarned;
  final int totalXp;

  const XpResult({
    required this.xpEarned,
    required this.coinsEarned,
    required this.totalXp,
  });
}

class XpService extends ChangeNotifier {
  int _totalXp = 0;
  int get totalXp => _totalXp;

  /// Calculate XP earned for a completed game.
  /// Formula: base XP from score, penalised for mistakes, bonus for speed.
  XpResult calculateReward({
    required int score,
    required int mistakes,
    required int attempts,
    required int durationSeconds,
  }) {
    // Base: score maps linearly to 0–100 XP.
    final base = (score.clamp(0, 100)).toDouble();
    // Penalty: –5 XP per mistake, capped at –30.
    final penalty = (mistakes * 5).clamp(0, 30).toDouble();
    // Speed bonus: +10 XP if completed in under 60 s on first attempt.
    final speedBonus = (durationSeconds < 60 && attempts == 1) ? 10.0 : 0.0;

    final xpEarned = (base - penalty + speedBonus).clamp(0, 110).toInt();
    final coinsEarned = (xpEarned / 10).floor();

    return XpResult(
      xpEarned: xpEarned,
      coinsEarned: coinsEarned,
      totalXp: _totalXp,
    );
  }

  /// Apply earned XP to the running total and notify listeners.
  void applyReward(XpResult result) {
    _totalXp += result.xpEarned;
    notifyListeners();
  }

  /// Seed the total from Supabase on app start.
  void hydrate(int xpFromServer) {
    _totalXp = xpFromServer;
    notifyListeners();
  }
}
