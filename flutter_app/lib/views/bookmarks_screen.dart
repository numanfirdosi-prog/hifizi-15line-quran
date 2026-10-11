import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../data/juz_data.dart';
import '../data/quran_data.dart';
import '../data/verse_index.dart';
import '../services/azan_alarm_service.dart';
import '../services/page_drawing_service.dart';
import '../services/preferences_service.dart';
import 'ayah_player_sheet.dart';

/// Bookmarks & saved data: pages, ayahs and notes with search, export /
/// import / clear-all toolbar actions.
///
/// The three saved kinds are visually distinguished everywhere:
///  - Page bookmark — bookmark icon, "PAGE" label, page thumbnail.
///  - Saved ayah — heart icon, "AYAH" label, Surah • Ayah ref + page.
///  - Page note — note icon, "NOTE" label, note preview text.
/// All items persist in [PreferencesService] (local, survives restarts);
/// every destructive action asks for confirmation first.
class BookmarksScreen extends StatefulWidget {
  final void Function(int page) onOpenPage;
  const BookmarksScreen({required this.onOpenPage, super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
              Tab(text: 'Pages'),
              Tab(text: 'Notes'),
              Tab(text: 'Ayahs'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v.trim()),
                style: TextStyle(color: cs.onSurface, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search saved items...',
                  hintStyle: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.45),
                      fontSize: 13),
                  prefixIcon:
                      Icon(Icons.search, color: cs.primary, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              color: cs.onSurface.withValues(alpha: 0.5),
                              size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: cs.onSurface.withValues(alpha: 0.06),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Consumer<PreferencesService>(
                builder: (context, prefs, _) => TabBarView(
                  children: [
                    _AllSavedTab(
                        prefs: prefs,
                        onOpenPage: widget.onOpenPage,
                        query: _query,
                        onEditNote: _editNote),
                    _buildPagesList(
                        context, prefs, widget.onOpenPage, _query),
                    _buildNotesList(
                        context, prefs, widget.onOpenPage, _query, _editNote),
                    _SavedAyahsList(
                        prefs: prefs,
                        onOpenPage: widget.onOpenPage,
                        query: _query),
                  ],
                ),
              ),
            ),
          ],
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
          'This removes all bookmarks, saved ayahs, page notes and tints. '
          'This cannot be undone.',
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

  /// Edit a page note in place (same storage as the reader's note button).
  Future<void> _editNote(
      BuildContext context, PreferencesService prefs, int page) async {
    final controller =
        TextEditingController(text: prefs.pageNotes[page.toString()] ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Note — Page $page'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Write your note...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final text = controller.text;
    controller.dispose();
    if (saved == true) {
      await prefs.setPageNote(page, text.trim().isEmpty ? null : text.trim());
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

/// Small type label so page bookmarks, ayahs and notes are never confused.
Widget _typeLabel(BuildContext context, String label) {
  final cs = Theme.of(context).colorScheme;
  return Container(
    margin: const EdgeInsets.only(top: 4),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: cs.primary.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: cs.primary,
        fontSize: 9,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.6,
      ),
    ),
  );
}

Widget _emptyState(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withValues(alpha: 0.1),
              border:
                  Border.all(color: cs.primary.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, size: 34, color: cs.primary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Confirmation guard for every single-item delete.
Future<bool> _confirmDelete(
    BuildContext context, String title, String message) async {
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;
}

Widget _pageTile(
  BuildContext context,
  PreferencesService prefs,
  int page,
  void Function(int page) onOpenPage,
) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  return Card(
    color: cs.surface,
    child: ListTile(
      // Saved page preview from the bundled mushaf page images.
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(
          'assets/pages/$page.webp',
          width: 40,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.bookmark, color: cs.primary, size: 32),
        ),
      ),
      title: Row(
        children: [
          Text('Page $page'),
          const SizedBox(width: 8),
          _typeLabel(context, 'PAGE'),
        ],
      ),
      subtitle: Text(
        'Juz ${juzForPage(page)} • Tap to open',
        style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.55), fontSize: 12),
      ),
      onTap: () => onOpenPage(page),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Remove bookmark',
        onPressed: () async {
          final ok = await _confirmDelete(
            context,
            'Remove bookmark?',
            'Remove the bookmark for Page $page? This cannot be undone.',
          );
          if (ok) prefs.toggleBookmark(page);
        },
      ),
    ),
  );
}

