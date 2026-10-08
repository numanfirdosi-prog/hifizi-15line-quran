import 'package:flutter_test/flutter_test.dart';
import 'package:nur_al_quran/data/ayah_layout.dart';

// Website-exact text area: left 10.97%, top 6.62%, w 78.34%, h 86.89%.
// Line N (1-based) spans ty in [(N-1)/15, N/15) of the text area.
double fxForTx(double tx) => 0.1097 + tx * 0.7834;
double fyForTy(double ty) => 0.0662 + ty * 0.8689;

void main() {
  // Synthetic segments on a REGULAR page (1-based lines, like the website):
  // ayah 2:255 spans line 2 (right 70, width 30) and line 3 (full width);
  // ayah 2:256 on line 4; decoy ayah 2:254 on line 1 at the same x-range.
  const segs = [
    AyahSeg(surah: 2, ayah: 254, line: 1, right: 70, width: 30),
    AyahSeg(surah: 2, ayah: 255, line: 2, right: 70, width: 30),
    AyahSeg(surah: 2, ayah: 255, line: 3, right: 0, width: 100),
    AyahSeg(surah: 2, ayah: 256, line: 4, right: 10, width: 50),
  ];

  group('hitTestAyah — regular page (website-exact)', () {
    test('tap on visual line 2 hits the line-2 ayah (1-based, no off-by-one)',
        () {
      // ty=0.1 -> line floor(0.1*15)+1 = 2; tx=0.15 -> xRight=85 in [70,100]
      final hit = hitTestAyah(segs, fxForTx(0.15), fyForTy(0.1), 100);
      expect(hit, isNotNull);
      expect(hit!.surah, 2);
      expect(hit.ayah, 255); // NOT the line-1 decoy (254)
    });

    test('tap on visual line 1 hits the line-1 ayah', () {
      // ty=0.03 -> line 1
      final hit = hitTestAyah(segs, fxForTx(0.15), fyForTy(0.03), 100);
      expect(hit, isNotNull);
      expect(hit!.ayah, 254);
    });

    test('tap far from any segment returns null', () {
      // tx=0.9 -> xRight=10; line 2 segment spans [70,100]
      expect(hitTestAyah(segs, fxForTx(0.9), fyForTy(0.1), 100), isNull);
    });

    test('tap on page margin (outside text area) returns null', () {
      expect(hitTestAyah(segs, 0.05, fyForTy(0.1), 100), isNull); // left margin
      expect(hitTestAyah(segs, fxForTx(0.5), 0.02, 100), isNull); // top margin
      expect(hitTestAyah(segs, fxForTx(0.5), 0.99, 100), isNull); // bottom margin
    });

    test('narrowest overlapping segment wins', () {
      const overlapping = [
        AyahSeg(surah: 1, ayah: 1, line: 5, right: 0, width: 100),
        AyahSeg(surah: 1, ayah: 2, line: 5, right: 40, width: 20),
      ];
      // tx=0.5 -> xRight=50 hits both; narrower (width 20) should win
      final hit = hitTestAyah(overlapping, fxForTx(0.5), fyForTy(0.32), 100);
      expect(hit, isNotNull);
      expect(hit!.ayah, 2);
    });

    test('last line clamps: ty=0.999 -> line 15', () {
      const line15 = [AyahSeg(surah: 114, ayah: 6, line: 15, right: 0, width: 100)];
      final hit = hitTestAyah(line15, fxForTx(0.5), fyForTy(0.999), 611);
      expect(hit, isNotNull);
      expect(hit!.ayah, 6);
    });

    test('empty segment list returns null', () {
      expect(hitTestAyah(const [], 0.5, 0.5, 100), isNull);
    });
  });

  group('hitTestAyah — Lauh pages 2 & 3', () {
    test('page 2 bismillah cartouche (line 0) hit', () {
      const p2 = [AyahSeg(surah: 1, ayah: 1, line: 0, right: 0, width: 100)];
      // cartouche: left 28%, top 36.5%, w 44%, h 6.2%
      final hit = hitTestAyah(p2, 0.5, 0.39, 2);
      expect(hit, isNotNull);
      expect(hit!.surah, 1);
      expect(hit.ayah, 1);
    });

    test('page 2 line-1 row hit', () {
      const p2 = [AyahSeg(surah: 1, ayah: 2, line: 1, right: 0, width: 75)];
      // line 1 row: top 42.8%, h 6.85%, left 24.6%, w 50.8%
      // tx=0.5 -> xRight=50 in [0,75]
      final hit = hitTestAyah(p2, 0.246 + 0.5 * 0.508, 0.462, 2);
      expect(hit, isNotNull);
      expect(hit!.ayah, 2);
    });

    test('tap outside lauh rows returns null', () {
      const p2 = [AyahSeg(surah: 1, ayah: 2, line: 1, right: 0, width: 75)];
      expect(hitTestAyah(p2, 0.1, 0.462, 2), isNull); // left of row
      expect(hitTestAyah(p2, 0.5, 0.9, 2), isNull); // below rows
    });

    test('page 3 uses lauh layout too', () {
      const p3 = [AyahSeg(surah: 2, ayah: 1, line: 1, right: 0, width: 25)];
      final hit = hitTestAyah(p3, 0.246 + 0.9 * 0.508, 0.462, 3);
      expect(hit, isNotNull);
      expect(hit!.ayah, 1);
    });
  });

  group('rectsForAyah — website-exact', () {
    test('regular page rect math', () {
      final rects = rectsForAyah(segs, 2, 255, 100);
      expect(rects.length, 2);
      final first = rects.first; // line 2, right 70, width 30
      expect(first.left, closeTo(0.1097 + 0.0 * 0.7834, 0.0001));
      expect(first.width, closeTo(0.30 * 0.7834, 0.0001));
      expect(first.top, closeTo(0.0662 + 1 / 15 * 0.8689, 0.0001));
      expect(first.height, closeTo(0.8689 / 15, 0.0001));
    });

    test('full-width segment spans the text area', () {
      final rects = rectsForAyah(segs, 2, 255, 100);
      final full = rects[1]; // line 3, right 0, width 100
      expect(full.left, closeTo(0.1097, 0.0001));
      expect(full.width, closeTo(0.7834, 0.0001));
      expect(full.top, closeTo(0.0662 + 2 / 15 * 0.8689, 0.0001));
    });

    test('lauh page rect uses the absolute row geometry', () {
      const p2 = [AyahSeg(surah: 1, ayah: 2, line: 1, right: 0, width: 75)];
      final rects = rectsForAyah(p2, 1, 2, 2);
      expect(rects.length, 1);
      final r = rects.first;
      expect(r.left, closeTo(0.246 + 0.25 * 0.508, 0.0001));
      expect(r.width, closeTo(0.75 * 0.508, 0.0001));
      expect(r.top, closeTo(0.428, 0.0001));
      expect(r.height, closeTo(0.0685, 0.0001));
    });

    test('unknown ayah returns empty', () {
      expect(rectsForAyah(segs, 114, 6, 100), isEmpty);
    });
  });

  group('loadPageAyahSegments (real asset)', () {
    test('611 pages, cached', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final map = await loadPageAyahSegments();
      expect(map.length, 611);
      expect(map[4]!.any((s) => s.line == 1), isTrue); // 1-based lines
      expect(map[4]!.any((s) => s.line == 15), isTrue);
      final again = await loadPageAyahSegments();
      expect(identical(map, again), isTrue);
    });

    test('real hit-test: page 2 bismillah cartouche', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final map = await loadPageAyahSegments();
      final p2 = map[2]!;
      final hit = hitTestAyah(p2, 0.5, 0.39, 2);
      expect(hit, isNotNull);
      expect(hit!.surah, 1);
      expect(hit.ayah, 1);
    });

    test('real hit-test: page 4 line-1 segment', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final map = await loadPageAyahSegments();
      final p4 = map[4]!;
      // 2:5 on page 4: line 1, right 0, width 100 -> middle of text area top
      final hit = hitTestAyah(p4, fxForTx(0.5), fyForTy(0.03), 4);
      expect(hit, isNotNull);
      expect(hit!.surah, 2);
      expect(hit.ayah, 5);
    });

    test('real hit-test: page 20 line 6 keeps Ayah 123 (وَاتَّقُوْا)', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final map = await loadPageAyahSegments();
      final p20 = map[20]!;
      // Line 6 has 2:123 opening word at right=90, width=10
      final line6Seg = p20.firstWhere(
        (s) => s.surah == 2 && s.ayah == 123 && s.line == 6,
      );
      expect(line6Seg.right, 90.0);
      expect(line6Seg.width, 10.0);

      // Hit test on line 6 at xRight=95 (tx=0.05)
      final hit = hitTestAyah(p20, fxForTx(0.05), fyForTy(5.5 / 15), 20);
      expect(hit, isNotNull);
      expect(hit!.surah, 2);
      expect(hit.ayah, 123);
    });

    test('real hit-test: page 20 line 8 correctly separates Ayah 123 and 124', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final map = await loadPageAyahSegments();
      final p20 = map[20]!;

      // Ayah 123 ends with يُنْصَرُوْنَ + circle marker (0 to 70% from right)
      // Tapping at xRight=60 (tx=0.40) must hit Ayah 123
      final hit123 = hitTestAyah(p20, fxForTx(0.40), fyForTy(7.5 / 15), 20);
      expect(hit123, isNotNull);
      expect(hit123!.surah, 2);
      expect(hit123.ayah, 123);

      // Tapping near circle marker at xRight=66 (tx=0.34) must hit Ayah 123
      final hitMarker = hitTestAyah(p20, fxForTx(0.34), fyForTy(7.5 / 15), 20);
      expect(hitMarker, isNotNull);
      expect(hitMarker!.surah, 2);
      expect(hitMarker.ayah, 123);

      // Ayah 124 starts with وَإِذِ ابْتَلَى (70% to 100% from right)
      // Tapping at xRight=80 (tx=0.20) must hit Ayah 124
      final hit124 = hitTestAyah(p20, fxForTx(0.20), fyForTy(7.5 / 15), 20);
      expect(hit124, isNotNull);
      expect(hit124!.surah, 2);
      expect(hit124.ayah, 124);
    });
  });
}
