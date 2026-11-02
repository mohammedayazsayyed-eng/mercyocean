import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AyahRef {
  final int surahNumber;
  final int ayahNumber;
  final int page;

  const AyahRef({
    required this.surahNumber,
    required this.ayahNumber,
    required this.page,
  });

  Map<String, dynamic> toJson() => {
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    'page': page,
  };

  factory AyahRef.fromJson(Map<String, dynamic> json) => AyahRef(
    surahNumber: json['surahNumber'] as int,
    ayahNumber: json['ayahNumber'] as int,
    page: json['page'] as int,
  );
}

class MushafBookmark {
  final String id;
  final List<AyahRef> ayahs;
  final DateTime savedAt;
  final String? label;

  const MushafBookmark({
    required this.id,
    required this.ayahs,
    required this.savedAt,
    this.label,
  });

  int get firstPage => ayahs.first.page;
  int get firstSurah => ayahs.first.surahNumber;

  MushafBookmark copyWith({String? label}) =>
      MushafBookmark(id: id, ayahs: ayahs, savedAt: savedAt, label: label);

  Map<String, dynamic> toJson() => {
    'id': id,
    'ayahs': ayahs.map((a) => a.toJson()).toList(),
    'savedAt': savedAt.toIso8601String(),
    'label': label,
  };

  factory MushafBookmark.fromJson(Map<String, dynamic> json) => MushafBookmark(
    id: json['id'] as String,
    ayahs: (json['ayahs'] as List)
        .map((e) => AyahRef.fromJson(e as Map<String, dynamic>))
        .toList(),
    savedAt: DateTime.parse(json['savedAt'] as String),
    label: json['label'] as String?,
  );
}

class MushafBookmarkService {
  static const String _key = 'mushaf_bookmarks';

  static Future<List<MushafBookmark>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List;
      final bookmarks = decoded
          .map((e) => MushafBookmark.fromJson(e as Map<String, dynamic>))
          .toList();
      bookmarks.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return bookmarks;
    } catch (_) {
      // Data saved by an older, incompatible format - discard it.
      await prefs.remove(_key);
      return [];
    }
  }

  static Future<MushafBookmark> addBookmark(
    List<AyahRef> ayahs, {
    String? label,
  }) async {
    final bookmarks = await getBookmarks();
    final bookmark = MushafBookmark(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      ayahs: ayahs,
      savedAt: DateTime.now(),
      label: (label == null || label.trim().isEmpty) ? null : label.trim(),
    );
    bookmarks.add(bookmark);
    await _save(bookmarks);
    return bookmark;
  }

  static Future<void> removeBookmark(String id) async {
    final bookmarks = await getBookmarks();
    bookmarks.removeWhere((b) => b.id == id);
    await _save(bookmarks);
  }

  static Future<void> renameBookmark(String id, String? label) async {
    final bookmarks = await getBookmarks();
    final index = bookmarks.indexWhere((b) => b.id == id);
    if (index == -1) return;

    bookmarks[index] = bookmarks[index].copyWith(
      label: (label == null || label.trim().isEmpty) ? null : label.trim(),
    );
    await _save(bookmarks);
  }

  static Future<void> _save(List<MushafBookmark> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(bookmarks.map((b) => b.toJson()).toList()),
    );
  }
}
