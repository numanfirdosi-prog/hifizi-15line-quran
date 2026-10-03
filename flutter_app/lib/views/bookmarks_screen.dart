import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../data/quran_data.dart';
import '../data/verse_index.dart';
import '../services/azan_alarm_service.dart';
import '../services/page_drawing_service.dart';
import '../services/preferences_service.dart';
import 'ayah_player_sheet.dart';

/// Bookmarks & saved data: pages, ayahs and notes with export / import /
/// clear-all toolbar actions.
class BookmarksScreen extends StatelessWidget {
  final void Function(int page) onOpenPage;
  const BookmarksScreen({required this.onOpenPage, super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bookmarks & Saved'),
          actions: [
            IconButton(
              icon: const Icon(Icons.file_download_outlined),
              tooltip: 'Export backup',
              onPressed: () => _showExportDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.file_upload_outlined),
              tooltip: 'Import backup',
              onPressed: () => _showImportDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear all saved data',
              onPressed: () => _confirmClearAll(context),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All Saved'),
              Tab(text: 'Pages Only'),
              Tab(text: 'Notes Only'),
              Tab(text: 'Ayahs'),
            ],
          ),
        ),
        body: Consumer<PreferencesService>(
          builder: (context, prefs, _) => TabBarView(
            children: [
              _AllSavedTab(prefs: prefs, onOpenPage: onOpenPage),
              _buildPagesList(context, prefs, onOpenPage),
              _buildNotesList(context, prefs, onOpenPage),
              _SavedAyahsList(prefs: prefs, onOpenPage: onOpenPage),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Export / Import / Clear-all toolbar actions
  // ------------------------------------------------------------------

  /// Re-applies city / asr method / alarm prefs to the alarm scheduler
  /// (same helper shape as SettingsScreen._reschedule).
  Future<void> _rescheduleAlarms(PreferencesService prefs) {
    return AzanAlarmService().scheduleDailyPrayerAlarms(
      location: prefs.selectedCity,
      asrMode: prefs.asrMethod,
      enabledAlarms: prefs.prayerAlarms,
      azanSoundEnabled: prefs.azanSoundEnabled,
      lockscreenAlarmEnabled: prefs.lockscreenAlarmEnabled,
    );
  }

  Future<void> _showExportDialog(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final json =
        Provider.of<PreferencesService>(context, listen: false).exportJson();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Backup'),
        content: SizedBox(
          width: double.maxFinite,
          height: 320,
          child: SingleChildScrollView(child: SelectableText(json)),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: json));
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Backup copied to clipboard')),
                );
              }
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final dir = await getApplicationDocumentsDirectory();
                final file = File('${dir.path}/nur_al_quran_backup.json');
                await file.writeAsString(json);
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text('Saved to ${file.path}')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text('Save failed: $e')),
                  );
                }
              }
            },
            child: const Text('Save to file'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showImportDialog(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    final controller = TextEditingController();
    bool? ok;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Backup'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Paste backup JSON here',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              ok = await prefs.importJson(controller.text.trim());
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (ok != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(ok! ? 'Imported' : 'Invalid backup')),
      );
      if (ok!) {
        // Imported prefs (city / asr method / alarm toggles) must reach the
        // alarm scheduler now, not only on the next app launch.
        await _rescheduleAlarms(prefs);
        // Imported page drawings must reach the drawing service too.
        await Provider.of<PageDrawingService>(context, listen: false).reload();
      }
    }
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all saved data?'),
        content: const Text(
          'This removes all bookmarks, saved ayahs, page notes and tints.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await prefs.clearSavedData();
      messenger.showSnackBar(
        const SnackBar(content: Text('All saved data cleared')),
      );
    }
  }
}

// ------------------------------------------------------------------
// Shared row builders
// ------------------------------------------------------------------

Widget _sectionHeader(BuildContext context, String title) {
  final theme = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
    child: Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

Widget _emptyState(BuildContext context, String message) {
  final theme = Theme.of(context);
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    ),
  );
}

Widget _pageTile(
  BuildContext context,
  PreferencesService prefs,
  int page,
  void Function(int page) onOpenPage,
) {
  final theme = Theme.of(context);
  return Card(
    color: theme.colorScheme.surface,
    child: ListTile(
      leading: Icon(Icons.bookmark, color: theme.colorScheme.primary),
      title: Text('Page $page'),
      onTap: () => onOpenPage(page),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Remove bookmark',
        onPressed: () => prefs.toggleBookmark(page),
      ),
    ),
  );
}

Widget _noteTile(
  BuildContext context,
  PreferencesService prefs,
  MapEntry<String, String> entry,
  void Function(int page) onOpenPage,
) {
  final theme = Theme.of(context);
  final page = int.tryParse(entry.key) ?? 0;
  return Card(
    color: theme.colorScheme.surface,
    child: ListTile(
      leading: Icon(Icons.note_alt_outlined, color: theme.colorScheme.primary),
      title: Text('Page $page'),
      subtitle: Text(
        entry.value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => onOpenPage(page),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Delete note',
        onPressed: () => prefs.setPageNote(page, null),
      ),
    ),
  );
}

