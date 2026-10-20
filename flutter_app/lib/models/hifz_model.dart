class SabaqRecord {
  final String id;
  final int page;
  final int? surah;
  final int? ayahFrom;
  final int? ayahTo;
  final DateTime date;
  final bool isCompleted;
  final String? notes;

  const SabaqRecord({
    required this.id,
    required this.page,
    this.surah,
    this.ayahFrom,
    this.ayahTo,
    required this.date,
    this.isCompleted = false,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'page': page,
        'surah': surah,
        'ayahFrom': ayahFrom,
        'ayahTo': ayahTo,
        'date': date.toIso8601String(),
        'isCompleted': isCompleted,
        'notes': notes,
      };

  factory SabaqRecord.fromJson(Map<String, dynamic> m) => SabaqRecord(
        id: m['id'] as String? ?? '',
        page: m['page'] as int? ?? 1,
        surah: m['surah'] as int?,
        ayahFrom: m['ayahFrom'] as int?,
        ayahTo: m['ayahTo'] as int?,
        date: DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now(),
        isCompleted: m['isCompleted'] as bool? ?? false,
        notes: m['notes'] as String?,
      );
}

class SabqiRecord {
  final String id;
  final int startPage;
  final int endPage;
  final DateTime date;
  final bool isCompleted;
  final String? notes;

  const SabqiRecord({
    required this.id,
    required this.startPage,
    required this.endPage,
    required this.date,
    this.isCompleted = false,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'startPage': startPage,
        'endPage': endPage,
        'date': date.toIso8601String(),
        'isCompleted': isCompleted,
        'notes': notes,
      };

  factory SabqiRecord.fromJson(Map<String, dynamic> m) => SabqiRecord(
        id: m['id'] as String? ?? '',
        startPage: m['startPage'] as int? ?? 1,
        endPage: m['endPage'] as int? ?? 1,
        date: DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now(),
        isCompleted: m['isCompleted'] as bool? ?? false,
        notes: m['notes'] as String?,
      );
}

class HifzMistake {
  final String id;
  final int surah;
  final int ayah;
  final int page;
  final String mistakeType; // e.g. "I'rab / Harkat", "Shuba / Mutashabihat", "Kalima / Words", "Waqf"
  final String? notes;
  final DateTime date;
  final bool isResolved;
  final int count;

  const HifzMistake({
    required this.id,
    required this.surah,
    required this.ayah,
    required this.page,
    required this.mistakeType,
    this.notes,
    required this.date,
    this.isResolved = false,
    this.count = 1,
  });

  HifzMistake copyWith({
    bool? isResolved,
    int? count,
    String? notes,
    String? mistakeType,
  }) =>
      HifzMistake(
        id: id,
        surah: surah,
        ayah: ayah,
        page: page,
        mistakeType: mistakeType ?? this.mistakeType,
        notes: notes ?? this.notes,
        date: date,
        isResolved: isResolved ?? this.isResolved,
        count: count ?? this.count,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'surah': surah,
        'ayah': ayah,
        'page': page,
        'mistakeType': mistakeType,
        'notes': notes,
        'date': date.toIso8601String(),
        'isResolved': isResolved,
        'count': count,
      };

  factory HifzMistake.fromJson(Map<String, dynamic> m) => HifzMistake(
        id: m['id'] as String? ?? '',
        surah: m['surah'] as int? ?? 1,
        ayah: m['ayah'] as int? ?? 1,
        page: m['page'] as int? ?? 1,
        mistakeType: m['mistakeType'] as String? ?? "I'rab / Harkat",
        notes: m['notes'] as String?,
        date: DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now(),
        isResolved: m['isResolved'] as bool? ?? false,
        count: m['count'] as int? ?? 1,
      );
}
