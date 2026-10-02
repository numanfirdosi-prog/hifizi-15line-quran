import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/quran_data.dart';
import '../models/surah.dart';
import '../services/audio_recitation_service.dart';
import '../services/preferences_service.dart';
import '../services/qari_download_service.dart';
import '../utils/script_font.dart';
import 'offline_download_screen.dart';

/// Audio Studio: choose a world-renowned reciter, quick-play beloved surahs,
/// browse all surahs with filters (like the website's audio tab), and control
/// the currently playing recitation (speed + repeat).
class AudioStudioScreen extends StatefulWidget {
  const AudioStudioScreen({super.key});

  @override
  State<AudioStudioScreen> createState() => _AudioStudioScreenState();
}

class _AudioStudioScreenState extends State<AudioStudioScreen> {
  // 0 = All 114, 1 = Juz 'Amma (78-114), 2 = Makki, 3 = Madani
  int _filterIndex = 0;

  @override
  void initState() {
    super.initState();
    // Lazy disk scan so "Offline" chips reflect already-downloaded packs.
    Future.microtask(() {
      if (!mounted) return;
      context.read<QariDownloadService>().refreshCompleteCache();
    });
  }

  List<Surah> _filteredSurahs() {
    switch (_filterIndex) {
      case 1:
        return allSurahs.where((s) => s.number >= 78).toList();
      case 2:
        return allSurahs.where((s) => s.isMeccan).toList();
      case 3:
        return allSurahs.where((s) => !s.isMeccan).toList();
      default:
        return allSurahs;
    }
  }

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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Consumer<QariDownloadService>(
                                builder: (context, dl, _) {
                                  final offline = dl
                                              .progressOf(q.id)
                                              .state ==
                                          QariPackState.complete ||
                                      dl.isKnownComplete(q.id);
                                  if (!offline) {
                                    return const SizedBox.shrink();
                                  }
                                  return Container(
                                    margin: const EdgeInsets.only(right: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: gold.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: gold.withOpacity(0.5)),
                                    ),
                                    child: Text(
                                      'Offline',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: gold,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.download_outlined),
                                color: gold,
                                tooltip: 'Download for offline',
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const OfflineDownloadScreen(),
                                    ),
                                  );
                                },
                              ),
                              selected
                                  ? Icon(Icons.check_circle, color: gold)
                                  : const Icon(
                                      Icons.radio_button_unchecked),
                            ],
                          ),
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

          const SizedBox(height: 16),

          // ---------------------------------------------------------
          // Browse & Play (website audio-tab filters)
          // ---------------------------------------------------------
          _sectionTitle(context, 'Browse & Play', '📚', gold),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(4, (i) {
              const labels = [
                'All 114 Surahs',
                "Juz 'Amma (78–114)",
                'Makki Surahs',
                'Madani Surahs',
              ];
              final selected = _filterIndex == i;
              return ChoiceChip(
                label: Text(labels[i]),
                selected: selected,
                selectedColor: gold,
                backgroundColor: colorScheme.surface,
                labelStyle: TextStyle(
                  color: selected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(color: gold.withOpacity(0.5)),
                onSelected: (_) => setState(() => _filterIndex = i),
              );
            }),
          ),
          const SizedBox(height: 8),
          Consumer<AudioRecitationService>(
            builder: (context, audio, _) {
              final list = _filteredSurahs();
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, i) {
                  final s = list[i];
                  final isPlaying =
                      audio.isPlaying && audio.currentSurah == s.number;
                  return Card(
                    color: colorScheme.surface,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isPlaying
                            ? gold
                            : theme.dividerColor.withOpacity(0.3),
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            gold.withOpacity(isPlaying ? 1.0 : 0.15),
                        child: Text(
                          '${s.number}',
                          style: TextStyle(
                            color: isPlaying
                                ? colorScheme.onPrimary
                                : gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        s.nameEn,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${s.totalAyahs} verses • ${s.isMeccan ? 'Makki' : 'Madani'}',
                        style: theme.textTheme.labelSmall,
                      ),
                      trailing: Text(
                        s.nameAr,
                        style: arabicStyle(
                            context
                                .read<PreferencesService>()
                                .scriptStyle,
                            fontSize: 18,
                            color: gold),
                      ),
                      onTap: () {
                        if (isPlaying) {
                          audio.pause();
                        } else {
                          final prefs =
                              context.read<PreferencesService>();
                          audio.setRepeatMode(prefs.repeatMode);
                          audio
                              .setSpeed(prefs.playbackSpeed)
                              .then((_) => audio.playSurah(
                                  surahNumber: s.number));
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 8),
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
