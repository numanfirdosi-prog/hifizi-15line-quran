import 'dart:convert';

import 'package:flutter/services.dart';

/// One ayah fragment on a single 15-line page: the segment's line (0-14)
/// and its horizontal span measured in % from the RIGHT edge (RTL layout).
class AyahSeg {
  final int surah;
  final int ayah;
  final int line;
  final double right;
  final double width;

  const AyahSeg({
    required this.surah,
    required this.ayah,
    required this.line,
    required this.right,
    required this.width,
  });
}

/// Highlight rectangle for one ayah segment, in % of the page image box
/// (left/top based, 0..100).
class AyahRect {
  final double leftPct;
  final double topPct;
  final double widthPct;
  final double heightPct;

  const AyahRect({
    required this.leftPct,
    required this.topPct,
    required this.widthPct,
    required this.heightPct,
  });
}

Map<int, List<AyahSeg>>? _segmentsCache;

/// Parses `assets/data/page_ayahs_15lines.json` once and caches
/// page number -> list of ayah segments.
Future<Map<int, List<AyahSeg>>> loadPageAyahSegments() async {
  if (_segmentsCache != null) return _segmentsCache!;
  final raw =
      await rootBundle.loadString('assets/data/page_ayahs_15lines.json');
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  final out = <int, List<AyahSeg>>{};
  decoded.forEach((pageStr, entries) {
    final page = int.tryParse(pageStr);
    if (page == null || entries is! List) return;
    final segs = <AyahSeg>[];
    for (final e in entries) {
      if (e is! Map<String, dynamic>) continue;
      final surah = (e['surah'] as num?)?.toInt();
      final ayah = (e['ayah'] as num?)?.toInt();
      final segments = e['segments'];
      if (surah == null || ayah == null || segments is! List) continue;
      for (final s in segments) {
        if (s is! Map<String, dynamic>) continue;
        final line = (s['line'] as num?)?.toInt();
        final right = (s['right'] as num?)?.toDouble();
        final width = (s['width'] as num?)?.toDouble();
        if (line == null || right == null || width == null) continue;
        segs.add(AyahSeg(
          surah: surah,
          ayah: ayah,
          line: line.clamp(0, 14),
          right: right,
          width: width,
        ));
      }
    }
    out[page] = segs;
  });
  _segmentsCache = out;
  return out;
}

/// Hit-tests a tap at fractional image-box coordinates.
/// [fx]: 0..1 from the LEFT edge, [fy]: 0..1 from the top.
/// Returns the narrowest matching segment (null when the tap hit no ayah).
AyahSeg? hitTestAyah(List<AyahSeg> segs, double fx, double fy) {
  final lineIdx = (fy * 15).floor().clamp(0, 14);
  final xRight = (1 - fx) * 100; // convert to % from right edge
  AyahSeg? best;
  for (final s in segs) {
    if (s.line != lineIdx) continue;
    if (xRight < s.right || xRight > s.right + s.width) continue;
    if (best == null || s.width < best.width) best = s;
  }
  return best;
}

/// Highlight rectangles (in % of the image box) for one ayah on a page.
List<AyahRect> rectsForAyah(List<AyahSeg> segs, int s, int v) {
  final out = <AyahRect>[];
  for (final seg in segs) {
    if (seg.surah != s || seg.ayah != v) continue;
    out.add(AyahRect(
      leftPct: 100 - seg.right - seg.width,
      topPct: seg.line / 15 * 100,
      widthPct: seg.width,
      heightPct: 100 / 15,
    ));
  }
  return out;
}
