import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nur_al_quran/models/islamic_search_result.dart';
import 'package:nur_al_quran/services/islamic_search_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IslamicSearchResult & IslamicCitation Models', () {
    test('JSON serialization & deserialization preserves all fields', () {
      final citation = IslamicCitation(
        bookName: 'صحیح البخاری',
        author: 'امام محمد بن اسماعیل بخاری',
        volume: 'جلد 1',
        pageOrNumber: 'حدیث نمبر 1',
        chapter: 'کتاب بدء الوحی',
        grading: 'صحیح',
        schoolOfThought: 'جمہور امت',
        sourceUrl: 'https://sunnah.com/bukhari:1',
      );

      final result = IslamicSearchResult(
        id: 'test_1',
        title: 'انما الاعمال بالنیات',
        category: IslamicSearchCategory.hadith,
        evidenceType: EvidenceType.hadithMarfu,
        summary: 'تمام اعمال کا دار و مدار نیتوں پر ہے۔',
        arabicText: 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ',
        translation: 'اعمال کا دار و مدار نیتوں پر ہے۔',
        englishTranslation: 'Actions are by intentions.',
        citation: citation,
        tafsirOrCommentary: 'شرح فتح الباری',
        differencesOfOpinion: null,
        searchSource: 'Canonical Hadith Repo',
        timestamp: DateTime(2026, 10, 13),
      );

      final json = result.toJson();
      final fromJson = IslamicSearchResult.fromJson(json);

      expect(fromJson.id, 'test_1');
      expect(fromJson.title, 'انما الاعمال بالنیات');
      expect(fromJson.category, IslamicSearchCategory.hadith);
      expect(fromJson.evidenceType, EvidenceType.hadithMarfu);
      expect(fromJson.citation.bookName, 'صحیح البخاری');
      expect(fromJson.citation.pageOrNumber, 'حدیث نمبر 1');
      expect(fromJson.citation.grading, 'صحیح');
      expect(fromJson.citation.sourceUrl, 'https://sunnah.com/bukhari:1');
    });

    test('toShareableText formats authentic header and citation', () {
      final citation = IslamicCitation(
        bookName: 'الفتاوى الهندية',
        volume: 'جلد 1',
        pageOrNumber: 'صفحہ 172',
      );
      final result = IslamicSearchResult(
        id: 'fiqh_test',
        title: 'زکوٰۃ کا نصاب',
        category: IslamicSearchCategory.fiqh,
        evidenceType: EvidenceType.scholarlyIjma,
        summary: 'چاندی کا نصاب ساڑھے باون تولے ہے۔',
        arabicText: 'وَفِي الرِّقَّةِ رُبُعُ الْعُشْرِ.',
        translation: 'چاندی میں چالیسواں حصہ زکوٰۃ ہے۔',
        citation: citation,
        searchSource: 'Alamgiri',
        timestamp: DateTime.now(),
      );

      final text = result.toShareableText();
      expect(text.contains('نور القرآن — اسلامی سوال و جواب'), isTrue);
      expect(text.contains('زکوٰۃ کا نصاب'), isTrue);
      expect(text.contains('الفتاوى الهندية'), isTrue);
      expect(text.contains('جلد 1'), isTrue);
    });

    test('EvidenceType distinguishes Nass from scholarly Ijtihad', () {
      expect(EvidenceType.quranNass.labelUrdu.contains('نصِ قرآنی'), isTrue);
      expect(EvidenceType.hadithMarfu.labelUrdu.contains('حدیثِ مبارکہ'), isTrue);
      expect(EvidenceType.scholarlyIjtihad.labelUrdu.contains('اجتہاد'), isTrue);
      expect(EvidenceType.linguisticLexicon.labelUrdu.contains('لغت'), isTrue);
    });
  });

  group('IslamicSearchService Query & Routing', () {
    final service = IslamicSearchService();

    test('Searches Fiqh rulings accurately with verified citations', () async {
      final results = await service.search(
        query: 'سجدہ سہو',
        category: IslamicSearchCategory.fiqh,
      );

      expect(results.isNotEmpty, isTrue);
      final first = results.first;
      expect(first.category, IslamicSearchCategory.fiqh);
      expect(first.evidenceType, EvidenceType.scholarlyIjtihad);
      expect(first.citation.bookName.contains('رد المحتار') || first.citation.bookName.contains('شامی'), isTrue);
      expect(first.citation.volume, isNotNull);
      expect(first.citation.pageOrNumber, isNotNull);
    });

    test('Searches Hadith with canonical chapter and number', () async {
      final results = await service.search(
        query: 'الاعمال بالنیات',
        category: IslamicSearchCategory.hadith,
      );

      expect(results.isNotEmpty, isTrue);
      final hadith = results.firstWhere((r) => r.id.contains('bukhari_1'));
      expect(hadith.arabicText.contains('إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ'), isTrue);
      expect(hadith.citation.pageOrNumber, 'حدیث نمبر 1');
      expect(hadith.citation.grading, 'صحیح (الجامع الصحیح)');
    });

    test('Searches Lexicon (Lughat) with classical root breakdown', () async {
      final results = await service.search(
        query: 'تقوی',
        category: IslamicSearchCategory.lughat,
      );

      expect(results.isNotEmpty, isTrue);
      final entry = results.first;
      expect(entry.evidenceType, EvidenceType.linguisticLexicon);
      expect(entry.arabicText.contains('و-ق-ي'), isTrue);
      expect(entry.citation.bookName.contains('المفردات'), isTrue);
    });
  });
}

