import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../data/quran_data.dart';
import '../data/verse_index.dart';
import '../data/ayah_layout.dart';
import '../services/preferences_service.dart';
import '../services/audio_recitation_service.dart';
import '../services/page_drawing_service.dart';
import '../services/page_image_service.dart';
import 'reader_settings_sheet.dart';

class MushafScreen extends StatefulWidget {
  final int initialPage;
  const MushafScreen({Key? key, this.initialPage = 2}) : super(key: key);

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  late PageController _pageController;
  late int _currentPage;
  final TransformationController _transformController =
      TransformationController();
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

  // Page drawing (pen/brush/highlighter/rectangle/eraser): the stroke
  // currently being drawn (not yet persisted) and its page.
  DrawingStroke? _inProgressStroke;
  int? _inProgressPage;

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
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    _currentPage =
        widget.initialPage > 0 ? widget.initialPage : prefs.lastReadPage;
    // Pages in Mushaf are 1 to 611
    _pageController = PageController(initialPage: _currentPage - 1);
    _firstVerseIndex = loadPageFirstVerseIndex();
    _segmentsFuture = loadPageAyahSegments();
    _versePageIndexFuture = loadVersePageIndex();
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

  // ------------------------------------------------------------------
  // Page drawing tools (📜 menu): pen / brush / highlighter / rectangle /
  // eraser. Strokes are stored as fractions of the image box so they
  // scale with any screen size.
  // ------------------------------------------------------------------

  static Color _parseHexColor(String hex) {
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    return Color(int.tryParse(h, radix: 16) ?? 0xFFD4AF37);
  }

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

