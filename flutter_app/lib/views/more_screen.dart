import 'package:flutter/material.dart';

import 'audio_studio_screen.dart';
import 'backup_restore_screen.dart';
import 'bookmarks_screen.dart';
import 'check_update_tile.dart';
import 'info_screens.dart';
import 'juz_index_screen.dart';
import 'khatm_planner_screen.dart';
import 'offline_download_screen.dart';
import 'qiblah_screen.dart';
import 'ramzan_duas_screen.dart';
import 'search_quran_screen.dart';
import 'settings_screen.dart';

/// "More" menu screen: one list of all app sections not on the bottom tabs.
class MoreScreen extends StatelessWidget {
  final void Function(int page) onOpenPage;
  final void Function(int tabIndex) onSelectTab;

  const MoreScreen(
      {required this.onOpenPage, required this.onSelectTab, super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  /// Pushes a screen that can jump to a mushaf page: the pushed route is
  /// popped first so the mushaf tab switch underneath becomes visible.
  void _pushJumpable(
      BuildContext context, Widget Function(void Function(int)) build) {
    _push(
      context,
      build((page) {
        Navigator.of(context).pop();
        onOpenPage(page);
      }),
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

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required void Function() onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: cs.primary.withOpacity(0.15),
        child: Icon(icon, color: cs.primary),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: cs.onSurface,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
      trailing: Icon(
        Icons.chevron_right,
        color: cs.primary,
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'More',
          style: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _tile(
            context,
            icon: Icons.format_list_bulleted,
            title: 'Surahs',
            subtitle: 'سورتیں',
            onTap: () => onSelectTab(2),
          ),
          _tile(
            context,
            icon: Icons.headphones_outlined,
            title: 'Audio Studio',
            subtitle: 'آڈیو اسٹوڈیو',
            onTap: () => _push(context, AudioStudioScreen()),
          ),
          _tile(
            context,
            icon: Icons.format_list_numbered,
            title: 'Juz Index',
            subtitle: 'پارہ انڈیکس',
            onTap: () => _pushJumpable(context, (open) => JuzIndexScreen(onOpenPage: open)),
          ),
          _tile(
            context,
            icon: Icons.calendar_month_outlined,
            title: 'Khatm Planner',
            subtitle: 'تیس دن کا ختم شیڈول',
            onTap: () =>
                _pushJumpable(context, (open) => KhatmPlannerScreen(onOpenPage: open)),
          ),
          _tile(
            context,
            icon: Icons.search,
            title: 'Search Quran',
            subtitle: 'قرآن تلاش کریں',
            onTap: () =>
                _pushJumpable(context, (open) => SearchQuranScreen(onOpenPage: open)),
          ),
          _tile(
            context,
            icon: Icons.bookmark_outline,
            title: 'Bookmarks & Saved',
            subtitle: 'نشانات اور محفوظ آیات',
            onTap: () =>
                _pushJumpable(context, (open) => BookmarksScreen(onOpenPage: open)),
          ),
          _tile(
            context,
            icon: Icons.nightlight_round,
            title: 'Ramzan & Duas',
            subtitle: 'رمضان اور دعائیں',
            onTap: () =>
                _pushJumpable(context, (open) => RamzanDuasScreen(onOpenPage: open)),
          ),
          _tile(
            context,
            icon: Icons.cloud_download_outlined,
            title: 'Offline Download Center',
            subtitle: 'آف لائن ڈاؤن لوڈ',
            onTap: () => _push(context, OfflineDownloadScreen()),
          ),
          _tile(
            context,
            icon: Icons.explore_outlined,
            title: 'Qiblah Compass',
            subtitle: 'قبلہ کمپاس',
            onTap: () => _push(context, const QiblahScreen()),
          ),
          _tile(
            context,
            icon: Icons.access_time,
            title: 'Prayer Times & Azan',
            subtitle: 'اوقات الصلوٰۃ',
            onTap: () => onSelectTab(3),
          ),
          const Divider(height: 1),
          _tile(
            context,
            icon: Icons.settings_outlined,
            title: 'Preferences',
            subtitle: 'ترجیحات',
            onTap: () => _openSettings(context),
          ),
          _tile(
            context,
            icon: Icons.cloud_outlined,
            title: 'Backup & Restore',
            subtitle: 'بیک اپ اور بحالی',
            onTap: () => _push(context, BackupRestoreScreen()),
          ),
          _tile(
            context,
            icon: Icons.help_outline,
            title: 'Questions & FAQ',
            subtitle: 'سوالات و جوابات',
            onTap: () => _push(context, FaqScreen()),
          ),
          _tile(
            context,
            icon: Icons.info_outline,
            title: 'About & Licenses',
            subtitle: 'متعلق اور لائسنسز',
            onTap: () => _push(context, AboutScreen()),
          ),
          _tile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'رازداری کی پالیسی',
            onTap: () => _push(context, PrivacyScreen()),
          ),
          const CheckUpdateTile(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
