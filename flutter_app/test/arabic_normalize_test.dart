import 'package:flutter_test/flutter_test.dart';
import 'package:nur_al_quran/utils/script_font.dart';

void main() {
  group('arabicFontFamily', () {
    test('sans style uses Noto Sans Arabic', () {
      expect(arabicFontFamily('sans'), 'Noto Sans Arabic');
    });

    test('uthmani style uses KFGQPC Uthmanic', () {
      expect(arabicFontFamily('uthmani'), 'KFGQPC Uthmanic');
    });

    test('retired nastaliq falls back to KFGQPC Uthmanic', () {
      expect(arabicFontFamily('nastaliq'), 'KFGQPC Uthmanic');
    });
  });

  group('normalizeArabicDisplay', () {
    test('replaces U+06E1 sukun with standard U+0652', () {
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

    test('corrects false ya-hamza-below and decomposed letters in 16:90', () {
      const broken1690 = '۞إِنَّ ٱللَّهَ يَأۡمُرُ بِٱلۡعَدۡلِ وَٱلۡإِحۡسَٰنِ وَإِيتَآيِٕ ذِي ٱلۡقُرۡبَىٰ';
      final fixed = normalizeArabicDisplay(broken1690);
      expect(fixed.contains('وَإِيتَآءِ'), isTrue);
      expect(fixed.contains('۞إِنَّ'), isTrue);
      expect(fixed.contains('يَأْمُرُ'), isTrue);
      expect(fixed.contains('وَٱلْإِحْسَٰنِ'), isTrue);
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
  });
}
