import 'package:flutter_test/flutter_test.dart';
import 'package:nur_al_quran/utils/script_font.dart';

void main() {
  group('normalizeArabicDisplay', () {
    test('replaces U+06E1 sukun with standard U+0652', () {
      // نَفْسًا with U+06E1 (dotless head of khah) as in the bundled data.
      const broken = 'نَف\u06e1سًا';
      const fixed = 'نَف\u0652سًا';
      expect(normalizeArabicDisplay(broken), fixed);
    });

    test('no U+06E1 remains after normalization', () {
      const text = 'لَا يُكَلِّفُ ٱللَّهُ نَف\u06e1سًا';
      final out = normalizeArabicDisplay(text);
      expect(out.contains('\u06e1'), isFalse);
      expect(out.contains('\u0652'), isTrue);
    });

    test('leaves already-correct text untouched', () {
      const text = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
      expect(normalizeArabicDisplay(text), text);
    });

    test('handles empty string', () {
      expect(normalizeArabicDisplay(''), '');
    });
  });

  group('urduStyle', () {
    test('uses the dedicated Urdu font family', () {
      expect(urduStyle().fontFamily, 'Noto Nastaliq Urdu');
    });

    test('urdu font differs from arabic font families', () {
      expect(urduStyle().fontFamily, isNot(arabicFontFamily('nastaliq')));
      expect(urduStyle().fontFamily, isNot(arabicFontFamily('uthmani')));
    });
  });
}
