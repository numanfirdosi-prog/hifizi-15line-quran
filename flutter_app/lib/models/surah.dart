class Surah {
  final int number;
  final String nameEn;
  final String meaning;
  final String nameAr;
  final int totalAyahs;
  final String revelation; // 'Meccan' or 'Medinan'
  final int startPage;
  final String nameHi;

  const Surah({
    required this.number,
    required this.nameEn,
    required this.meaning,
    required this.nameAr,
    required this.totalAyahs,
    required this.revelation,
    required this.startPage,
    required this.nameHi,
  });

  bool get isMeccan => revelation.toLowerCase() == 'meccan';

  factory Surah.fromList(int index, List<dynamic> raw, int startPage, String hindi) {
    return Surah(
      number: index + 1,
      nameEn: raw[0] as String,
      meaning: raw[1] as String,
      nameAr: raw[2] as String,
      totalAyahs: raw[3] as int,
      revelation: raw[4] as String,
      startPage: startPage,
      nameHi: hindi,
    );
  }
}

