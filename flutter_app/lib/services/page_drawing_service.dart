import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A single freehand/rectangle stroke drawn on a mushaf page.
/// All coordinates are fractions (0..1) of the page image box, so strokes
/// scale with any screen size.
class DrawingStroke {
  /// 'pen' | 'brush' | 'highlighter' | 'rectangle'
  final String tool;

  /// Hex color without '#', e.g. 'D4AF37'.
  final String colorHex;

  /// Stroke width as a fraction of the image-box width.
  final double width;

  /// Fraction-space points (pen / brush / highlighter).
  final List<Offset> points;

  /// Fraction-space rect (rectangle tool).
  final Rect rect;

  const DrawingStroke({
    required this.tool,
    required this.colorHex,
    required this.width,
    this.points = const [],
    this.rect = Rect.zero,
  });

  DrawingStroke copyWith({List<Offset>? points, Rect? rect}) => DrawingStroke(
        tool: tool,
        colorHex: colorHex,
        width: width,
        points: points ?? this.points,
        rect: rect ?? this.rect,
      );

  Map<String, dynamic> toJson() => {
        'tool': tool,
        'color': colorHex,
        'width': width,
        'points': points.map((p) => [p.dx, p.dy]).toList(),
        'rect': [rect.left, rect.top, rect.right, rect.bottom],
      };

  factory DrawingStroke.fromJson(Map<String, dynamic> m) {
    final pts = <Offset>[];
    final rawPts = m['points'];
    if (rawPts is List) {
      for (final p in rawPts) {
        if (p is List && p.length >= 2) {
          final x = (p[0] as num?)?.toDouble() ?? 0.0;
          final y = (p[1] as num?)?.toDouble() ?? 0.0;
          pts.add(Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0)));
        }
      }
    }
    var r = Rect.zero;
    final rawRect = m['rect'];
    if (rawRect is List && rawRect.length >= 4) {
      final l = (rawRect[0] as num?)?.toDouble() ?? 0.0;
      final t = (rawRect[1] as num?)?.toDouble() ?? 0.0;
      final rr = (rawRect[2] as num?)?.toDouble() ?? 0.0;
      final b = (rawRect[3] as num?)?.toDouble() ?? 0.0;
      r = Rect.fromLTRB(
        l.clamp(0.0, 1.0),
        t.clamp(0.0, 1.0),
        rr.clamp(0.0, 1.0),
        b.clamp(0.0, 1.0),
      );
    }
    return DrawingStroke(
      tool: (m['tool'] as String?) ?? 'pen',
      colorHex: (m['color'] as String?) ?? 'D4AF37',
      width: ((m['width'] as num?)?.toDouble() ?? 0.005).clamp(0.001, 0.2),
      points: pts,
      rect: r,
    );
  }
}

/// Per-tool default stroke widths (fraction of image-box width).
double drawingWidthForTool(String tool) {
  switch (tool) {
    case 'brush':
      return 0.014;
    case 'highlighter':
      return 0.04;
    case 'rectangle':
      return 0.005;
    case 'pen':
    default:
      return 0.005;
  }
}

/// Pure eraser hit-test: true when fraction-space point [p] touches [s]
/// within [tolerance] (fraction units).
bool hitTestStroke(DrawingStroke s, Offset p, double tolerance) {
  if (s.tool == 'rectangle') {
    return s.rect.inflate(tolerance).contains(p);
  }
  final pts = s.points;
  if (pts.isEmpty) return false;
  if (pts.length == 1) {
    return (pts.first - p).distance <= tolerance;
  }
  for (var i = 0; i < pts.length - 1; i++) {
    if (_distToSegment(p, pts[i], pts[i + 1]) <= tolerance) return true;
  }
  return false;
}

double _distToSegment(Offset p, Offset a, Offset b) {
  final abx = b.dx - a.dx;
  final aby = b.dy - a.dy;
  final len2 = abx * abx + aby * aby;
  if (len2 == 0) return (p - a).distance;
  var t = ((p.dx - a.dx) * abx + (p.dy - a.dy) * aby) / len2;
  t = t.clamp(0.0, 1.0);
  final cx = a.dx + t * abx;
  final cy = a.dy + t * aby;
  return sqrt((p.dx - cx) * (p.dx - cx) + (p.dy - cy) * (p.dy - cy));
}

