import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Reciter { naqshbandi, alafasy }

const Map<Reciter, String> kReciterNames = {
  Reciter.alafasy: 'Mishary Alafasy',
  Reciter.naqshbandi: 'Qari Abdur Rahman Naqshbandi',
};

/// The reciter chosen by the user (remembered between launches).
final ValueNotifier<Reciter> reciterNotifier = ValueNotifier(Reciter.naqshbandi);

const String _kReciterKey = 'reciter';

Future<void> loadReciter() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kReciterKey);
    reciterNotifier.value = Reciter.values.firstWhere(
      (r) => r.name == saved,
      orElse: () => Reciter.naqshbandi,
    );
  } catch (_) {}
}

Future<void> setReciter(Reciter r) async {
  reciterNotifier.value = r;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kReciterKey, r.name);
  } catch (_) {}
}

class ReciterButton extends StatelessWidget {
  final Color color;
  const ReciterButton({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Reciter>(
      valueListenable: reciterNotifier,
      builder: (context, current, _) => PopupMenuButton<Reciter>(
        tooltip: 'Reciter',
        icon: Icon(Icons.record_voice_over, color: color),
        initialValue: current,
        onSelected: setReciter,
        itemBuilder: (context) => [
          for (final r in Reciter.values)
            PopupMenuItem<Reciter>(
              value: r,
              child: Text(
                kReciterNames[r]!,
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
            ),
        ],
      ),
    );
  }
}