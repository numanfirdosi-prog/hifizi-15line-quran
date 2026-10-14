import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/quran_data.dart';
import '../data/verse_index.dart';
import '../services/audio_recitation_service.dart';
import '../services/preferences_service.dart';
import '../services/tafsir_service.dart';
import '../utils/script_font.dart';

/// Full Tafsir view for one surah: every ayah in order, each with
/// Arabic text → Urdu tarjuma (Kanzul Iman) → English → Ibn Kathir
/// Urdu tafsir. Optionally scrolls to a specific ayah (from Jump).
class TafsirSurahScreen extends StatefulWidget {
  final int surah;
  final int? scrollToAyah;

  const TafsirSurahScreen({required this.surah, this.scrollToAyah, super.key});

  @override
  State<TafsirSurahScreen> createState() => _TafsirSurahScreenState();
}

class _TafsirSurahScreenState extends State<TafsirSurahScreen> {
  Future<_SurahTafsirData>? _loadFuture;
  final Map<int, GlobalKey> _ayahKeys = {};
  final ScrollController _scrollController = ScrollController();
  bool _scrolled = false;
  int _scrollAttempts = 0;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Loads Arabic+English, Urdu, and all tafsir for this surah.
  /// TafsirService caches the surah file after the first getTafsir,
  /// so the loop below hits the in-memory cache, not the disk.
  Future<_SurahTafsirData> _loadData() async {
    final results = await Future.wait([
      loadQuranText(),
      loadUrduKanzulIman(),
    ]);
    final entries = (results[0] as List<QuranTextEntry>)
        .where((e) => e.s == widget.surah)
        .toList()
      ..sort((a, b) => a.v.compareTo(b.v));
    final urdu = results[1] as Map<String, String>;

    final tafsir = <int, String?>{};
    final service = TafsirService();
    for (final entry in entries) {
      tafsir[entry.v] = await service.getTafsir(widget.surah, entry.v);
    }
    return _SurahTafsirData(entries: entries, urdu: urdu, tafsir: tafsir);
  }

