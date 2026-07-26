import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:mercyocean/models/tasbih_save_model.dart';

class TasbihService {
  static const String _key = 'tasbih_saves';

  static Future<List<TasbihSave>> getSaves() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List;
      final saves = decoded
          .map((e) => TasbihSave.fromJson(e as Map<String, dynamic>))
          .toList();
      saves.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return saves;
    } catch (_) {
      // Data saved by an older, incompatible format - discard it.
      await prefs.remove(_key);
      return [];
    }
  }

  static Future<TasbihSave> addSave({
    required String name,
    required int count,
  }) async {
    final saves = await getSaves();
    final save = TasbihSave(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      count: count,
      savedAt: DateTime.now(),
    );
    saves.add(save);
    await _persist(saves);
    return save;
  }

  /// Updates the count (and bumps the timestamp) of an existing save —
  /// used when the user continues counting from a resumed save.
  static Future<void> updateCount(String id, int count) async {
    final saves = await getSaves();
    final index = saves.indexWhere((s) => s.id == id);
    if (index == -1) return;

    saves[index] = saves[index].copyWith(count: count, savedAt: DateTime.now());
    await _persist(saves);
  }

  static Future<void> rename(String id, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    final saves = await getSaves();
    final index = saves.indexWhere((s) => s.id == id);
    if (index == -1) return;

    saves[index] = saves[index].copyWith(name: trimmed);
    await _persist(saves);
  }

  static Future<void> delete(String id) async {
    final saves = await getSaves();
    saves.removeWhere((s) => s.id == id);
    await _persist(saves);
  }

  static Future<void> _persist(List<TasbihSave> saves) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(saves.map((s) => s.toJson()).toList()),
    );
  }
}
