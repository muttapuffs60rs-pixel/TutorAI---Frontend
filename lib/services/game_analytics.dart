/// game_analytics.dart
/// Pure data class representing a completed game session.
/// All fields come directly from the React engine; no XP/coin logic here.
class GameAnalytics {
  final String gameId;
  final String lessonId;
  final int score;        // 0–100
  final int mistakes;
  final int attempts;
  final int durationSeconds;
  final bool completed;
  final Map<String, int> actions; // e.g. { 'dropped': 3, 'reset': 1 }

  const GameAnalytics({
    required this.gameId,
    required this.lessonId,
    required this.score,
    required this.mistakes,
    required this.attempts,
    required this.durationSeconds,
    required this.completed,
    this.actions = const {},
  });

  factory GameAnalytics.fromJson(Map<String, dynamic> json) {
    return GameAnalytics(
      gameId:          json['gameId']   as String? ?? '',
      lessonId:        json['lessonId'] as String? ?? '',
      score:           (json['score']           as num?)?.toInt() ?? 0,
      mistakes:        (json['mistakes']        as num?)?.toInt() ?? 0,
      attempts:        (json['attempts']        as num?)?.toInt() ?? 1,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      completed:       json['completed'] as bool? ?? false,
      actions: (json['actions'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0)),
    );
  }

  @override
  String toString() =>
      'GameAnalytics(game=$gameId, lesson=$lessonId, score=$score, '
      'mistakes=$mistakes, attempts=$attempts, dur=${durationSeconds}s)';
}
