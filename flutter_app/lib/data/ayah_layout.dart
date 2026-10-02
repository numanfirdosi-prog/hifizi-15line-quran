import 'dart:convert';

import 'package:flutter/services.dart';

/// Geometry copied exactly from the 15-line Quran website
/// (`mushaf-redesign.css`):
///
/// ```css
/// .mushaf-ayah-overlay {
///   top: 6.62%; height: 86.89%;
///   left: 10.97%; right: 10.69%;
/// }
/// ```
///
/// Segments are positioned with `style.right` / `style.width` (%) *inside*
/// 15 equal line rows of this text area (RTL layout) — NOT the full page.
/// Regular pages (4..611) use 1-based line numbers 1..15.
///
/// Lauh pages (2, 3) use a different absolute layout
/// (`.page-lauh-overlay`):
/// - bismillah cartouche (line 0): left 28%, top 36.5%, w 44%, h 6.2%
/// - lines 1..6: left 24.6%, width 50.8%, per-line top/height below.
class AyahSeg {
  final int surah;
  final int ayah;

  /// Website line number: 1..15 on regular pages, 0..6 on Lauh pages.
  final int line;

  /// Horizontal span in % from the RIGHT edge of the line row (RTL).
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

/// Highlight rectangle for one ayah segment, as fractions (0..1) of the
/// page-image box (left/top based).
class AyahRect {
  final double left;
  final double top;
  final double width;
  final double height;

  const AyahRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
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
          line: line,
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

// ---------------------------------------------------------------------------
// Website-exact geometry constants (fractions of the page image).
// ---------------------------------------------------------------------------

/// Regular-page text area (`.mushaf-ayah-overlay`).
const double _kTextLeft = 0.1097;
const double _kTextTop = 0.0662;
const double _kTextWidth = 0.7834; // 1 - 0.1097 - 0.1069
const double _kTextHeight = 0.8689;

/// Lauh bismillah cartouche (line 0 on page 2).
const double _kLauhBisLeft = 0.28;
const double _kLauhBisTop = 0.365;
const double _kLauhBisW = 0.44; // 1 - 0.28 - 0.28
const double _kLauhBisH = 0.062;

/// Lauh line rows 1..6: left 24.6%, width 50.8%, (top, height) per line.
const double _kLauhRowLeft = 0.246;
const double _kLauhRowW = 0.508; // 1 - 0.246 - 0.246
const Map<int, (double, double)> _kLauhRows = {
  1: (0.428, 0.0685),
  2: (0.4965, 0.0685),
  3: (0.565, 0.0685),
  4: (0.6335, 0.0685),
  5: (0.702, 0.0685),
  6: (0.7705, 0.0715),
};

bool _isLauhPage(int page) => page == 2 || page == 3;

/// Matches the narrowest segment on [line] containing the horizontal
/// position [tx] (0..1 from the LEFT edge of the line row).
AyahSeg? _matchLine(List<AyahSeg> segs, int line, double tx) {
  if (tx < 0 || tx > 1) return null;
  const eps = 0.5; // tolerance in % for segment boundaries
  final xRight = (1 - tx) * 100; // % from the right edge (RTL)
  AyahSeg? best;
  for (final s in segs) {
    if (s.line != line) continue;
    if (xRight < s.right - eps || xRight > s.right + s.width + eps) continue;
    if (best == null || s.width < best.width) best = s;
  }
  return best;
}

/// Hit-tests a tap at fractional page-image coordinates.
/// [fx]: 0..1 from the LEFT edge, [fy]: 0..1 from the top.
/// Returns the narrowest matching segment (null when the tap hit no ayah).
AyahSeg? hitTestAyah(List<AyahSeg> segs, double fx, double fy, int page) {
  if (_isLauhPage(page)) {
    // Bismillah cartouche (line 0).
    if (fy >= _kLauhBisTop &&
        fy <= _kLauhBisTop + _kLauhBisH &&
        fx >= _kLauhBisLeft &&
        fx <= _kLauhBisLeft + _kLauhBisW) {
      return _matchLine(segs, 0, (fx - _kLauhBisLeft) / _kLauhBisW);
    }
    for (final entry in _kLauhRows.entries) {
      final top = entry.value.$1;
      final h = entry.value.$2;
      if (fy >= top &&
          fy <= top + h &&
          fx >= _kLauhRowLeft &&
          fx <= _kLauhRowLeft + _kLauhRowW) {
        return _matchLine(segs, entry.key, (fx - _kLauhRowLeft) / _kLauhRowW);
      }
    }
    return null;
  }

  // Regular page: map into the website's text area, then 1-based line rows.
  final tx = (fx - _kTextLeft) / _kTextWidth;
  final ty = (fy - _kTextTop) / _kTextHeight;
  if (tx < 0 || tx > 1 || ty < 0 || ty > 1) return null; // tapped a margin
  final lineNo = ((ty * 15).floor() + 1).clamp(1, 15);
  return _matchLine(segs, lineNo, tx);
}

/// Highlight rectangles (fractions 0..1 of the page-image box) for one ayah.
List<AyahRect> rectsForAyah(List<AyahSeg> segs, int s, int v, int page) {
  final out = <AyahRect>[];
  for (final seg in segs) {
    if (seg.surah != s || seg.ayah != v) continue;
    if (_isLauhPage(page)) {
      if (seg.line == 0) {
        out.add(AyahRect(
          left: _kLauhBisLeft + (100 - seg.right - seg.width) / 100 * _kLauhBisW,
          top: _kLauhBisTop,
          width: seg.width / 100 * _kLauhBisW,
          height: _kLauhBisH,
        ));
      } else {
        final row = _kLauhRows[seg.line];
        if (row == null) continue;
        out.add(AyahRect(
          left: _kLauhRowLeft + (100 - seg.right - seg.width) / 100 * _kLauhRowW,
          top: row.$1,
          width: seg.width / 100 * _kLauhRowW,
          height: row.$2,
        ));
      }
      continue;
    }
    // Regular page: segment % is relative to the text-area row.
    out.add(AyahRect(
      left: _kTextLeft + (100 - seg.right - seg.width) / 100 * _kTextWidth,
      top: _kTextTop + (seg.line - 1) / 15 * _kTextHeight,
      width: seg.width / 100 * _kTextWidth,
      height: _kTextHeight / 15,
    ));
  }
  return out;
}
