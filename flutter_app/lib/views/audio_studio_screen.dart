import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/quran_data.dart';
import '../models/surah.dart';
import '../services/audio_recitation_service.dart';
import '../services/preferences_service.dart';
import '../services/qari_audio_storage.dart';
import '../services/qari_download_service.dart';
import '../utils/script_font.dart';
import 'offline_download_screen.dart';

/// Audio Studio: choose a world-renowned reciter, quick-play beloved surahs,
/// browse all surahs with filters (like the website's audio tab), and control
/// the currently playing recitation (speed + repeat).
///
/// Reciter cards show truthful, clearly differentiated states:
/// selected / downloaded (verified on disk) / downloading / paused /
/// incomplete / partially downloaded / unavailable-offline.
class AudioStudioScreen extends StatefulWidget {
  const AudioStudioScreen({super.key});

  @override
  State<AudioStudioScreen> createState() => _AudioStudioScreenState();
}

class _AudioStudioScreenState extends State<AudioStudioScreen> {
  // 0 = All 114, 1 = Juz 'Amma (78-114), 2 = Makki, 3 = Madani
  int _filterIndex = 0;
  String _reciterQuery = '';
  final TextEditingController _reciterSearchController =
      TextEditingController();

  /// null = still checking, true/false = result.
  bool? _online;

  /// One-time disk scan of partial packs, so cards can truthfully show
  /// "Partially downloaded" (keyed by qari id -> (surahs, ayahs)).
  Map<String, (int, int)> _diskCounts = {};

  @override
  void initState() {
    super.initState();
    // Lazy disk scan so "Offline" chips reflect already-downloaded packs.
    Future.microtask(() {
      if (!mounted) return;
      context.read<QariDownloadService>().refreshCompleteCache();
    });
    _checkConnectivity();
    _loadDiskCounts();
  }

  @override
  void dispose() {
    _reciterSearchController.dispose();
    super.dispose();
  }

