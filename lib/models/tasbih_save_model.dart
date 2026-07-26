class TasbihSave {
  final String id;
  final String name;
  final int count;
  final DateTime savedAt;

  const TasbihSave({
    required this.id,
    required this.name,
    required this.count,
    required this.savedAt,
  });

  TasbihSave copyWith({String? name, int? count, DateTime? savedAt}) =>
      TasbihSave(
        id: id,
        name: name ?? this.name,
        count: count ?? this.count,
        savedAt: savedAt ?? this.savedAt,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'count': count,
    'savedAt': savedAt.toIso8601String(),
  };

  factory TasbihSave.fromJson(Map<String, dynamic> json) => TasbihSave(
    id: json['id'] as String,
    name: json['name'] as String,
    count: json['count'] as int,
    savedAt: DateTime.parse(json['savedAt'] as String),
  );
}
