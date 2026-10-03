import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nur_al_quran/services/page_drawing_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  DrawingStroke penStroke() => const DrawingStroke(
        tool: 'pen',
        colorHex: 'D4AF37',
        width: 0.005,
        points: [Offset(0.1, 0.2), Offset(0.3, 0.4)],
      );

  group('DrawingStroke JSON round-trip', () {
    test('pen stroke round-trips', () {
      final s = penStroke();
      final back = DrawingStroke.fromJson(s.toJson());
      expect(back.tool, 'pen');
      expect(back.colorHex, 'D4AF37');
      expect(back.width, 0.005);
      expect(back.points.length, 2);
      expect(back.points[0], const Offset(0.1, 0.2));
    });

    test('rectangle stroke round-trips', () {
      const s = DrawingStroke(
        tool: 'rectangle',
        colorHex: 'E53935',
        width: 0.005,
        rect: Rect.fromLTRB(0.1, 0.2, 0.5, 0.6),
      );
      final back = DrawingStroke.fromJson(s.toJson());
      expect(back.tool, 'rectangle');
      expect(back.rect.left, 0.1);
      expect(back.rect.bottom, 0.6);
    });

    test('brush stroke round-trips with many points', () {
      final s = DrawingStroke(
        tool: 'brush',
        colorHex: '1E88E5',
        width: 0.014,
        points: List.generate(20, (i) => Offset(i / 20, 0.5)),
      );
      final back = DrawingStroke.fromJson(s.toJson());
      expect(back.points.length, 20);
      expect(back.width, 0.014);
    });

    test('highlighter stroke round-trips', () {
      const s = DrawingStroke(
        tool: 'highlighter',
        colorHex: '43A047',
        width: 0.04,
        points: [Offset(0.2, 0.3), Offset(0.8, 0.3)],
      );
      final back = DrawingStroke.fromJson(s.toJson());
      expect(back.tool, 'highlighter');
      expect(back.colorHex, '43A047');
    });

    test('malformed json falls back to safe defaults', () {
      final back = DrawingStroke.fromJson(const {});
      expect(back.tool, 'pen');
      expect(back.points, isEmpty);
      expect(back.rect, Rect.zero);
    });

    test('coordinates are clamped to 0..1', () {
      final back = DrawingStroke.fromJson({
        'tool': 'pen',
        'color': 'D4AF37',
        'width': 0.005,
        'points': [
          [-0.5, 1.7]
        ],
        'rect': [0, 0, 0, 0],
      });
      expect(back.points.first.dx, 0.0);
      expect(back.points.first.dy, 1.0);
    });
  });

  group('drawingWidthForTool', () {
    test('highlighter is widest, pen/rectangle thinnest', () {
      expect(drawingWidthForTool('highlighter'),
          greaterThan(drawingWidthForTool('brush')));
      expect(drawingWidthForTool('brush'),
          greaterThan(drawingWidthForTool('pen')));
      expect(drawingWidthForTool('pen'), drawingWidthForTool('rectangle'));
    });
  });

  group('hitTestStroke (eraser)', () {
    test('point near a segment hits', () {
      final s = penStroke();
      expect(hitTestStroke(s, const Offset(0.2, 0.3), 0.02), isTrue);
    });

    test('far point misses', () {
      final s = penStroke();
      expect(hitTestStroke(s, const Offset(0.9, 0.9), 0.02), isFalse);
    });

    test('point inside rectangle hits, outside misses', () {
      const s = DrawingStroke(
        tool: 'rectangle',
        colorHex: 'D4AF37',
        width: 0.005,
        rect: Rect.fromLTRB(0.2, 0.2, 0.6, 0.6),
      );
      expect(hitTestStroke(s, const Offset(0.4, 0.4), 0.01), isTrue);
      expect(hitTestStroke(s, const Offset(0.9, 0.9), 0.01), isFalse);
    });

    test('single dot stroke hits within tolerance', () {
      const s = DrawingStroke(
        tool: 'pen',
        colorHex: 'D4AF37',
        width: 0.005,
        points: [Offset(0.5, 0.5)],
      );
      expect(hitTestStroke(s, const Offset(0.51, 0.5), 0.02), isTrue);
      expect(hitTestStroke(s, const Offset(0.7, 0.5), 0.02), isFalse);
    });
  });

  group('PageDrawingService', () {
    test('addStroke + strokesFor + hasDrawings', () async {
      final svc = PageDrawingService();
      await svc.init();
      expect(svc.hasDrawings(2), isFalse);
      await svc.addStroke(2, penStroke());
      expect(svc.hasDrawings(2), isTrue);
      expect(svc.strokesFor(2).length, 1);
      expect(svc.hasDrawings(3), isFalse);
    });

    test('removeStrokeAt removes topmost touching stroke', () async {
      final svc = PageDrawingService();
      await svc.init();
      await svc.addStroke(2, penStroke());
      await svc.addStroke(
          2,
          const DrawingStroke(
            tool: 'pen',
            colorHex: 'E53935',
            width: 0.005,
            points: [Offset(0.8, 0.8), Offset(0.9, 0.9)],
          ));
      final removed =
          await svc.removeStrokeAt(2, const Offset(0.85, 0.85), 0.02);
      expect(removed, isTrue);
      expect(svc.strokesFor(2).length, 1);
      expect(svc.strokesFor(2).first.colorHex, 'D4AF37');
      final missed =
          await svc.removeStrokeAt(2, const Offset(0.0, 0.0), 0.02);
      expect(missed, isFalse);
    });

    test('clearPage removes only that page', () async {
      final svc = PageDrawingService();
      await svc.init();
      await svc.addStroke(2, penStroke());
      await svc.addStroke(3, penStroke());
      await svc.clearPage(2);
      expect(svc.hasDrawings(2), isFalse);
      expect(svc.hasDrawings(3), isTrue);
    });

    test('setTool/setColor/exitDrawing notify listeners', () async {
      final svc = PageDrawingService();
      var count = 0;
      svc.addListener(() => count++);
      svc.setTool('highlighter');
      expect(svc.selectedTool, 'highlighter');
      expect(svc.isDrawingMode, isTrue);
      svc.setColor('#e53935');
      expect(svc.selectedColorHex, 'E53935');
      svc.exitDrawing();
      expect(svc.selectedTool, isNull);
      expect(svc.isDrawingMode, isFalse);
      expect(count, 3);
    });

    test('persistence format uses nur_page_drawings key', () async {
      final svc = PageDrawingService();
      await svc.init();
      await svc.addStroke(5, penStroke());
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(PageDrawingService.prefsKey);
      expect(raw, isNotNull);
      // A fresh service instance loads the same strokes back.
      final svc2 = PageDrawingService();
      await svc2.init();
      expect(svc2.strokesFor(5).length, 1);
      expect(svc2.strokesFor(5).first.tool, 'pen');
    });

    test('reload picks up externally changed prefs', () async {
      final svc = PageDrawingService();
      await svc.init();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PageDrawingService.prefsKey, '{"7":[]}');
      await svc.reload();
      expect(svc.hasDrawings(7), isFalse); // empty list stored
      await prefs.setString(PageDrawingService.prefsKey, 'not-json{{{');
      await svc.reload(); // must not throw
    });
  });
}
