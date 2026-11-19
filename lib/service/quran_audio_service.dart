import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_speed.dart';

class AyahTiming {
  final int surah;
  final int ayah;
  final int fileIndex;
  final int startMs;
  final int? endMs;

  const AyahTiming({
    required this.surah,
    required this.ayah,
    required this.fileIndex,
    required this.startMs,
    this.endMs,
  });

  String get key => '$surah:$ayah';
}

/// Plays Qari Abdur Rahman Naqshbandi's 30 per-juz MP3s with ayah-level
/// control, using the timing index in assets/data/qari_timings.json.
class QuranAudioService {
  static const String _baseUrl =
      'https://pub-51e5db1746bd40cabed10bc6f62928e5.r2.dev';
  static const String _assetPath = 'assets/data/qari_timings.json';

  final AudioPlayer player = AudioPlayer();

  List<String> _files = [];
  final Map<String, AyahTiming> _byKey = {};
  final Map<int, List<AyahTiming>> _byFileIndex = {};
  int? _loadedFileIndex;
  bool _isLoaded = false;
  int _playToken = 0;
  StreamSubscription<PlayerState>? _stateSub;

  int? get loadedFileIndex => _loadedFileIndex;

  Future<void> init() async {
    if (_isLoaded) return;

    final raw = await rootBundle.loadString(_assetPath);
    final Map<String, dynamic> jsonMap = json.decode(raw);

    _files = List<String>.from(jsonMap['files'] as List);
    final List rows = jsonMap['ayahs'] as List;

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i] as List;
      final int surah = (row[0] as num).toInt();
      final int ayah = (row[1] as num).toInt();
      final int fileIndex = (row[2] as num).toInt();
      final int startMs = (row[3] as num).toInt();

      int? endMs;
      if (i + 1 < rows.length) {
        final nextRow = rows[i + 1] as List;
        if ((nextRow[2] as num).toInt() == fileIndex) {
          endMs = (nextRow[3] as num).toInt();
        }
      }

      final timing = AyahTiming(
        surah: surah,
        ayah: ayah,
        fileIndex: fileIndex,
        startMs: startMs,
        endMs: endMs,
      );
      _byKey[timing.key] = timing;
      _byFileIndex.putIfAbsent(fileIndex, () => []).add(timing);
    }

    // keep the shared speed setting in sync, and continue into the next
    // juz file when one finishes
    audioSpeedNotifier.addListener(_applySpeed);
    _stateSub = player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) {
        _playNextFile();
      }
    });

    _isLoaded = true;
  }

  void _applySpeed() {
    player.setSpeed(audioSpeedNotifier.value);
  }

  // The files in the bucket are named "01. cüz.mp3" ... "30. cüz.mp3"
  // (the ü is stored as "u" plus a combining diaeresis, as in the R2 object URL).
  String urlForFileIndex(int fileIndex) {
    final nn = (fileIndex + 1).toString().padLeft(2, '0');
    return '$_baseUrl/${Uri.encodeComponent('$nn. cu\u0308z.mp3')}';
  }

  AyahTiming? timingFor(int surah, int ayah) => _byKey['$surah:$ayah'];

  /// Plays from a specific surah and ayah, switching juz MP3 if needed.
  Future<void> playAyah(int surah, int ayah) async {
    await init();
    final target = timingFor(surah, ayah);
    if (target == null) return;

    final token = ++_playToken; // a newer tap cancels an older, slower one
    final start = Duration(milliseconds: target.startMs);

    if (_loadedFileIndex == target.fileIndex && player.audioSource != null) {
      await player.seek(start);
    } else {
      _loadedFileIndex = null;
      try {
        await player.setUrl(urlForFileIndex(target.fileIndex),
            initialPosition: start);
      } catch (e) {
        _loadedFileIndex = null;
        rethrow;
      }
      if (token != _playToken) return;
      _loadedFileIndex = target.fileIndex;
    }

    await player.setSpeed(audioSpeedNotifier.value);
    if (token != _playToken) return;
    unawaited(player.play());
  }

  Future<void> _playNextFile() async {
    final idx = _loadedFileIndex;
    if (idx == null || idx + 1 >= _files.length) return;
    final next = _byFileIndex[idx + 1];
    if (next == null || next.isEmpty) return;
    await playAyah(next.first.surah, next.first.ayah);
  }

  /// The ayah being recited at [position] in file [fileIndex].
  AyahTiming? activeAyahAt(int fileIndex, Duration position) {
    final list = _byFileIndex[fileIndex];
    if (list == null || list.isEmpty) return null;

    final int posMs = position.inMilliseconds;
    int lo = 0, hi = list.length - 1, ans = 0;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (list[mid].startMs <= posMs) {
        ans = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return list[ans];
  }

  /// Emits the current ayah, only when it changes.
  Stream<AyahTiming?> activeAyahStream() {
    return player.positionStream.map((pos) {
      final idx = _loadedFileIndex;
      return idx == null ? null : activeAyahAt(idx, pos);
    }).distinct((a, b) => a?.key == b?.key);
  }

  Future<void> dispose() async {
    audioSpeedNotifier.removeListener(_applySpeed);
    await _stateSub?.cancel();
    await player.dispose();
  }
}