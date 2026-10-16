import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/quran_data.dart';
import '../data/verse_index.dart';
import '../main.dart';
import '../services/audio_recitation_service.dart';
import '../services/preferences_service.dart';
import '../services/tafsir_service.dart';
import '../utils/script_font.dart';

/// Cached full-Quran text (Arabic + English) for the player sheet.
Future<List<QuranTextEntry>>? _quranTextFuture;

/// Cached Urdu (Kanzul Iman) translation for the player sheet.
Future<Map<String, String>>? _urduFuture;

/// Combined player data: [List<QuranTextEntry>, Map<String, String>].
Future<List<dynamic>>? _playerDataFuture;

/// Shares an ayah via the Android share sheet (Arabic + English + reference).
/// Never includes private notes.
Future<void> shareAyah(BuildContext context,
    {required int surah, required int ayah}) async {
  final name = allSurahs[(surah - 1).clamp(0, 113)].nameEn;
  if (ayah == 0) {
    const text = 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ\n\n'
        '"In the name of Allah, the Entirely Merciful, the Especially Merciful."\n\n'
        '— Surah ';
    await Share.share('$text$name (Bismillah) • Nur Al-Quran');
    return;
  }
  _quranTextFuture ??= loadQuranText();
  final list = await _quranTextFuture;
  QuranTextEntry? entry;
  if (list != null) {
    for (final e in list) {
      if (e.s == surah && e.v == ayah) {
        entry = e;
        break;
      }
    }
  }
  final text = entry == null
      ? 'Surah $name ($surah:$ayah) — Nur Al-Quran'
      : '${entry.ar}\n\n"${entry.en}"\n\n— Surah $name ($surah:$ayah) • Nur Al-Quran';
  await Share.share(text);
}

/// Opens the ayah player: highlights the tapped ayah and plays its audio,
/// advancing ayah-by-ayah until the user presses stop.
void showAyahPlayer(BuildContext context,
    {required int surah, required int ayah}) {
  final audio = Provider.of<AudioRecitationService>(context, listen: false);
  _quranTextFuture ??= loadQuranText();
  _urduFuture ??= loadUrduKanzulIman();
  _playerDataFuture ??=
      Future.wait<dynamic>([_quranTextFuture!, _urduFuture!]);
  // Start playback after the sheet is on screen so the UI updates live.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final ok = await audio.playAyah(surah: surah, ayah: ayah);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio nahi chal saka — internet check karein'),
        ),
      );
    }
  });
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AyahPlayerSheet(),
  );
}

class _AyahPlayerSheet extends StatelessWidget {
  const _AyahPlayerSheet();

