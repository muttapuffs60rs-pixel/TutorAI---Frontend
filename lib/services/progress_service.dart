/// progress_service.dart
/// Owns all Supabase persistence for game scores and lesson progress.
/// Called by the screen after receiving GAME_COMPLETED; never by React.
library;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'game_analytics.dart';
import 'xp_service.dart';

class ProgressService {
  final SupabaseClient _db;
  final XpService _xpService;

  ProgressService({required SupabaseClient db, required XpService xpService})
      : _db = db,
        _xpService = xpService;

  /// Persists a completed game session across all relevant tables.
  /// All Supabase writes are concentrated here; the WebView screen is a
  /// pure presenter.
  ///
  /// Returns the [XpResult] so callers can update native UI.
  Future<XpResult> recordCompletion(GameAnalytics analytics) async {
    final userId = _db.auth.currentUser?.id;

    final reward = _xpService.calculateReward(
      score: analytics.score,
      mistakes: analytics.mistakes,
      attempts: analytics.attempts,
      durationSeconds: analytics.durationSeconds,
    );

    if (userId != null) {
      try {
        // ── 1. Raw game score record ──────────────────────────────────────
        await _db.from('game_scores').insert({
          'user_id':      userId,
          'game_id':      analytics.gameId,
          'lesson_id':    analytics.lessonId,
          'score':        analytics.score,
          'mistakes':     analytics.mistakes,
          'attempts':     analytics.attempts,
          'duration_sec': analytics.durationSeconds,
          'xp_earned':    reward.xpEarned,
          'completed':    analytics.completed,
          'recorded_at':  DateTime.now().toIso8601String(),
        });

        // ── 2. Lesson progress upsert ─────────────────────────────────────
        await _db.from('lesson_progress').upsert(
          {
            'user_id':    userId,
            'lesson_id':  analytics.lessonId,
            'completed':  analytics.completed,
            'best_score': analytics.score,
            'attempts':   analytics.attempts,
            'updated_at': DateTime.now().toIso8601String(),
          },
          onConflict: 'user_id,lesson_id',
        );

        // ── 3. XP ledger (RPC – activate once Supabase function exists) ───
        // await _db.rpc('add_xp', params: {
        //   'p_user_id': userId,
        //   'p_xp':      reward.xpEarned,
        //   'p_coins':   reward.coinsEarned,
        // });

        // ── 4. Daily streak touch (RPC) ───────────────────────────────────
        // await _db.rpc('touch_daily_streak', params: {'p_user_id': userId});
      } catch (e, st) {
        debugPrint('[ProgressService] Supabase error: $e\n$st');
        // Non-fatal – local XP is still applied so the UI feels responsive.
      }
    }

    // Apply XP locally regardless of network success.
    _xpService.applyReward(reward);
    return reward;
  }
}
