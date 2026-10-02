import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/quran_data.dart';
import '../data/verse_index.dart';
import '../services/audio_recitation_service.dart';
import '../services/preferences_service.dart';
import '../utils/script_font.dart';

/// Cached full-Quran text (Arabic + English) for the player sheet.
Future<List<QuranTextEntry>>? _quranTextFuture;

/// Opens the ayah player: highlights the tapped ayah and plays its audio,
/// advancing ayah-by-ayah until the user presses stop.
void showAyahPlayer(BuildContext context,
    {required int surah, required int ayah}) {
  final audio = Provider.of<AudioRecitationService>(context, listen: false);
  _quranTextFuture ??= loadQuranText();
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
                  child: FutureBuilder<List<QuranTextEntry>>(
                    future: _quranTextFuture,
                    builder: (context, snap) {
                      final entry = _find(snap.data, s, v);
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
