import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/quran_data.dart';
import '../services/audio_recitation_service.dart';
import '../services/preferences_service.dart';
import '../utils/script_font.dart';

/// Audio Studio: choose a world-renowned reciter, quick-play beloved surahs,
/// and control the currently playing recitation (speed + repeat).
class AudioStudioScreen extends StatelessWidget {
  const AudioStudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gold = colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Audio Recitations'),
            Text(
              '${availableQaris.length} Reciter Masters',
              style: theme.textTheme.labelSmall?.copyWith(
                color: gold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------------------------------------------------------
          // Choose World-Renowned Reciter
          // ---------------------------------------------------------
          Consumer<AudioRecitationService>(
            builder: (context, audio, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(
                      context, 'Choose World-Renowned Reciter', '🎙️', gold),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: gold.withOpacity(0.5)),
                    ),
                    child: DropdownButton<Qari>(
                      value: audio.selectedQari,
                      isExpanded: true,
                      underline: const SizedBox(),
                      dropdownColor: colorScheme.surface,
                      icon: Icon(Icons.arrow_drop_down, color: gold),
                      style: theme.textTheme.bodyMedium,
                      items: availableQaris
                          .map((q) => DropdownMenuItem<Qari>(
                                value: q,
                                child: Text(
                                  '${q.name} (${q.style})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (q) async {
                        if (q != null) await audio.setQari(q);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: availableQaris.length,
                    itemBuilder: (context, i) {
                      final q = availableQaris[i];
                      final selected = q.id == audio.selectedQari.id;
                      return Card(
                        color: colorScheme.surface,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: selected
                                ? gold
                                : theme.dividerColor.withOpacity(0.3),
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: selected
                                ? gold
                                : colorScheme.onSurface.withOpacity(0.1),
                            child: Icon(Icons.mic,
                                color: selected ? colorScheme.onPrimary : gold),
                          ),
                          title: Text(q.name,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                q.arabic,
                                style: arabicStyle(
                                    context
                                        .read<PreferencesService>()
                                        .scriptStyle,
                                    fontSize: 16,
                                    color: theme.textTheme.bodySmall?.color ??
                                        colorScheme.onSurface),
                              ),
                              Text('${q.style} • ${q.country}',
                                  style: theme.textTheme.labelSmall),
                            ],
                          ),
                          trailing: selected
                              ? Icon(Icons.check_circle, color: gold)
                              : const Icon(Icons.radio_button_unchecked),
                          onTap: () => audio.setQari(q),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // ---------------------------------------------------------
          // Quick Play
          // ---------------------------------------------------------
          _sectionTitle(context, 'Quick Play', '⚡', gold),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _QuickPlayChip(label: 'Al-Fatihah', surahNumber: 1),
              _QuickPlayChip(label: 'Ya-Sin', surahNumber: 36),
              _QuickPlayChip(label: 'Ar-Rahman', surahNumber: 55),
              _QuickPlayChip(label: 'Al-Mulk', surahNumber: 67),
            ],
          ),

          const SizedBox(height: 16),

          // ---------------------------------------------------------
          // Now Playing
          // ---------------------------------------------------------
          _sectionTitle(context, 'Now Playing', '🎧', gold),
          const SizedBox(height: 8),
          Consumer<AudioRecitationService>(
            builder: (context, audio, _) {
              final prefs = context.watch<PreferencesService>();
              final hasTrack = audio.currentSurah > 0;
              final surah = hasTrack ? allSurahs[audio.currentSurah - 1] : null;

              return Card(
                color: colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: gold.withOpacity(0.4)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  surah != null
                                      ? surah.nameEn
                                      : 'Nothing playing',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: gold,
                                  ),
                                ),
                                if (surah != null)
                                  Text(
                                    surah.nameAr,
                                    style: arabicStyle(prefs.scriptStyle,
                                        fontSize: 22),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  'Qari: ${audio.selectedQari.name} (${audio.selectedQari.style})',
                                  style: theme.textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (audio.isPlaying) {
                                audio.pause();
                              } else if (audio.currentSurah > 0) {
                                audio.playSurah(
                                    surahNumber: audio.currentSurah);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: gold,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: gold.withOpacity(0.4),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Icon(
                                audio.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: colorScheme.onPrimary,
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Speed',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [0.5, 1.0, 1.25, 1.5, 2.0].map((s) {
                          final selected = prefs.playbackSpeed == s;
                          return ChoiceChip(
                            label: Text('${s}x'),
                            selected: selected,
                            selectedColor: gold,
                            labelStyle: TextStyle(
                              color: selected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                            ),
                            onSelected: (_) async {
                              await audio.setSpeed(s);
                              await prefs.setPlaybackSpeed(s);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Text('Repeat',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: const [
                          _RepeatChip(label: 'Off', mode: 0),
                          _RepeatChip(label: '1x', mode: 1),
                          _RepeatChip(label: '3x', mode: 3),
                          _RepeatChip(label: '5x', mode: 5),
                          _RepeatChip(label: '∞', mode: -1),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

Widget _sectionTitle(
    BuildContext context, String title, String emoji, Color accent) {
  return Text(
    '$emoji  $title',
    style: Theme.of(context)
        .textTheme
        .titleSmall
        ?.copyWith(fontWeight: FontWeight.bold, color: accent),
  );
}

class _QuickPlayChip extends StatelessWidget {
  final String label;
  final int surahNumber;
  const _QuickPlayChip({required this.label, required this.surahNumber});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;
    return ActionChip(
      avatar: Icon(Icons.play_circle_outline, color: gold, size: 18),
      label: Text(label),
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(color: gold.withOpacity(0.6)),
      onPressed: () {
        // AudioStudioScreen's quick play: apply saved speed + repeat prefs.
        final audio = context.read<AudioRecitationService>();
        final prefs = context.read<PreferencesService>();
        audio.setRepeatMode(prefs.repeatMode);
        audio.setSpeed(prefs.playbackSpeed).then(
              (_) => audio.playSurah(surahNumber: surahNumber),
            );
      },
    );
  }
}

class _RepeatChip extends StatelessWidget {
  final String label;
  final int mode;
  const _RepeatChip({required this.label, required this.mode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;
    final prefs = context.watch<PreferencesService>();
    final selected = prefs.repeatMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: gold,
      labelStyle: TextStyle(
        color: selected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface,
      ),
      onSelected: (_) {
        final audio = context.read<AudioRecitationService>();
        audio.setRepeatMode(mode);
        prefs.setRepeatMode(mode);
      },
    );
  }
}
