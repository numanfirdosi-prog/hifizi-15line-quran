import 'package:flutter_test/flutter_test.dart';
import 'package:nur_al_quran/data/ayah_layout.dart';

void main() {
  // Synthetic segments: ayah 2:255 occupies line 2, right 70%, width 30%.
  const segs = [
    AyahSeg(surah: 2, ayah: 255, line: 2, right: 70, width: 30),
    AyahSeg(surah: 2, ayah: 255, line: 3, right: 0, width: 100),
    AyahSeg(surah: 2, ayah: 256, line: 4, right: 10, width: 50),
  ];

  group('hitTestAyah', () {
    test('tap inside segment hits (RTL: fx=0.1 -> xRight=90 in [70,100])', () {
      // fy=0.15 -> line (0.15*15).floor() = 2
      final hit = hitTestAyah(segs, 0.1, 0.15);
      expect(hit, isNotNull);
      expect(hit!.surah, 2);
      expect(hit.ayah, 255);
    });

    test('tap far from any segment returns null', () {
      // fx=0.9 -> xRight=10, line 2 segment spans [70,100]
      expect(hitTestAyah(segs, 0.9, 0.15), isNull);
    });

    test('tap on wrong line returns null', () {
      // fy=0.9 -> line 13, no segments there
      expect(hitTestAyah(segs, 0.1, 0.9), isNull);
    });

    test('narrowest overlapping segment wins', () {
      const overlapping = [
        AyahSeg(surah: 1, ayah: 1, line: 0, right: 0, width: 100),
        AyahSeg(surah: 1, ayah: 2, line: 0, right: 40, width: 20),
      ];
      // xRight=50 hits both; narrower (width 20) should win
      final hit = hitTestAyah(overlapping, 0.5, 0.02);
      expect(hit, isNotNull);
      expect(hit!.ayah, 2);
    });

    test('fy=1.0 clamps to last line instead of overflowing', () {
      // (1.0*15).floor() = 15 -> clamped to 14; no segment on line 14
      expect(hitTestAyah(segs, 0.5, 1.0), isNull);
    });

    test('empty segment list returns null', () {
      expect(hitTestAyah(const [], 0.5, 0.5), isNull);
    });
  });

  group('rectsForAyah', () {
    test('math: right 70 width 30 -> leftPct 0', () {
      final rects = rectsForAyah(segs, 2, 255);
      expect(rects.length, 2);
      final first = rects.first;
      expect(first.leftPct, 0.0);
      expect(first.widthPct, 30.0);
      expect(first.topPct, closeTo(2 / 15 * 100, 0.001));
      expect(first.heightPct, closeTo(100 / 15, 0.001));
    });

    test('full-width segment: right 0 width 100 -> leftPct 0 width 100', () {
      final rects = rectsForAyah(segs, 2, 255);
      final full = rects[1];
      expect(full.leftPct, 0.0);
      expect(full.widthPct, 100.0);
    });

    test('unknown ayah returns empty', () {
      expect(rectsForAyah(segs, 114, 6), isEmpty);
    });
  });

  group('loadPageAyahSegments (real asset)', () {
    test('page 2 has segments for Al-Fatihah', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final map = await loadPageAyahSegments();
      expect(map.length, 611);
      final p2 = map[2]!;
      expect(p2, isNotEmpty);
      expect(p2.first.surah, 1);
      expect(p2.first.ayah, 1);
      // Second call returns the cached instance.
      final again = await loadPageAyahSegments();
      expect(identical(map, again), isTrue);
    });

    test('real hit-test on page 2 first ayah', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final map = await loadPageAyahSegments();
      final p2 = map[2]!;
      // 1:1 on page 2: line 0, right 0, width 100 -> any fx, fy~0.03 hits.
      final hit = hitTestAyah(p2, 0.5, 0.03);
      expect(hit, isNotNull);
      expect(hit!.surah, 1);
      expect(hit.ayah, 1);
    });
  });
}
