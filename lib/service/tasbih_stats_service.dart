import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TasbihStats {
  final int today;
  final int rounds;
  final int bestStreak;

  const TasbihStats({
    required this.today,
    required this.rounds,
    required this.bestStreak,
  });

  static const empty = TasbihStats(today: 0, rounds: 0, bestStreak: 0);
}

/// Tracks how many times the user has tapped the tasbih counter per
/// calendar day — independent of the live counter's value, which can be
/// reset or resumed freely without affecting daily activity.
class TasbihStatsService {
  static const String _key = 'tasbih_daily_taps';

  /// Keep in step with `kRoundTarget` in tasbih_page.dart.
  static const int _roundSize = 100;

  static Future<Map<String, int>> _readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value as int));
    } catch (_) {
      // Data saved by an older, incompatible format - discard it.
      await prefs.remove(_key);
      return {};
    }
  }

  static Future<void> _writeAll(Map<String, int> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data));
  }

  static String _keyFor(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Records one tap for today and returns the refreshed stats snapshot.
  static Future<TasbihStats> recordTap() async {
    final data = await _readAll();
    final todayKey = _keyFor(DateTime.now());
    data[todayKey] = (data[todayKey] ?? 0) + 1;
    await _writeAll(data);
    return _computeStats(data);
  }

  static Future<TasbihStats> getStats() async {
    return _computeStats(await _readAll());
  }

  static TasbihStats _computeStats(Map<String, int> data) {
    final todayKey = _keyFor(DateTime.now());
    final todayCount = data[todayKey] ?? 0;

    final activeDates =
        data.entries
            .where((e) => e.value > 0)
            .map((e) => DateTime.parse(e.key))
            .toSet()
            .toList()
          ..sort();

    var bestStreak = 0;
    var run = 0;
    DateTime? previous;
    for (final date in activeDates) {
      run = (previous != null && date.difference(previous).inDays == 1)
          ? run + 1
          : 1;
      if (run > bestStreak) bestStreak = run;
      previous = date;
    }

    return TasbihStats(
      today: todayCount,
      rounds: todayCount ~/ _roundSize,
      bestStreak: bestStreak,
    );
  }
}
