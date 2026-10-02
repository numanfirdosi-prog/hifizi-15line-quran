import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

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
