import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/quran_data.dart';
import '../data/verse_index.dart';
import '../services/audio_recitation_service.dart';
import '../services/preferences_service.dart';
import '../utils/script_font.dart';
import 'tafsir_ayah_detail_screen.dart';

/// FAST Ayah List for one surah: every ayah in order, each with
/// Arabic text → Urdu tarjuma (Kanzul Iman) → English.
///
/// NO tafsir is loaded here — that is what made the old screen slow
/// (it fetched tafsir for ALL ayahs upfront). Tapping an ayah card
/// opens [TafsirAyahDetailScreen], which loads tafsir for that ONE
/// ayah only. The list therefore opens instantly.
class TafsirSurahScreen extends StatefulWidget {
  final int surah;

  const TafsirSurahScreen({required this.surah, super.key});

  @override
  State<TafsirSurahScreen> createState() => _TafsirSurahScreenState();
}

class _TafsirSurahScreenState extends State<TafsirSurahScreen> {
  Future<_SurahListData>? _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadData();
  }

  /// Loads Arabic+English and Urdu only — no tafsir.
  Future<_SurahListData> _loadData() async {
    final results = await Future.wait([
      loadQuranText(),
      loadUrduKanzulIman(),
    ]);
    final entries = (results[0] as List<QuranTextEntry>)
        .where((e) => e.s == widget.surah)
        .toList()
      ..sort((a, b) => a.v.compareTo(b.v));
    final urdu = results[1] as Map<String, String>;
    return _SurahListData(entries: entries, urdu: urdu);
  }

  Widget _ayahCard(BuildContext context, _SurahListData data,
      QuranTextEntry entry, PreferencesService prefs) {
    final cs = Theme.of(context).colorScheme;
    final urduText = data.urdu['${entry.s}:${entry.v}'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TafsirAyahDetailScreen(
                surah: entry.s,
                ayah: entry.v,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ayah number badge + audio button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
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
                  // Per-ayah audio: plays this ayah (auto-advances
                  // ayah-by-ayah like the Ayah Player). Shows pause
                  // while this ayah plays.
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
                        tooltip: isThisPlaying
                            ? 'Pause'
                            : 'Ayah ki audio sunain',
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
                  Icon(Icons.chevron_right, color: cs.primary),
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
              // "Tafsir Parhiye" hint
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_stories, size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    'تفسیر پڑھیے',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      body: FutureBuilder<_SurahListData>(
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
                      'Ayah list load nahi ho saki',
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
          return ListView(
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

/// Loaded data for one surah's Ayah List view (no tafsir).
class _SurahListData {
  final List<QuranTextEntry> entries;
  final Map<String, String> urdu;

  const _SurahListData({
    required this.entries,
    required this.urdu,
  });
}
