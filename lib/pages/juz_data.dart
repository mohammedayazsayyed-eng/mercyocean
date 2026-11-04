import 'package:qcf_quran_plus/qcf_quran_plus.dart';

/// One continuous run of ayahs from a single surah that falls inside a Juz.
/// Example: Juz 1 = [Al-Fatihah 1-7] + [Al-Baqarah 1-141].
class JuzSegment {
  final int surah;
  final int startAyah;
  final int endAyah;

  const JuzSegment(this.surah, this.startAyah, this.endAyah);

  bool get isFullSurah => startAyah == 1 && endAyah == getVerseCount(surah);
}

const int kTotalJuz = 30;

List<List<JuzSegment>>? _juzCache;

/// Walks every ayah of the Quran once (6236 lookups) and groups them by Juz.
/// Uses only getJuzNumber() and getVerseCount(), which your package already has.
List<List<JuzSegment>> _buildAllJuz() {
  final result = List.generate(kTotalJuz, (_) => <JuzSegment>[]);

  for (int s = 1; s <= totalSurahCount; s++) {
    final count = getVerseCount(s);
    for (int v = 1; v <= count; v++) {
      final juzNo = getJuzNumber(s, v);
      final list = result[juzNo - 1];

      if (list.isNotEmpty &&
          list.last.surah == s &&
          list.last.endAyah == v - 1) {
        // Same surah, next ayah: extend the current segment.
        final last = list.removeLast();
        list.add(JuzSegment(s, last.startAyah, v));
      } else {
        list.add(JuzSegment(s, v, v));
      }
    }
  }
  return result;
}

/// Returns the surah segments of a Juz (1 to 30). Computed once, then cached.
List<JuzSegment> juzSegments(int juzNo) {
  _juzCache ??= _buildAllJuz();
  return _juzCache![juzNo - 1];
}
