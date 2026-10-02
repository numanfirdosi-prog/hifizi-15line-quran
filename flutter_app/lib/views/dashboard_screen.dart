import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/ayah_of_day.dart';
import '../data/juz_data.dart';
import '../data/quran_data.dart';
import '../data/verse_index.dart';
import '../services/audio_recitation_service.dart';
import '../services/preferences_service.dart';
import '../utils/script_font.dart';
import 'audio_studio_screen.dart';
import 'backup_restore_screen.dart';
import 'bookmarks_screen.dart';
import 'info_screens.dart';
import 'juz_index_screen.dart';
import 'offline_download_screen.dart';
import 'qiblah_screen.dart';
import 'ramzan_duas_screen.dart';
import 'search_quran_screen.dart';
import 'settings_screen.dart';

/// Home/dashboard view for the Nur-Al-Quran app: last-read position,
/// reading progress, Ayah of the Day, quick-access grid, Mushaf info,
/// and a preview of saved ayahs.
class DashboardScreen extends StatelessWidget {
  final void Function(int page) onOpenPage;
  final void Function(int tabIndex) onSelectTab; // 1=mushaf,2=surahs,3=prayer

  const DashboardScreen(
      {required this.onOpenPage, required this.onSelectTab, super.key});

  // Shared future so the asset index is loaded once across rebuilds.
  static Future<Map<String, int>>? _verseIndexFuture;