Widget _noteTile(
  BuildContext context,
  PreferencesService prefs,
  MapEntry<String, String> entry,
  void Function(int page) onOpenPage,
  Future<void> Function(
          BuildContext, PreferencesService, int page)
      onEditNote,
) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  final page = int.tryParse(entry.key) ?? 0;
  return Card(
    color: cs.surface,
    child: ListTile(
      leading: Icon(Icons.note_alt_outlined, color: cs.primary, size: 32),
      title: Row(
        children: [
          Text('Page $page'),
          const SizedBox(width: 8),
          _typeLabel(context, 'NOTE'),
        ],
      ),
      subtitle: Text(
        entry.value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => onOpenPage(page),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit note',
            onPressed: () => onEditNote(context, prefs, page),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete note',
            onPressed: () async {
              final ok = await _confirmDelete(
                context,
                'Delete note?',
                'Delete your note on Page $page? This cannot be undone.',
              );
              if (ok) prefs.setPageNote(page, null);
            },
          ),
        ],
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
  final cs = theme.colorScheme;
  final parts = key.split(':');
  final s = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
  final v = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
  final surahName =
      (s >= 1 && s <= allSurahs.length) ? allSurahs[s - 1].nameEn : 'Surah $s';
  final page = index?[key];
  return Card(
    color: cs.surface,
    child: ListTile(
      leading: Icon(Icons.favorite, color: cs.primary, size: 30),
      title: Row(
        children: [
          Flexible(
            child: Text(
              '$surahName • Ayah $v',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _typeLabel(context, 'AYAH'),
        ],
      ),
      subtitle: Text(
        index == null ? 'Loading page…' : 'Page ${page ?? '?'} • Tap to play',
        style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.55), fontSize: 12),
      ),
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
            onPressed: () async {
              final ok = await _confirmDelete(
                context,
                'Remove saved ayah?',
                'Remove $surahName, Ayah $v from saved ayahs? '
                'This cannot be undone.',
              );
              if (ok) prefs.toggleSavedAyah(key);
            },
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

bool _matchesQuery(String query, String text) =>
    query.isEmpty || text.toLowerCase().contains(query.toLowerCase());

Widget _buildPagesList(
  BuildContext context,
  PreferencesService prefs,
  void Function(int page) onOpenPage,
  String query,
) {
  final pages = [...prefs.bookmarks]
      .where((p) => _matchesQuery(query, 'page $p'))
      .toList()
    ..sort();
  if (pages.isEmpty) {
    return _emptyState(
      context,
      icon: Icons.bookmark_border,
      title: query.isEmpty ? 'No bookmarked pages' : 'No matches',
      message: query.isEmpty
          ? 'Bookmark any mushaf page to find it here later.'
          : 'No bookmarked page matches "$query".',
      actionLabel: query.isEmpty ? 'Open the Mushaf' : null,
      onAction: query.isEmpty ? () => onOpenPage(1) : null,
    );
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
  String query,
  Future<void> Function(BuildContext, PreferencesService, int page)
      onEditNote,
) {
  final notes = _sortedNotes(prefs)
      .where((e) =>
          _matchesQuery(query, '${e.value} page ${e.key}'))
      .toList();
  if (notes.isEmpty) {
    return _emptyState(
      context,
      icon: Icons.note_alt_outlined,
      title: query.isEmpty ? 'No page notes' : 'No matches',
      message: query.isEmpty
          ? 'Tap the pencil (note) button on any reader page to write a '
              'note — it will appear here.'
          : 'No note matches "$query".',
    );
  }
  return ListView(
    padding: const EdgeInsets.all(12),
    children: [
      for (final entry in notes)
        _noteTile(context, prefs, entry, onOpenPage, onEditNote),
    ],
  );
}

/// "All Saved" tab: combined pages + ayahs + notes sections.
class _AllSavedTab extends StatelessWidget {
  final PreferencesService prefs;
  final void Function(int page) onOpenPage;
  final String query;
  final Future<void> Function(
      BuildContext, PreferencesService, int page) onEditNote;
  const _AllSavedTab({
    required this.prefs,
    required this.onOpenPage,
    required this.query,
    required this.onEditNote,
  });

  @override
  Widget build(BuildContext context) {
    final pages = [...prefs.bookmarks]
        .where((p) => _matchesQuery(query, 'page $p'))
        .toList()
      ..sort();
    final notes = _sortedNotes(prefs)
        .where((e) => _matchesQuery(query, '${e.value} page ${e.key}'))
        .toList();
    final ayahs = prefs.savedAyahs
        .where((k) => _matchesQuery(query, k))
        .toList();
    if (pages.isEmpty && ayahs.isEmpty && notes.isEmpty) {
      return _emptyState(
        context,
        icon: Icons.bookmarks_outlined,
        title: query.isEmpty ? 'Nothing saved yet' : 'No matches',
        message: query.isEmpty
            ? 'Bookmark pages, save ayahs and write notes from the reader — '
                'everything you save appears here.'
            : 'Nothing saved matches "$query".',
        actionLabel: query.isEmpty ? 'Open the Mushaf' : null,
        onAction: query.isEmpty ? () => onOpenPage(1) : null,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (pages.isNotEmpty) ...[
          _sectionHeader(context, 'Bookmarked Pages'),
          for (final page in pages) _pageTile(context, prefs, page, onOpenPage),
        ],
        if (ayahs.isNotEmpty) ...[
          _sectionHeader(context, 'Saved Ayahs'),
          _SavedAyahsColumn(
              prefs: prefs, onOpenPage: onOpenPage, query: query),
        ],
        if (notes.isNotEmpty) ...[
          _sectionHeader(context, 'Page Notes'),
          for (final entry in notes)
            _noteTile(context, prefs, entry, onOpenPage, onEditNote),
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
  final String query;
  const _SavedAyahsList(
      {required this.prefs, required this.onOpenPage, required this.query});

  @override
  State<_SavedAyahsList> createState() => _SavedAyahsListState();
}

class _SavedAyahsListState extends State<_SavedAyahsList> {
  late final Future<Map<String, int>> _indexFuture = loadVersePageIndex();

  @override
  Widget build(BuildContext context) {
    final prefs = widget.prefs;
    final ayahs = prefs.savedAyahs
        .where((k) => _matchesQuery(widget.query, _ayahSearchText(k)))
        .toList();
    if (ayahs.isEmpty) {
      return _emptyState(
        context,
        icon: Icons.favorite_border,
        title: widget.query.isEmpty ? 'No saved ayahs' : 'No matches',
        message: widget.query.isEmpty
            ? 'Ayahs you save appear here with their Surah reference and '
                'mushaf page.'
            : 'No saved ayah matches "${widget.query}".',
      );
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

String _ayahSearchText(String key) {
  final parts = key.split(':');
  final s = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
  final surahName = (s >= 1 && s <= allSurahs.length)
      ? allSurahs[s - 1].nameEn
      : 'Surah $s';
  return '$key $surahName';
}

/// Saved-ayahs rows for the "All Saved" tab (a Column, no nested ListView).
class _SavedAyahsColumn extends StatefulWidget {
  final PreferencesService prefs;
  final void Function(int page) onOpenPage;
  final String query;
  const _SavedAyahsColumn(
      {required this.prefs, required this.onOpenPage, required this.query});

  @override
  State<_SavedAyahsColumn> createState() => _SavedAyahsColumnState();
}

class _SavedAyahsColumnState extends State<_SavedAyahsColumn> {
  late final Future<Map<String, int>> _indexFuture = loadVersePageIndex();

  @override
  Widget build(BuildContext context) {
    final prefs = widget.prefs;
    final ayahs = prefs.savedAyahs
        .where((k) => _matchesQuery(widget.query, _ayahSearchText(k)))
        .toList();
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