/// Freehand page drawings (highlighter / pen / brush / rectangle / eraser).
///
/// Strokes are stored per page under a single SharedPreferences key
/// ('nur_page_drawings') as JSON `{ "<page>": [stroke, ...] }`. The selected
/// tool/color are session-only (not persisted).
class PageDrawingService extends ChangeNotifier {
  static const String prefsKey = 'nur_page_drawings';

  /// The 6 drawing colors offered in the color picker.
  static const List<String> paletteHexes = [
    'D4AF37', // gold (default)
    'E53935', // red
    '43A047', // green
    '1E88E5', // blue
    '8E24AA', // purple
    '212121', // black
  ];

  final Map<String, List<DrawingStroke>> _drawings = {};
  SharedPreferences? _prefs;

  /// Currently active drawing tool ('pen' | 'brush' | 'highlighter' |
  /// 'rectangle' | 'eraser'), or null when not in drawing mode.
  String? _selectedTool;
  String _selectedColorHex = paletteHexes[0];

  String? get selectedTool => _selectedTool;
  String get selectedColorHex => _selectedColorHex;
  bool get isDrawingMode => _selectedTool != null;

  Color get selectedColor => _parseHex(_selectedColorHex);

  static Color _parseHex(String hex) {
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    return Color(int.tryParse(h, radix: 16) ?? 0xFFD4AF37);
  }

  /// Loads persisted drawings. Safe to call more than once.
  Future<void> init() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await reload();
    } catch (_) {
      // Best effort: drawings simply start empty.
    }
  }

  /// Re-reads drawings from disk (e.g. after a backup import).
  Future<void> reload() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final raw = _prefs?.getString(prefsKey);
      _drawings.clear();
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          decoded.forEach((k, v) {
            if (v is List) {
              final strokes = <DrawingStroke>[];
              for (final item in v) {
                if (item is Map) {
                  try {
                    strokes.add(DrawingStroke.fromJson(
                        item.map((kk, vv) =>
                            MapEntry(kk.toString(), vv))));
                  } catch (_) {}
                }
              }
              _drawings[k.toString()] = strokes;
            }
          });
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final map = <String, dynamic>{
        for (final e in _drawings.entries)
          e.key: e.value.map((s) => s.toJson()).toList(),
      };
      await _prefs?.setString(prefsKey, jsonEncode(map));
    } catch (_) {}
  }

  /// Strokes for [page] (read-only view).
  List<DrawingStroke> strokesFor(int page) =>
      List.unmodifiable(_drawings[page.toString()] ?? const []);

  bool hasDrawings(int page) =>
      (_drawings[page.toString()]?.isNotEmpty ?? false);

  Future<void> addStroke(int page, DrawingStroke stroke) async {
    try {
      final key = page.toString();
      (_drawings[key] ??= []).add(stroke);
      notifyListeners();
      await _persist();
    } catch (_) {}
  }

  /// Removes the topmost stroke touching fraction-space point [p].
  /// Returns true when a stroke was removed.
  Future<bool> removeStrokeAt(int page, Offset p, double tolerance) async {
    try {
      final key = page.toString();
      final strokes = _drawings[key];
      if (strokes == null || strokes.isEmpty) return false;
      for (var i = strokes.length - 1; i >= 0; i--) {
        if (hitTestStroke(strokes[i], p, tolerance)) {
          strokes.removeAt(i);
          notifyListeners();
          await _persist();
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Removes all drawing strokes for [page]. Notes are separate
  /// (see PreferencesService.setPageNote).
  Future<void> clearPage(int page) async {
    try {
      _drawings.remove(page.toString());
      notifyListeners();
      await _persist();
    } catch (_) {}
  }

  void setTool(String? tool) {
    _selectedTool = tool;
    notifyListeners();
  }

  void setColor(String hex) {
    _selectedColorHex = hex.replaceAll('#', '').toUpperCase();
    notifyListeners();
  }

  void exitDrawing() {
    _selectedTool = null;
    notifyListeners();
  }
}
