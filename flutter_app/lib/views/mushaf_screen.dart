import 'dart:math';
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import '../data/quran_data.dart';
import '../data/juz_data.dart';
import '../data/verse_index.dart';
import '../data/ayah_layout.dart';
import '../services/preferences_service.dart';
import '../services/audio_recitation_service.dart';
import '../services/page_drawing_service.dart';
import '../utils/page_image_url.dart';
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

  @override
  void dispose() {
    _audio.removeListener(_followAyah);
    _pageController.dispose();
    _scrollController?.dispose();
    _transformController.dispose();
    super.dispose();
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
    final fx = (local.dx / box.size.width).clamp(0.0, 1.0);
    final fy = (local.dy / box.size.height).clamp(0.0, 1.0);
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
    return Offset(
      (local.dx / box.size.width).clamp(0.0, 1.0),
      (local.dy / box.size.height).clamp(0.0, 1.0),
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

  /// Height of one page item in scroll mode. The item is an
  /// AspectRatio(0.6908) at full list width (see _buildPageItem), so the
  /// scroll math must use the full width — not width minus margins —
  /// or jump targets drift further off with every page.
  double _scrollItemHeight(BuildContext context) =>
      MediaQuery.of(context).size.width / 0.6908;

  /// The page image Container + CachedNetworkImage (with tint overlay),
  /// without the InteractiveViewer wrapper. The image box keeps the exact
  /// page-image aspect (7428x10753 -> 0.6908) so ayah tap coordinates map
  /// 1:1 to the image.
  Widget _buildPageImage(BuildContext context, int pageNum) {
    // Night theme: gently darken the white page so it doesn't strain the
    // eyes. Only the page image is filtered, not the highlight/drawing
    // overlays painted above it.
    final nightDim = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF7EE),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: 0.6908,
          child: Stack(
            children: [
              ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: nightDim ? 0.22 : 0.0),
                    BlendMode.darken,
                  ),
                  child: CachedNetworkImage(
                    imageUrl: mushafPageImageUrl(pageNum),
                    fit: BoxFit.contain,
                    // M7: pages are cached on disk — the Mushaf keeps working offline.
                    progressIndicatorBuilder: (context, url, progress) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF0F3A2C)),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Loading Page $pageNum...',
                              style: const TextStyle(
                                  color: Color(0xFF0F3A2C),
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    },
                    errorWidget: (context, url, error) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        color: const Color(0xFFFAF7EE),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.menu_book,
                                  size: 64, color: Color(0xFF0F3A2C)),
                              const SizedBox(height: 16),
                              Text(
                                'صفحہ $pageNum',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F3A2C)),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '15-Line Offline Mushaf Page',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )),
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
      ),
    );
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
            // Website: 15px band on the (max 580px wide -> ~870px tall) wrapper.
            final bandH = h * 0.0172;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            // Website gold: light rgba(212,175,55,0.45), dark rgba(240,205,95,0.50).
            final gold = isDark
                ? const Color.fromRGBO(240, 205, 95, 0.50)
                : const Color.fromRGBO(212, 175, 55, 0.45);
            return StreamBuilder<double>(
              stream: audio.ayahProgressStream,
              initialData: 0.0,
              builder: (context, progSnap) {
                final progress = (progSnap.data ?? 0.0).clamp(0.0, 1.0);
                // Website progress distribution: segments fill in line order,
                // weighted by width (min 5), each filling right-to-left.
                final weights = ayahSegs.map((s) => max(5.0, s.width)).toList();
                final total = weights.fold(0.0, (a, b) => a + b);
                double acc = 0;
                return IgnorePointer(
                  child: Stack(
                    children: [
                      for (int i = 0; i < ayahSegs.length; i++)
                        Builder(builder: (context) {
                          final seg = ayahSegs[i];
                          final startFrac = acc / total;
                          acc += weights[i];
                          final endFrac = acc / total;
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
                          final rw = r.width * w;
                          return Positioned(
                            left: r.left * w,
                            top: r.top * h + (r.height * h - bandH) / 2,
                            width: rw,
                            height: bandH,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: Stack(
                                children: [
                                  // RTL fill: gold grows from the right edge.
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
    final pageImage = _buildPageImage(context, pageNum);
    if (!interactive) {
      return AspectRatio(aspectRatio: 0.6908, child: pageImage);
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
    // Scrolling is disabled while drawing so strokes are not interrupted.
    final drawingActive =
        Provider.of<PageDrawingService>(context).isDrawingMode;
    _scrollController ??= ScrollController(
      initialScrollOffset: (_currentPage - 1) * itemHeight,
    );
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

          // Floating bookmark (save) button, top-right like the
          // reference design. Hidden while a drawing tool is active
          // (the drawing-mode chip occupies that corner instead).
          if (!drawingActive)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 12,
              child: Material(
                color: cs.surface.withValues(alpha: 0.85),
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => prefs.toggleBookmark(_currentPage),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked
                          ? cs.primary
                          : cs.onSurface.withValues(alpha: 0.7),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),

          // Floating note button, bottom-left like the reference
          // design. Opens the page drawing/notes menu.
          Positioned(
            left: 12,
            bottom: 92,
            child: Material(
              color: const Color(0xFFE8F5E9),
              shape: const CircleBorder(),
              elevation: 3,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _showDrawingMenu(_currentPage),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.edit_note,
                    color: Color(0xFF2E7D32),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          // Persistent reader control bar: Speed / Play / Repeat / Menu
          // (image-1 style; always visible at the bottom of the page).
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                  top: BorderSide(
                    color: cs.primary.withValues(alpha: 0.25),
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
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Speed',
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.6),
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
                        border: Border.all(color: cs.primary, width: 2),
                      ),
                      child: Icon(
                        audio.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: cs.onSurface,
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
                                color: cs.onSurface.withValues(alpha: 0.75),
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
                                      color: cs.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _repeatLabels[prefs.repeatMode] ?? '',
                                      style: TextStyle(
                                        color: cs.onPrimary,
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
                              color: cs.onSurface.withValues(alpha: 0.6),
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
                        color: cs.onSurface.withValues(alpha: 0.75),
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
    return translucent ? c.withValues(alpha: 0.45) : c;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      final paint = Paint()
        ..color = _colorOf(s.colorHex, s.tool == 'highlighter')
        ..strokeWidth = max(1.5, s.width * size.width)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (s.tool == 'rectangle') {
        final r = s.rect;
        canvas.drawRect(
          Rect.fromLTRB(
            r.left * size.width,
            r.top * size.height,
            r.right * size.width,
            r.bottom * size.height,
          ),
          paint,
        );
      } else {
        final pts = s.points
            .map((p) => Offset(p.dx * size.width, p.dy * size.height))
            .toList();
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