Widget _ayahTile(
  BuildContext context,
  PreferencesService prefs,
  String key,
  Map<String, int>? index,
  void Function(int page) onOpenPage,
) {
  final theme = Theme.of(context);
  final parts = key.split(':');
  final s = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
  final v = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
  final surahName =
      (s >= 1 && s <= allSurahs.length) ? allSurahs[s - 1].nameEn : 'Surah $s';
  final page = index?[key];
  return Card(
    color: theme.colorScheme.surface,
    child: ListTile(
      leading: Icon(Icons.favorite, color: theme.colorScheme.primary),
      title: Text('$surahName • Ayah $v'),
      subtitle: Text(index == null ? 'Loading page…' : 'Page ${page ?? '?'}'),
      // Tapping a saved ayah highlights it and plays its audio ayah-by-ayah.
      onTap: () => showAyahPlayer(context, surah: s, ayah: v),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'Open page ${page ?? '?'}',
            onPressed: () => onOpenPage(page ?? 1),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Remove ayah',
            onPressed: () => prefs.toggleSavedAyah(key),
          ),
        ],
      ),
    ),
  );
}

List<MapEntry<String, String>> _sortedNotes(PreferencesService prefs) {
  final entries = prefs.pageNotes.entries.toList();
  entries.sort(
    (a, b) => (int.tryParse(a.key) ?? 0).compareTo(int.tryParse(b.key) ?? 0),
  );
  return entries;
}

Widget _buildPagesList(
  BuildContext context,
  PreferencesService prefs,
  void Function(int page) onOpenPage,
) {
  final pages = [...prefs.bookmarks]..sort();
  if (pages.isEmpty) {
    return _emptyState(context, 'No bookmarked pages yet.');
  }
  return ListView(
    padding: const EdgeInsets.all(12),
    children: [
      for (final page in pages) _pageTile(context, prefs, page, onOpenPage),
    ],
  );
}

Widget _buildNotesList(
  BuildContext context,
  PreferencesService prefs,
  void Function(int page) onOpenPage,
) {
  final notes = _sortedNotes(prefs);
  if (notes.isEmpty) {
    return _emptyState(context, 'No page notes yet.');
  }
  return ListView(
    padding: const EdgeInsets.all(12),
    children: [
      for (final entry in notes) _noteTile(context, prefs, entry, onOpenPage),
    ],
  );
}

/// "All Saved" tab: combined pages + ayahs + notes sections.
class _AllSavedTab extends StatelessWidget {
  final PreferencesService prefs;
  final void Function(int page) onOpenPage;
  const _AllSavedTab({required this.prefs, required this.onOpenPage});

  @override
  Widget build(BuildContext context) {
    final pages = [...prefs.bookmarks]..sort();
    final notes = _sortedNotes(prefs);
    if (pages.isEmpty && prefs.savedAyahs.isEmpty && notes.isEmpty) {
      return _emptyState(context, 'Nothing saved yet.');
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (pages.isNotEmpty) ...[
          _sectionHeader(context, 'Bookmarked Pages'),
          for (final page in pages) _pageTile(context, prefs, page, onOpenPage),
        ],
        if (prefs.savedAyahs.isNotEmpty) ...[
          _sectionHeader(context, 'Saved Ayahs'),
          _SavedAyahsColumn(prefs: prefs, onOpenPage: onOpenPage),
        ],
        if (notes.isNotEmpty) ...[
          _sectionHeader(context, 'Page Notes'),
          for (final entry in notes)
            _noteTile(context, prefs, entry, onOpenPage),
        ],
      ],
    );
  }
}

/// Saved-ayahs tab (own ListView): loads the verse->page index once and
/// rebuilds on [PreferencesService] changes via the parent Consumer.
class _SavedAyahsList extends StatefulWidget {
  final PreferencesService prefs;
  final void Function(int page) onOpenPage;
  const _SavedAyahsList({required this.prefs, required this.onOpenPage});

  @override
  State<_SavedAyahsList> createState() => _SavedAyahsListState();
}

class _SavedAyahsListState extends State<_SavedAyahsList> {
  late final Future<Map<String, int>> _indexFuture = loadVersePageIndex();

  @override
  Widget build(BuildContext context) {
    final prefs = widget.prefs;
    final ayahs = prefs.savedAyahs;
    if (ayahs.isEmpty) {
      return _emptyState(context, 'No saved ayahs yet.');
    }
    return FutureBuilder<Map<String, int>>(
      future: _indexFuture,
      builder: (context, snapshot) {
        final index = snapshot.data;
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (final key in ayahs)
              _ayahTile(context, prefs, key, index, widget.onOpenPage),
          ],
        );
      },
    );
  }
}

/// Saved-ayahs rows for the "All Saved" tab (a Column, no nested ListView).
class _SavedAyahsColumn extends StatefulWidget {
  final PreferencesService prefs;
  final void Function(int page) onOpenPage;
  const _SavedAyahsColumn({required this.prefs, required this.onOpenPage});

  @override
  State<_SavedAyahsColumn> createState() => _SavedAyahsColumnState();
}

class _SavedAyahsColumnState extends State<_SavedAyahsColumn> {
  late final Future<Map<String, int>> _indexFuture = loadVersePageIndex();

  @override
  Widget build(BuildContext context) {
    final prefs = widget.prefs;
    final ayahs = prefs.savedAyahs;
    if (ayahs.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<Map<String, int>>(
      future: _indexFuture,
      builder: (context, snapshot) {
        final index = snapshot.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final key in ayahs)
              _ayahTile(context, prefs, key, index, widget.onOpenPage),
          ],
        );
      },
    );
  }
}
