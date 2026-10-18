import 'package:flutter/material.dart';
import '../main.dart';
import 'package:provider/provider.dart';
import '../data/quran_data.dart';
import '../data/verse_index.dart';
import '../services/audio_recitation_service.dart';
import '../services/preferences_service.dart';
import '../services/tafsir_service.dart';
import '../utils/script_font.dart';

/// Detail page for ONE ayah: Arabic ayah on top → Urdu Kanzul Iman
/// tarjuma → English → full Ibn Kathir Urdu tafsir.
///
/// Tafsir is loaded lazily for THIS ayah only (one
/// [TafsirService.getTafsir] lookup), so the page opens fast —
/// unlike the old flow, which fetched tafsir for every ayah in the
/// surah before showing anything.
class TafsirAyahDetailScreen extends StatefulWidget {
  final int surah;
  final int ayah;

  const TafsirAyahDetailScreen({
    required this.surah,
    required this.ayah,
    super.key,
  });

  @override
  State<TafsirAyahDetailScreen> createState() =>
      _TafsirAyahDetailScreenState();
}

class _TafsirAyahDetailScreenState extends State<TafsirAyahDetailScreen> {
  Future<_AyahDetailData>? _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadData();
  }

  /// Loads this one ayah's Arabic+English, Urdu, and tafsir.
  Future<_AyahDetailData> _loadData() async {
    final results = await Future.wait([
      loadQuranText(),
      loadUrduKanzulIman(),
      TafsirService().getTafsir(widget.surah, widget.ayah),
    ]);
    final entries = results[0] as List<QuranTextEntry>;
    final urdu = results[1] as Map<String, String>;
    final tafsir = results[2] as String?;
    final entry = entries.firstWhere(
      (e) => e.s == widget.surah && e.v == widget.ayah,
      orElse: () => QuranTextEntry(
          s: widget.surah, v: widget.ayah, ar: '', en: ''),
    );
    return _AyahDetailData(
      entry: entry,
      urduText: urdu['${widget.surah}:${widget.ayah}'] ?? '',
      tafsir: tafsir,
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
          '${surah.nameEn} — Ayah ${widget.ayah}',
          style: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),
      body: FutureBuilder<_AyahDetailData>(
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
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.error.withValues(alpha: 0.08),
                        border: Border.all(
                            color: cs.error.withValues(alpha: 0.30)),
                      ),
                      child: Icon(Icons.error_outline,
                          color: cs.error, size: 32),
                    ),
                    const SizedBox(height: Nur.s12),
                    const Text(
                      'Ayah load nahi ho saki',
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
          final entry = data.entry;
          final tafsirText = data.tafsir;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                Nur.screenMargin, Nur.s8, Nur.screenMargin, Nur.s24),
            child: Container(
              padding: const EdgeInsets.all(Nur.s20),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(Nur.cardRadius),
                border: Border.all(
                  color: cs.outlineVariant,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.06),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'Surah ${widget.surah} • Ayah ${widget.ayah}',
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Consumer<AudioRecitationService>(
                        builder: (context, audio, _) {
                          final isThisPlaying = audio.isPlaying &&
                              audio.currentSurah == widget.surah &&
                              audio.currentAyah == widget.ayah;
                          return IconButton(
                            icon: Icon(
                              isThisPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill,
                              color: cs.primary,
                              size: 32,
                            ),
                            tooltip: isThisPlaying
                                ? 'Pause'
                                : 'Ayah ki audio sunain',
                            onPressed: () async {
                              final svc =
                                  Provider.of<AudioRecitationService>(
                                      context,
                                      listen: false);
                              if (isThisPlaying) {
                                await svc.pause();
                                return;
                              }
                              final ok = await svc.playAyah(
                                  surah: widget.surah,
                                  ayah: widget.ayah,
                                  singleAyah: true);
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
                  const SizedBox(height: 16),
                  // Arabic ayah (large)
                  Text(
                    entry.ar,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: arabicStyle(
                      prefs.scriptStyle,
                      fontSize: 30,
                      color: cs.onSurface,
                      scale: prefs.ayahScale,
                    ),
                  ),
                  // Urdu tarjuma
                  if (data.urduText.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      data.urduText,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: urduStyle(
                        fontSize: 18,
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
                    const SizedBox(height: 16),
                    Text(
                      entry.en,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.5,
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
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                          child: Divider(color: cs.outlineVariant)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.diamond,
                            size: 12, color: cs.tertiary),
                      ),
                      Expanded(
                          child: Divider(color: cs.outlineVariant)),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                          fontSize: 17,
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
                  const SizedBox(height: 12),
                  // Tafsir text (or graceful not-available note)
                  if (tafsirText != null && tafsirText.trim().isNotEmpty)
                    Text(
                      tafsirText,
                      textDirection: TextDirection.rtl,
                      style: urduStyle(
                        fontSize: 17,
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
            ),
          );
        },
      ),
    );
  }
}

/// Loaded data for one ayah's detail page.
class _AyahDetailData {
  final QuranTextEntry entry;
  final String urduText;
  final String? tafsir;

  const _AyahDetailData({
    required this.entry,
    required this.urduText,
    required this.tafsir,
  });
}
