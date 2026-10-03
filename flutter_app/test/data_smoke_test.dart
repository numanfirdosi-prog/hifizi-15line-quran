import 'dart:io';
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

    test('urdu kanzuliman has no known typos', () {
      // Reads the bundled JSON directly (rootBundle needs a widget test).
      final file = File('assets/data/quran_urdu_kanzuliman.json');
      final List<dynamic> data =
          jsonDecode(file.readAsStringSync()) as List<dynamic>;
      expect(data.length, 6236);
      String ur(int s, int v) => (data.firstWhere(
            (e) => (e as Map<String, dynamic>)['s'] == s && e['v'] == v,
          ) as Map<String, dynamic>)['ur'] as String;
      // 3:191: "کرت ہیں" typo -> "کرتے ہیں"
      expect(ur(3, 191).contains('یاد کرتے ہیں'), isTrue);
      expect(ur(3, 191).contains('کرت ہیں'), isFalse);
      // 28:44: "جانت" typo -> "جانب" (Arabic: بِجَانِبِ)
      expect(ur(28, 44).contains('طور کی جانب'), isTrue);
    });
  });
    test('urdu kanzuliman: full-audit typos stay fixed', () {
      final file = File('assets/data/quran_urdu_kanzuliman.json');
      final List<dynamic> data =
          jsonDecode(file.readAsStringSync()) as List<dynamic>;
      expect(data.length, 6236);
      final words = <String>{};
      final bigrams = <String>{};
      final trigrams = <String>{};
      const punct = '،؛؟!.()«»"\u061C';
      String strip(String t) {
        var s = t;
        while (s.isNotEmpty && punct.contains(s[s.length - 1])) {
          s = s.substring(0, s.length - 1);
        }
        while (s.isNotEmpty && punct.contains(s[0])) { s = s.substring(1); }
        return s;
      }
      for (final e in data) {
        final tokens = ((e as Map<String, dynamic>)['ur'] as String).split(' ');
        for (final t in tokens) { words.add(strip(t)); }
        for (var i = 0; i + 1 < tokens.length; i++) {
          bigrams.add('${tokens[i]} ${tokens[i + 1]}');
        }
        for (var i = 0; i + 2 < tokens.length; i++) {
          trigrams.add('${tokens[i]} ${tokens[i + 1]} ${tokens[i + 2]}');
        }
      }
      // None of the audited split-typo fragments may reappear.
      const splitTypos = <String>[
        'ہر گز',
        'لا ؤ',
        'فورا ً',
        'نصاری ٰ',
        'موسی ٰ',
        'نا چار',
        'دن یا',
        'دوز خی',
        'علا قہ',
        'زلز لہ',
        'کا فروں',
        'چھوڑ تا',
        'جا ہل',
        'نو ر',
        'بڑا ئی',
        'اتا رے',
        'بتا تا',
        'ما نگا',
        'بند ر',
        'صا ف',
        'ا تاری',
        'فریا د',
        'مخا لفت',
        'با ز',
        'کا ر',
        'ہوجا تا',
        'برسا یا',
        'کنا رے',
        'قا فلہ',
        'تھو ڑا',
        'کا فر',
        'پو را',
        'تھو ڑے',
        'ر ہے',
        'با ر',
        'پا ؤ',
        'ہزا ر',
        'ر ہو',
        'کمزو ر',
        'چا ہتے',
        'چا ر',
        'نما ز',
        'سنا تا',
        'اتا ری',
        'بگا ڑ',
        'چا ہا',
        'بنا ؤ',
        'ہو تی',
        'فرما تا',
        'بنا یا',
        'کہا وت',
        'جا نچ',
        'خو ف',
        'پہنچا تا',
        'ظا لموں',
        'پا تا',
        'صا لح',
        'لگا تار',
        'چا ہیں',
        'جا ؤ',
        'کا موں',
        'با پ',
        'چا ل',
        'نکا لنا',
        'دروا زوں',
        'جا تا',
        'گر ج',
        'برُ ا',
        'د یں',
        'یا د',
        'حضو ر',
        'ر وح',
        'معز ز',
        'کفا یت',
        'بر ا',
        'قیا مت',
        'دو ست',
        'پا ئی',
        'ساما ن',
        'ان ہی',
        'سلوی ٰ',
        'د لائی',
        'جھٹلا ئیں',
        'ہا رون',
        'دو نوں',
        'تمھا رے',
        'نا شکر',
        'فر ما',
        'ز یادتی',
        'ڈرا ئے',
        'تما م',
        'دوڑ تا',
        'پو جتے',
        'زیا دہ',
        'بنا تا',
        'نا شکرا',
        'انگو روں',
        'روز ِ',
        'غا لب',
        'کڑ ک',
        'ک سے',
        'بھا گنے',
        'عیسی ٰ',
        'نشا نیاں',
        'جھگڑ تے',
        'دیکھ ا',
        'کو شش',
        'عنقر یب',
        'لو ط',
        'حسا ب',
        'بتا نے',
        'چا ہو',
        'مسلما نوں',
        'کو تک',
        'قنا ویز',
        'جا ئیں،',
        'ڈرا نے',
        'کڑ وڑا',
        'بر تنے',
        'بز د لی',
        'قر آ ن',
        'ا ور',
        'او ر',
        'م یں',
        'کا ن',
        'ا نہیں',
        'طر ف',
        'کو ئی',
        'ایما ن',
        'و الا',
        'وا لا',
        'پا س',
        'کر و',
        'وا لوں',
        'کا م',
        'ضرو ر',
        'کہ ا',
        'با ت',
        'ہما رے',
        'ہو ا',
        'فر ماؤ',
        'فرما ؤ',
        'تمہا را',
        'فرما یا',
        'لا ئے',
        'جا نتا',
        'پرہیزگا روں',
        'کتا ب',
        'سزا وار',
        'درد ناک',
        'پرہیز گاروں',
        'تا بع',
        'آ نے',
        'نکا لا',
        'پکڑ تا',
        'جان نے',
        'بڑھا پا',
        'کہ نا',
        'جما دے',
        'حیا ئی',
        'اُ س',
        'بتا دے',
        'ا بھی',
        'د یکھا',
        'خو بیوں',
        'سرا ہے',
        'جھٹلا نے',
        'جا نا',
      ];
      for (final frag in splitTypos) {
        final n = frag.split(' ').length;
        final set = n == 2 ? bigrams : trigrams;
        expect(set.contains(frag), isFalse, reason: 'typo: $frag');
      }
      // None of the audited jammed-word typos may reappear.
      const jammedTypos = <String>[
        'اللہکے',
        'انکا',
        'اسمیں',
        'انکے',
        'انکی',
        'اسکی',
        'پھرتمہیں',
        'اسکے',
        'اسکا',
        'بعداس',
        'ہرچیز',
        'لوگے',
        'کروگے',
        'پھروگے',
        'ہوگے',
        'آلیا',
        'اسحق',
      ];
      for (final frag in jammedTypos) {
        expect(words.contains(frag), isFalse, reason: 'typo: $frag');
      }
      // Spot-check key fixed verses read correctly.
      String ur(int s, int v) => (data.firstWhere(
            (e) => (e as Map<String, dynamic>)['s'] == s && e['v'] == v,
          ) as Map<String, dynamic>)['ur'] as String;
      expect(ur(2, 206).contains('گناہ'), isTrue);
      expect(ur(6, 135).contains('آخرت'), isTrue);
      expect(ur(11, 24).contains('کیا تم دھیان نہیں'), isTrue);
      expect(ur(28, 44).contains('طور کی جانب'), isTrue);
      expect(ur(64, 14).contains('بیبیاں'), isTrue);
      expect(ur(3, 191).contains('یاد کرتے ہیں'), isTrue);
      expect(ur(8, 44).contains('کافر'), isTrue);
      expect(ur(11, 14).contains('اللہ کے علم'), isTrue);
    });
}