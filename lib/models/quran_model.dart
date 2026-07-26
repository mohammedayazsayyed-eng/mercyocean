/// Quran models for Al-Quran Cloud API
library;

// Surah list response
class SurahListResponse {
  List<Surah>? data;

  SurahListResponse({this.data});

  factory SurahListResponse.fromJson(Map<String, dynamic> json) =>
      SurahListResponse(
        data: json["data"] == null
            ? []
            : List<Surah>.from(json["data"]!.map((x) => Surah.fromJson(x))),
      );

  /// Factory constructor for UmmahAPI surahs list response
  factory SurahListResponse.fromUmmahApiJson(Map<String, dynamic> json) {
    final surahsData = json["data"]?["surahs"] as List<dynamic>?;
    final List<Surah> surahs = surahsData != null
        ? surahsData
              .cast<Map<String, dynamic>>()
              .map((x) => Surah.fromUmmahApiJson(x))
              .toList()
        : [];
    return SurahListResponse(data: surahs);
  }
}

class Surah {
  int? number;
  String? name;
  String? englishName;
  String? englishNameTranslation;
  int? numberOfAyahs;
  String? revelationType;

  Surah({
    this.number,
    this.name,
    this.englishName,
    this.englishNameTranslation,
    this.numberOfAyahs,
    this.revelationType,
  });

  factory Surah.fromJson(Map<String, dynamic> json) => Surah(
    number: json["number"],
    name: json["name"],
    englishName: json["englishName"],
    englishNameTranslation: json["englishNameTranslation"],
    numberOfAyahs: json["numberOfAyahs"],
    revelationType: json["revelationType"],
  );

  /// Factory constructor for UmmahAPI surah response
  factory Surah.fromUmmahApiJson(Map<String, dynamic> json) => Surah(
    number: json["number"],
    name: json["name_arabic"],
    englishName: json["name_english"],
    englishNameTranslation: json["name_translation"],
    numberOfAyahs: json["verses_count"],
    revelationType: json["revelation_place"], // "makkah" or "madinah"
  );

  Map<String, dynamic> toJson() => {
    "number": number,
    "name": name,
    "englishName": englishName,
    "englishNameTranslation": englishNameTranslation,
    "numberOfAyahs": numberOfAyahs,
    "revelationType": revelationType,
  };
}

// Detailed surah with ayahs
class SurahDetailResponse {
  Surah? surah;
  List<Ayah>? ayahs;

  SurahDetailResponse({this.surah, this.ayahs});

  factory SurahDetailResponse.fromJson(Map<String, dynamic> json) =>
      SurahDetailResponse(
        surah: json["data"] != null ? Surah.fromJson(json["data"]) : null,
        ayahs: json["data"] != null && json["data"]["ayahs"] != null
            ? List<Ayah>.from(
                json["data"]["ayahs"]!.map((x) => Ayah.fromJson(x)),
              )
            : [],
      );

  /// Factory constructor for UmmahAPI surah detail response
  factory SurahDetailResponse.fromUmmahApiJson(Map<String, dynamic> json) {
    final surahData = json["data"]?["surah"] as Map<String, dynamic>?;
    final surah = surahData != null ? Surah.fromUmmahApiJson(surahData) : null;

    final versesData = json["data"]?["verses"] as List<dynamic>?;
    final List<Ayah> ayahs = versesData != null
        ? versesData
              .cast<Map<String, dynamic>>()
              .map((x) => Ayah.fromUmmahApiJson(x))
              .toList()
        : [];

    return SurahDetailResponse(surah: surah, ayahs: ayahs);
  }
}

class Ayah {
  int? number;
  String? text;
  String? numberInSurah;
  String? juz;
  String? manzil;
  String? page;
  String? ruku;
  String? hizbQuarter;
  bool? sajdah;
  String? translation;
  String? audioUrl;

  Ayah({
    this.number,
    this.text,
    this.numberInSurah,
    this.juz,
    this.manzil,
    this.page,
    this.ruku,
    this.hizbQuarter,
    this.sajdah,
    this.translation,
    this.audioUrl,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) => Ayah(
    number: json["number"],
    text: json["text"],
    numberInSurah: json["numberInSurah"]?.toString(),
    juz: json["juz"]?.toString(),
    manzil: json["manzil"]?.toString(),
    page: json["page"]?.toString(),
    ruku: json["ruku"]?.toString(),
    hizbQuarter: json["hizbQuarter"]?.toString(),
    sajdah: json["sajdah"],
    translation: json["translation"],
    audioUrl: json["audioUrl"],
  );

  /// Factory constructor for UmmahAPI verse response
  factory Ayah.fromUmmahApiJson(Map<String, dynamic> json) {
    // Extract translation from translations object (default to English Sahih International)
    String? translation;
    final translations = json["translations"] as Map<String, dynamic>?;
    if (translations != null) {
      translation =
          (translations["sahih_international"] ??
                  translations["yusuf_ali"] ??
                  translations.values.firstOrNull)
              as String?;
    }

    // Get audio URL
    final audio = json["audio"] as Map<String, dynamic>?;
    final audioUrl = audio?["ayah_audio"] as String?;

    return Ayah(
      number: json["ayah"],
      text: json["arabic"],
      numberInSurah: json["ayah"]?.toString(),
      translation: translation,
      audioUrl: audioUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    "number": number,
    "text": text,
    "numberInSurah": numberInSurah,
    "juz": juz,
    "manzil": manzil,
    "page": page,
    "ruku": ruku,
    "hizbQuarter": hizbQuarter,
    "sajdah": sajdah,
    "translation": translation,
    "audioUrl": audioUrl,
  };
}

// Translation model for English text
class AyahWithTranslation {
  Ayah? ayah;
  String? translation;

  AyahWithTranslation({this.ayah, this.translation});

  factory AyahWithTranslation.fromJson(Map<String, dynamic> json) =>
      AyahWithTranslation(
        ayah: json["ayah"] != null ? Ayah.fromJson(json["ayah"]) : null,
        translation: json["translation"],
      );
}

// Audio Surah model for recitations
class SurahAudioResponse {
  Surah? surah;
  List<AyahAudio>? ayahs;

  SurahAudioResponse({this.surah, this.ayahs});

  /// Get the audio URL for the entire surah
  String? get audioUrl {
    if (ayahs == null || ayahs!.isEmpty) return null;
    return ayahs!.first.audioUrl;
  }

  factory SurahAudioResponse.fromJson(Map<String, dynamic> json) =>
      SurahAudioResponse(
        surah: json["data"] != null ? Surah.fromJson(json["data"]) : null,
        ayahs: json["data"] != null && json["data"]["ayahs"] != null
            ? List<AyahAudio>.from(
                json["data"]["ayahs"]!.map((x) => AyahAudio.fromJson(x)),
              )
            : [],
      );
}

// Individual ayah with audio
class AyahAudio {
  int? number;
  String? text;
  String? audioUrl;
  String? numberInSurah;

  AyahAudio({this.number, this.text, this.audioUrl, this.numberInSurah});

  factory AyahAudio.fromJson(Map<String, dynamic> json) => AyahAudio(
    number: json["number"],
    text: json["text"],
    audioUrl: json["audio"],
    numberInSurah: json["numberInSurah"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "number": number,
    "text": text,
    "audio": audioUrl,
    "numberInSurah": numberInSurah,
  };
}
