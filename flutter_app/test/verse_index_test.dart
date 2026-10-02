import 'package:flutter_test/flutter_test.dart';
import 'package:nur_al_quran/data/verse_index.dart';

void main() {
  group('buildVersePageIndex', () {
    test('maps verseKey to page numbers', () {
      final sample = <String, dynamic>{
        '1': [
          {'verseKey': '1:1'},
          {'verseKey': '1:2'},
        ],
        '2': [
          {'verseKey': '1:3'},
          {'verseKey': '2:1'},
        ],
      };
      final index = buildVersePageIndex(sample);
      expect(index['1:1'], 1);
      expect(index['1:2'], 1);
      expect(index['1:3'], 2);
      expect(index['2:1'], 2);
      expect(index.length, 4);
    });

    test('ignores entries without a verseKey and bad page keys', () {
      final sample = <String, dynamic>{
        '5': [
          {'surah': 2, 'ayah': 9},
          {'verseKey': '2:10'},
        ],
        'abc': [
          {'verseKey': '3:1'},
        ],
      };
      final index = buildVersePageIndex(sample);
      expect(index, {'2:10': 5});
    });
  });

  group('buildPageFirstVerseIndex', () {
    test('maps page to its first verseKey', () {
      final sample = <String, dynamic>{
        '1': [
          {'verseKey': '1:1'},
          {'verseKey': '1:2'},
        ],
        '2': [
          {'verseKey': '2:1'},
        ],
      };
      final index = buildPageFirstVerseIndex(sample);
      expect(index, {1: '1:1', 2: '2:1'});
    });

    test('skips empty pages', () {
      final sample = <String, dynamic>{
        '1': [],
        '2': [
          {'verseKey': '1:1'},
        ],
      };
      final index = buildPageFirstVerseIndex(sample);
      expect(index, {2: '1:1'});
    });
  });

  group('normalizeArabic', () {
    test('strips diacritics', () {
      expect(normalizeArabic('بِسْمِ'), 'بسم');
    });

    test('normalizes alef and hamza variants', () {
      expect(normalizeArabic('أإآٱ'), 'اااا');
      expect(normalizeArabic('مؤمن'), 'مومن');
      expect(normalizeArabic('قرئ'), 'قري');
    });

    test('leaves plain text unchanged', () {
      expect(normalizeArabic('بسم الله'), 'بسم الله');
    });
  });

  group('QuranTextEntry', () {
    test('parses one entry from JSON', () {
      final entry = QuranTextEntry.fromJson({
        's': 1,
        'v': 1,
        'ar': 'بِسْمِ اللَّهِ',
        'en': 'In the name of Allah',
      });
      expect(entry.s, 1);
      expect(entry.v, 1);
      expect(entry.ar, 'بِسْمِ اللَّهِ');
      expect(entry.en, 'In the name of Allah');
    });
  });
}
