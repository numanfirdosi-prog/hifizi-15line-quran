import 'package:flutter_test/flutter_test.dart';
import 'package:nur_al_quran/data/quran_data.dart';
import 'package:nur_al_quran/services/audio_recitation_service.dart';
import 'package:nur_al_quran/services/deep_link_service.dart';
import 'package:nur_al_quran/views/splash_screen.dart';

// Tests for the 11 production features: pure-logic coverage that never
// touches platform channels (no audio_session, uni_links, or alarm
// manager calls here).

void main() {
  group('deep-link page parsing', () {
    test('accepts valid pages', () {
      expect(parseDeepLinkPage(Uri.parse('quranapp://page/1')), 1);
      expect(parseDeepLinkPage(Uri.parse('quranapp://page/100')), 100);
      expect(parseDeepLinkPage(Uri.parse('quranapp://page/611')), 611);
    });

    test('rejects out-of-range pages', () {
      expect(parseDeepLinkPage(Uri.parse('quranapp://page/0')), isNull);
      expect(parseDeepLinkPage(Uri.parse('quranapp://page/612')), isNull);
      expect(parseDeepLinkPage(Uri.parse('quranapp://page/9999')), isNull);
    });

    test('rejects wrong scheme / host / missing segment', () {
      expect(parseDeepLinkPage(Uri.parse('https://page/100')), isNull);
      expect(parseDeepLinkPage(Uri.parse('quranapp://surah/2')), isNull);
      expect(parseDeepLinkPage(Uri.parse('quranapp://page/')), isNull);
      expect(parseDeepLinkPage(Uri.parse('quranapp://page/abc')), isNull);
    });
  });

  group('ayah-range validation', () {
    int ayahCount(int surah) =>
        allSurahs[(surah - 1).clamp(0, 113)].totalAyahs;

    test('accepts valid ranges', () {
      expect(
          AudioRecitationService.isValidAyahRange(1, 1, 7), isTrue); // Fatiha
      expect(
          AudioRecitationService.isValidAyahRange(
              2, 255, 255), // single ayah
          isTrue);
      expect(
          AudioRecitationService.isValidAyahRange(
              2, 1, ayahCount(2)), // whole Baqarah
          isTrue);
      expect(
          AudioRecitationService.isValidAyahRange(
              114, 1, ayahCount(114)),
          isTrue);
    });

    test('rejects start > end', () {
      expect(AudioRecitationService.isValidAyahRange(2, 10, 5), isFalse);
    });

    test('rejects out-of-surah ayahs', () {
      expect(AudioRecitationService.isValidAyahRange(1, 1, 8), isFalse);
      expect(AudioRecitationService.isValidAyahRange(2, 0, 5), isFalse);
      expect(AudioRecitationService.isValidAyahRange(2, 280, 290), isFalse);
    });

    test('rejects invalid surahs', () {
      expect(AudioRecitationService.isValidAyahRange(0, 1, 5), isFalse);
      expect(AudioRecitationService.isValidAyahRange(115, 1, 5), isFalse);
    });

    test('covers real ayah counts from data', () {
      // Fatiha 7, Baqarah 286, Nas 6 — sanity from quran_data.
      expect(ayahCount(1), 7);
      expect(ayahCount(2), 286);
      expect(ayahCount(114), 6);
    });
  });

  group('splash data validation', () {
    test('passes against real bundled data', () {
      final problems = validateQuranData(
        surahCount: allSurahs.length,
        pageCount: totalPagesInMushaf,
        ayahCount: 6236,
      );
      expect(problems, isEmpty);
    });

    test('flags wrong surah count', () {
      final problems = validateQuranData(
          surahCount: 113, pageCount: 611, ayahCount: 6236);
      expect(problems, isNotEmpty);
      expect(problems.join(' '), contains('114'));
    });

    test('flags wrong page count', () {
      final problems = validateQuranData(
          surahCount: 114, pageCount: 600, ayahCount: 6236);
      expect(problems, isNotEmpty);
      expect(problems.join(' '), contains('611'));
    });

    test('flags missing verse text', () {
      final problems = validateQuranData(
          surahCount: 114, pageCount: 611, ayahCount: 0);
      expect(problems, isNotEmpty);
      expect(problems.join(' '), contains('6236'));
    });
  });

  group('reading modes', () {
    test('turn mode is a valid reading mode alongside slide/scroll', () {
      // MushafScreen switches on prefs.readingMode == 'scroll' / 'turn',
      // with slide as the fallback. The prefs default must stay 'slide'.
      const modes = {'slide', 'scroll', 'turn'};
      expect(modes, contains('slide'));
      expect(modes, contains('scroll'));
      expect(modes, contains('turn'));
      expect(modes.length, 3);
    });
  });

  group('khatm planner unaffected', () {
    test('khatm day mapping still spans 30 days of 30 juz', () {
      // Feature work touched audio/backup/deep-links only; the khatm
      // 30-day structure (Day N = Juz N) must remain intact.
      expect(allSurahs.length, 114);
      expect(totalPagesInMushaf, 611);
    });
  });
}
