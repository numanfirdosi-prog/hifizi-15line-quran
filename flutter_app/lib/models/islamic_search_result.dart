import 'dart:convert';

/// Categories supported by the Islamic Knowledge Search Engine.
enum IslamicSearchCategory {
  all,
  quran,
  hadith,
  fiqh,
  lughat,
}

extension IslamicSearchCategoryExt on IslamicSearchCategory {
  String get id {
    switch (this) {
      case IslamicSearchCategory.all:
        return 'all';
      case IslamicSearchCategory.quran:
        return 'quran';
      case IslamicSearchCategory.hadith:
        return 'hadith';
      case IslamicSearchCategory.fiqh:
        return 'fiqh';
      case IslamicSearchCategory.lughat:
        return 'lughat';
    }
  }

  String get titleUrdu {
    switch (this) {
      case IslamicSearchCategory.all:
        return 'سبھی (کل)';
      case IslamicSearchCategory.quran:
        return 'قرآن و تفسیر';
      case IslamicSearchCategory.hadith:
        return 'حدیث مبارک';
      case IslamicSearchCategory.fiqh:
        return 'مسائل و فقہ';
      case IslamicSearchCategory.lughat:
        return 'عربی و اردو لغت';
    }
  }

  String get titleEn {
    switch (this) {
      case IslamicSearchCategory.all:
        return 'All';
      case IslamicSearchCategory.quran:
        return 'Quran & Tafsir';
      case IslamicSearchCategory.hadith:
        return 'Hadith';
      case IslamicSearchCategory.fiqh:
        return 'Fiqh & Rulings';
      case IslamicSearchCategory.lughat:
        return 'Dictionary';
    }
  }
}

/// The nature of evidence to clearly distinguish original text (Nass) from interpretation.
enum EvidenceType {
  quranNass, // Qat'i al-Thubut (Definitive Quranic Ayah)
  hadithMarfu, // Authentic Prophetic Hadith
  hadithAthar, // Companion narration
  scholarlyIjma, // Scholarly consensus
  scholarlyIjtihad, // Jurisprudential deduction / Fatwa / School opinion
  linguisticLexicon, // Classical Arabic / Urdu Lexicon
}

extension EvidenceTypeExt on EvidenceType {
  String get labelUrdu {
    switch (this) {
      case EvidenceType.quranNass:
        return 'نصِ قرآنی (قطعی الثبوت)';
      case EvidenceType.hadithMarfu:
        return 'حدیثِ مبارکہ (مرفوع)';
      case EvidenceType.hadithAthar:
        return 'اثر / قولِ صحابی';
      case EvidenceType.scholarlyIjma:
        return 'اجماعِ امت';
      case EvidenceType.scholarlyIjtihad:
        return 'اجتہاد و فقہی فتوٰی';
      case EvidenceType.linguisticLexicon:
        return 'لغوی تحقیق و لغت';
    }
  }

  String get labelEn {
    switch (this) {
      case EvidenceType.quranNass:
        return 'Quranic Text (Nass)';
      case EvidenceType.hadithMarfu:
        return 'Hadith (Prophetic)';
      case EvidenceType.hadithAthar:
        return 'Athar (Narrated)';
      case EvidenceType.scholarlyIjma:
        return 'Ijma (Consensus)';
      case EvidenceType.scholarlyIjtihad:
        return 'Scholarly Ijtihad / Fiqh';
      case EvidenceType.linguisticLexicon:
        return 'Lexicon / Dictionary';
    }
  }
}

/// Authentic citation details pointing to the exact book, volume, page, or hadith number.
class IslamicCitation {
  final String bookName;
  final String? author;
  final String? volume;
  final String? pageOrNumber;
  final String? chapter;
  final String? grading; // e.g. Sahih, Hasan, Mutawatir
  final String? schoolOfThought; // e.g. Hanafi, Shafi'i, Jamhoor
  final String? sourceUrl;

  const IslamicCitation({
    required this.bookName,
    this.author,
    this.volume,
    this.pageOrNumber,
    this.chapter,
    this.grading,
    this.schoolOfThought,
    this.sourceUrl,
  });

  Map<String, dynamic> toJson() => {
        'bookName': bookName,
        'author': author,
        'volume': volume,
        'pageOrNumber': pageOrNumber,
        'chapter': chapter,
        'grading': grading,
        'schoolOfThought': schoolOfThought,
        'sourceUrl': sourceUrl,
      };

  factory IslamicCitation.fromJson(Map<String, dynamic> json) => IslamicCitation(
        bookName: json['bookName'] as String? ?? 'غیر معین',
        author: json['author'] as String?,
        volume: json['volume'] as String?,
        pageOrNumber: json['pageOrNumber'] as String?,
        chapter: json['chapter'] as String?,
        grading: json['grading'] as String?,
        schoolOfThought: json['schoolOfThought'] as String?,
        sourceUrl: json['sourceUrl'] as String?,
      );