  /// Scrolls to [widget.scrollToAyah] once its card is laid out.
  ///
  /// ListView only mounts near-visible children, so a far-down ayah
  /// (e.g. 2:255 or 36:58) has no [GlobalKey] context on the first
  /// frame — the old code returned silently and the list stayed at
  /// Ayah 1. This version scrolls down in chunks to force layout of
  /// further items, then retries [Scrollable.ensureVisible] until the
  /// target context exists. [_scrolled] is set only after a successful
  /// scroll (or after the bounded retry budget is exhausted).
  void _scrollToAyahIfNeeded() {
    if (_scrolled) return;
    final target = widget.scrollToAyah;
    if (target == null) return;
    final key = _ayahKeys[target];
    if (key?.currentContext != null) {
      _scrolled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 600),
          alignment: 0.05,
        );
      });
      return;
    }
    // Target not laid out yet — scroll down a chunk to force the
    // ListView to mount further children, then retry. Bounded so an
    // invalid/out-of-range target can't loop forever. 8000px chunks
    // converge fast even for the longest surahs (2:255 etc.).
    if (_scrollAttempts < 100) {
      _scrollAttempts++;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        final pos = _scrollController.position;
        final next =
            (pos.pixels + 8000).clamp(0.0, pos.maxScrollExtent);
        if (next == pos.pixels) return; // Already at bottom.
        _scrollController.jumpTo(next);
        Future.delayed(const Duration(milliseconds: 120), () {
          if (!mounted) return;
          _scrollToAyahIfNeeded();
        });
      });
    }
  }

  Widget _ayahCard(BuildContext context, _SurahTafsirData data,
      QuranTextEntry entry, PreferencesService prefs) {
    final cs = Theme.of(context).colorScheme;
    final urduText = data.urdu['${entry.s}:${entry.v}'] ?? '';
    final tafsirText = data.tafsir[entry.v];

    return Container(
      key: _ayahKeys.putIfAbsent(entry.v, () => GlobalKey()),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ayah number badge + audio button
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'Ayah ${entry.v}',
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              // Per-ayah audio: plays this ayah (auto-advances ayah-by-ayah
              // like the Ayah Player). Shows pause while this ayah plays.
              Consumer<AudioRecitationService>(
                builder: (context, audio, _) {
                  final isThisPlaying = audio.isPlaying &&
                      audio.currentSurah == entry.s &&
                      audio.currentAyah == entry.v;
                  return IconButton(
                    icon: Icon(
                      isThisPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                      color: cs.primary,
                      size: 30,
                    ),
                    tooltip:
                        isThisPlaying ? 'Pause' : 'Ayah ki audio sunain',
                    onPressed: () async {
                      final svc = Provider.of<AudioRecitationService>(
                          context,
                          listen: false);
                      if (isThisPlaying) {
                        await svc.pause();
                        return;
                      }
                      final ok = await svc.playAyah(
                          surah: entry.s, ayah: entry.v);
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Audio nahi chal saka — internet check karein'),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Arabic ayah
          Text(
            entry.ar,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: arabicStyle(
              prefs.scriptStyle,
              fontSize: 24,
              color: cs.onSurface,
              scale: prefs.ayahScale,
            ),
          ),
          // Urdu tarjuma
          if (urduText.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              urduText,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: urduStyle(
                fontSize: 16,
                color: cs.onSurface.withValues(alpha: 0.92),
                scale: prefs.ayahScale,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ترجمہ: کنزالایمان (احمد رضا خان)',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: urduStyle(
                fontSize: 12,
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          // English translation
          if (entry.en.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              entry.en,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: cs.onSurface.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'English: Saheeh International',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          // Golden divider
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Divider(color: cs.primary.withValues(alpha: 0.4))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.diamond, size: 12, color: cs.primary),
              ),
              Expanded(child: Divider(color: cs.primary.withValues(alpha: 0.4))),
            ],
          ),
          const SizedBox(height: 10),
          // Tafsir header
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(Icons.auto_stories, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'تفسیر ابن کثیر',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'حافظ عماد الدین ابن کثیر رحمہ اللہ',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.55),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Tafsir text (or graceful not-available note)
          if (tafsirText != null && tafsirText.trim().isNotEmpty)
            Text(
              tafsirText,
              textDirection: TextDirection.rtl,
              style: urduStyle(
                fontSize: 16,
                color: cs.onSurface,
                scale: prefs.ayahScale,
              ),
            )
          else
            Text(
              'اس آیت کی تفسیر دستیاب نہیں ہے۔',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final prefs = Provider.of<PreferencesService>(context);
    final surah = allSurahs[widget.surah - 1];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${surah.nameEn} — ${surah.nameAr}',
          style: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),
      body: FutureBuilder<_SurahTafsirData>(
        future: _loadFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: cs.error, size: 36),
                    const SizedBox(height: 8),
                    const Text(
                      'Tafsir load nahi ho saki',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => setState(() {
                        _loadFuture = _loadData();
                      }),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          final data = snap.data!;
          // Scroll to the jumped ayah once the list is laid out.
          WidgetsBinding.instance.addPostFrameCallback(
              (_) => _scrollToAyahIfNeeded());
          return ListView(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            children: [
              // Surah header: name + ayah count
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    Text(
                      surah.nameAr,
                      textDirection: TextDirection.rtl,
                      style: arabicStyle(
                        prefs.scriptStyle,
                        fontSize: 30,
                        color: cs.primary,
                        scale: prefs.ayahScale,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Surah ${surah.number} • ${surah.nameEn} • ${surah.totalAyahs} Ayahs • ${surah.revelation}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.65),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Bismillah header (all surahs except 1 — where it is ayah 1 —
              // and 9 — which has no Bismillah).
              if (widget.surah != 1 && widget.surah != 9)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Text(
                    'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: arabicStyle(
                      prefs.scriptStyle,
                      fontSize: 24,
                      color: cs.onSurface,
                      scale: prefs.ayahScale,
                    ),
                  ),
                ),
              ...data.entries.map((e) => _ayahCard(context, data, e, prefs)),
            ],
          );
        },
      ),
    );
  }
}

/// Loaded data for one surah's Tafsir view.
class _SurahTafsirData {
  final List<QuranTextEntry> entries;
  final Map<String, String> urdu;
  final Map<int, String?> tafsir;

  const _SurahTafsirData({
    required this.entries,
    required this.urdu,
    required this.tafsir,
  });
}
