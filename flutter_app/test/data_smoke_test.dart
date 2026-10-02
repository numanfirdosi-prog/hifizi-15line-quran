import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nur_al_quran/data/ayah_of_day.dart';
import 'package:nur_al_quran/data/duas_data.dart';
import 'package:nur_al_quran/data/juz_data.dart';

void main() {
  group('data smoke tests', () {
    test('embedded quran_text sample parses', () {
      const sample =
          '{"s":1,"v":1,"ar":"\u0628\u0650\u0633\u0652\u0645\u0650 \u0671\u0644\u0644\u0651\u064e\u0647\u0650 \u0671\u0644\u0631\u0651\u064e\u062d\u0652\u0645\u064e\u0670\u0646\u0650 \u0671\u0644\u0631\u0651\u064e\u062d\u0650\u064a\u0645\u0650","en":"In the name of Allah, the Entirely Merciful, the Especially Merciful"}';
      final Map<String, dynamic> entry =
          jsonDecode(sample) as Map<String, dynamic>;
      expect(entry['s'], 1);
      expect(entry['v'], 1);
      expect(entry['ar'], isA<String>());
      expect((entry['ar'] as String).isNotEmpty, isTrue);
      expect(entry['en'], isA<String>());
      expect((entry['en'] as String).isNotEmpty, isTrue);
    });

    test('ayahOfDayList has 30 entries and rotates', () {
      expect(ayahOfDayList.length, 30);
      for (final a in ayahOfDayList) {
        expect(a.ar.isNotEmpty, isTrue);
        expect(a.en.isNotEmpty, isTrue);
        expect(a.reflection.isNotEmpty, isTrue);
      }
      expect(ayahOfDayFor(DateTime(2026, 1, 1)), same(ayahOfDayList[0]));
      expect(ayahOfDayFor(DateTime(2026, 1, 30)), same(ayahOfDayList[29]));
      expect(ayahOfDayFor(DateTime(2026, 1, 31)), same(ayahOfDayList[0]));
      expect(ayahOfDayFor(DateTime(2026, 2, 1)), same(ayahOfDayList[0]));
    });

    test('duas has 8 entries', () {
      expect(duas.length, 8);
      expect(duas.map((d) => d.id).toSet().length, 8);
    });

    test('juzList has 30 entries with correct start pages', () {
      expect(juzList.length, 30);
      expect(juzList[0].startPage, 2);
      expect(juzList[1].startPage, 23);
      expect(juzList[2].startPage, 43);
      expect(juzList[29].endVerse, '114:6');
      expect(juzList[0].endVerse, '2:141');
      // start pages strictly increasing
      for (var i = 1; i < juzList.length; i++) {
        expect(juzList[i].startPage, greaterThan(juzList[i - 1].startPage));
      }
    });

    test('juzForPage maps pages to juz', () {
      expect(juzForPage(2), 1);
      expect(juzForPage(22), 1);
      expect(juzForPage(23), 2);
      expect(juzForPage(611), 30);
    });
  });
}