  QuranTextEntry? _find(List<QuranTextEntry>? list, int s, int v) {
    if (list == null) return null;
    for (final e in list) {
      if (e.s == s && e.v == v) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer2<AudioRecitationService, PreferencesService>(
      builder: (context, audio, prefs, _) {
        final s = audio.currentSurah.clamp(1, 114);
        final v = audio.currentAyah;
        final surah = allSurahs[s - 1];
        return ConstrainedBox(
          // Cap the sheet height so long translations scroll inside the
          // content area instead of pushing the pinned controls off-screen.
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.92,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(Nur.radiusSheet)),
              border: Border(
                top: BorderSide(color: Nur.goldBorder(), width: 1),
              ),
            ),
            padding: EdgeInsets.only(
              left: Nur.s20,
              right: Nur.s20,
              top: Nur.s12,
              bottom: MediaQuery.of(context).viewInsets.bottom + Nur.s16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle.
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: Nur.s12),
                // Header: Surah name + ayah number, share, close.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Surah ${surah.nameEn}',
                            style: TextStyle(
                              color: cs.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: Nur.fontTitle,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            v == 0
                                ? 'Bismillah'
                                : 'Ayah $v of ${surah.totalAyahs}',
                            style: TextStyle(
                              color: cs.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.share,
                          color: cs.onSurface.withValues(alpha: 0.6)),
                      tooltip: 'Share ayah',
                      onPressed: () =>
                          shareAyah(context, surah: s, ayah: v),
                    ),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: cs.onSurface.withValues(alpha: 0.6)),
                      tooltip: 'Close (audio keeps playing)',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Playback progress (gold) + state.
                StreamBuilder<double>(
                  stream: audio.ayahProgressStream,
                  initialData: 0.0,
                  builder: (context, psnap) => ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: (psnap.data ?? 0.0).clamp(0.0, 1.0),
                      minHeight: 3,
                      backgroundColor:
                          cs.onSurface.withValues(alpha: 0.12),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(cs.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${audio.isPlaying ? 'Playing' : 'Paused'} • ${audio.selectedQari.name}',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.6),
                      fontSize: Nur.fontCaption,
                    ),
                  ),
                ),
                const SizedBox(height: Nur.s8),
                // Scrollable content: Arabic, Urdu (RTL), English.
                // Flexible (not fixed) so short ayat shrink-wrap while long
                // translations scroll — never clipped behind the controls.
                Flexible(
                  child: SingleChildScrollView(
                    child: StatefulBuilder(
                      builder: (sctx, setState) =>
                          FutureBuilder<List<dynamic>>(
                        future: _playerDataFuture,
                        builder: (context, snap) {
                          // Load failure: show an error with Retry instead of
                          // spinning forever on the poisoned cached future.
                          if (snap.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: cs.error, size: 36),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Quran ka text load nahi ho saka',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: cs.onSurface, fontSize: 14),
                                    ),
                                    const SizedBox(height: 8),
                                    FilledButton(
                                      onPressed: () {
                                        // Drop the failed cached futures so the
                                        // retry actually re-fires them.
                                        _quranTextFuture = loadQuranText();
                                        _urduFuture =
                                            loadUrduKanzulIman();
                                        _playerDataFuture =
                                            Future.wait<dynamic>([
                                          _quranTextFuture!,
                                          _urduFuture!,
                                        ]);
                                        setState(() {});
                                      },
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          final list =
                              snap.data?[0] as List<QuranTextEntry>?;
                          final urduMap =
                              snap.data?[1] as Map<String, String>?;
                          final entry = v == 0
                              ? const QuranTextEntry(
                                  s: 1,
                                  v: 1,
                                  ar: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
                                  en: 'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
                                )
                              : _find(list, s, v);
                          final urdu = v == 0
                              ? 'شروع اللہ کے نام سے جو بے انتہا مہربان، نہایت رحم فرمانے والا ہے'
                              : (urduMap?['$s:$v'] ?? '');
                          return Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(Nur.s16),
                                decoration: BoxDecoration(
                                  // Restrained gold wash (not pale gold on
                                  // white): the ayah text stays the focus.
                                  color: cs.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                      Nur.buttonRadius),
                                  border: Border.all(
                                      color: Nur.goldBorder(0.35)),
                                ),
                            child: entry == null
                                ? Center(
                                    child: CircularProgressIndicator(
                                        color: cs.primary),
                                  )
                                : Column(
                                    children: [
                                      Text(
                                        entry.ar,
                                        textAlign: TextAlign.center,
                                        textDirection: TextDirection.rtl,
                                        style: arabicStyle(
                                          prefs.scriptStyle,
                                          fontSize: 26,
                                          color: cs.onSurface,
                                          scale: prefs.ayahScale,
                                          height: 2.0,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      if (urdu.isNotEmpty) ...[
                                        Text(
                                          urdu,
                                          textAlign: TextAlign.center,
                                          textDirection: TextDirection.rtl,
                                          style: urduStyle(
                                            fontSize: 18,
                                            color: cs.onSurface
                                                .withValues(alpha: 0.9),
                                            scale: prefs.ayahScale,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'ترجمہ: کنزالایمان (احمد رضا خان)',
                                          textAlign: TextAlign.center,
                                          textDirection: TextDirection.rtl,
                                          style: urduStyle(
                                            fontSize: 12,
                                            color: cs.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                      Text(
                                        entry.en,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: cs.onSurface
                                              .withValues(alpha: 0.85),
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'English: Saheeh International',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: cs.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                              ),
                              const SizedBox(height: 16),
                              _TafsirSection(surah: s, ayah: v),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Pinned controls: always visible, never scrolled away.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _playerControl(
                      context,
                      icon: Icons.skip_previous,
                      tooltip: 'Previous ayah',
                      iconSize: 32,
                      onTap: () => audio.playPrevAyah(),
                    ),
                    const SizedBox(width: 8),
                    _playerControl(
                      context,
                      icon: audio.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      tooltip: audio.isPlaying ? 'Pause' : 'Play',
                      iconSize: 48,
                      onTap: () =>
                          audio.isPlaying ? audio.pause() : audio.resume(),
                    ),
                    const SizedBox(width: 8),
                    _playerControl(
                      context,
                      icon: Icons.skip_next,
                      tooltip: 'Next ayah',
                      iconSize: 32,
                      onTap: () => audio.playNextAyah(),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    audio.stop();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.stop, size: 18),
                  label: const Text('Stop & Close'),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                _RepeatRangeRow(surah: s),
                const SizedBox(height: 4),
                Text(
                  'Ayah-by-ayah • plays until you press stop',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// One player control with a guaranteed 48dp minimum touch target.
  Widget _playerControl(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required double iconSize,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(Nur.s24),
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
              minWidth: Nur.minTouchTarget, minHeight: Nur.minTouchTarget),
          child: Center(
            child: Icon(icon, color: cs.primary, size: iconSize),
          ),
        ),
      ),
    );
  }

}

/// Repeat-range picker: loops ayahs [start]..[end] of the current surah.
/// Validates start <= end within the surah's ayah count.
class _RepeatRangeRow extends StatefulWidget {
  final int surah;
  const _RepeatRangeRow({required this.surah});

  @override
  State<_RepeatRangeRow> createState() => _RepeatRangeRowState();
}

class _RepeatRangeRowState extends State<_RepeatRangeRow> {
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final audio = Provider.of<AudioRecitationService>(context);
    final total = allSurahs[(widget.surah - 1).clamp(0, 113)].totalAyahs;
    if (audio.hasAyahRepeatRange) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: Nur.s12, vertical: Nur.s8),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Nur.radiusSm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.repeat, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              'Repeating ${audio.repeatRangeStart}–${audio.repeatRangeEnd}',
              style: TextStyle(
                  color: cs.onSurface, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: audio.clearAyahRepeatRange,
              child: const Text('Stop'),
            ),
          ],
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Repeat range:',
          style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.7), fontSize: 13),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 64,
          child: TextField(
            controller: _startCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurface, fontSize: 14),
            decoration: InputDecoration(
              hintText: '1',
              hintStyle: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.4)),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Nur.buttonRadius),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('–',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6))),
        ),
        SizedBox(
          width: 64,
          child: TextField(
            controller: _endCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurface, fontSize: 14),
            decoration: InputDecoration(
              hintText: '$total',
              hintStyle: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.4)),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Nur.buttonRadius),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () async {
            final start = int.tryParse(_startCtrl.text.trim());
            final end = int.tryParse(_endCtrl.text.trim());
            if (start == null ||
                end == null ||
                !AudioRecitationService.isValidAyahRange(
                    widget.surah, start, end)) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Invalid range — use 1–$total with start ≤ end'),
                  ),
                );
              }
              return;
            }
            await audio.setAyahRepeatRange(
              surah: widget.surah,
              startAyah: start,
              endAyah: end,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            padding:
                const EdgeInsets.symmetric(horizontal: Nur.s12, vertical: Nur.s8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Nur.buttonRadius),
            ),
          ),
          child: const Text('Start'),
        ),
      ],
    );
  }
}