  /// Paint layer for persisted + in-progress drawing strokes.
  Widget _buildDrawingPaint(int pageNum) {
    return Positioned.fill(
      child: Consumer<PageDrawingService>(
        builder: (context, draw, _) {
          final strokes = draw.strokesFor(pageNum);
          final inProgress =
              (_inProgressPage == pageNum) ? _inProgressStroke : null;
          if (strokes.isEmpty && inProgress == null) {
            return const SizedBox.shrink();
          }
          return CustomPaint(
            painter: _PageDrawingPainter([
              ...strokes,
              if (inProgress != null) inProgress,
            ]),
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
        if (tool == null) return const SizedBox.shrink();
        return Positioned(
          top: 8,
          right: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _toolLabel(tool),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: Colors.black.withValues(alpha: 0.6),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    _cancelInProgress();
                    draw.exitDrawing();
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.close, color: Colors.white, size: 16),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _drawingMenuItem(
                  sheetCtx, Icons.palette, const Color(0xFFE53935), 'Color',
                  () {
                Navigator.pop(sheetCtx);
                _showColorRow();
              }),
              _drawingMenuItem(
                  sheetCtx, Icons.highlight, cs.primary, 'Highlighter', () {
                Navigator.pop(sheetCtx);
                _showToolSheet();
              }),
              _drawingMenuItem(sheetCtx, Icons.note_add, cs.primary, 'Notes',
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
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: cs.onSurface, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  /// Color picker row (6 colors); picking one opens the Drawing Tools sheet.
  void _showColorRow() {
    final cs = Theme.of(context).colorScheme;
    final draw = Provider.of<PageDrawingService>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final hex in PageDrawingService.paletteHexes)
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    draw.setColor(hex);
                    Navigator.pop(sheetCtx);
                    _showToolSheet();
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _parseHexColor(hex),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: draw.selectedColorHex == hex
                            ? cs.primary
                            : Colors.black26,
                        width: 2,
                      ),
                    ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Drawing Tools',
                        style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 17,
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
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
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
                size: 30),
            const SizedBox(height: 6),
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
        title:
            Text('Page $pageNum note', style: TextStyle(color: cs.onSurface)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: TextStyle(color: cs.onSurface),
          decoration: InputDecoration(
            hintText: 'Write a note for this page…',
            hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
            border: const OutlineInputBorder(),
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

  /// Opens the reader settings bottom sheet (3-dot menu).
  void _showReaderSettings(BuildContext context) {
    showReaderSettingsSheet(context);
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
    return mq.padding.top +
        _kTopOrnamentHeight +
        mq.size.width / _kPageAspect +
        _kBottomOrnamentHeight +
        _kBottomSpacerHeight +
        mq.padding.bottom;
  }

  /// The page image (with night tint overlay), without the InteractiveViewer
  /// wrapper. The reader is decorated top and bottom: the golden Bismillah
  /// cartouche above the page and a star medallion with the page number
  /// below, over a rich golden arabesque pattern — so the screen never looks
  /// empty. The image box keeps the exact page-image aspect (_kPageAspect)
  /// so ayah tap coordinates map 1:1 to the image.
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
    // Royal golden background like the reference mushaf: a luminous gold
    // gradient with a denser arabesque pattern. Night page mode stays pure
    // black; dark theme uses a deep bronze gradient.
    final bgDecoration = nightPage
        ? const BoxDecoration(color: Colors.black)
        : BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: nightDim
                  ? const [
                      Color(0xFF6E5E2F),
                      Color(0xFF8A7A4A),
                      Color(0xFF6E5E2F)
                    ]
                  : const [
                      Color(0xFFF8E7B4),
                      Color(0xFFF0D89E),
                      Color(0xFFE4C47C)
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
          painter: _OrnamentPatternPainter(nightDim: nightDim || nightPage),
          child: Column(
            children: [
              SizedBox(
                // Fixed ornament heights: scroll-mode items size to their
                // content, so these must be exact — _scrollItemHeight
                // depends on them.
                height: _kTopOrnamentHeight,
                child: _buildTopOrnament(pageNum, nightDim),
              ),
              // The page-image box keeps the exact page aspect in both
              // modes: in scroll mode the column height is unbounded, so
              // the box sizes purely from the list width instead of being
              // squeezed by the ornaments inside a fixed AspectRatio.
              _buildImageBox(
                scrollMode,
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
              SizedBox(
                height: _kBottomOrnamentHeight,
                child: Center(child: _buildBottomOrnament(pageNum, nightDim)),
              ),
              // Reserve space for the overlaying bottom control bar so the
              // Manzil badge isn't hidden behind it.
              SizedBox(
                height: _kBottomSpacerHeight +
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
  /// fills the leftover column space as before.
  Widget _buildImageBox(bool scrollMode, Widget stack) {
    final box = AspectRatio(aspectRatio: _kPageAspect, child: stack);
    return scrollMode ? box : Expanded(child: box);
  }

  /// Ornamental header above the page: Bismillah in gold calligraphy under
  /// a thin gold top border, like the reference mushaf design.
  /// Ornamental header above the page: the golden Bismillah cartouche from
  /// the reference mushaf design. It glows on the golden background and
  /// keeps its royal look on the black night-page background.
  Widget _buildTopOrnament(int pageNum, bool nightDim) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/images/cartouche_bismillah.png',
            height: 86,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  /// Ornamental footer below the page: the Manzil badge in a golden frame,
  /// like the reference design.
  Widget _buildBottomOrnament(int pageNum, bool nightDim) {
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thin golden divider tying the footer to the royal header.
            Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 72),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF9A7B1E),
                    Color(0xFFC9A227),
                    Color(0xFF9A7B1E)
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 14),
              child: Center(
                  child: _ManzilBadge(manzil: manzil, nightDim: nightDim)),
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

  /// True aspect ratio of the bundled page images (720x1080).
  static const double _kPageAspect = 2 / 3;

  /// Fixed ornament heights (px) framing the page image. Scroll-mode items
  /// size to their content, so these must stay exact: [_scrollItemHeight]
  /// adds them to the width-derived image height for the scroll math.
  /// Top: 86px Bismillah cartouche + 10px padding.
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
    return PageView.builder(
      controller: _pageController,
      reverse: true, // RTL for Mushaf reading
      physics: drawingActive ? const NeverScrollableScrollPhysics() : null,
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
    final isScroll = prefs.readingMode == 'scroll';
    final isTurn = prefs.readingMode == 'turn';

    // Reset the scroll controller when leaving scroll mode so it re-syncs
    // to the current page next time.
    if (!isScroll && _scrollController != null) {
      _scrollController!.dispose();
      _scrollController = null;
      _scrollViewWidth = null;
    }

    return Scaffold(
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
            PageView.builder(
              controller: _pageController,
              reverse: true, // RTL for Mushaf reading
              physics:
                  drawingActive ? const NeverScrollableScrollPhysics() : null,
              itemCount: totalPagesInMushaf,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) =>
                  _buildPageItem(context, index + 1),
            ),

          // Bookmark ribbon, top-right like the reference design. Hidden
          // while a drawing tool is active (the drawing-mode chip occupies
          // that corner instead).
          if (!drawingActive)
            Positioned(
              top: MediaQuery.of(context).padding.top,
              right: 16,
              child: GestureDetector(
                onTap: () => prefs.toggleBookmark(_currentPage),
                child: CustomPaint(
                  painter: _RibbonPainter(
                    color: isBookmarked
                        ? const Color(0xFF6E5018)
                        : const Color(0xFF4A3517),
                  ),
                  child: Container(
                    width: 44,
                    height: 64,
                    alignment: Alignment.topCenter,
                    padding: const EdgeInsets.only(top: 10),
                    child: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: Colors.white.withValues(alpha: 0.95),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),

          // Floating + button, bottom-left like the reference design.
          // Opens the page drawing/notes menu (same as the note button).
          Positioned(
            left: 12,
            bottom: 92,
            child: Material(
              color: const Color(0xFF4A3517),
              shape: const CircleBorder(),
              elevation: 3,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _showDrawingMenu(_currentPage),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),

          // Persistent reader control bar: Speed / Play / Repeat / Menu.
          // Reference design: dark bar with gold accents.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF2A1D08),
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFC9A227),
                    width: 1.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Speed
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _cycleSpeed,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _speedLabel(prefs.playbackSpeed),
                            style: const TextStyle(
                              color: Color(0xFFE8C766),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Speed',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Play / Pause (big circular button)
                  GestureDetector(
                    onTap: _onPlayPausePressed,
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFC9A227), width: 2.5),
                      ),
                      child: Icon(
                        audio.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  // Repeat (badge shows active mode)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _cycleRepeat,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                Icons.repeat,
                                color: Colors.white.withValues(alpha: 0.85),
                                size: 24,
                              ),
                              if (prefs.repeatMode != 0)
                                Positioned(
                                  right: -8,
                                  top: -6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFC9A227),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _repeatLabels[prefs.repeatMode] ?? '',
                                      style: const TextStyle(
                                        color: Color(0xFF0A1F17),
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
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Night page mode toggle: invert page (black bg, white text)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () =>
                        prefs.setNightPageMode(!prefs.nightPageMode),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            prefs.nightPageMode
                                ? Icons.dark_mode
                                : Icons.dark_mode_outlined,
                            color: prefs.nightPageMode
                                ? const Color(0xFFE8C766)
                                : Colors.white.withValues(alpha: 0.85),
                            size: 24,
                          ),
                          Text(
                            'Night',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 3-dot menu -> reader settings sheet
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showReaderSettings(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Icon(
                        Icons.more_vert,
                        color: Colors.white.withValues(alpha: 0.85),
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints persisted + in-progress freehand drawing strokes inside the page
/// image box. Coordinates are fractions (0..1) of the box.
class _PageDrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  _PageDrawingPainter(this.strokes);

  static Color _colorOf(String hex, bool translucent) {
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    final c = Color(int.tryParse(h, radix: 16) ?? 0xFFD4AF37);
    // The highlighter must stay translucent like a real marker so the
    // Quranic text always shows through, even with dark colors.
    return translucent ? c.withValues(alpha: 0.30) : c;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Strokes are stored as fractions of the true image rect; map them
    // through the letterbox-aware rect so they stay glued to the text.
    final img = _MushafScreenState._imageRect(size.width, size.height);
    Offset mapPt(Offset p) =>
        Offset(img.dx + p.dx * img.w, img.dy + p.dy * img.h);
    for (final s in strokes) {
      final paint = Paint()
        ..color = _colorOf(s.colorHex, s.tool == 'highlighter')
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
    final pct = (_total != null && _total! > 0)
        ? (_received / _total! * 100).round().clamp(0, 100)
        : null;
    return Container(
      color: const Color(0xFFFAF7EE),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(Color(0xFF4A3517)),
            ),
            const SizedBox(height: 12),
            Text(
              pct != null
                  ? 'Loading Page ${widget.pageNum}... $pct%'
                  : 'Loading Page ${widget.pageNum}...',
              style: const TextStyle(
                  color: Color(0xFF4A3517), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: const Color(0xFFFAF7EE),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Color(0xFF4A3517)),
            const SizedBox(height: 16),
            Text(
              'صفحہ ${widget.pageNum}',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A3517)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Page load nahi ho saka — internet check karein',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
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

/// Bookmark ribbon painter: a vertical ribbon with a V-notch at the bottom.
class _RibbonPainter extends CustomPainter {
  final Color color;
  _RibbonPainter({required this.color});

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
    // Shadow.
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(path, Paint()..color = color);
    // Gold edge highlight on the left.
    canvas.drawLine(
      const Offset(1.5, 0),
      Offset(1.5, h - 2),
      Paint()
        ..color = const Color(0xFFC9A227).withValues(alpha: 0.7)
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _RibbonPainter old) => old.color != color;
}

/// Manzil badge: an ornamental golden frame with the Manzil number,
/// like the reference mushaf design.
class _ManzilBadge extends StatelessWidget {
  final int manzil;
  final bool nightDim;
  const _ManzilBadge({required this.manzil, required this.nightDim});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFC9A227);
    const deepGold = Color(0xFF9A7B1E);
    const bronze = Color(0xFF4A3517);
    return CustomPaint(
      painter: _ManzilFramePainter(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 8),
        child: Text(
          'Manzil $manzil',
          style: TextStyle(
            fontFamily: 'Amiri Quran',
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: nightDim ? Colors.white : bronze,
          ),
        ),
      ),
    );
  }
}

/// Ornamental double frame with pointed ends for the Manzil badge.
class _ManzilFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const gold = Color(0xFFC9A227);
    const deepGold = Color(0xFF9A7B1E);
    final w = size.width;
    final h = size.height;
    const tip = 14.0;

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

    // Outer gold frame.
    canvas.drawPath(
      frame(0),
      Paint()
        ..color = gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    // Inner deep-gold frame.
    canvas.drawPath(
      frame(5),
      Paint()
        ..color = deepGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    // Small diamonds at the pointed tips.
    for (final dx in [0.0, w]) {
      final cx = dx == 0 ? 0.0 : w;
      final path = Path()
        ..moveTo(cx, h / 2 - 5)
        ..lineTo(cx + (dx == 0 ? 5 : -5), h / 2)
        ..lineTo(cx, h / 2 + 5)
        ..lineTo(cx + (dx == 0 ? -5 : 5), h / 2)
        ..close();
      canvas.drawPath(path, Paint()..color = gold);
    }
  }

  @override
  bool shouldRepaint(covariant _ManzilFramePainter old) => false;
}

/// Golden Islamic arabesque lattice painted behind the reader ornaments,
/// like the reference mushaf design.
class _OrnamentPatternPainter extends CustomPainter {
  final bool nightDim;
  _OrnamentPatternPainter({required this.nightDim});

  @override
  void paint(Canvas canvas, Size size) {
    final base = nightDim ? Colors.black : const Color(0xFF9A7B1E);
    final paint = Paint()
      ..color = base.withValues(alpha: 0.17)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final dotPaint = Paint()
      ..color = base.withValues(alpha: 0.22)
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
      old.nightDim != nightDim;
}
