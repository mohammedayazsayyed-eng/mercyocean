import 'dart:async';
import 'dart:io';

/// Downloads the Qari's per-ayah clips in the background so the next ayah is
/// already on the phone when the current one ends (no pause between ayahs).
class QariClipCache {
  QariClipCache._();
  static final QariClipCache instance = QariClipCache._();

  static const String baseUrl =
      'https://pub-51e5db1746bd40cabed10bc6f62928e5.r2.dev/qari';

  final Directory _dir = Directory('${Directory.systemTemp.path}/qari_clips');
  final Map<String, Future<File?>> _inflight = {};
  bool _ready = false;

  String _name(int surah, int ayah) =>
      '${surah.toString().padLeft(3, '0')}${ayah.toString().padLeft(3, '0')}.mp3';

  String urlFor(int surah, int ayah) => '$baseUrl/${_name(surah, ayah)}';

  Future<void> _ensureDir() async {
    if (_ready) return;
    await _dir.create(recursive: true);
    _ready = true;
  }

  /// Path of the clip if it is already downloaded, otherwise null.
  Future<String?> cachedPath(int surah, int ayah) async {
    try {
      await _ensureDir();
      final f = File('${_dir.path}/${_name(surah, ayah)}');
      if (await f.exists() && await f.length() > 1000) return f.path;
    } catch (_) {}
    return null;
  }

  /// Starts downloading a clip (does nothing if it is cached or on its way).
  Future<File?> prefetch(int surah, int ayah) {
    final key = _name(surah, ayah);
    final running = _inflight[key];
    if (running != null) return running;
    final job = _download(surah, ayah).whenComplete(() => _inflight.remove(key));
    _inflight[key] = job;
    return job;
  }

  Future<File?> _download(int surah, int ayah) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      await _ensureDir();
      final f = File('${_dir.path}/${_name(surah, ayah)}');
      if (await f.exists() && await f.length() > 1000) return f;
      final req = await client.getUrl(Uri.parse(urlFor(surah, ayah)));
      final res = await req.close().timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) {
        await res.drain<void>();
        return null;
      }
      final tmp = File('${f.path}.part');
      final sink = tmp.openWrite();
      await sink.addStream(res).timeout(const Duration(seconds: 40));
      await sink.close();
      await tmp.rename(f.path);
      return f;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