/// Tafsir Ibn Kathir (Urdu) section shown below the ayah + translations
/// in the Ayah Player Sheet.
///
/// Loads the bundled offline tafsir for the current ayah via
/// [TafsirService]. Shows a loading shimmer while fetching, the full
/// tafsir text when available, and a graceful "not available" note
/// when this ayah is not covered by the bundled data (expected for
/// ayahs outside the bundled set — never an error).
class _TafsirSection extends StatefulWidget {
  final int surah;
  final int ayah;

  const _TafsirSection({required this.surah, required this.ayah});

  @override
  State<_TafsirSection> createState() => _TafsirSectionState();
}

class _TafsirSectionState extends State<_TafsirSection> {
  Future<String?>? _tafsirFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _TafsirSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surah != widget.surah ||
        oldWidget.ayah != widget.ayah) {
      _load();
    }
  }

  void _load() {
    _tafsirFuture = TafsirService().getTafsir(widget.surah, widget.ayah);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Nur.s16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(Nur.buttonRadius),
        border: Border.all(color: Nur.goldBorder(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Golden header: Tafsir Ibn Kathir.
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
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: Nur.s4),
          Divider(color: Nur.goldBorder(0.4)),
          const SizedBox(height: Nur.s8),
          FutureBuilder<String?>(
            future: _tafsirFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    textDirection: TextDirection.rtl,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'تفسیر لوڈ ہو رہی ہے...',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }
              final text = snap.data;
              if (text == null || text.trim().isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'اس آیت کی تفسیر دستیاب نہیں ہے۔',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                );
              }
              return Text(
                text,
                textDirection: TextDirection.rtl,
                style: urduStyle(
                  fontSize: 16,
                  color: cs.onSurface,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
