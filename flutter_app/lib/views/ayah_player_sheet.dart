import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/quran_data.dart';
import '../data/verse_index.dart';
import '../services/audio_recitation_service.dart';
import '../services/preferences_service.dart';
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
  final name = allSurahs[(surah - 1).clamp(0, 113)].nameEn;
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
        final surahName = allSurahs[s - 1].nameEn;
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$surahName • $s:$v',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
              // Highlighted current ayah
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
                        final entry = _find(list, s, v);
                        final urdu = urduMap?['$s:$v'] ?? '';
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: cs.primary.withValues(alpha: 0.5)),
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
                                ],
                              ),
                      );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 32,
                    tooltip: 'Previous ayah',
                    icon: Icon(Icons.skip_previous, color: cs.primary),
                    onPressed: () => audio.playPrevAyah(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    iconSize: 56,
                    tooltip: audio.isPlaying ? 'Pause' : 'Play',
                    icon: Icon(
                      audio.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: cs.primary,
                    ),
                    onPressed: () =>
                        audio.isPlaying ? audio.pause() : audio.resume(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    iconSize: 32,
                    tooltip: 'Next ayah',
                    icon: Icon(Icons.skip_next, color: cs.primary),
                    onPressed: () => audio.playNextAyah(),
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
                audio.selectedQari.name,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              Text(
                'Ayah-by-ayah • plays until you press stop',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
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
              border: const OutlineInputBorder(),
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
              border: const OutlineInputBorder(),
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
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text('Start'),
        ),
      ],
    );
  }
}
