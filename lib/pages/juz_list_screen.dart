import 'package:flutter/material.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';

import 'juz_data.dart';
import 'juz_reader_screen.dart';

class JuzListScreen extends StatelessWidget {
  const JuzListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Juz wise',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: kTotalJuz,
          itemBuilder: (context, index) {
            final juzNo = index + 1;
            final segments = juzSegments(juzNo);
            final first = segments.first;

            final names = segments
                .map((s) => getSurahNameEnglish(s.surah))
                .toList();
            final surahPreview = names.length <= 3
                ? names.join(', ')
                : '${names.take(2).join(', ')} ... ${names.last}';

            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JuzReaderScreen(juz: juzNo),
                  ),
                ),
                leading: CircleAvatar(
                  backgroundColor: primaryColor.withValues(alpha: 0.12),
                  child: Text(
                    '$juzNo',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                title: Text(
                  'Juz $juzNo',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                subtitle: Text(
                  'Starts: ${getSurahNameEnglish(first.surah)} '
                  '${first.surah}:${first.startAyah}\n$surahPreview',
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
                ),
                isThreeLine: true,
                trailing: Text(
                  getSurahNameArabic(first.surah),
                  style: TextStyle(
                    color: primaryColor,
                    fontFamily: 'Neirizi',
                    fontSize: 18,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
