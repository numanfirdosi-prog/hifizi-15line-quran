import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../data/ayah_of_day.dart';
import '../data/juz_data.dart';
import '../data/quran_data.dart';
import '../data/verse_index.dart';
import '../models/surah.dart';
import '../services/preferences_service.dart';
import '../utils/script_font.dart';
import '../widgets/premium_card.dart';
import '../widgets/section_header.dart';
import 'ayah_player_sheet.dart';
import 'audio_studio_screen.dart';
import 'backup_restore_screen.dart';
import 'bookmarks_screen.dart';
import 'info_screens.dart';
import 'juz_index_screen.dart';
import 'khatm_planner_screen.dart';
import 'offline_download_screen.dart';
import 'qiblah_screen.dart';
import 'ramzan_duas_screen.dart';
import 'mushaf_screen.dart';
import 'search_quran_screen.dart';
import 'settings_screen.dart';
import 'tafsir_home_screen.dart';

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

  /// Premium card wrapper shared across the dashboard.
  Widget _card(BuildContext context,
      {required Widget child, bool goldAccent = false}) {
    return NurCard(child: child, goldAccent: goldAccent);
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return NurSectionHeader(title: text);
  }

  // ------------------------------------------------------------------
  // Compact brand header: app name + edition line, theme-aware.
  // ------------------------------------------------------------------

  Widget _brandHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Nur.s20, Nur.s12, Nur.s20, Nur.s4),
      child: Row(
        children: [
          Container(
            width: Nur.buttonHeight,
            height: Nur.buttonHeight,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(Nur.buttonRadius),
              border: Border.all(
                  color: cs.primary.withValues(alpha: 0.35)),
            ),
            child: Icon(Icons.menu_book_rounded,
                color: cs.primary, size: Nur.iconSize),
          ),
          const SizedBox(width: Nur.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nur Al-Quran',
                  style: textTheme.titleLarge?.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 2),
                Text(
                  '15-Line Hifzi Mushaf',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  /// Pushes a screen that can jump to a mushaf page: pushes MushafScreen
  /// directly onto the navigator stack so system back / back button returns
  /// directly to this screen (Bookmarks, Juz Index, Search, etc.).
  void _pushJumpable(
      BuildContext context, Widget Function(void Function(int)) build) {
    _push(
      context,
      build((page) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MushafScreen(initialPage: page),
          ),
        );
      }),
    );
  }

  void _openSettings(BuildContext context) {
    _push(
      context,
      SettingsScreen(onOpenPage: (p) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MushafScreen(initialPage: p),
          ),
        );
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
        goldAccent: true,
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
                minimumSize: const Size(0, Nur.buttonHeight),
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
      goldAccent: true,
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
                  minimumSize: const Size(0, Nur.buttonHeight),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  // Opens the ayah player: highlights the ayah and plays
                  // its audio ayah-by-ayah until stopped.
                  showAyahPlayer(
                    context,
                    surah: prefs.lastReadSurah,
                    ayah: prefs.lastReadAyah,
                  );
                },
                icon: const Icon(Icons.headphones_outlined),
                label: Text('Listen from Ayah ${prefs.lastReadAyah}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.primary,
                  side: BorderSide(color: cs.primary),
                  minimumSize: const Size(0, Nur.buttonHeight),
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
      goldAccent: true,
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
            normalizeArabicDisplay(a.ar),
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
                  minimumSize: const Size(0, Nur.buttonHeight),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  // Highlights the ayah and plays its audio ayah-by-ayah.
                  showAyahPlayer(context, surah: a.surah, ayah: a.ayah);
                },
                icon: const Icon(Icons.headphones_outlined),
                label: const Text('Listen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.primary,
                  side: BorderSide(color: cs.primary),
                  minimumSize: const Size(0, Nur.buttonHeight),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Surah quick-jump card (type a surah name -> opens its first page)
  // ------------------------------------------------------------------

  Widget _surahPickerCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_outlined,
                  color: cs.primary, size: Nur.iconSize),
              const SizedBox(width: Nur.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '114 Surahs',
                      style: TextStyle(
                        color: cs.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Jump to any surah',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => onSelectTab(2),
                icon: const Icon(Icons.list, size: Nur.iconSizeSm),
                label: const Text('Browse All'),
                style: TextButton.styleFrom(foregroundColor: cs.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Autocomplete<Surah>(
            displayStringForOption: (s) => s.nameEn,
            optionsBuilder: (textEditingValue) {
              final q = textEditingValue.text.trim().toLowerCase();
              if (q.isEmpty) return const Iterable<Surah>.empty();
              return allSurahs.where((s) =>
                  s.nameEn.toLowerCase().contains(q) ||
                  s.nameAr.contains(textEditingValue.text.trim()) ||
                  s.number.toString() == q);
            },
            onSelected: (surah) => onOpenPage(surah.startPage),
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'Type surah name… e.g. Ya-Sin',
                  hintStyle: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.5)),
                  prefixIcon: Icon(Icons.search, color: cs.primary),
                  filled: true,
                  fillColor:
                      cs.onSurface.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(Nur.buttonRadius),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(color: cs.onSurface),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: cs.surface,
                  elevation: 4,
                  borderRadius: BorderRadius.circular(Nur.buttonRadius),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - 64,
                    child: ConstrainedBox(
                      // Cap the dropdown height so many matches scroll
                      // inside instead of overflowing the screen.
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                        final s = options.elementAt(index);
                        return ListTile(
                          dense: true,
                          leading: Text(
                            '${s.number}',
                            style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.bold),
                          ),
                          title: Text(s.nameEn,
                              style: TextStyle(color: cs.onSurface)),
                          subtitle: Text(
                            '${s.meaning} • Page ${s.startPage}',
                            style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.6),
                                fontSize: 12),
                          ),
                          trailing: Text(
                            s.nameAr,
                            style: TextStyle(
                                color: cs.primary, fontSize: 16),
                          ),
                          onTap: () => onSelected(s),
                        );
                      },
                      ),
                    ),
                  ),
                ),
              );
            },
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
            () => _pushJumpable(context, (open) => JuzIndexScreen(onOpenPage: open))),
        _QuickItem('Khatm Planner', Icons.calendar_month_outlined,
            () => _pushJumpable(context, (open) => KhatmPlannerScreen(onOpenPage: open))),
        _QuickItem('Bookmarks & Saved', Icons.bookmark_outline,
            () => _pushJumpable(context, (open) => BookmarksScreen(onOpenPage: open))),
        _QuickItem('Search Quran', Icons.search,
            () => _pushJumpable(context, (open) => SearchQuranScreen(onOpenPage: open))),
        _QuickItem('Tafsir', Icons.auto_stories,
            () => _push(context, const TafsirHomeScreen())),
        _QuickItem('Audio Recitations', Icons.headphones_outlined,
            () => _push(context, AudioStudioScreen())),
        _QuickItem(
            'Prayer Times & Azan', Icons.access_time, () => onSelectTab(3)),
        _QuickItem('Qiblah Compass', Icons.explore_outlined,
            () => _push(context, const QiblahScreen())),
        _QuickItem('Ramzan & Duas', Icons.nightlight_round,
            () => _pushJumpable(context, (open) => RamzanDuasScreen(onOpenPage: open))),
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
          padding: const EdgeInsets.fromLTRB(
              Nur.screenMargin, Nur.s8, Nur.screenMargin, Nur.s8),
          mainAxisSpacing: Nur.s12,
          crossAxisSpacing: Nur.s12,
          children: items.map((item) {
            return InkWell(
              borderRadius: BorderRadius.circular(Nur.radiusMd),
              onTap: item.onTap,
              child: Container(
                padding: const EdgeInsets.all(Nur.s8),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(Nur.radiusMd),
                  border: Border.all(color: cs.primary.withOpacity(0.25)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: cs.primary.withOpacity(0.15),
                      child: Icon(item.icon,
                          color: cs.primary, size: Nur.iconSize),
                    ),
                    const SizedBox(height: Nur.s8),
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
        borderRadius: BorderRadius.circular(Nur.buttonRadius),
        onTap: () => onOpenPage(prefs.lastReadPage),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: Nur.s8, vertical: Nur.s4),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(Nur.radiusLg),
              ),
              child: Text(
                'SPECIAL EDITION',
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
                    _pushJumpable(context, (open) => BookmarksScreen(onOpenPage: open)),
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
                    leading: Icon(Icons.bookmark,
                        color: cs.primary, size: Nur.iconSize),
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
        _brandHeader(context),
        const SizedBox(height: Nur.s4),
        _lastReadCard(context),
        _progressCard(context),
        _ayahOfDayCard(context),
        _surahPickerCard(context),
        _quickAccessSection(context),
        _mushafInfoCard(context),
        _savedAyahsSection(context),
        const SizedBox(height: Nur.screenMargin),
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
