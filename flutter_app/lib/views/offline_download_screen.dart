import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:provider/provider.dart';

import '../services/audio_recitation_service.dart';
import '../services/qari_audio_storage.dart';
import '../services/qari_download_service.dart';
import '../utils/page_image_url.dart';

/// Pre-downloads mushaf page images into the image cache so they work
/// offline. Audio quick-set buttons stream only: the player caches audio in
/// its own internal store (not the image cache), so pre-downloading here
/// would not make audio available offline.
class OfflineDownloadScreen extends StatefulWidget {
  const OfflineDownloadScreen({super.key});

  @override
  State<OfflineDownloadScreen> createState() => _OfflineDownloadScreenState();
}

class _OfflineDownloadScreenState extends State<OfflineDownloadScreen> {
  static const _totalPages = 611;

  int _downloadedPages = 0;
  bool _downloadingPages = false;

  static const _quickSurahs = <int, String>{
    1: 'Al-Fatihah',
    36: 'Ya-Sin',
    55: 'Ar-Rahman',
    67: 'Al-Mulk',
  };

  Future<void> _downloadAllPages() async {
    setState(() {
      _downloadingPages = true;
      _downloadedPages = 0;
    });
    final cache = DefaultCacheManager();
    for (var i = 1; i <= _totalPages; i++) {
      try {
        await cache.downloadFile(mushafPageImageUrl(i));
      } catch (_) {}
      if (!mounted) return;
      setState(() => _downloadedPages = i);
    }
    if (!mounted) return;
    setState(() => _downloadingPages = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All pages downloaded for offline reading')),
    );
  }

  Future<void> _clearCache() async {
    try {
      await DefaultCacheManager().emptyCache();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not clear cache: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Download Center')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Mushaf pages section.
          Card(
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mushaf Pages',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Download all 611 pages for offline reading.',
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _downloadingPages ? null : _downloadAllPages,
                    child: Text(
                      _downloadingPages
                          ? 'Downloading…'
                          : 'Download all 611 pages',
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _downloadedPages / _totalPages,
                  ),
                  const SizedBox(height: 4),
                  Text('Downloaded $_downloadedPages / $_totalPages'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Qari audio packs (full offline downloads).
          const _QariAudioSection(),
          const SizedBox(height: 12),
          // Audio quick set.
          Card(
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Audio (Quick Set)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Popular surahs to keep handy.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry in _quickSurahs.entries)
                        OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Streaming only'),
                              ),
                            );
                          },
                          child: Text(entry.value),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Clear cache.
          Card(
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Storage',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Clear cache'),
                    onPressed: _clearCache,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Note card.
          Card(
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Pages are also cached automatically as you view them.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Qari audio packs: download a reciter's full pack (114 surah MP3s +
/// 6236 ayah MP3s) for offline playback everywhere audio plays.
class _QariAudioSection extends StatefulWidget {
  const _QariAudioSection();

  @override
  State<_QariAudioSection> createState() => _QariAudioSectionState();
}

class _QariAudioSectionState extends State<_QariAudioSection> {
  Map<String, (int, int)> _counts = {};
  Map<String, int> _bytes = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  /// (Re)scans each qari's pack directory for file counts and bytes.
  Future<void> _refresh() async {
    final dl = context.read<QariDownloadService>();
    await dl.refreshCompleteCache();
    final counts = <String, (int, int)>{};
    final bytes = <String, int>{};
    for (final q in availableQaris) {
      counts[q.id] = await dl.countsOf(q.id);
      bytes[q.id] = await dl.bytesOf(q.id);
    }
    if (!mounted) return;
    setState(() {
      _counts = counts;
      _bytes = bytes;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Qari Audio',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Download a reciter\u2019s full pack (114 surahs + 6,236 ayahs) '
              'for offline playback — everywhere audio plays. '
              'Best downloaded over Wi-Fi.',
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: availableQaris.length,
                itemBuilder: (context, i) {
                  final q = availableQaris[i];
                  return _QariRow(
                    qari: q,
                    counts: _counts[q.id],
                    bytes: _bytes[q.id],
                    onCountsDirty: _refresh,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _QariRow extends StatelessWidget {
  final Qari qari;
  final (int, int)? counts;
  final int? bytes;
  final VoidCallback onCountsDirty;

  const _QariRow({
    required this.qari,
    required this.counts,
    required this.bytes,
    required this.onCountsDirty,
  });

  static String _mb(int b) => '${(b / 1048576).toStringAsFixed(1)} MB';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;
    final dl = context.watch<QariDownloadService>();
    final p = dl.progressOf(qari.id);
    final complete =
        p.state == QariPackState.complete || dl.isKnownComplete(qari.id);
    final scannedTotal = counts == null ? 0 : counts!.$1 + counts!.$2;

    final String status;
    final int shownDone;
    final double barValue;
    if (complete) {
      status = 'Downloaded — plays offline';
      shownDone = QariAudioStorage.totalPackFiles;
      barValue = 1.0;
    } else if (p.state == QariPackState.downloading) {
      status = 'Downloading\u2026';
      shownDone = p.done;
      barValue = p.fraction;
    } else if (p.state == QariPackState.paused) {
      status = 'Paused';
      shownDone = p.done;
      barValue = p.fraction;
    } else if (p.state == QariPackState.error) {
      status = p.errorMessage ?? 'Error';
      shownDone = p.done;
      barValue = p.fraction;
    } else if (scannedTotal > 0) {
      status = 'Partially downloaded';
      shownDone = scannedTotal;
      barValue = scannedTotal / QariAudioStorage.totalPackFiles;
    } else {
      status = 'Not downloaded';
      shownDone = 0;
      barValue = 0.0;
    }

    final List<Widget> actions;
    if (p.state == QariPackState.downloading) {
      actions = [
        TextButton(
          onPressed: () => dl.pauseDownload(qari.id),
          child: const Text('Pause'),
        ),
        TextButton(
          onPressed: () => dl.cancelDownload(qari.id),
          child: const Text('Cancel'),
        ),
      ];
    } else if (complete) {
      actions = [
        TextButton(
          onPressed: () async {
            await dl.deleteDownload(qari.id);
            onCountsDirty();
          },
          child: const Text('Delete'),
        ),
      ];
    } else {
      final resumeLabel = (p.state == QariPackState.paused ||
              p.state == QariPackState.error ||
              scannedTotal > 0)
          ? 'Resume'
          : 'Download';
      actions = [
        ElevatedButton(
          onPressed: () => dl.startDownload(qari),
          child: Text(resumeLabel),
        ),
        if (scannedTotal > 0 || p.done > 0)
          TextButton(
            onPressed: () async {
              await dl.deleteDownload(qari.id);
              onCountsDirty();
            },
            child: const Text('Delete'),
          ),
      ];
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
                      '${qari.name} (${qari.style})',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$status \u2022 $shownDone / '
                      '${QariAudioStorage.totalPackFiles} files'
                      '${bytes != null && bytes! > 0 ? ' \u2022 ${_mb(bytes!)}' : ''}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              if (complete)
                Icon(Icons.offline_pin, color: gold, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: barValue),
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: actions),
        ],
      ),
    );
  }
}
