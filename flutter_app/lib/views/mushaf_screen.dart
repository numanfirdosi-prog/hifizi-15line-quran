import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../data/quran_data.dart';
import '../data/juz_data.dart';
import '../data/verse_index.dart';
import '../data/ayah_layout.dart';
import '../services/preferences_service.dart';
import '../services/audio_recitation_service.dart';
import '../utils/page_image_url.dart';

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
  bool _showStudyToolbar = false;
  // Ayah quick-jump pill strip (collapsible).
  bool _showAyahPills = true;

  // Semi-transparent study highlight tints.
  static const List<Color> _tintColors = [
    Color(0x88FFEB3B), // yellow
    Color(0x884CAF50), // green
    Color(0x88F48FB1), // pink
    Color(0x8890CAF9), // blue
    Color(0x88FFB74D), // orange
  ];

  // Cached page -> first 's:v' index (loaded once, used for audio + markRead).
  late final Future<Map<int, String>> _firstVerseIndex;

  // Ayah tap-to-play: per-page ayah segments + verseKey->page index,
  // both loaded once and cached.
  late final Future<Map<int, List<AyahSeg>>> _segmentsFuture;
  late final Future<Map<String, int>> _versePageIndexFuture;
  late final AudioRecitationService _audio;
  bool _followingAyah = false;

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

  /// Shares the current page reference via the Android share sheet.
  /// Never includes private notes.
  Future<void> _shareCurrentPage() async {
    var ref = 'Page $_currentPage';
    try {
      final index = await _firstVerseIndex;
      final firstVerse = index[_currentPage];
      if (firstVerse != null) {
        final parts = firstVerse.split(':');
        final s = (int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 1)
            .clamp(1, 114);
        final name = allSurahs[s - 1].nameEn;
        var juz = 1;
        for (final j in juzList) {
          if (_currentPage >= j.startPage) juz = j.number;
        }
        ref = 'Page $_currentPage • Surah $name • Juz $juz';
      }
    } catch (_) {}
    await Share.share('$ref — Nur Al-Quran');
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
    final hit = hitTestAyah(segsMap[pageNum] ?? const <AyahSeg>[], fx, fy, pageNum);
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

  String _tintHexOf(Color color) =>
      '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';

  Color _parseHex(String hex) => Color(int.parse(hex.substring(1), radix: 16));

  Color? _pageTintColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      return _parseHex(hex);
    } catch (_) {
      return null;
    }
  }

  void _showJumpToPageDialog() {
    final cs = Theme.of(context).colorScheme;
    final textController = TextEditingController(text: _currentPage.toString());
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    // N5: dispose the controller when the dialog closes.
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title:  Text('ورقہ / صفحہ منتخب کریں',
            style: TextStyle(color: cs.onSurface, fontFamily: 'serif')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Page Number (1 to 611):',
              style: TextStyle(color: Color(0xFFE2E8F0)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(color: cs.onSurface, fontSize: 18),
              decoration: InputDecoration(
                filled: true,
                fillColor: cs.secondary,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                hintText: 'Enter page 1-611',
                hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Cancel', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
            ),
            onPressed: () {
              final p = int.tryParse(textController.text.trim());
              if (p != null && p >= 1 && p <= totalPagesInMushaf) {
                Navigator.pop(ctx);
                if (prefs.readingMode == 'scroll') {
                  final itemHeight = _scrollItemHeight(context);
                  _scrollController?.animateTo(
                    (p - 1) * itemHeight,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  _pageController.jumpToPage(p - 1);
                }
              }
            },
            child: const Text('Go to Page'),
          ),
        ],
      ),
    ).then((_) => textController.dispose());
  }

  void _showNoteDialog() {
    final cs = Theme.of(context).colorScheme;
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    final textController = TextEditingController(
      text: prefs.pageNotes['$_currentPage'] ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text(
          'نوٹ — صفحہ $_currentPage (Page Note)',
          style:  TextStyle(
              color: cs.primary, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: textController,
          maxLines: 4,
          style: TextStyle(color: cs.onSurface, fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: cs.secondary,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: 'Write a note for this page...',
            hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Cancel', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
            ),
            onPressed: () {
              final text = textController.text.trim();
              prefs.setPageNote(_currentPage, text.isEmpty ? null : text);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) => textController.dispose());
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

  /// Toggles recitation of the Surah on the current page.
  Future<void> _onPlayPausePressed() async {
    final audio = Provider.of<AudioRecitationService>(context, listen: false);
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    if (audio.isPlaying) {
      await audio.pause();
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

  double _scrollItemHeight(BuildContext context) =>
      (MediaQuery.of(context).size.width - 8) / 0.6908;

  /// The page image Container + CachedNetworkImage (with tint overlay),
  /// without the InteractiveViewer wrapper. The image box keeps the exact
  /// page-image aspect (7428x10753 -> 0.6908) so ayah tap coordinates map
  /// 1:1 to the image.
  Widget _buildPageImage(BuildContext context, int pageNum) {
    final prefs = Provider.of<PreferencesService>(context);
    final tint = _pageTintColor(prefs.pageTint['$pageNum']);
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
              CachedNetworkImage(
                imageUrl: mushafPageImageUrl(pageNum),
                fit: BoxFit.contain,
              // M7: pages are cached on disk — the Mushaf keeps working offline.
              progressIndicatorBuilder: (context, url, progress) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF0F3A2C)),
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
            ),
            if (tint != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            // Currently playing ayah highlight (ayah-by-ayah audio mode).
            _buildAyahHighlights(pageNum),
            // Tap-to-ayah detector: LAST so it sits above the overlays.
            // Translucent: taps pass through visually but are still caught.
            Positioned.fill(
              child: Builder(
                builder: (tapCtx) => GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapUp: (d) => _onPageTap(tapCtx, d, pageNum),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
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
        if (!audio.ayahMode) return const SizedBox.shrink();
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
            final isDark =
                Theme.of(context).brightness == Brightness.dark;
            // Website gold: light rgba(212,175,55,0.45), dark rgba(240,205,95,0.50).
            final gold = isDark
                ? const Color.fromRGBO(240, 205, 95, 0.50)
                : const Color.fromRGBO(212, 175, 55, 0.45);
            return StreamBuilder<double>(
              stream: audio.ayahProgressStream,
              initialData: 0.0,
              builder: (context, progSnap) {
                final progress =
                    (progSnap.data ?? 0.0).clamp(0.0, 1.0);
                // Website progress distribution: segments fill in line order,
                // weighted by width (min 5), each filling right-to-left.
                final weights = ayahSegs
                    .map((s) => max(5.0, s.width))
                    .toList();
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
                            segProg = (progress - startFrac) /
                                (endFrac - startFrac);
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

  /// Ayah quick-jump pill strip (like the website's `.ayah-pill` bar):
  /// distinct ayahs of the current page; tapping a pill plays that ayah
  /// exactly like tapping it on the page image. Sits outside the
  /// InteractiveViewer so pinch-zoom keeps working.
  Widget _buildAyahPillStrip(BuildContext context, double bottomOffset) {
    final cs = Theme.of(context).colorScheme;
    if (!_showAyahPills) {
      return Positioned(
        right: 12,
        bottom: bottomOffset,
        child: Material(
          color: cs.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _showAyahPills = true),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.format_list_numbered,
                      size: 16, color: cs.primary),
                  const SizedBox(width: 4),
                  Text('آیات',
                      style: TextStyle(
                          color: cs.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  Icon(Icons.expand_less,
                      size: 16, color: cs.primary),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Positioned(
      left: 12,
      right: 12,
      bottom: bottomOffset,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: cs.primary.withValues(alpha: 0.3)),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _showAyahPills = false),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.expand_more,
                    size: 18, color: cs.primary),
              ),
            ),
            Expanded(
              child: FutureBuilder<Map<int, List<AyahSeg>>>(
                future: _segmentsFuture,
                builder: (context, snap) {
                  final ayahs = distinctAyahs(
                      snap.data?[_currentPage] ?? const <AyahSeg>[]);
                  if (ayahs.isEmpty) {
                    return Text(
                      'No ayah data for this page',
                      style: TextStyle(
                        color:
                            cs.onSurface.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    );
                  }
                  return Consumer<AudioRecitationService>(
                    builder: (context, audio, _) {
                      return SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: ayahs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 6),
                          itemBuilder: (context, i) {
                            final seg = ayahs[i];
                            final isPlaying = audio.ayahMode &&
                                audio.currentSurah == seg.surah &&
                                audio.currentAyah == seg.ayah;
                            final surahName =
                                allSurahs[seg.surah - 1].nameEn;
                            return Tooltip(
                              message: '$surahName ${seg.surah}:${seg.ayah}',
                              child: InkWell(
                                borderRadius:
                                    BorderRadius.circular(16),
                                onTap: () async {
                                  final ok = await _audio.playAyah(
                                      surah: seg.surah,
                                      ayah: seg.ayah);
                                  if (!ok && mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Audio nahi chal saka — internet check karein'),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isPlaying
                                        ? cs.primary
                                        : cs.primary.withValues(
                                            alpha: 0.12),
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    border: Border.all(
                                      color: cs.primary.withValues(
                                          alpha:
                                              isPlaying ? 1.0 : 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    '${seg.ayah}',
                                    style: TextStyle(
                                      color: isPlaying
                                          ? cs.onPrimary
                                          : cs.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
    return InteractiveViewer(
      transformationController: _transformController,
      minScale: 1.0,
      maxScale: 3.5,
      child: pageImage,
    );
  }

  /// Lightweight page-turn reading mode: the same PageView as slide mode,
  /// but each page gets a subtle 3D flip driven by the drag offset.
  /// Purposefully modest (no heavy curl shader) so it stays smooth on
  /// mid-range devices; slide mode remains the fallback.
  Widget _buildTurnView(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      reverse: true, // RTL for Mushaf reading
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
            transform: Matrix4.identity()..setEntry(3, 2, 0.002)..rotateY(angle),
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
        itemCount: totalPagesInMushaf,
        itemBuilder: (context, index) =>
            _buildPageItem(context, index + 1, interactive: false),
      ),
    );
  }

  Widget _buildStudyToolbar(BuildContext context, PreferencesService prefs) {
    final cs = Theme.of(context).colorScheme;
    final currentHex = prefs.pageTint['$_currentPage'];
    final hasNote = prefs.pageNotes.containsKey('$_currentPage');
    return Container(
      color: cs.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Tint color dots
          for (final color in _tintColors)
            GestureDetector(
              onTap: () {
                final hex = _tintHexOf(color);
                prefs.setPageTint(_currentPage, currentHex == hex ? null : hex);
              },
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: currentHex == _tintHexOf(color)
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.24),
                    width: currentHex == _tintHexOf(color) ? 2.5 : 1,
                  ),
                ),
              ),
            ),
          const Spacer(),
          // Note button with indicator badge
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.note_add, color: cs.onSurface.withValues(alpha: 0.7)),
                if (hasNote)
                  Positioned(
                    right: 0,
                    top: 2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration:  BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Page Note',
            onPressed: _showNoteDialog,
          ),
          IconButton(
            icon: Icon(Icons.clear, color: cs.onSurface.withValues(alpha: 0.7)),
            tooltip: 'Clear tint & note',
            onPressed: () {
              prefs.setPageTint(_currentPage, null);
              prefs.setPageNote(_currentPage, null);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = Provider.of<PreferencesService>(context);
    final audio = Provider.of<AudioRecitationService>(context);
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
      appBar: AppBar(
        // (AppBar background from theme)
        elevation: 2,
        title: Row(
          children: [
            Text(
              'صفحہ $_currentPage',
              style:  TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '/ $totalPagesInMushaf',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontSize: 14),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              audio.isPlaying ? Icons.pause : Icons.play_arrow,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
            tooltip: 'Play / Pause Surah Recitation',
            onPressed: _onPlayPausePressed,
          ),
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? cs.primary : cs.onSurface.withValues(alpha: 0.7),
            ),
            onPressed: () => prefs.toggleBookmark(_currentPage),
          ),
          IconButton(
            icon: Icon(
              Icons.brush,
              color:
                  _showStudyToolbar ? cs.primary : cs.onSurface.withValues(alpha: 0.7),
            ),
            tooltip: 'Study Tools',
            onPressed: () =>
                setState(() => _showStudyToolbar = !_showStudyToolbar),
          ),
          IconButton(
            icon: Icon(Icons.swap_horiz, color: cs.onSurface.withValues(alpha: 0.7)),
            tooltip: 'Jump to Page',
            onPressed: _showJumpToPageDialog,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                color: cs.onSurface.withValues(alpha: 0.7)),
            tooltip: 'More',
            color: cs.surface,
            onSelected: (value) {
              if (value == 'share') _shareCurrentPage();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'share',
                child: Text('Share page',
                    style: TextStyle(color: cs.onSurface)),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Study toolbar (highlights + notes) below the AppBar
          if (_showStudyToolbar) _buildStudyToolbar(context, prefs),
          Expanded(
            child: Stack(
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
                    itemCount: totalPagesInMushaf,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) =>
                        _buildPageItem(context, index + 1),
                  ),

                // Bottom Quick Page Controller Slider
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: audio.isPlaying ? 80 : 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 8),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon:  Icon(Icons.arrow_back_ios,
                              size: 16, color: cs.onSurface.withValues(alpha: 0.7)),
                          onPressed: () {
                            if (_currentPage > 1) {
                              if (isScroll) {
                                final itemHeight = _scrollItemHeight(context);
                                _scrollController?.animateTo(
                                  (_currentPage - 2) * itemHeight,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            }
                          },
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: cs.primary,
                              inactiveTrackColor: cs.onSurface.withValues(alpha: 0.24),
                              thumbColor: cs.primary,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6),
                            ),
                            child: Slider(
                              value: _currentPage.toDouble(),
                              min: 1.0,
                              max: totalPagesInMushaf.toDouble(),
                              onChanged: (val) {
                                final target = val.toInt();
                                if (isScroll) {
                                  final itemHeight = _scrollItemHeight(context);
                                  _scrollController
                                      ?.jumpTo((target - 1) * itemHeight);
                                } else {
                                  _pageController.jumpToPage(target - 1);
                                }
                              },
                            ),
                          ),
                        ),
                        IconButton(
                          icon:  Icon(Icons.arrow_forward_ios,
                              size: 16, color: cs.onSurface.withValues(alpha: 0.7)),
                          onPressed: () {
                            if (_currentPage < totalPagesInMushaf) {
                              if (isScroll) {
                                final itemHeight = _scrollItemHeight(context);
                                _scrollController?.animateTo(
                                  _currentPage * itemHeight,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Ayah quick-jump pills (above the page slider)
                _buildAyahPillStrip(
                    context, audio.isPlaying ? 150 : 86),

                // Audio Recitation Bar (when active)
                if (audio.isPlaying)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A291E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: cs.primary, width: 1.2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black54, blurRadius: 10),
                        ],
                      ),
                      child: Row(
                        children: [
                           Icon(Icons.graphic_eq,
                              color: cs.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Surah ${audio.currentSurah}: ${allSurahs[audio.currentSurah - 1].nameEn}',
                                  style:  TextStyle(
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                                Text(
                                  audio.selectedQari.name,
                                  style:  TextStyle(
                                      color: cs.primary, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _cycleSpeed,
                            child: Text(
                              _speedLabel(prefs.playbackSpeed),
                              style:  TextStyle(
                                  color: cs.primary, fontSize: 11),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _cycleRepeat,
                            child: Text(
                              _repeatLabels[prefs.repeatMode] ?? 'Off',
                              style:  TextStyle(
                                  color: cs.primary, fontSize: 11),
                            ),
                          ),
                          IconButton(
                            icon:  Icon(Icons.pause_circle_filled,
                                color: cs.primary, size: 32),
                            onPressed: _onPlayPausePressed,
                          ),
                          IconButton(
                            icon:  Icon(Icons.close,
                                color: cs.onSurface.withValues(alpha: 0.54), size: 20),
                            onPressed: () => audio.stop(),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
