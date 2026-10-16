import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' show PointMode, PointerDownEvent, PointerEvent;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../data/quran_data.dart';
import '../main.dart';
import '../data/verse_index.dart';
import '../data/ayah_layout.dart';
import '../services/preferences_service.dart';
import '../services/audio_recitation_service.dart';
import '../services/page_drawing_service.dart';
import '../services/page_image_service.dart';
import 'reader_settings_sheet.dart';

class MushafScreen extends StatefulWidget {
  final int initialPage;
  final VoidCallback? onBackToPreviousTab;
  const MushafScreen(
      {Key? key, this.initialPage = 2, this.onBackToPreviousTab})
      : super(key: key);

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  final List<int> _pageHistory = [];
  late PageController _pageController;
  late int _currentPage;
  final TransformationController _transformController =
      TransformationController();
  // Pinch-zoom / page-swipe arbitration: PageView (page turns) and
  // InteractiveViewer (zoom/pan) fight over the same gestures. Track the
  // zoom scale and the number of pointers down so page turns are disabled
  // while pinching or while zoomed in — drags then pan the zoomed page
  // instead of flipping pages.
  int _pointerCount = 0;
  bool _twoFingerDown = false;
  bool _zoomed = false;
  ScrollController? _scrollController;
  // List width the scroll controller was built for: the scroll item height
  // derives from the width, so on rotation the offset must be re-based.
  double? _scrollViewWidth;
  // Per-page image retry counters: bumping the counter rebuilds the
  // page image loader with a fresh key to retry a failed load.
  final Map<int, int> _imgRetry = {};
  // Pages whose image has fully loaded.
  final Set<int> _loadedPages = {};

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _audio.removeListener(_followAyah);
    _pageController.dispose();
    _scrollController?.dispose();
    _transformController.dispose();
    super.dispose();
  }

  // Cached page -> first 's:v' index (loaded once, used for audio + markRead).
  late final Future<Map<int, String>> _firstVerseIndex;

  // Ayah tap-to-play: per-page ayah segments + verseKey->page index,
  // both loaded once and cached.
  late final Future<Map<int, List<AyahSeg>>> _segmentsFuture;
  late final Future<Map<String, int>> _versePageIndexFuture;
  late final AudioRecitationService _audio;
  bool _followingAyah = false;

  // Pages whose edition page carries a Bismillah (every surah start except
  // At-Tawbah, which has none): only these show the Bismillah cartouche in
  // the top ornament. All other pages get a neutral symmetric ornament, so
  // no decorative Bismillah appears where the edition has none.
  late final Future<Set<int>> _bismillahPagesFuture;
  // Surah number -> first mushaf page, for the Surah/Manzil jump dialogs.
  Map<int, int>? _surahFirstPage;

  // Page drawing (pen/brush/highlighter/rectangle/eraser): the stroke
  // currently being drawn (not yet persisted) and its page.
  DrawingStroke? _inProgressStroke;
  int? _inProgressPage;
  bool _highlightsVisible = true;
  bool _showColorPalette = false;

  static const List<double> _speeds = [0.5, 1.0, 1.25, 1.5, 2.0];
  static const List<int> _repeatModes = [0, 1, 3, 5, -1];
  static const Map<int, String> _repeatLabels = {
    0: 'Off',
    1: '1x',
    3: '3x',
    5: '5x',
    -1: '∞',
  };

  @override
  void initState() {
    super.initState();
    // Track pinch-zoom scale so page turns can be locked while zoomed in.
    _transformController.addListener(_onTransformChanged);
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    _currentPage =
        widget.initialPage > 0 ? widget.initialPage : prefs.lastReadPage;
    // Pages in Mushaf are 1 to 611
    _pageController = PageController(initialPage: _currentPage - 1);
    _firstVerseIndex = loadPageFirstVerseIndex();
    _segmentsFuture = loadPageAyahSegments();
    _versePageIndexFuture = loadVersePageIndex();
    // Derive the Bismillah pages from the segment data: a page shows the
    // Bismillah cartouche iff it contains a surah's first ayah (At-Tawbah
    // has no Bismillah in the edition).
    _bismillahPagesFuture = _segmentsFuture.then((segs) {
      final pages = <int>{};
      segs.forEach((page, list) {
        for (final s in list) {
          if (s.ayah == 1 && s.surah != 9) {
            pages.add(page);
            break;
          }
        }
      });
      return pages;
    });
    // Surah -> first page, for the jump dialogs (via each surah's first ayah).
    _versePageIndexFuture.then((index) {
      final map = <int, int>{};
      for (var s = 1; s <= 114; s++) {
        final p = index['$s:1'];
        if (p != null) map[s] = p;
      }
      if (mounted) setState(() => _surahFirstPage = map);
    });
    _audio = Provider.of<AudioRecitationService>(context, listen: false);
    _audio.addListener(_followAyah);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTapHint());
  }

  void _setCurrentPage(int page) {
    final pageNum = page.clamp(1, totalPagesInMushaf);
    if (pageNum == _currentPage) return;
    setState(() {
      _currentPage = pageNum;
    });
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    prefs.setLastReadPage(pageNum);
    prefs.addReadPage(pageNum);
    _markPageRead(pageNum, prefs);
  }

  void _onPageChanged(int index) {
    _setCurrentPage(index + 1);
    // Reset pinch zoom so the new page opens at normal scale instead of
    // inheriting the previous page's zoom transform.
    try {
      _transformController.value = Matrix4.identity();
    } catch (_) {}
  }

  /// Fires on every transform change during pinch/pan. Only rebuilds when
  /// the zoomed state actually flips (crossing the 1.01 threshold), so
  /// continuous pinch updates don't spam setState.
  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.01;
    if (zoomed != _zoomed) {
      setState(() => _zoomed = zoomed);
    }
  }

  /// A second finger touching down means a pinch is starting: lock page
  /// turns immediately so the gesture goes to the InteractiveViewer
  /// instead of the PageView (this is what makes pinch-zoom respond on
  /// the FIRST attempt instead of after several tries).
  void _onPointerDown(PointerDownEvent _) {
    _pointerCount++;
    if (_pointerCount >= 2 && !_twoFingerDown) {
      setState(() => _twoFingerDown = true);
    }
  }

  /// Finger lifted / cancelled: unlock page turns once fewer than two
  /// pointers remain (unless still zoomed in, which keeps the lock).
  void _onPointerUpOrCancel(PointerEvent _) {
    if (_pointerCount > 0) _pointerCount--;
    if (_pointerCount < 2 && _twoFingerDown) {
      setState(() => _twoFingerDown = false);
    }
  }

  /// Page turns are locked while pinching (2+ fingers), while zoomed in,
  /// or while a drawing tool is active — so drags pan the zoomed page
  /// instead of flipping pages (which also caused the zoomed pages to
  /// visually overlap during a half-finished page transition).
  bool _pageTurnsLocked(bool drawingActive) =>
      drawingActive || _zoomed || _twoFingerDown;

  /// Records last-read surah/ayah/page from the page's first verse.
  Future<void> _markPageRead(int page, PreferencesService prefs) async {
    try {
      final index = await _firstVerseIndex;
      if (!mounted) return;
      final firstVerse = index[page];
      if (firstVerse == null) return;
      final parts = firstVerse.split(':');
      final surah = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 1;
      final ayah = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 1;
      await prefs.markRead(surah: surah, ayah: ayah, page: page);
    } catch (_) {}
  }

  /// When ayah-by-ayah audio is playing, keep the visible page on the
  /// currently playing ayah's page.
  Future<void> _followAyah() async {
    if (_followingAyah || !mounted) return;
    if (!_audio.ayahMode) return;
    final key = '${_audio.currentSurah}:${_audio.currentAyah}';
    final index = await _versePageIndexFuture;
    if (!mounted) return;
    final page = index[key];
    if (page == null || page == _currentPage) return;
    _followingAyah = true;
    try {
      final prefs = Provider.of<PreferencesService>(context, listen: false);
      if (prefs.readingMode == 'scroll') {
        final itemHeight = _scrollItemHeight(context);
        await _scrollController?.animateTo(
          (page - 1) * itemHeight,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else if (_pageController.hasClients) {
        await _pageController.animateToPage(
          page - 1,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    } catch (_) {
    } finally {
      _followingAyah = false;
    }
  }

  /// One-time hint telling the user that ayahs on the page are tappable.
  Future<void> _maybeShowTapHint() async {
    if (!mounted) return;
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    if (prefs.ayahTapHintShown) return;
    try {
      await prefs.setAyahTapHintShown(true);
    } catch (_) {
      return; // SharedPreferences not ready — skip the one-time hint.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            '💡 Kisi bhi ayat par tap karein — woh highlight hogi aur tilawat shuru ho jayegi'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  /// Handles a tap on the page image: hit-tests the ayah segments and
  /// starts ayah-by-ayah audio for the tapped ayah.
  Future<void> _onPageTap(
      BuildContext tapCtx, TapUpDetails details, int pageNum) async {
    final box = tapCtx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final local = box.globalToLocal(details.globalPosition);
    // Map the tap to the true rendered image rect (letterbox-aware).
    final img = _imageRect(box.size.width, box.size.height);
    final fx = ((local.dx - img.dx) / img.w).clamp(0.0, 1.0);
    final fy = ((local.dy - img.dy) / img.h).clamp(0.0, 1.0);
    final segsMap = await _segmentsFuture;
    if (!mounted) return;
    final hit =
        hitTestAyah(segsMap[pageNum] ?? const <AyahSeg>[], fx, fy, pageNum);
    if (hit == null) return;
    final ok = await _audio.playAyah(surah: hit.surah, ayah: hit.ayah);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio nahi chal saka — internet check karein'),
        ),
      );
    }
  }

  /// Plays Bismillah (ayah 0) for the surah that starts on [pageNum].
  Future<void> _playBismillahForPage(int pageNum) async {
    final segsMap = await _segmentsFuture;
    final segs = segsMap[pageNum] ?? const <AyahSeg>[];
    for (final s in segs) {
      if (s.surah == 1 && s.ayah == 1) {
        final ok = await _audio.playAyah(surah: 1, ayah: 1);
        if (!ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Audio nahi chal saka — internet check karein'),
            ),
          );
        }
        return;
      }
      if (s.ayah == 0 && s.surah != 9) {
        final ok = await _audio.playAyah(surah: s.surah, ayah: 0);
        if (!ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Audio nahi chal saka — internet check karein'),
            ),
          );
        }
        return;
      }
    }
  }

  // ------------------------------------------------------------------
  // Page drawing tools (📜 menu): pen / brush / highlighter / rectangle /
  // eraser. Strokes are stored as fractions of the image box so they
  // scale with any screen size.
  // ------------------------------------------------------------------

  String _toolLabel(String tool) {
    switch (tool) {
      case 'rectangle':
        return 'Rectangle';
      case 'pen':
        return 'Pen';
      case 'highlighter':
        return 'Highlighter';
      case 'brush':
        return 'Brush';
      case 'eraser':
        return 'Eraser';
      default:
        return tool;
    }
  }

  IconData _toolIcon(String? tool) {
    switch (tool) {
      case 'rectangle':
        return Icons.crop_square;
      case 'pen':
        return Icons.edit;
      case 'brush':
        return Icons.brush;
      case 'eraser':
        return Icons.cleaning_services;
      case 'highlighter':
      default:
        return Icons.highlight;
    }
  }

  /// Paint layer for persisted + in-progress drawing strokes.
  Widget _buildDrawingPaint(int pageNum) {
    if (!_highlightsVisible) return const SizedBox.shrink();
    return Positioned.fill(
      child: Consumer<PageDrawingService>(
        builder: (context, draw, _) {
          final strokes = draw.strokesFor(pageNum);
          final inProgress =
              (_inProgressPage == pageNum) ? _inProgressStroke : null;
          if (strokes.isEmpty && inProgress == null) {
            return const SizedBox.shrink();
          }
          final prefs = Provider.of<PreferencesService>(context, listen: false);
          return CustomPaint(
            painter: _PageDrawingPainter(
              [
                ...strokes,
                if (inProgress != null) inProgress,
              ],
              isNightMode: prefs.nightPageMode,
            ),
          );
        },
      ),
    );
  }

  /// Chip shown while a drawing tool is active: tool name + X to exit.
  Widget _buildDrawingModeChip() {
    return Consumer<PageDrawingService>(
      builder: (context, draw, _) {
        final tool = draw.selectedTool;
        if (tool == null || tool == 'highlighter') return const SizedBox.shrink();
        final cs = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        // Floating overlay chip: dark in light mode, theme surface in dark
        // mode, so it stays readable over both the white and inverted page.
        final chipBg = isDark
            ? cs.surface
            : Color.lerp(cs.surface, Colors.black, 0.72)!;
        final chipFg = isDark ? cs.onSurface : cs.surface;
        return Positioned(
          top: 8,
          right: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: Nur.s8, vertical: Nur.s4),
                decoration: BoxDecoration(
                  color: chipBg.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(Nur.radiusMd),
                ),
                child: Text(
                  _toolLabel(tool),
                  style: TextStyle(
                      color: chipFg,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: Nur.s4),
              Material(
                color: chipBg.withValues(alpha: 0.92),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    _cancelInProgress();
                    draw.exitDrawing();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(Nur.s16),
                    child: Icon(Icons.close, color: chipFg, size: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _cancelInProgress() {
    if (_inProgressStroke != null || _inProgressPage != null) {
      setState(() {
        _inProgressStroke = null;
        _inProgressPage = null;
      });
    }
  }

  /// Converts a global pointer position to fraction coordinates (0..1)
  /// of the page image box.
  Offset _toFraction(BuildContext tapCtx, Offset globalPosition) {
    final box = tapCtx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.width <= 0) {
      return const Offset(-1, -1);
    }
    final local = box.globalToLocal(globalPosition);
    // Store drawing strokes as fractions of the true rendered image rect
    // (letterbox-aware) so they stay glued to the text.
    final img = _imageRect(box.size.width, box.size.height);
    return Offset(
      ((local.dx - img.dx) / img.w).clamp(0.0, 1.0),
      ((local.dy - img.dy) / img.h).clamp(0.0, 1.0),
    );
  }

  void _onDrawStart(BuildContext tapCtx, DragStartDetails d, int pageNum,
      PageDrawingService draw) {
    final tool = draw.selectedTool;
    if (tool == null) return;
    if (tool == 'eraser') {
      _onEraseAt(tapCtx, d.globalPosition, pageNum, draw);
      return;
    }
    // Highlighter is freehand like pen/brush: the stroke follows the finger
    // path exactly (no whole-ayah auto-highlight).
    final f = _toFraction(tapCtx, d.globalPosition);
    if (f.dx < 0) return;
    setState(() {
      _inProgressPage = pageNum;
      _inProgressStroke = DrawingStroke(
        tool: tool,
        colorHex: draw.selectedColorHex,
        width: drawingWidthForTool(tool),
        points: tool == 'rectangle' ? const [] : [f],
        rect: tool == 'rectangle' ? Rect.fromPoints(f, f) : Rect.zero,
      );
    });
  }

  void _onDrawUpdate(BuildContext tapCtx, DragUpdateDetails d, int pageNum,
      PageDrawingService draw) {
    final tool = draw.selectedTool;
    if (tool == null) return;
    if (tool == 'eraser') {
      _onEraseAt(tapCtx, d.globalPosition, pageNum, draw);
      return;
    }
    // Highlighter appends freehand points like pen/brush.
    final cur = _inProgressStroke;
    if (cur == null || _inProgressPage != pageNum || cur.tool != tool) return;
    final f = _toFraction(tapCtx, d.globalPosition);
    if (f.dx < 0) return;
    setState(() {
      if (tool == 'rectangle') {
        _inProgressStroke =
            cur.copyWith(rect: Rect.fromPoints(cur.rect.topLeft, f));
      } else {
        _inProgressStroke = cur.copyWith(points: [...cur.points, f]);
      }
    });
  }

  Future<void> _onDrawEnd(int pageNum, PageDrawingService draw) async {
    final s = _inProgressStroke;
    final p = _inProgressPage;
    _inProgressStroke = null;
    _inProgressPage = null;
    if (s == null || p != pageNum) {
      if (mounted) setState(() {});
      return;
    }
    await draw.addStroke(pageNum, s);
    if (mounted) setState(() {});
  }

  Future<void> _onEraseAt(BuildContext tapCtx, Offset globalPosition,
      int pageNum, PageDrawingService draw) async {
    final f = _toFraction(tapCtx, globalPosition);
    if (f.dx < 0) return;
    final removed = await draw.removeStrokeAt(pageNum, f, 0.025);
    if (removed && mounted) setState(() {});
  }

  /// Bottom sheet 1: Color | Highlighter | Notes | Clear.
  void _showDrawingMenu(int pageNum) {
    final cs = Theme.of(context).colorScheme;
    final draw = Provider.of<PageDrawingService>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Nur.cardRadius)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: Nur.s20, horizontal: Nur.s8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _drawingMenuItem(
                  sheetCtx, Icons.palette, draw.selectedColor, 'Color', () {
                Navigator.pop(sheetCtx);
                _showColorRow();
              }),
              _drawingMenuItem(
                  sheetCtx, Icons.highlight, const Color(0xFFD4AF37), 'Highlighter', () {
                Navigator.pop(sheetCtx);
                draw.setTool('highlighter');
              }),
              _drawingMenuItem(sheetCtx, Icons.note_alt_outlined, cs.primary, 'Notes',
                  () {
                Navigator.pop(sheetCtx);
                _showPageNoteDialog(pageNum);
              }),
              _drawingMenuItem(
                  sheetCtx, Icons.delete_outline, cs.primary, 'Clear', () {
                Navigator.pop(sheetCtx);
                _confirmClearPage(pageNum);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawingMenuItem(BuildContext sheetCtx, IconData icon, Color color,
      String label, VoidCallback onTap) {
    final cs = Theme.of(sheetCtx).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(Nur.buttonRadius),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Nur.s16, vertical: Nur.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: Nur.iconSizeLg),
            const SizedBox(height: Nur.s4),
            Text(label, style: TextStyle(color: cs.onSurface, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  /// Color picker row (6 colors); picking one selects the color and enters highlighter mode.
  void _showColorRow() {
    final cs = Theme.of(context).colorScheme;
    final draw = Provider.of<PageDrawingService>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Nur.cardRadius)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: Nur.s20, horizontal: Nur.s16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final hex in PageDrawingService.paletteHexes)
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    draw.setColor(hex);
                    draw.setTool('highlighter');
                    Navigator.pop(sheetCtx);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: PageDrawingService.parseHex(hex),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: draw.selectedColorHex == hex
                            ? cs.primary
                            : Colors.black26,
                        width: draw.selectedColorHex == hex ? 3 : 1.5,
                      ),
                    ),
                    child: draw.selectedColorHex == hex
                        ? const Icon(Icons.check, size: 22, color: Colors.black87)
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom sheet 2: the 5 drawing tools (3 + 2 grid like the reference).
  void _showToolSheet() {
    final cs = Theme.of(context).colorScheme;
    final draw = Provider.of<PageDrawingService>(context, listen: false);
    final tools = <List<dynamic>>[
      ['rectangle', Icons.crop_square, 'Rectangle'],
      ['pen', Icons.edit, 'Pen'],
      ['highlighter', Icons.highlight, 'Highlighter'],
      ['brush', Icons.brush, 'Brush'],
      ['eraser', Icons.cleaning_services, 'Eraser'],
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Nur.cardRadius)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              Nur.s16, Nur.s12, Nur.s16, Nur.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Drawing Tools',
                        style: TextStyle(
                            color: cs.onSurface,
                            fontSize: Nur.fontTitle,
                            fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: cs.onSurface),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (final t in tools)
                    _toolButton(
                      sheetCtx,
                      t[0] as String,
                      t[1] as IconData,
                      t[2] as String,
                      () {
                        _cancelInProgress();
                        draw.setTool(t[0] as String);
                        Navigator.pop(sheetCtx);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolButton(BuildContext sheetCtx, String id, IconData icon,
      String label, VoidCallback onTap) {
    final cs = Theme.of(sheetCtx).colorScheme;
    final draw = Provider.of<PageDrawingService>(sheetCtx, listen: false);
    final selected = draw.selectedTool == id;
    return InkWell(
      borderRadius: BorderRadius.circular(Nur.cardRadius),
      onTap: onTap,
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: Nur.s16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Nur.cardRadius),
          border: Border.all(
            color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.25),
            width: selected ? 2 : 1,
          ),
          color: selected ? cs.primary.withValues(alpha: 0.12) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: selected
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.75),
                size: Nur.iconSizeLg),
            const SizedBox(height: Nur.s4),
            Text(label,
                style: TextStyle(
                    color: selected ? cs.primary : cs.onSurface,
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  /// Page note dialog (uses the existing pageNotes storage).
  void _showPageNoteDialog(int pageNum) {
    final cs = Theme.of(context).colorScheme;
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    final controller =
        TextEditingController(text: prefs.pageNotes['$pageNum'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Nur.radiusLg)),
        title:
            Text('Page $pageNum note', style: TextStyle(color: cs.onSurface)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: TextStyle(color: cs.onSurface),
          decoration: InputDecoration(
            hintText: 'Write a note for this page…',
            hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Nur.buttonRadius),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
            ),
            onPressed: () async {
              await prefs.setPageNote(pageNum, controller.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  /// Clears both drawings and the note for this page (with confirm).
  void _confirmClearPage(int pageNum) {
    final cs = Theme.of(context).colorScheme;
    final draw = Provider.of<PageDrawingService>(context, listen: false);
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    final hasNote = (prefs.pageNotes['$pageNum'] ?? '').isNotEmpty;
    if (!draw.hasDrawings(pageNum) && !hasNote) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to clear on this page')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Nur.radiusLg)),
        title:
            Text('Clear page markings?', style: TextStyle(color: cs.onSurface)),
        content: Text(
          'This removes all drawings and the note for page $pageNum.',
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              _cancelInProgress();
              draw.exitDrawing();
              await draw.clearPage(pageNum);
              await prefs.setPageNote(pageNum, null);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  String _speedLabel(double v) =>
      v == v.roundToDouble() ? '${v.toInt()}x' : '${v}x';

  void _cycleSpeed() {
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    final audio = Provider.of<AudioRecitationService>(context, listen: false);
    final next =
        _speeds[(_speeds.indexOf(prefs.playbackSpeed) + 1) % _speeds.length];
    audio.setSpeed(next);
    prefs.setPlaybackSpeed(next);
  }

  void _cycleRepeat() {
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    final audio = Provider.of<AudioRecitationService>(context, listen: false);
    final next = _repeatModes[
        (_repeatModes.indexOf(prefs.repeatMode) + 1) % _repeatModes.length];
    audio.setRepeatMode(next);
    prefs.setRepeatMode(next);
  }

  /// One control-bar button: a guaranteed 48dp minimum touch target with
  /// a generous ink splash, regardless of the icon/label size inside.
  Widget _barControl({required VoidCallback onTap, required Widget child}) {
    return InkWell(
      borderRadius: BorderRadius.circular(Nur.buttonRadius),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
            minWidth: Nur.minTouchTarget, minHeight: Nur.minTouchTarget),
        child: Center(child: child),
      ),
    );
  }

  /// Subtle circular page-navigation button with a guaranteed 48dp touch
  /// target. Translucent so the page shows through; dimmed at the bounds.
  Widget _pageNavButton({
    required IconData icon,
    required String tooltip,
    required bool enabled,
    required Color buttonColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Opacity(
      opacity: enabled ? 0.92 : 0.28,
      child: Material(
        color: buttonColor.withValues(alpha: 0.78),
        // Hairline outline keeps the chevron legible over the page
        // without a heavy shadow.
        shape: CircleBorder(
          side: BorderSide(
            color: iconColor.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
                minWidth: Nur.minTouchTarget, minHeight: Nur.minTouchTarget),
            child: Center(
              child: Tooltip(
                message: tooltip,
                child: Icon(icon, color: iconColor, size: Nur.iconSizeLg),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the reader settings bottom sheet (3-dot menu).
  void _showReaderSettings(BuildContext context) {
    showReaderSettingsSheet(
      context,
      onJumpToPage: _jumpToPage,
      surahFirstPage: _surahFirstPage,
    );
  }

  /// Jumps directly to any page in the Mushaf (1..611) across all reading modes.
  void _jumpToPage(int page, {bool recordHistory = true}) {
    final target = page.clamp(1, totalPagesInMushaf);
    if (recordHistory && target != _currentPage) {
      _pageHistory.add(_currentPage);
    }
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    if (prefs.readingMode == 'scroll') {
      final itemHeight = _scrollItemHeight(context);
      _scrollController?.jumpTo((target - 1) * itemHeight);
    } else if (_pageController.hasClients) {
      _pageController.jumpToPage(target - 1);
    }
    _setCurrentPage(target);
  }

  /// Handles back navigation from the reader:
  /// 1. If drawing tool is active -> exits drawing mode.
  /// 2. If page jump history exists -> returns to previous page.
  /// 3. If pushed onto Navigator (from Bookmarks, Search, Juz Index) -> pops route.
  /// 4. If bottom tab in HomeNavigationScreen -> returns to previous tab.
  void _handleBack() {
    final draw = Provider.of<PageDrawingService>(context, listen: false);
    if (draw.isDrawingMode) {
      _cancelInProgress();
      setState(() {
        _showColorPalette = false;
      });
      draw.exitDrawing();
      return;
    }

    if (_pageHistory.isNotEmpty) {
      final prevPage = _pageHistory.removeLast();
      _jumpToPage(prevPage, recordHistory: false);
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    if (widget.onBackToPreviousTab != null) {
      widget.onBackToPreviousTab!();
    }
  }

  /// Toggles recitation of the Surah on the current page.
  Future<void> _onPlayPausePressed() async {
    final audio = Provider.of<AudioRecitationService>(context, listen: false);
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    if (audio.isPlaying) {
      await audio.pause();
      return;
    }
    // Resume a paused track where it left off instead of restarting the
    // surah from the beginning. A paused player reports ready with its
    // source still loaded; a stopped/finished one does not, and falls
    // through to a fresh start below.
    final player = audio.player;
    if (!player.playing &&
        player.processingState == ProcessingState.ready &&
        player.audioSource != null) {
      await audio.resume();
      return;
    }
    final index = await _firstVerseIndex;
    if (!mounted) return;
    final firstVerse = index[_currentPage];
    var surah = 1;
    if (firstVerse != null) {
      surah = int.tryParse(firstVerse.split(':').first) ?? 1;
    }
    audio.setRepeatMode(prefs.repeatMode);
    await audio.setSpeed(prefs.playbackSpeed);
    await audio.playSurah(surahNumber: surah);
  }

  /// Height of one page item in scroll mode. The item sizes to its
  /// content: the SafeArea top inset, the fixed-height top/bottom
  /// ornaments, the page image at its exact aspect ([_kPageAspect]) at
  /// full list width, and the control-bar clearance spacer — so the scroll
  /// math must use the full width (not width minus margins) or jump
  /// targets drift further off with every page.
  double _scrollItemHeight(BuildContext context) {
    final mq = MediaQuery.of(context);
    final orn = _ornamentHeights(context);
    return mq.padding.top +
        orn.top +
        mq.size.width / _kPageAspect +
        orn.bottom +
        orn.spacer +
        mq.padding.bottom;
  }

  /// The page image (with night tint overlay), without the InteractiveViewer
  /// wrapper. The reader is decorated top and bottom: a Bismillah cartouche
  /// above the page where the edition carries one (a neutral symmetric gold
  /// ornament elsewhere) and the Manzil badge below, over a rich golden
  /// arabesque pattern — so the screen never looks empty. The image box
  /// keeps the exact page-image aspect (_kPageAspect) so ayah tap
  /// coordinates map 1:1 to the image.
  ///
  /// In scroll mode ([scrollMode]) the column height is unbounded, so the
  /// image box sizes purely from the list width (exact aspect) and the
  /// fixed-height ornaments frame it — the decorated page is never forced
  /// into a fixed AspectRatio, which used to squeeze the image box.
  Widget _buildPageImage(BuildContext context, int pageNum,
      {bool scrollMode = false}) {
    // Night theme: gently darken the white page so it doesn't strain the
    // eyes. Only the page image is filtered, not the highlight/drawing
    // overlays painted above it.
    final nightDim = Theme.of(context).brightness == Brightness.dark;
    // Night page mode: invert the page image (black background, white
    // text) for comfortable reading at night. Persisted toggle in
    // PreferencesService; only the page image is filtered, never the
    // highlight/drawing overlays painted above it.
    final nightPage =
        Provider.of<PreferencesService>(context, listen: false).nightPageMode;
    final cs = Theme.of(context).colorScheme;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    // Theme gold token: primary in Night Slate, secondary in the light themes.
    final gold = isDarkTheme ? cs.primary : cs.secondary;
    // Orientation-aware ornament heights: hidden in landscape so the page
    // gets the full height; full royal framing in portrait.
    final orn = _ornamentHeights(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    // Royal golden background derived from the theme tokens (never
    // hardcoded): a luminous gold wash in light mode, a deep bronze in dark
    // mode. Night page mode stays pure black. The wash blends with the page
    // edges so tall screens never show an empty-looking gap.
    final bgDecoration = nightPage
        ? const BoxDecoration(color: Colors.black)
        : BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: nightDim
                  ? [
                      Color.lerp(gold, Colors.black, 0.74)!,
                      Color.lerp(gold, Colors.black, 0.62)!,
                      Color.lerp(gold, Colors.black, 0.74)!,
                    ]
                  : [
                      Color.lerp(gold, cs.surface, 0.60)!,
                      Color.lerp(gold, cs.surface, 0.70)!,
                      Color.lerp(gold, cs.surface, 0.58)!,
                    ],
            ),
          );
    return SafeArea(
      bottom: false,
      child: Container(
        // Seamless page background: on tall screens the area around the page
        // blends with the page instead of looking like an empty gap.
        decoration: bgDecoration,
        child: CustomPaint(
          painter: _OrnamentPatternPainter(
            pattern: nightPage
                ? Colors.white
                : (nightDim
                    ? Color.lerp(gold, Colors.black, 0.30)!
                    : Color.lerp(gold, Colors.black, 0.28)!),
          ),
          child: Column(
            children: [
              if (orn.top > 0)
                SizedBox(
                  // Fixed ornament heights: scroll-mode items size to their
                  // content, so these must be exact — _scrollItemHeight
                  // depends on them.
                  height: orn.top,
                  child: _buildTopOrnament(pageNum),
                ),
              // The page-image box keeps the exact page aspect in both
              // modes: in scroll mode the column height is unbounded, so
              // the box sizes purely from the list width instead of being
              // squeezed by the ornaments inside a fixed AspectRatio.
              // In landscape the box is likewise width-driven (the page
              // is taller than the screen and pans vertically).
              _buildImageBox(
                scrollMode,
                isLandscape,
                Stack(
                  children: [
                Positioned.fill(
                  child: ColorFiltered(
                    colorFilter: nightPage
                        ? const ColorFilter.matrix(_kInvertMatrix)
                        : ColorFilter.mode(
                            Colors.black
                                .withValues(alpha: nightDim ? 0.22 : 0.0),
                            BlendMode.darken,
                          ),
                    child: _ResilientPageImage(
                      key: ValueKey(
                          'mushaf-page-$pageNum-${_imgRetry[pageNum] ?? 0}'),
                      pageNum: pageNum,
                      onLoaded: () => _loadedPages.add(pageNum),
                      onRetry: () => setState(() {
                        _imgRetry[pageNum] = (_imgRetry[pageNum] ?? 0) + 1;
                      }),
                    ),
                  ),
                ),
                // Currently playing ayah highlight (ayah-by-ayah audio mode).
                _buildAyahHighlights(pageNum),
                // Freehand page drawings (pen/brush/highlighter/rectangle).
                // Paint sits below the gesture layer.
                _buildDrawingPaint(pageNum),
                // Page gesture layer: ayah tap-to-play normally, drawing
                // gestures while a drawing tool is active. LAST among the
                // full-page layers so it sits above the paint.
                // Translucent: taps pass through visually but are still caught.
                Positioned.fill(
                  child: Builder(
                    builder: (tapCtx) => Consumer<PageDrawingService>(
                      builder: (context, draw, _) {
                        if (draw.selectedTool == null) {
                          return GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTapUp: (d) => _onPageTap(tapCtx, d, pageNum),
                            child: Container(color: Colors.transparent),
                          );
                        }
                        return GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onPanStart: (d) =>
                              _onDrawStart(tapCtx, d, pageNum, draw),
                          onPanUpdate: (d) =>
                              _onDrawUpdate(tapCtx, d, pageNum, draw),
                          onPanEnd: (_) => _onDrawEnd(pageNum, draw),
                          onTapUp: draw.selectedTool == 'eraser'
                              ? (d) => _onEraseAt(
                                  tapCtx, d.globalPosition, pageNum, draw)
                              : null,
                          child: Container(color: Colors.transparent),
                        );
                      },
                    ),
                  ),
                ),
                // Drawing-mode indicator + exit chip.
                // (The 📜 per-page button was replaced by the screen-level
                // floating note button, bottom-left like the reference design.)
                _buildDrawingModeChip(),
                  ],
                ),
              ),
              if (orn.bottom > 0)
                SizedBox(
                  height: orn.bottom,
                  child: Center(child: _buildBottomOrnament(pageNum)),
                ),
              // Reserve space for the overlaying bottom control bar so the
              // Manzil badge isn't hidden behind it (portrait only;
              // landscape hides the bottom ornament).
              SizedBox(
                height: orn.spacer +
                    MediaQuery.of(context).padding.bottom,
              ),
            ],
          ),
  ),
  ),
);
  }

  /// Wraps the page-image [stack] in a box with the exact page aspect.
  /// In scroll mode the column height is unbounded, so the box sizes
  /// purely from the list width (never squeezed); otherwise Expanded
  /// fills the leftover column space as before. In landscape slide/turn
  /// mode the InteractiveViewer is unconstrained (constrained: false),
  /// so a bare AspectRatio collapses to zero — its Stack child has no
  /// intrinsic size — and the page VANISHES. Pin the box to the
  /// SafeArea-adjusted screen width so it gets a real size; the tall
  /// page then pans vertically inside the InteractiveViewer.
  Widget _buildImageBox(bool scrollMode, bool landscape, Widget stack) {
    final box = AspectRatio(aspectRatio: _kPageAspect, child: stack);
    if (landscape && !scrollMode) {
      final mq = MediaQuery.of(context);
      final w = mq.size.width - mq.padding.left - mq.padding.right;
      return SizedBox(width: w, height: w / _kPageAspect, child: stack);
    }
    return scrollMode ? box : Expanded(child: box);
  }

  /// Ornamental header above the page. Pages whose edition page carries a
  /// Bismillah (surah starts, except At-Tawbah) show the royal Bismillah
  /// cartouche; every other page shows a neutral symmetric gold ornament —
  /// never a decorative Bismillah where the edition has none. Both are
  /// centered in the same fixed-height box for consistent positioning.
  Widget _buildTopOrnament(int pageNum) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? cs.primary : cs.secondary;
    return FutureBuilder<Set<int>>(
      future: _bismillahPagesFuture,
      builder: (context, snap) {
        // Safe default while loading: the neutral ornament (never flash a
        // Bismillah where it doesn't belong).
        final hasBismillah = snap.data?.contains(pageNum) ?? false;
        return Column(
          // Fill the fixed-height ornament box so the cartouche / neutral
          // ornament stays vertically centered with balanced margins.
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasBismillah)
              _BismillahHeader(
                onTap: () => _playBismillahForPage(pageNum),
              )
            else
              _NeutralTopOrnament(gold: gold),
            const SizedBox(height: 5),
            // Subtle ornamental transition rule connecting banner to page.
            _HairlineRule(gold: gold),
          ],
        );
      },
    );
  }

  /// Ornamental footer below the page: a thin golden divider tying the
  /// footer to the header, plus the Manzil badge in a golden frame.
  Widget _buildBottomOrnament(int pageNum) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? cs.primary : cs.secondary;
    return FutureBuilder<Map<int, String>>(
      future: _firstVerseIndex,
      builder: (context, snap) {
        var manzil = 1;
        final fv = snap.data?[pageNum];
        if (fv != null) {
          final s = int.tryParse(fv.split(':').first);
          if (s != null) manzil = _manzilForSurah(s);
        }
        return Column(
          // Fill the fixed-height ornament box for balanced margins.
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Thin golden divider tying the footer to the royal header.
            _HairlineRule(gold: gold, horizontalMargin: 72),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Center(child: _ManzilBadge(manzil: manzil)),
            ),
          ],
        );
      },
    );
  }

  /// The 7 manazil of the Quran by surah number.
  int _manzilForSurah(int surah) {
    if (surah <= 4) return 1;
    if (surah <= 9) return 2;
    if (surah <= 16) return 3;
    if (surah <= 25) return 4;
    if (surah <= 36) return 5;
    return surah <= 49 ? 6 : 7;
  }

  /// Ornament heights framing the page image. In portrait the royal
  /// golden framing (cartouche / Manzil badge / control-bar spacer) is
  /// kept. In landscape the screen is short, so the decorative ornaments
  /// are hidden to give the page the full height — the Quran text itself
  /// lives inside the page image, so nothing sacred is lost. The page
  /// then fills the screen width with large, readable text.
  ({double top, double bottom, double spacer}) _ornamentHeights(
      BuildContext context) {
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      return (top: 0.0, bottom: 0.0, spacer: 0.0);
    }
    return (
      top: _kTopOrnamentHeight,
      bottom: _kBottomOrnamentHeight,
      spacer: _kBottomSpacerHeight,
    );
  }

  /// True aspect ratio of the bundled page images (720x1080).
  static const double _kPageAspect = 2 / 3;

  /// Fixed ornament heights (px) framing the page image. Scroll-mode items
  /// size to their content, so these must stay exact: [_scrollItemHeight]
  /// adds them to the width-derived image height for the scroll math.
  /// Top: Bismillah cartouche (surah-start pages) or the neutral symmetric
  /// ornament (all other pages) + transition rule, centered in the box.
  static const double _kTopOrnamentHeight = 96.0;

  /// Bottom: 2px divider + Manzil badge + padding, centered in a fixed box.
  static const double _kBottomOrnamentHeight = 64.0;

  /// Spacer reserving room for the overlaying bottom control bar.
  static const double _kBottomSpacerHeight = 76.0;

  /// Color matrix that inverts the mushaf page image for night page mode:
  /// white page -> black background, black text -> white. Only the page
  /// image is filtered, never the highlight/drawing overlays above it.
  static const List<double> _kInvertMatrix = <double>[
    -1, 0, 0, 0, 255,
    0, -1, 0, 0, 255,
    0, 0, -1, 0, 255,
    0, 0, 0, 1, 0,
  ];

  /// Page images are rendered with BoxFit.contain. When the overlay box
  /// aspect differs from the image aspect, the image is letterboxed — this
  /// returns the true rendered image rect within a boxW x boxH box, so
  /// highlights, taps and drawings map 1:1 to the image content.
  static ({double dx, double dy, double w, double h}) _imageRect(
      double boxW, double boxH) {
    if (boxW / boxH > _kPageAspect) {
      final h = boxH, w = boxH * _kPageAspect;
      return (dx: (boxW - w) / 2, dy: 0.0, w: w, h: h);
    }
    final w = boxW, h = boxW / _kPageAspect;
    return (dx: 0.0, dy: (boxH - h) / 2, w: w, h: h);
  }

  /// Website-exact ayah highlight (visible only while ayah-by-ayah audio is
  /// active): a thin gold band (15px equivalent, vertically centered on the
  /// line row, no border) that fills right-to-left with the audio progress,
  /// just like `.ayah-segment.playing` on the 15-line Quran website.
  Widget _buildAyahHighlights(int pageNum) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final audio = Provider.of<AudioRecitationService>(context);
        final prefs = Provider.of<PreferencesService>(context);
        // Audio Mode toggle: when off, no ayah highlighting follows audio.
        if (!audio.ayahMode || !prefs.audioHighlightEnabled) {
          return const SizedBox.shrink();
        }
        return FutureBuilder<Map<int, List<AyahSeg>>>(
          future: _segmentsFuture,
          builder: (context, snap) {
            final segs = snap.data?[pageNum] ?? const <AyahSeg>[];
            final ayahSegs = segs
                .where((s) =>
                    s.surah == audio.currentSurah &&
                    s.ayah == audio.currentAyah)
                .toList()
              ..sort((a, b) => a.line.compareTo(b.line));
            if (ayahSegs.isEmpty) return const SizedBox.shrink();
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            // The image may be letterboxed inside the box (BoxFit.contain);
            // map highlight coordinates to the true rendered image rect.
            final img = _imageRect(w, h);
            final isDark = Theme.of(context).brightness == Brightness.dark;
            // Website gold: light rgba(212,175,55,0.45), dark rgba(240,205,95,0.50).
            final gold = isDark
                ? const Color.fromRGBO(240, 205, 95, 0.50)
                : const Color.fromRGBO(212, 175, 55, 0.45);
            // Ayah-confined highlight: each line-band covers ONLY the tapped
            // ayah's own words on that line (its segment extent) — from where
            // the ayah starts to where it ends — at full line height, filling
            // right-to-left with the audio progress. Never the full text
            // width: neighbouring ayahs on the same line must stay unlit.
            return StreamBuilder<double>(
              stream: audio.ayahProgressStream,
              initialData: 0.0,
              builder: (context, progSnap) {
                final progress = (progSnap.data ?? 0.0).clamp(0.0, 1.0);
                // Website progress distribution: segments fill in line order,
                // weighted by width (min 5), each filling right-to-left.
                // Every segment's [start, end) progress window is precomputed
                // here. Never mutate shared state inside the Builder closures
                // below: their build order is not guaranteed, and a shared
                // accumulator assigned wrong windows to segments — lighting
                // up the wrong lines out of order (first line dark while
                // later lines filled).
                final weights = ayahSegs.map((s) => max(5.0, s.width)).toList();
                final total = weights.fold(0.0, (a, b) => a + b);
                final windows = <List<double>>[];
                double acc = 0;
                for (final w in weights) {
                  final startFrac = acc / total;
                  acc += w;
                  windows.add([startFrac, acc / total]);
                }
                return IgnorePointer(
                  child: Stack(
                    children: [
                      for (int i = 0; i < ayahSegs.length; i++)
                        Builder(builder: (context) {
                          final seg = ayahSegs[i];
                          final startFrac = windows[i][0];
                          final endFrac = windows[i][1];
                          double segProg;
                          if (progress >= endFrac) {
                            segProg = 1.0;
                          } else if (progress <= startFrac) {
                            segProg = 0.0;
                          } else {
                            segProg =
                                (progress - startFrac) / (endFrac - startFrac);
                          }
                          final r = rectForSeg(seg, pageNum);
                          final rw = r.width * img.w;
                          return Positioned(
                            left: img.dx + r.left * img.w,
                            top: img.dy + r.top * img.h,
                            width: rw,
                            height: r.height * img.h,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: Stack(
                                children: [
                                  // RTL fill: gold grows from the right edge
                                  // of the ayah's own words on this line.
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    bottom: 0,
                                    width: rw * segProg.clamp(0.0, 1.0),
                                    child: Container(color: gold),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Per-page widget reused by both reading modes. In scroll mode the page
  /// is non-interactive (no pinch zoom) so the list can scroll.
  Widget _buildPageItem(BuildContext context, int pageNum,
      {bool interactive = true}) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final pageImage = _buildPageImage(context, pageNum, scrollMode: !interactive);
    if (!interactive) {
      // Scroll mode: the item sizes to its content (fixed-height ornaments
      // + the page image at its exact aspect) — never force the decorated
      // page into a fixed AspectRatio, which squeezed the image box.
      return pageImage;
    }
    // While a drawing tool is active, pinch/pan zoom is disabled so draw
    // gestures are not stolen by the InteractiveViewer.
    final drawingActive =
        Provider.of<PageDrawingService>(context).isDrawingMode;
    return InteractiveViewer(
      transformationController: _transformController,
      minScale: 1.0,
      maxScale: 3.5,
      // Generous boundary margin so a zoomed page can be panned freely
      // without its edges sticking at the viewport (which felt like the
      // page was refusing to move and letters were cut off).
      boundaryMargin: const EdgeInsets.all(80),
      // Landscape: the page is taller than the screen (width-driven), so
      // the child must NOT be forced to viewport size — panning scrolls
      // through the page vertically. Portrait: the page fits, so
      // constrain it to the viewport as before.
      constrained: !isLandscape,
      // Landscape: start at the top of the page (like the reference
      // video), not centered (which would cut off top and bottom).
      alignment: isLandscape ? Alignment.topCenter : Alignment.center,
      panEnabled: !drawingActive,
      scaleEnabled: !drawingActive,
      child: pageImage,
    );
  }

  /// Lightweight page-turn reading mode: the same PageView as slide mode,
  /// but each page gets a subtle 3D flip driven by the drag offset.
  /// Purposefully modest (no heavy curl shader) so it stays smooth on
  /// mid-range devices; slide mode remains the fallback.
  Widget _buildTurnView(BuildContext context) {
    // Page swipes are disabled while drawing so strokes are not
    // interrupted by page changes.
    final drawingActive =
        Provider.of<PageDrawingService>(context).isDrawingMode;
    return Listener(
      // Pointer tracking for pinch-zoom arbitration: a second finger
      // locks page turns so the pinch reaches the InteractiveViewer.
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUpOrCancel,
      onPointerCancel: _onPointerUpOrCancel,
      child: PageView.builder(
        controller: _pageController,
        reverse: true, // RTL for Mushaf reading
        physics:
            _pageTurnsLocked(drawingActive) ? const NeverScrollableScrollPhysics() : null,
        itemCount: totalPagesInMushaf,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) => AnimatedBuilder(
        animation: _pageController,
        builder: (context, child) {
          double t = 0.0;
          if (_pageController.position.haveDimensions) {
            t = (_pageController.page! - index).clamp(-1.0, 1.0);
          }
          // Gentle flip: rotate around the vertical axis with perspective,
          // slightly shrinking the page mid-turn.
          final angle = -t * 0.55;
          final scale = 1.0 - 0.07 * t.abs();
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: _buildPageItem(context, index + 1),
      ),
      ),
    );
  }

  Widget _buildScrollView(BuildContext context) {
    final itemHeight = _scrollItemHeight(context);
    final width = MediaQuery.of(context).size.width;
    if (_scrollController == null || _scrollViewWidth != width) {
      // (Re)create the controller when entering scroll mode or when the
      // width changes (rotation): the item height derives from the width,
      // so the old pixel offset would land mid-page or past the end —
      // re-base it on the current page instead.
      _scrollController?.dispose();
      _scrollController = ScrollController(
        initialScrollOffset: (_currentPage - 1) * itemHeight,
      );
      _scrollViewWidth = width;
    }
    // Scrolling is disabled while drawing so strokes are not interrupted.
    final drawingActive =
        Provider.of<PageDrawingService>(context).isDrawingMode;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification ||
            notification is ScrollEndNotification) {
          final page = (notification.metrics.pixels / itemHeight).floor() + 1;
          _setCurrentPage(page);
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: drawingActive ? const NeverScrollableScrollPhysics() : null,
        itemCount: totalPagesInMushaf,
        itemBuilder: (context, index) =>
            _buildPageItem(context, index + 1, interactive: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = Provider.of<PreferencesService>(context);
    final audio = Provider.of<AudioRecitationService>(context);
    // Page swipes are disabled while a drawing tool is active.
    final drawingActive =
        Provider.of<PageDrawingService>(context).isDrawingMode;
    final cs = Theme.of(context).colorScheme;
    final isBookmarked = prefs.bookmarks.contains(_currentPage);
    final isNightTheme = Theme.of(context).brightness == Brightness.dark;
    final isDark = isNightTheme || prefs.nightPageMode;

    // Reader control-bar palette, derived from the theme tokens (never
    // hardcoded): theme surfaces, theme gold accents (primary in Night
    // Slate, secondary in the light themes), subtle gold-tinted borders.
    // A dark bar is used in dark theme and in night-page mode.
    //
    // Light themes (Emerald Day, Antique Parchment) with the black night
    // page: the generic dark bar (light surface lerped 35% toward black)
    // came out a muddy mid-grey that clashed with the black page and
    // washed out the cream text, ruining the page look. Use a properly
    // dark bar instead (88% toward black) so the footer reads as
    // intentional and premium. Night Slate (dark theme) is untouched —
    // its deep-green bar already harmonizes with the black page.
    final lightThemeNightPage = !isNightTheme && prefs.nightPageMode;
    final barDark = isDark;
    final barSurface = lightThemeNightPage
        ? Color.lerp(cs.surface, Colors.black, 0.88)!
        : (barDark
            ? Color.lerp(cs.surface, Colors.black, 0.35)!
            : cs.surface);
    final barText = barDark
        ? (isNightTheme ? cs.onSurface : cs.surface)
        : cs.onSurface;
    final barSubText = barText.withValues(alpha: 0.65);
    final barAccent = isNightTheme ? cs.primary : cs.secondary;
    final barBorder = barAccent.withValues(alpha: 0.45);
    final barOnAccent = isNightTheme ? cs.onPrimary : cs.onSecondary;
    final isScroll = prefs.readingMode == 'scroll';
    final isTurn = prefs.readingMode == 'turn';

    // Reset the scroll controller when leaving scroll mode so it re-syncs
    // to the current page next time.
    if (!isScroll && _scrollController != null) {
      _scrollController!.dispose();
      _scrollController = null;
      _scrollViewWidth = null;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        // Full-screen reader: no AppBar — the Quran page fills the screen
        // like the reference design. System back button navigates back.
        body: Stack(
          children: [
          // PageView with Reverse direction for Quranic Right-to-Left Reading
          if (isScroll)
            _buildScrollView(context)
          else if (isTurn)
            _buildTurnView(context)
          else
            Listener(
              // Pointer tracking for pinch-zoom arbitration: a second
              // finger locks page turns so the pinch reaches the
              // InteractiveViewer.
              onPointerDown: _onPointerDown,
              onPointerUp: _onPointerUpOrCancel,
              onPointerCancel: _onPointerUpOrCancel,
              child: PageView.builder(
                controller: _pageController,
                reverse: true, // RTL for Mushaf reading
                physics:
                    _pageTurnsLocked(drawingActive) ? const NeverScrollableScrollPhysics() : null,
                itemCount: totalPagesInMushaf,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) =>
                    _buildPageItem(context, index + 1),
              ),
            ),

          // Previous / next page chevrons. RTL reading: the next page is
          // reached from the left edge, the previous page from the right —
          // matching the mushaf page-turn direction. Hidden while a drawing
          // tool is active so navigation can never steal a stroke, and they
          // sit above the page gesture layer so taps never reach ayah
          // hit-testing or start drawing.
          if (!drawingActive) ...[
            Positioned(
              left: 2,
              top: 0,
              bottom: 0,
              child: Center(
                child: _pageNavButton(
                  icon: Icons.chevron_left,
                  tooltip: 'Next page',
                  enabled: _currentPage < totalPagesInMushaf,
                  buttonColor: barSurface,
                  iconColor: barText,
                  onTap: () => _jumpToPage(_currentPage + 1),
                ),
              ),
            ),
            Positioned(
              right: 2,
              top: 0,
              bottom: 0,
              child: Center(
                child: _pageNavButton(
                  icon: Icons.chevron_right,
                  tooltip: 'Previous page',
                  enabled: _currentPage > 1,
                  buttonColor: barSurface,
                  iconColor: barText,
                  onTap: () => _jumpToPage(_currentPage - 1),
                ),
              ),
            ),
          ],

          // Bookmark ribbon, top-right like the reference design. Hidden
          // while a drawing tool is active (the drawing-mode chip occupies
          // that corner instead).
          if (!drawingActive)
            Positioned(
              top: MediaQuery.of(context).padding.top + 2,
              right: 16,
              child: GestureDetector(
                onTap: () => prefs.toggleBookmark(_currentPage),
                // 48dp minimum tap target around the 44-wide ribbon.
                child: Container(
                  padding: const EdgeInsets.all(2),
                  color: Colors.transparent,
                  child: CustomPaint(
                    painter: _RibbonPainter(
                      fill: isBookmarked ? barAccent : barSurface,
                      stroke: barAccent,
                      shadowAlpha: isDark ? 0.45 : 0.22,
                    ),
                    child: Container(
                      width: 44,
                      height: 62,
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.only(top: 8),
                      child: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: isBookmarked ? barOnAccent : barText,
                        size: Nur.iconSizeSm,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Back button, top-left (symmetrical with bookmark ribbon).
          if (!drawingActive)
            Positioned(
              top: MediaQuery.of(context).padding.top + 4,
              left: 14,
              child: Material(
                color: barSurface.withValues(alpha: 0.88),
                shape: CircleBorder(
                  side: BorderSide(
                    color: barBorder.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _handleBack,
                  child: Padding(
                    padding: const EdgeInsets.all(9),
                    child: Icon(
                      Icons.arrow_back,
                      color: barText,
                      size: Nur.iconSizeSm,
                    ),
                  ),
                ),
              ),
            ),

          // When in drawing mode: bottom-left has X (close), bottom-right has Eye (toggle highlights).
          // When not in drawing mode: bottom-left has + button.
          if (drawingActive) ...[
            // Exit button (X) bottom-left
            Positioned(
              left: 14,
              bottom: 84 + MediaQuery.of(context).padding.bottom,
              child: Material(
                color: barSurface,
                shape: CircleBorder(
                  side: BorderSide(
                    color: barBorder,
                    width: 1,
                  ),
                ),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    _cancelInProgress();
                    setState(() {
                      _showColorPalette = false;
                    });
                    Provider.of<PageDrawingService>(context, listen: false)
                        .exitDrawing();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(Nur.s12),
                    child: Icon(
                      Icons.close,
                      color: barText,
                      size: Nur.iconSize,
                    ),
                  ),
                ),
              ),
            ),
            // Show/Hide toggle button (Eye) bottom-right
            Positioned(
              right: 14,
              bottom: 84 + MediaQuery.of(context).padding.bottom,
              child: Material(
                color: barSurface,
                shape: CircleBorder(
                  side: BorderSide(
                    color: barBorder,
                    width: 1,
                  ),
                ),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    setState(() {
                      _highlightsVisible = !_highlightsVisible;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(Nur.s12),
                    child: Icon(
                      _highlightsVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: barText,
                      size: Nur.iconSize,
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Floating + button, bottom-left like the reference design.
            Positioned(
              left: 14,
              bottom: 84 + MediaQuery.of(context).padding.bottom,
              child: Material(
                color: barSurface,
                shape: CircleBorder(
                  side: BorderSide(
                    color: barBorder,
                    width: 1,
                  ),
                ),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _showDrawingMenu(_currentPage),
                  child: Padding(
                    padding: const EdgeInsets.all(11),
                    child: Icon(
                      Icons.add,
                      color: barAccent,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Floating color palette row above toolbar when Color is tapped
          if (drawingActive && _showColorPalette)
            Positioned(
              left: 24,
              right: 24,
              bottom: 76 + MediaQuery.of(context).padding.bottom,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Nur.s16, vertical: Nur.s8),
                  decoration: BoxDecoration(
                    color: barSurface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: barBorder, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: Nur.s8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Consumer<PageDrawingService>(
                    builder: (context, draw, _) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final hex in PageDrawingService.paletteHexes)
                          GestureDetector(
                            onTap: () {
                              draw.setColor(hex);
                              draw.setTool('highlighter');
                              setState(() {
                                _showColorPalette = false;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: Nur.s4),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: PageDrawingService.parseHex(hex),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: draw.selectedColorHex == hex
                                      ? barAccent
                                      : (isDark
                                          ? Colors.white24
                                          : Colors.black26),
                                  width:
                                      draw.selectedColorHex == hex ? 3 : 1.5,
                                ),
                              ),
                              child: draw.selectedColorHex == hex
                                  ? const Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Colors.black87,
                                    )
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Persistent reader control bar:
          // When in drawing mode: 4-button Highlighter Toolbar (Color, Highlighter, Notes, Clear)
          // When reading: Speed / Play / Repeat / Night / More
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: barSurface,
                border: Border(
                  top: BorderSide(
                    color: barBorder,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Nur.screenMargin, vertical: Nur.s4),
                  child: drawingActive
                      ? Consumer<PageDrawingService>(
                          builder: (context, draw, _) => Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // 1. Color
                              _barControl(
                                onTap: () {
                                  setState(() {
                                    _showColorPalette = !_showColorPalette;
                                  });
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: Nur.iconSize,
                                      height: Nur.iconSize,
                                      decoration: BoxDecoration(
                                        color: draw.selectedColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: barAccent,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Color',
                                      style: TextStyle(
                                        color: barText.withValues(alpha: 0.85),
                                        fontSize: Nur.fontSmall,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 2. Drawing tools (opens the 5-tool sheet:
                              // Rectangle / Pen / Highlighter / Brush / Eraser)
                              _barControl(
                                onTap: () {
                                  _showToolSheet();
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _toolIcon(draw.selectedTool),
                                      color: barAccent,
                                      size: Nur.iconSize,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _toolLabel(draw.selectedTool ?? 'highlighter'),
                                      style: TextStyle(
                                        color: barAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: Nur.fontSmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 3. Notes
                              _barControl(
                                onTap: () =>
                                    _showPageNoteDialog(_currentPage),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.note_alt_outlined,
                                      color: barText.withValues(alpha: 0.85),
                                      size: Nur.iconSize,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Notes',
                                      style: TextStyle(
                                        color: barText.withValues(alpha: 0.65),
                                        fontSize: Nur.fontSmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 4. Clear
                              _barControl(
                                onTap: () =>
                                    _confirmClearPage(_currentPage),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      color: barText.withValues(alpha: 0.85),
                                      size: Nur.iconSize,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Clear',
                                      style: TextStyle(
                                        color: barText.withValues(alpha: 0.65),
                                        fontSize: Nur.fontSmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 5. Undo
                              _barControl(
                                onTap: () =>
                                    draw.undo(_currentPage),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.undo,
                                      color: (draw.canUndo(_currentPage)
                                              ? barText
                                              : barText.withValues(
                                                  alpha: 0.35))
                                          .withValues(alpha: 0.85),
                                      size: Nur.iconSize,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Undo',
                                      style: TextStyle(
                                        color: barText.withValues(alpha: 0.65),
                                        fontSize: Nur.fontSmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 6. Redo
                              _barControl(
                                onTap: () =>
                                    draw.redo(_currentPage),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.redo,
                                      color: (draw.canRedo(_currentPage)
                                              ? barText
                                              : barText.withValues(
                                                  alpha: 0.35))
                                          .withValues(alpha: 0.85),
                                      size: Nur.iconSize,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Redo',
                                      style: TextStyle(
                                        color: barText.withValues(alpha: 0.65),
                                        fontSize: Nur.fontSmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Speed
                            _barControl(
                              onTap: _cycleSpeed,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _speedLabel(prefs.playbackSpeed),
                                    style: TextStyle(
                                      color: barAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: Nur.s16,
                                    ),
                                  ),
                                  Text(
                                    'Speed',
                                    style: TextStyle(
                                      color: barText.withValues(alpha: 0.65),
                                      fontSize: Nur.fontSmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Play / Pause (big circular button, gold outline)
                            GestureDetector(
                              onTap: _onPlayPausePressed,
                              child: Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: barAccent, width: 2),
                                ),
                                child: Icon(
                                  audio.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: barText,
                                  size: 32,
                                ),
                              ),
                            ),
                            // Repeat (badge shows active mode)
                            _barControl(
                              onTap: _cycleRepeat,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Icon(
                                        Icons.repeat,
                                        color: barText.withValues(alpha: 0.85),
                                        size: Nur.iconSize,
                                      ),
                                      if (prefs.repeatMode != 0)
                                        Positioned(
                                          right: -8,
                                          top: -6,
                                          child: Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 1),
                                            decoration: BoxDecoration(
                                              color: barAccent,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      Nur.s8),
                                            ),
                                            child: Text(
                                              _repeatLabels[
                                                      prefs.repeatMode] ??
                                                  '',
                                              style: TextStyle(
                                                color: barOnAccent,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  Text(
                                    'Repeat',
                                    style: TextStyle(
                                      color: barText.withValues(alpha: 0.65),
                                      fontSize: Nur.fontSmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Night page mode toggle: invert page (black bg, white text)
                            _barControl(
                              onTap: () => prefs
                                  .setNightPageMode(!prefs.nightPageMode),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    prefs.nightPageMode
                                        ? Icons.dark_mode
                                        : Icons.dark_mode_outlined,
                                    color: prefs.nightPageMode
                                        ? barAccent
                                        : barText.withValues(alpha: 0.85),
                                    size: Nur.iconSize,
                                  ),
                                  Text(
                                    'Night',
                                    style: TextStyle(
                                      color: barText.withValues(alpha: 0.65),
                                      fontSize: Nur.fontSmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 3-dot menu -> reader settings sheet
                            _barControl(
                              onTap: () => _showReaderSettings(context),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.more_vert,
                                    color: barText.withValues(alpha: 0.85),
                                    size: Nur.iconSize,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'More',
                                    style: TextStyle(
                                      color: barSubText,
                                      fontSize: Nur.fontSmall,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

/// Paints persisted + in-progress freehand drawing strokes inside the page
/// image box. Coordinates are fractions (0..1) of the box.
class _PageDrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final bool isNightMode;
  _PageDrawingPainter(this.strokes, {this.isNightMode = false});

  static Color _colorOf(String hex, bool translucent) {
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    final c = Color(int.tryParse(h, radix: 16) ?? 0xFFFFD54F);
    // Translucent pastel tint so text shines through crisply
    return translucent ? c.withValues(alpha: 0.38) : c;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Strokes are stored as fractions of the true image rect; map them
    // through the letterbox-aware rect so they stay glued to the text.
    final img = _MushafScreenState._imageRect(size.width, size.height);
    Offset mapPt(Offset p) =>
        Offset(img.dx + p.dx * img.w, img.dy + p.dy * img.h);

    for (final s in strokes) {
      if (s.tool == 'highlighter') {
        final hlPaint = Paint()
          ..color = _colorOf(s.colorHex, true)
          ..style = PaintingStyle.fill
          ..blendMode = isNightMode ? BlendMode.screen : BlendMode.multiply;

        if (s.rect != Rect.zero) {
          final r = Rect.fromLTRB(
            img.dx + s.rect.left * img.w,
            img.dy + s.rect.top * img.h,
            img.dx + s.rect.right * img.w,
            img.dy + s.rect.bottom * img.h,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(r, const Radius.circular(3)),
            hlPaint,
          );
        } else if (s.points.isNotEmpty) {
          final pts = s.points.map(mapPt).toList();
          final strokePaint = Paint()
            ..color = _colorOf(s.colorHex, true)
            ..strokeWidth = max(18.0, s.width * img.w)
            ..strokeCap = StrokeCap.square
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke
            ..blendMode = isNightMode ? BlendMode.screen : BlendMode.multiply;
          if (pts.length == 1) {
            canvas.drawCircle(pts.first, strokePaint.strokeWidth / 2,
                strokePaint..style = PaintingStyle.fill);
          } else {
            canvas.drawPoints(PointMode.polygon, pts, strokePaint);
          }
        }
      } else {
        final paint = Paint()
          ..color = _colorOf(s.colorHex, false)
          ..strokeWidth = max(1.5, s.width * img.w)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;
        if (s.tool == 'rectangle') {
          final r = s.rect;
          canvas.drawRect(
            Rect.fromLTRB(
              img.dx + r.left * img.w,
              img.dy + r.top * img.h,
              img.dx + r.right * img.w,
              img.dy + r.bottom * img.h,
            ),
            paint,
          );
        } else {
          final pts = s.points.map(mapPt).toList();
          if (pts.length == 1) {
            canvas.drawCircle(pts.first, paint.strokeWidth / 2,
                paint..style = PaintingStyle.fill);
          } else if (pts.length > 1) {
            canvas.drawPoints(PointMode.polygon, pts, paint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PageDrawingPainter oldDelegate) => true;
}

/// Page image with resilient multi-CDN loading.
///
/// Uses [PageImageService] which tries several CDNs in order (each with a
/// timeout), so a hanging/blocked host no longer freezes the reader on
/// "Loading..." forever. Shows download progress, the image on success,
/// or an error card with a retry button when every source fails.
class _ResilientPageImage extends StatefulWidget {
  final int pageNum;
  final VoidCallback onLoaded;
  final VoidCallback onRetry;

  const _ResilientPageImage({
    super.key,
    required this.pageNum,
    required this.onLoaded,
    required this.onRetry,
  });

  @override
  State<_ResilientPageImage> createState() => _ResilientPageImageState();
}

class _ResilientPageImageState extends State<_ResilientPageImage> {
  late Future<Uint8List> _future;
  int _received = 0;
  int? _total;
  bool _notified = false;

  @override
  void initState() {
    super.initState();
    _startLoad();
  }

  void _startLoad() {
    _received = 0;
    _total = null;
    _notified = false;
    _future = PageImageService.fetchPageImage(
      widget.pageNum,
      onProgress: (r, t) {
        if (mounted) {
          setState(() {
            _received = r;
            _total = t;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasData) {
          if (!_notified) {
            _notified = true;
            WidgetsBinding.instance
                .addPostFrameCallback((_) => widget.onLoaded());
          }
          return Image.memory(snap.data!, fit: BoxFit.contain);
        }
        if (snap.hasError) return _errorView();
        return _loadingView();
      },
    );
  }

  Widget _loadingView() {
    final cs = Theme.of(context).colorScheme;
    final pct = (_total != null && _total! > 0)
        ? (_received / _total! * 100).round().clamp(0, 100)
        : null;
    return Container(
      color: cs.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
            const SizedBox(height: 12),
            Text(
              pct != null
                  ? 'Loading Page ${widget.pageNum}... $pct%'
                  : 'Loading Page ${widget.pageNum}...',
              style: TextStyle(
                  color: cs.onSurface, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      color: cs.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: cs.primary),
            const SizedBox(height: 16),
            Text(
              'صفحہ ${widget.pageNum}',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Page load nahi ho saka — internet check karein',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.65)),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: widget.onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Dobara try karein'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bookmark ribbon painter: a vertical silk ribbon with a V-notch and
/// gold trim, with distinct saved and unsaved states. Fill/stroke colors
/// come from the theme tokens via the caller.
class _RibbonPainter extends CustomPainter {
  final Color fill;
  final Color stroke;
  final double shadowAlpha;
  _RibbonPainter({
    required this.fill,
    required this.stroke,
    required this.shadowAlpha,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const notch = 12.0;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h)
      ..lineTo(w / 2, h - notch)
      ..lineTo(0, h)
      ..close();

    // Soft elevation shadow
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: shadowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Fill ribbon color
    canvas.drawPath(path, Paint()..color = fill);

    // Gold border/edge stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );

    // Subtle inner gold edge highlight on left
    canvas.drawLine(
      const Offset(2.0, 0),
      Offset(2.0, h - 3),
      Paint()
        ..color = stroke.withValues(alpha: 0.7)
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _RibbonPainter old) =>
      old.fill != fill ||
      old.stroke != stroke ||
      old.shadowAlpha != shadowAlpha;
}

/// Royal Islamic Bismillah unwan cartouche header: authentic Amiri Quran
/// calligraphy nestled within an illuminated frame, blended with the page
/// background (never a pasted-sticker look). All colors come from the theme
/// tokens: gold detailing is the theme's gold (primary in Night Slate,
/// secondary in the light themes), text is onSurface for clear contrast in
/// both modes.
class _BismillahHeader extends StatelessWidget {
  final VoidCallback? onTap;
  const _BismillahHeader({this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? cs.primary : cs.secondary;
    final textColor = cs.onSurface;
    // Never wider than the screen: on very narrow devices the fixed
    // 320px minimum would overflow horizontally.
    final maxW = MediaQuery.of(context).size.width - 32;

    return Center(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: BoxConstraints(
            minHeight: 58,
            minWidth: min(320.0, maxW),
            maxWidth: 410,
          ),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: CustomPaint(
          painter: _BismillahCartouchePainter(
            surface: cs.surface,
            border: gold,
            innerBorder: cs.primary,
            accent: gold,
            isDark: isDark,
          ),
          child: Padding(
            padding:
                const EdgeInsets.only(left: 26, right: 26, top: 6, bottom: 14),
            child: Transform.translate(
              offset: const Offset(0, -3.5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '۞',
                    style: TextStyle(
                      fontFamily: 'Amiri Quran',
                      fontSize: 15,
                      color: gold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        fontFamily: 'Amiri Quran',
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '۞',
                    style: TextStyle(
                      fontFamily: 'Amiri Quran',
                      fontSize: 15,
                      color: gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}

/// Classical Islamic unwan cartouche frame with soft ogee-style rounded
/// geometry, double gold hairlines, and floret accents. Colors are passed in
/// from the theme tokens by [_BismillahHeader].
class _BismillahCartouchePainter extends CustomPainter {
  final Color surface;
  final Color border;
  final Color innerBorder;
  final Color accent;
  final bool isDark;
  _BismillahCartouchePainter({
    required this.surface,
    required this.border,
    required this.innerBorder,
    required this.accent,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(24),
    );

    // Subtle drop shadow
    canvas.drawRRect(
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Cartouche surface fill (blends with the page background wash)
    canvas.drawRRect(r, Paint()..color = surface);

    // Outer primary gold border
    canvas.drawRRect(
      r,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // Inner fine ornamental border
    final innerR = RRect.fromRectAndRadius(
      Rect.fromLTWH(4.0, 4.0, w - 8.0, h - 8.0),
      const Radius.circular(20),
    );
    canvas.drawRRect(
      innerR,
      Paint()
        ..color = innerBorder.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Symmetrical decorative diamond florets at the left and right tips
    for (final dx in [11.0, w - 11.0]) {
      final cy = h / 2;
      final diamond = Path()
        ..moveTo(dx, cy - 3.5)
        ..lineTo(dx + 3.5, cy)
        ..lineTo(dx, cy + 3.5)
        ..lineTo(dx - 3.5, cy)
        ..close();
      canvas.drawPath(diamond, Paint()..color = accent);
    }
  }

  @override
  bool shouldRepaint(covariant _BismillahCartouchePainter old) =>
      old.isDark != isDark ||
      old.surface != surface ||
      old.border != border ||
      old.innerBorder != innerBorder ||
      old.accent != accent;
}

/// Thin symmetrical gold hairline rule with soft transparent ends — the
/// shared ornamental divider for the page header and footer.
class _HairlineRule extends StatelessWidget {
  final Color gold;
  final double horizontalMargin;
  const _HairlineRule({required this.gold, this.horizontalMargin = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.5,
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            gold.withValues(alpha: 0.65),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

/// Premium neutral top ornament for pages whose edition page has no Bismillah:
/// a symmetrical eight-pointed star (khatam) medallion flanked by layered
/// gold rules with diamond accents — elegant framing with restrained gold
/// detailing and no calligraphy, so the header never looks empty.
class _NeutralTopOrnament extends StatelessWidget {
  final Color gold;
  const _NeutralTopOrnament({required this.gold});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 44),
      child: Row(
        children: [
          Expanded(child: _sideRules(true)),
          const SizedBox(width: 8),
          _diamond(5),
          const SizedBox(width: 10),
          SizedBox(
            width: 40,
            height: 40,
            child: CustomPaint(painter: _StarMedallionPainter(gold: gold)),
          ),
          const SizedBox(width: 10),
          _diamond(5),
          const SizedBox(width: 8),
          Expanded(child: _sideRules(false)),
        ],
      ),
    );
  }

  /// Double gold hairline fading out toward the page edge; the lower line is
  /// shorter for a classic stepped divider look.
  Widget _sideRules(bool isLeft) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 1.2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
              end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
              colors: [
                Colors.transparent,
                gold.withValues(alpha: 0.75),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
              end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
              colors: [
                Colors.transparent,
                gold.withValues(alpha: 0.45),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _diamond(double s) => Transform.rotate(
        angle: pi / 4,
        child: Container(
          width: s,
          height: s,
          color: gold.withValues(alpha: 0.85),
        ),
      );
}

/// Eight-pointed star (khatam) medallion: outer ring, inner ring, and two
/// overlapping squares forming the star, with a solid diamond at the center.
/// Purely geometric — no calligraphy.
class _StarMedallionPainter extends CustomPainter {
  final Color gold;
  const _StarMedallionPainter({required this.gold});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 1.5;
    final ring = Paint()
      ..color = gold.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    // Outer and inner rings.
    canvas.drawCircle(c, r, ring);
    canvas.drawCircle(
        c,
        r * 0.84,
        ring
          ..strokeWidth = 0.8
          ..color = gold.withValues(alpha: 0.6));
    // Eight-pointed star: two overlapping squares.
    final starPaint = Paint()
      ..color = gold.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final sr = r * 0.60;
    for (var k = 0; k < 2; k++) {
      final path = Path();
      for (var i = 0; i < 4; i++) {
        final a = -pi / 2 + k * pi / 4 + i * pi / 2;
        final p = Offset(c.dx + sr * cos(a), c.dy + sr * sin(a));
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, starPaint);
    }
    // Solid diamond at the center.
    final dot = Path()
      ..moveTo(c.dx, c.dy - 3.2)
      ..lineTo(c.dx + 3.2, c.dy)
      ..lineTo(c.dx, c.dy + 3.2)
      ..lineTo(c.dx - 3.2, c.dy)
      ..close();
    canvas.drawPath(
        dot, Paint()..color = gold..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _StarMedallionPainter oldDelegate) =>
      oldDelegate.gold != gold;
}

/// Manzil badge: an ornamental golden frame with the Manzil number.
/// Colors come from the theme tokens for clear contrast in both modes.
class _ManzilBadge extends StatelessWidget {
  final int manzil;
  const _ManzilBadge({required this.manzil});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      painter: _ManzilFramePainter(
        surface: cs.surface,
        gold: isDark ? cs.primary : cs.secondary,
        deepGold: cs.primary,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 6),
        child: Text(
          'Manzil $manzil',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Amiri Quran',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Ornamental double frame with pointed ends for the Manzil badge.
class _ManzilFramePainter extends CustomPainter {
  final Color surface;
  final Color gold;
  final Color deepGold;
  _ManzilFramePainter({
    required this.surface,
    required this.gold,
    required this.deepGold,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Slim pointed tips so the badge stays compact on narrow screens.
    const tip = 12.0;

    Path frame(double inset) {
      final p = Path();
      // Top edge with pointed left/right tips.
      p.moveTo(inset + tip, inset);
      p.lineTo(w - inset - tip, inset);
      p.lineTo(w - inset, h / 2);
      p.lineTo(w - inset - tip, h - inset);
      p.lineTo(inset + tip, h - inset);
      p.lineTo(inset, h / 2);
      p.close();
      return p;
    }

    // Background fill to blend smoothly with theme
    canvas.drawPath(
      frame(0),
      Paint()..color = surface,
    );

    // Outer gold frame.
    canvas.drawPath(
      frame(0),
      Paint()
        ..color = gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    // Inner deep-gold frame.
    canvas.drawPath(
      frame(3.5),
      Paint()
        ..color = deepGold.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );
    // Small diamonds at the pointed tips.
    for (final dx in [0.0, w]) {
      final cx = dx == 0 ? 0.0 : w;
      final path = Path()
        ..moveTo(cx, h / 2 - 4.0)
        ..lineTo(cx + (dx == 0 ? 4.0 : -4.0), h / 2)
        ..lineTo(cx, h / 2 + 4.0)
        ..lineTo(cx + (dx == 0 ? -4.0 : 4.0), h / 2)
        ..close();
      canvas.drawPath(path, Paint()..color = gold);
    }
  }

  @override
  bool shouldRepaint(covariant _ManzilFramePainter old) =>
      old.surface != surface || old.gold != gold || old.deepGold != deepGold;
}

/// Golden Islamic arabesque lattice painted behind the reader ornaments,
/// like the reference mushaf design. The pattern color is derived from the
/// theme tokens by the caller.
class _OrnamentPatternPainter extends CustomPainter {
  final Color pattern;
  _OrnamentPatternPainter({required this.pattern});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = pattern.withValues(alpha: 0.17)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final dotPaint = Paint()
      ..color = pattern.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    const step = 36.0;
    const r = 8.0;
    for (double y = step / 2; y < size.height; y += step) {
      for (double x = step / 2; x < size.width; x += step) {
        // 8-point star outline: two overlapping squares.
        for (int k = 0; k < 2; k++) {
          final path = Path();
          final rot = k * 3.14159 / 4;
          for (int i = 0; i < 4; i++) {
            final a = rot + i * 3.14159 / 2;
            final px = x + r * cos(a);
            final py = y + r * sin(a);
            if (i == 0) {
              path.moveTo(px, py);
            } else {
              path.lineTo(px, py);
            }
          }
          path.close();
          canvas.drawPath(path, paint);
        }
        canvas.drawCircle(Offset(x, y), 1.6, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OrnamentPatternPainter old) =>
      old.pattern != pattern;
}
