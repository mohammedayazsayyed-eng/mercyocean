import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global playback speed for Quran recitation (shared by all readers).
final ValueNotifier<double> audioSpeedNotifier = ValueNotifier<double>(1.0);

const List<double> kAudioSpeeds = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
const String _kSpeedKey = 'audio_speed';

String speedLabel(double s) =>
    '${s == s.roundToDouble() ? s.toInt() : s}x';

Future<void> loadAudioSpeed() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    audioSpeedNotifier.value = prefs.getDouble(_kSpeedKey) ?? 1.0;
  } catch (_) {}
}

Future<void> setAudioSpeed(double speed) async {
  audioSpeedNotifier.value = speed;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kSpeedKey, speed);
  } catch (_) {}
}

/// AppBar button showing the current speed with a dropdown of choices.
class AudioSpeedButton extends StatelessWidget {
  final Color color;
  const AudioSpeedButton({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: audioSpeedNotifier,
      builder: (context, speed, _) {
        return PopupMenuButton<double>(
          tooltip: 'Playback speed',
          initialValue: speed,
          onSelected: setAudioSpeed,
          itemBuilder: (_) => [
            for (final s in kAudioSpeeds)
              CheckedPopupMenuItem<double>(
                value: s,
                checked: s == speed,
                child: Text(speedLabel(s)),
              ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: color),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  speedLabel(speed),
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