  /// Best-effort connectivity probe (general internet, not a specific
  /// reciter server). Drives the offline banner and the per-card
  /// "Unavailable offline" state. Never throws.
  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      setState(() {
        _online = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _online = false);
    }
  }

  Future<void> _loadDiskCounts() async {
    try {
      final dl = context.read<QariDownloadService>();
      final map = <String, (int, int)>{};
      for (final q in availableQaris) {
        map[q.id] = await dl.countsOf(q.id);
      }
      if (!mounted) return;
      setState(() => _diskCounts = map);
    } catch (_) {}
  }

  List<Qari> _filteredQaris() {
    final q = _reciterQuery.trim().toLowerCase();
    if (q.isEmpty) return availableQaris;
    return availableQaris.where((r) {
      return r.name.toLowerCase().contains(q) ||
          r.arabic.contains(_reciterQuery.trim()) ||
          r.style.toLowerCase().contains(q) ||
          r.country.toLowerCase().contains(q);
    }).toList();
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

  Future<void> _confirmDeletePack(BuildContext context, Qari q) async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title: const Text('Delete downloaded audio?'),
        content: Text(
          '${q.name} (${q.style}) ka downloaded pack delete ho jayega. '
          'Streaming phir bhi chalta rahega.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: cs.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<QariDownloadService>().deleteDownload(q.id);
      await _loadDiskCounts();
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
          // Offline banner (streaming unavailable, downloads still play)
          // ---------------------------------------------------------
          if (_online == false) ...[
            Card(
              color: colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                    color: colorScheme.error.withValues(alpha: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, color: colorScheme.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You appear to be offline — streaming nahi chalega, '
                        'lekin downloaded reciters bajenge.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _online = null);
                        _checkConnectivity();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ---------------------------------------------------------
          // Choose World-Renowned Reciter
          // ---------------------------------------------------------
          Consumer2<AudioRecitationService, QariDownloadService>(
            builder: (context, audio, dl, _) {
              final qaris = _filteredQaris();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _sectionTitle(context,
                            'Choose World-Renowned Reciter', '🎙️', gold),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.folder_open, size: 18),
                        label: const Text('Manage'),
                        style: TextButton.styleFrom(
                          foregroundColor: gold,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const OfflineDownloadScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: gold.withValues(alpha: 0.5)),
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
                  const SizedBox(height: 10),
                  TextField(
                    controller: _reciterSearchController,
                    textInputAction: TextInputAction.search,
                    onChanged: (v) =>
                        setState(() => _reciterQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search reciters by name, style or country…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _reciterQuery.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: 'Clear reciter search',
                              onPressed: () {
                                _reciterSearchController.clear();
                                setState(() => _reciterQuery = '');
                              },
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Showing ${qaris.length} of ${availableQaris.length} reciters',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (qaris.isEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No reciters match "$_reciterQuery"',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: qaris.length,
                    itemBuilder: (context, i) => _reciterCard(
                      context,
                      qaris[i],
                      audio,
                      dl,
                    ),
                  ),
                  if (dl.hasActiveDownload)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Ek waqt me sirf ek reciter download hota hai — '
                        'doosra shuru karne par pehla pause ho jayega.',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
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
          _nowPlayingCard(context),

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
                side: BorderSide(
                    color: gold.withValues(alpha: 0.5)),
                onSelected: (_) =>
                    setState(() => _filterIndex = i),
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
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 6),
                itemBuilder: (context, i) {
                  final s = list[i];
                  final isPlaying =
                      audio.isPlaying && audio.currentSurah == s.number;
                  return Card(
                    color: colorScheme.surface,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isPlaying
                            ? gold
                            : theme.dividerColor
                                .withValues(alpha: 0.3),
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            gold.withValues(alpha: isPlaying ? 1.0 : 0.15),
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

  /// One reciter card with a clearly differentiated, truthful state:
  /// selected / downloaded (verified) / downloading / paused / incomplete /
  /// partially downloaded / unavailable-offline. Never claims "downloaded"
  /// until the full pack is verified on disk.
  Widget _reciterCard(
    BuildContext context,
    Qari q,
    AudioRecitationService audio,
    QariDownloadService dl,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final gold = cs.primary;
    final selected = q.id == audio.selectedQari.id;
    final progress = dl.progressOf(q.id);
    // TRUTHFUL "downloaded": the download service verified the full pack
    // (114 surah + 6236 ayah files) on disk — never from a flag alone.
    final downloaded = progress.state == QariPackState.complete ||
        dl.isKnownComplete(q.id);
    final counts = _diskCounts[q.id];
    final partialFiles = (counts?.$1 ?? 0) + (counts?.$2 ?? 0);
    final online = _online != false;

    Widget statusRow;
    switch (progress.state) {
      case QariPackState.downloading:
        statusRow = _downloadProgressRow(
          context,
          label:
              'Downloading… ${progress.done} / ${progress.total} (${(progress.fraction * 100).toStringAsFixed(0)}%)',
          fraction: progress.fraction,
          actions: [
            IconButton(
              icon: const Icon(Icons.pause_circle_outline),
              tooltip: 'Pause download',
              color: gold,
              onPressed: () => dl.pauseDownload(q.id),
            ),
          ],
        );
        break;
      case QariPackState.paused:
        statusRow = Row(
          children: [
            Expanded(
              child: _statusChip(
                context,
                'Paused • ${(progress.fraction * 100).toStringAsFixed(0)}% downloaded',
                Icons.pause_circle_outline,
                cs.onSurfaceVariant,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.play_circle_outline),
              tooltip: 'Resume download',
              color: gold,
              onPressed: () => dl.startDownload(q),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete downloaded files',
              color: cs.onSurfaceVariant,
              onPressed: () => _confirmDeletePack(context, q),
            ),
          ],
        );
        break;
      case QariPackState.error:
        statusRow = Row(
          children: [
            Expanded(
              child: _statusChip(
                context,
                'Incomplete • ${progress.errorCount} file(s) failed',
                Icons.error_outline,
                cs.error,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Retry failed files',
              color: gold,
              onPressed: () => dl.startDownload(q),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete downloaded files',
              color: cs.onSurfaceVariant,
              onPressed: () => _confirmDeletePack(context, q),
            ),
          ],
        );
        break;
      case QariPackState.complete:
      case QariPackState.idle:
        if (downloaded) {
          statusRow = Row(
            children: [
              Expanded(
                child: _statusChip(
                  context,
                  'Offline • ${QariAudioStorage.totalPackFiles} files verified',
                  Icons.offline_pin_outlined,
                  gold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete downloaded audio',
                color: cs.onSurfaceVariant,
                onPressed: () => _confirmDeletePack(context, q),
              ),
            ],
          );
        } else if (partialFiles > 0) {
          statusRow = Row(
            children: [
              Expanded(
                child: _statusChip(
                  context,
                  'Partially downloaded • $partialFiles files',
                  Icons.downloading_outlined,
                  cs.onSurfaceVariant,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined),
                tooltip: 'Resume download',
                color: gold,
                onPressed: () => dl.startDownload(q),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete downloaded files',
                color: cs.onSurfaceVariant,
                onPressed: () => _confirmDeletePack(context, q),
              ),
            ],
          );
        } else if (online) {
          statusRow = Row(
            children: [
              Expanded(
                child: Text(
                  'Stream online • download for offline',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined),
                tooltip: 'Download for offline',
                color: gold,
                onPressed: () => dl.startDownload(q),
              ),
            ],
          );
        } else {
          statusRow = _statusChip(
            context,
            'Unavailable offline',
            Icons.cloud_off_outlined,
            cs.onSurfaceVariant,
          );
        }
        break;
    }

    return Card(
      color: cs.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? gold : theme.dividerColor.withValues(alpha: 0.3),
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => audio.setQari(q),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: selected
                        ? gold
                        : cs.onSurface.withValues(alpha: 0.1),
                    child: Icon(Icons.mic,
                        color: selected ? cs.onPrimary : gold),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                q.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (selected)
                              Container(
                                margin:
                                    const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: gold,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Selected',
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(
                                    color: cs.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          q.arabic,
                          style: arabicStyle(
                              context
                                  .read<PreferencesService>()
                                  .scriptStyle,
                              fontSize: 16,
                              color: theme.textTheme.bodySmall?.color ??
                                  cs.onSurface),
                        ),
                        Text('${q.style} • ${q.country}',
                            style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: selected
                        ? gold
                        : cs.onSurfaceVariant,
                    semanticLabel:
                        selected ? 'Selected reciter' : 'Select reciter',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              statusRow,
            ],
          ),
        ),
      ),
    );
  }

  /// Small tinted status chip with an icon.
  Widget _statusChip(
      BuildContext context, String label, IconData icon, Color color) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(
                    color: color == cs.onSurfaceVariant
                        ? cs.onSurfaceVariant
                        : color,
                    fontWeight: FontWeight.w600,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Download progress row: label + determinate progress bar + actions.
  Widget _downloadProgressRow(
    BuildContext context, {
    required String label,
    required double fraction,
    required List<Widget> actions,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final gold = cs.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: gold,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ...actions,
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: gold.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(gold),
            semanticsLabel: label,
          ),
        ),
      ],
    );
  }

  /// Now Playing card: status (loading / error+retry / playing / paused),
  /// prev/play/next, position progress, resume-last-session, speed, repeat.
  Widget _nowPlayingCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final gold = cs.primary;

    return Consumer<AudioRecitationService>(
      builder: (context, audio, _) {
        final prefs = context.watch<PreferencesService>();
        final hasTrack = audio.hasActiveTrack;
        final surah =
            hasTrack ? allSurahs[audio.currentSurah - 1] : null;

        return Card(
          color: cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
                color: gold.withValues(alpha: 0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- status banner ----
                if (audio.errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: cs.error.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: cs.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            audio.errorMessage!,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: cs.error),
                          ),
                        ),
                        TextButton(
                          onPressed: () => audio.retryLast(),
                          child: const Text('Retry'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          tooltip: 'Dismiss',
                          color: cs.onSurfaceVariant,
                          onPressed: () => audio.clearError(),
                        ),
                      ],
                    ),
                  )
                else if (audio.isLoading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: gold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Loading audio…',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: gold),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            surah != null
                                ? surah.nameEn
                                : 'Nothing playing',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: gold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (surah != null)
                            Text(
                              surah.nameAr,
                              style: arabicStyle(
                                  prefs.scriptStyle,
                                  fontSize: 22),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            'Qari: ${audio.selectedQari.name} (${audio.selectedQari.style})',
                            style: theme.textTheme.labelSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            audio.statusText,
                            style: theme.textTheme.labelSmall
                                ?.copyWith(
                              color: audio.isPlaying
                                  ? gold
                                  : cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // prev / play / next
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      tooltip: audio.ayahMode
                          ? 'Previous ayah'
                          : 'Previous surah',
                      color: gold,
                      iconSize: 32,
                      onPressed: !hasTrack
                          ? null
                          : () => audio.ayahMode
                              ? audio.playPrevAyah()
                              : audio.playPrevSurah(),
                    ),
                    GestureDetector(
                      onTap: !hasTrack
                          ? null
                          : () {
                              if (audio.isPlaying) {
                                audio.pause();
                              } else {
                                audio.resume();
                              }
                            },
                      child: Opacity(
                        opacity: hasTrack ? 1.0 : 0.4,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: gold,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    gold.withValues(alpha: 0.25),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            audio.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: cs.onPrimary,
                            size: 30,
                            semanticLabel: audio.isPlaying
                                ? 'Pause'
                                : 'Play',
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      tooltip: audio.ayahMode
                          ? 'Next ayah'
                          : 'Next surah',
                      color: gold,
                      iconSize: 32,
                      onPressed: !hasTrack
                          ? null
                          : () => audio.ayahMode
                              ? audio.playNextAyah()
                              : audio.playNextSurah(),
                    ),
                  ],
                ),
                // ---- position progress (surah mode) ----
                if (hasTrack && !audio.ayahMode) ...[
                  const SizedBox(height: 8),
                  _positionBar(context, audio),
                ],
                // ---- resume last session ----
                if (!hasTrack) ...[
                  const SizedBox(height: 8),
                  _ResumeLastSessionButton(audio: audio),
                ],
                // ---- active ayah repeat range ----
                if (audio.hasAyahRepeatRange) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: gold.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.repeat, size: 14, color: gold),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            audio.repeatRangeLabel ?? '',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(
                              color: gold,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () =>
                              audio.clearAyahRepeatRange(),
                          child: Icon(Icons.close,
                              size: 16, color: gold),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text('Speed',
                    style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold)),
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
                            ? cs.onPrimary
                            : cs.onSurface,
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
                    style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold)),
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
    );
  }

  /// Position / duration bar for whole-surah playback.
  Widget _positionBar(
      BuildContext context, AudioRecitationService audio) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;
    return StreamBuilder<Duration?>(
      stream: audio.player.durationStream,
      builder: (context, durSnap) {
        return StreamBuilder<Duration>(
          stream: audio.player.positionStream,
          builder: (context, posSnap) {
            final dur = durSnap.data ?? Duration.zero;
            final pos = posSnap.data ?? Duration.zero;
            if (dur == Duration.zero) {
              return const SizedBox.shrink();
            }
            final frac = (pos.inMilliseconds /
                    dur.inMilliseconds)
                .clamp(0.0, 1.0);
            return Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: frac,
                    minHeight: 5,
                    backgroundColor:
                        gold.withValues(alpha: 0.2),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(gold),
                    semanticsLabel:
                        'Playback position ${_fmtDur(pos)} of ${_fmtDur(dur)}',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _fmtDur(pos),
                      style: theme.textTheme.labelSmall
                          ?.copyWith(
                              color: theme.colorScheme
                                  .onSurfaceVariant),
                    ),
                    Text(
                      _fmtDur(dur),
                      style: theme.textTheme.labelSmall
                          ?.copyWith(
                              color: theme.colorScheme
                                  .onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  static String _fmtDur(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$m:$ss';
  }
}

/// "Resume where you left off" button, shown when nothing is playing yet.
/// Loads the saved session label once in initState (not on every build).
class _ResumeLastSessionButton extends StatefulWidget {
  final AudioRecitationService audio;
  const _ResumeLastSessionButton({required this.audio});

  @override
  State<_ResumeLastSessionButton> createState() =>
      _ResumeLastSessionButtonState();
}

class _ResumeLastSessionButtonState
    extends State<_ResumeLastSessionButton> {
  late final Future<String?> _labelFuture;

  @override
  void initState() {
    super.initState();
    _labelFuture = widget.audio.lastSessionDescription();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;
    return FutureBuilder<String?>(
      future: _labelFuture,
      builder: (context, snap) {
        final label = snap.data;
        if (label == null) return const SizedBox.shrink();
        return OutlinedButton.icon(
          icon: const Icon(Icons.history, size: 18),
          label: Text('Resume: $label',
              overflow: TextOverflow.ellipsis),
          style: OutlinedButton.styleFrom(
            foregroundColor: gold,
            side: BorderSide(
                color: gold.withValues(alpha: 0.6)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () => widget.audio.resumeLastSession(),
        );
      },
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
      side: BorderSide(color: gold.withValues(alpha: 0.6)),
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