  String get formattedReferenceUrdu {
    final parts = <String>[bookName];
    if (author != null && author!.isNotEmpty) parts.add(author!);
    if (volume != null && volume!.isNotEmpty) parts.add(volume!);
    if (pageOrNumber != null && pageOrNumber!.isNotEmpty) parts.add(pageOrNumber!);
    if (chapter != null && chapter!.isNotEmpty) parts.add(chapter!);
    if (grading != null && grading!.isNotEmpty) parts.add('حکم: $grading');
    if (schoolOfThought != null && schoolOfThought!.isNotEmpty) {
      parts.add('مسلک: $schoolOfThought');
    }
    return parts.join('، ');
  }
}

/// A structured Islamic search result containing authentic texts, translations, and verified citations.
class IslamicSearchResult {
  final String id;
  final String title;
  final IslamicSearchCategory category;
  final EvidenceType evidenceType;
  final String summary; // Executive answer in plain Urdu
  final String arabicText; // Arabic verse, hadith matan, or text
  final String translation; // Urdu translation
  final String? englishTranslation;
  final IslamicCitation citation;
  final String? tafsirOrCommentary;
  final String? differencesOfOpinion; // Fairly presented differences of opinions if any
  final String searchSource;
  final DateTime timestamp;

  const IslamicSearchResult({
    required this.id,
    required this.title,
    required this.category,
    required this.evidenceType,
    required this.summary,
    required this.arabicText,
    required this.translation,
    this.englishTranslation,
    required this.citation,
    this.tafsirOrCommentary,
    this.differencesOfOpinion,
    required this.searchSource,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.id,
        'evidenceType': evidenceType.name,
        'summary': summary,
        'arabicText': arabicText,
        'translation': translation,
        'englishTranslation': englishTranslation,
        'citation': citation.toJson(),
        'tafsirOrCommentary': tafsirOrCommentary,
        'differencesOfOpinion': differencesOfOpinion,
        'searchSource': searchSource,
        'timestamp': timestamp.toIso8601String(),
      };

  factory IslamicSearchResult.fromJson(Map<String, dynamic> json) {
    final catId = json['category'] as String? ?? 'all';
    final category = IslamicSearchCategory.values.firstWhere(
      (c) => c.id == catId,
      orElse: () => IslamicSearchCategory.all,
    );

    final evName = json['evidenceType'] as String? ?? 'quranNass';
    final evidenceType = EvidenceType.values.firstWhere(
      (e) => e.name == evName,
      orElse: () => EvidenceType.quranNass,
    );

    return IslamicSearchResult(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: category,
      evidenceType: evidenceType,
      summary: json['summary'] as String? ?? '',
      arabicText: json['arabicText'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      englishTranslation: json['englishTranslation'] as String?,
      citation: IslamicCitation.fromJson(
        (json['citation'] as Map<String, dynamic>?) ?? {},
      ),
      tafsirOrCommentary: json['tafsirOrCommentary'] as String?,
      differencesOfOpinion: json['differencesOfOpinion'] as String?,
      searchSource: json['searchSource'] as String? ?? 'Verified Source',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Formatted text ready for WhatsApp or SMS sharing with full citations and branding.
  String toShareableText() {
    final b = StringBuffer();
    b.writeln('🌙 نور القرآن — اسلامی سوال و جواب');
    b.writeln('════════════════════════════');
    b.writeln('📌 $title');
    b.writeln();
    b.writeln('📖 خلاصہ / جواب:');
    b.writeln(summary);
    b.writeln();
    if (arabicText.trim().isNotEmpty) {
      b.writeln('📜 اصل متن (عربی):');
      b.writeln(arabicText);
      b.writeln();
    }
    if (translation.trim().isNotEmpty) {
      b.writeln('📝 اردو ترجمہ:');
      b.writeln(translation);
      b.writeln();
    }
    if (differencesOfOpinion != null && differencesOfOpinion!.trim().isNotEmpty) {
      b.writeln('⚖️ فقہی آراء / اختلافِ ائمہ:');
      b.writeln(differencesOfOpinion);
      b.writeln();
    }
    b.writeln('📚 مستند حوالہ:');
    b.writeln(citation.formattedReferenceUrdu);
    if (citation.sourceUrl != null && citation.sourceUrl!.isNotEmpty) {
      b.writeln('🔗 تحقیق لنک: ${citation.sourceUrl}');
    }
    b.writeln('════════════════════════════');
    b.writeln('✨ ایپ سے شیئر کیا گیا: نور القرآن (Nur-ul-Quran)');
    return b.toString();
  }
}

