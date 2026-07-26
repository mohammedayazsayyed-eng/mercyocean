/// Dua models for UmmahAPI
library;

class Dua {
  int? id;
  String? title;
  String? description;
  String? duaText;
  String? duaTranslation;
  String? transliteration;
  String? category;
  String? occasion;

  Dua({
    this.id,
    this.title,
    this.description,
    this.duaText,
    this.duaTranslation,
    this.transliteration,
    this.category,
    this.occasion,
  });

  /// Factory constructor for UmmahAPI dua response
  factory Dua.fromUmmahApiJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      throw FormatException(
        'Expected Map<String, dynamic>, got ${json.runtimeType}',
      );
    }
    return Dua(
      id: json["id"] as int?,
      title: json["title"] as String?,
      description: json["description"] as String?,
      duaText: json["arabic"] as String?,
      duaTranslation: json["translation"] as String?,
      transliteration: json["transliteration"] as String?,
      category: json["category"] as String?,
      occasion: json["occasion"] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "description": description,
    "dua_text": duaText,
    "dua_translation": duaTranslation,
    "transliteration": transliteration,
    "category": category,
    "occasion": occasion,
  };
}

class DuaListResponse {
  List<Dua>? duas;
  String? category;

  DuaListResponse({this.duas, this.category});

  /// Factory constructor for UmmahAPI duas list response
  // factory DuaListResponse.fromUmmahApiJson(Map<String, dynamic> json) {
  //   // final duasData = json["data"]?["duas"] as List<dynamic>?;
  //   // final List<Dua> duas = duasData != null
  //   //     ? duasData
  //   //           .cast<Map<String, dynamic>>()
  //   //           .map((x) => Dua.fromUmmahApiJson(x))
  //   //           .toList()
  //   //     : [];
  //   final dynamic duasRaw = json["data"]?["duas"];

  //   List<dynamic> duasData = [];

  //   if (duasRaw is List) {
  //     duasData = duasRaw;
  //   } else if (duasRaw is Map) {
  //     duasData = duasRaw.values.toList();
  //   }

  //   final List<Dua> duas = duasData
  //       .map((x) => Dua.fromUmmahApiJson(x as Map<String, dynamic>))
  //       .toList();
  //   return DuaListResponse(
  //     duas: duas,
  //     category: json["data"]?["category"] ?? "General",
  //   );
  // }
}