  static String _relativeTime(String iso) {
    if (iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 30) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _card(BuildContext context, {required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withOpacity(0.25)),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        text,
        style: TextStyle(
          color: cs.primary,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _openSettings(BuildContext context) {
    _push(
      context,
      SettingsScreen(onOpenPage: (p) {
        Navigator.of(context).pop();
        onOpenPage(p);
      }),
    );
  }

  // ------------------------------------------------------------------
  // Last Read card
  // ------------------------------------------------------------------

  Widget _lastReadCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final prefs = Provider.of<PreferencesService>(context);

    if (prefs.lastReadAt.isEmpty) {
      return _card(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Read',
              style: TextStyle(
                color: cs.primary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start your journey',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => onOpenPage(1),
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('Open the Quran'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
            ),
          ],
        ),
      );
    }

    final surahIndex = (prefs.lastReadSurah - 1).clamp(0, allSurahs.length - 1);
    final surah = allSurahs[surahIndex];
    final page = prefs.lastReadPage;
    final juz = juzForPage(page);
    final rel = _relativeTime(prefs.lastReadAt);

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last Read',
            style: TextStyle(
              color: cs.primary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  surah.nameEn,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                surah.nameAr,
                style: arabicStyle(
                  prefs.scriptStyle,
                  fontSize: 24,
                  color: cs.primary,
                  scale: prefs.ayahScale,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Page $page • Juz $juz'
            '${rel.isNotEmpty ? ' • $rel' : ''}',
            style:
                TextStyle(color: cs.onSurface.withOpacity(0.7), fontSize: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => onOpenPage(prefs.lastReadPage),
                icon: const Icon(Icons.play_arrow),
                label: Text('Continue Reading (Page $page)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  final audio = Provider.of<AudioRecitationService>(context,
                      listen: false);
                  audio.setRepeatMode(prefs.repeatMode);
                  audio.setSpeed(prefs.playbackSpeed);
                  audio.playSurah(surahNumber: prefs.lastReadSurah);
                },
                icon: const Icon(Icons.headphones_outlined),
                label: Text('Listen from Ayah ${prefs.lastReadAyah}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.primary,
                  side: BorderSide(color: cs.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Reading Progress card
  // ------------------------------------------------------------------

  Widget _progressCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final prefs = Provider.of<PreferencesService>(context);

    final pagesRead = (prefs.lastReadPage - 1).clamp(0, totalPagesInMushaf);
    final target = prefs.dailyTargetPages;
    final remaining = totalPagesInMushaf - pagesRead;
    final daysLeft = (remaining / max(1, target)).ceil();

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reading Progress',
            style: TextStyle(
              color: cs.primary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pagesRead / totalPagesInMushaf,
              minHeight: 10,
              backgroundColor: cs.onSurface.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$pagesRead of $totalPagesInMushaf Pages',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Target: $target pages / day',
            style:
                TextStyle(color: cs.onSurface.withOpacity(0.7), fontSize: 13),
          ),
          Text(
            'Est. $daysLeft days left',
            style:
                TextStyle(color: cs.onSurface.withOpacity(0.7), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Ayah of the Day card
  // ------------------------------------------------------------------

  Widget _ayahOfDayCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final prefs = Provider.of<PreferencesService>(context);
    final a = ayahOfDayFor(DateTime.now());
    final surah = allSurahs[(a.surah - 1).clamp(0, allSurahs.length - 1)];

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ayah of the Day',
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${surah.nameEn} • ${a.surah}:${a.ayah}',
                style: TextStyle(
                  color: cs.onSurface.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            a.ar,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: arabicStyle(
              prefs.scriptStyle,
              fontSize: 26,
              color: cs.onSurface,
              scale: prefs.ayahScale,
              height: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '"${a.en}"',
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.85),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tadabbur note: ${a.reflection}',
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: '${a.ar}\n${a.en}'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied')),
                  );
                },
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copy'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.primary,
                  side: BorderSide(color: cs.primary),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Provider.of<AudioRecitationService>(context, listen: false)
                      .playSurah(surahNumber: a.surah);
                },
                icon: const Icon(Icons.headphones_outlined),
                label: const Text('Listen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.primary,
                  side: BorderSide(color: cs.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Quick Access grid
  // ------------------------------------------------------------------

  List<_QuickItem> _quickItems(BuildContext context) => [
        _QuickItem(
            'All 114 Surahs', Icons.menu_book_outlined, () => onSelectTab(2)),
        _QuickItem('Juz Index', Icons.format_list_numbered,
            () => _push(context, JuzIndexScreen(onOpenPage: onOpenPage))),
        _QuickItem('Bookmarks & Saved', Icons.bookmark_outline,
            () => _push(context, BookmarksScreen(onOpenPage: onOpenPage))),
        _QuickItem('Search Quran', Icons.search,
            () => _push(context, SearchQuranScreen(onOpenPage: onOpenPage))),
        _QuickItem('Audio Recitations', Icons.headphones_outlined,
            () => _push(context, AudioStudioScreen())),
        _QuickItem(
            'Prayer Times & Azan', Icons.access_time, () => onSelectTab(3)),
        _QuickItem('Qiblah Compass', Icons.explore_outlined,
            () => _push(context, const QiblahScreen())),
        _QuickItem('Ramzan & Duas', Icons.nightlight_round,
            () => _push(context, RamzanDuasScreen(onOpenPage: onOpenPage))),
        _QuickItem('Preferences', Icons.settings_outlined,
            () => _openSettings(context)),
        _QuickItem('Questions & FAQ', Icons.help_outline,
            () => _push(context, FaqScreen())),
        _QuickItem('Backup & Restore', Icons.cloud_outlined,
            () => _push(context, BackupRestoreScreen())),
        _QuickItem('About & Licenses', Icons.info_outline,
            () => _push(context, AboutScreen())),
        _QuickItem('Offline Downloads', Icons.cloud_download_outlined,
            () => _push(context, OfflineDownloadScreen())),
      ];

  Widget _quickAccessSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = _quickItems(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Quick Access'),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: items.map((item) {
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: item.onTap,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.primary.withOpacity(0.25)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: cs.primary.withOpacity(0.15),
                      child: Icon(item.icon, color: cs.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // 15-Line Mushaf info card
  // ------------------------------------------------------------------

  Widget _mushafInfoCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final prefs = Provider.of<PreferencesService>(context);

    return _card(
      context,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onOpenPage(prefs.lastReadPage),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'SPECIALIZE',
                style: TextStyle(
                  color: cs.onPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '15-Line Mushaf',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hifzi / South Asian layout with standardized page endings — 611 pages',
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Open the Mushaf',
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(Icons.arrow_forward, size: 16, color: cs.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Saved Ayahs preview
  // ------------------------------------------------------------------

  Widget _savedAyahsSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final prefs = Provider.of<PreferencesService>(context);
    final saved = prefs.savedAyahs;

    if (saved.isEmpty) {
      return _card(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saved Ayahs & Bookmarks',
              style: TextStyle(
                color: cs.primary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No saved ayahs yet',
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final preview = saved.take(3).toList();
    _verseIndexFuture ??= loadVersePageIndex();

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Saved Ayahs & Bookmarks',
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    _push(context, BookmarksScreen(onOpenPage: onOpenPage)),
                child: Text(
                  'View All',
                  style: TextStyle(color: cs.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FutureBuilder<Map<String, int>>(
            future: _verseIndexFuture,
            builder: (context, snapshot) {
              final index = snapshot.data ?? const <String, int>{};
              return Column(
                children: preview.map((verseKey) {
                  final parts = verseKey.split(':');
                  final s = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 1;
                  final v = parts.length > 1 ? parts[1] : '';
                  final surahName =
                      allSurahs[(s - 1).clamp(0, allSurahs.length - 1)].nameEn;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.bookmark, color: cs.primary),
                    title: Text(
                      '$surahName $s:$v',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => onOpenPage(index[verseKey] ?? 1),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 8),
        _lastReadCard(context),
        _progressCard(context),
        _ayahOfDayCard(context),
        _quickAccessSection(context),
        _mushafInfoCard(context),
        _savedAyahsSection(context),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _QuickItem {
  final String title;
  final IconData icon;
  final void Function() onTap;

  const _QuickItem(this.title, this.icon, this.onTap);
}
