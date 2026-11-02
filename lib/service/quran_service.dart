import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/quran_model.dart';

class QuranService {
  final ApiService _apiService = ApiService();

  Future<List<Surah>?> getAllSurahs() async {
    try {
      final surahs = await _apiService.getAllSurahs();
      return surahs;
    } catch (e) {
      debugPrint('Error fetching surahs: $e');
      return null;
    }
  }

  Future<SurahDetailResponse?> getSurahWithVerses(int surahNumber) async {
    try {
      return await _apiService.getSurahDetail(surahNumber);
    } catch (e) {
      debugPrint('Error fetching surah detail: $e');
      return null;
    }
  }

  Future<Ayah?> getAyah(int surahNumber, int ayahNumber) async {
    try {
      final surahDetail = await _apiService.getSurahDetail(surahNumber);
      if (surahDetail.ayahs == null) return null;
      for (final ayah in surahDetail.ayahs!) {
        if (ayah.number == ayahNumber ||
            ayah.numberInSurah == ayahNumber.toString()) {
          return ayah;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching ayah $surahNumber:$ayahNumber: $e');
      return null;
    }
  }
}
