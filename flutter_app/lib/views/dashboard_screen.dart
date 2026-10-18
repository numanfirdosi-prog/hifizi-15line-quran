import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../main.dart';
import '../data/ayah_of_day.dart';
import '../data/juz_data.dart';
import '../data/quran_data.dart';
import '../data/verse_index.dart';
import '../models/prayer_times.dart';
import '../models/surah.dart';
import '../services/prayer_calculation_service.dart';
import '../services/preferences_service.dart';
import '../utils/script_font.dart';
import '../widgets/premium_card.dart';
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
import 'tafsir_ayah_detail_screen.dart';
import 'tafsir_home_screen.dart';

/// Home screen for Hafizi Quran & Tafsir matching Image 3 across all 3 themes.
class DashboardScreen extends StatelessWidget {
  final void Function(int page) onOpenPage;
  final void Function(int tabIndex) onSelectTab;

  const DashboardScreen({
    required this.onOpenPage,
    required this.onSelectTab,
    super.key,
  });

  static Future<Map<String, int>>? _verseIndexFuture;

  static String _relativeTime(String iso) {
    if (iso.isEmpty) return 'just now';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return 'just now';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '1 minute ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 30) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  /// "Jul 1" style date chip for the Last Read card (mockup).
  static String _dateChip(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  Widget _card(BuildContext context,
      {required Widget child, bool goldAccent = false}) {
    return NurCard(child: child, goldAccent: goldAccent);
  }

  static String _hijriDateString(DateTime dt, bool urdu) {
    var year = dt.year;
    var month = dt.month;
    final day = dt.day;
    if (month < 3) {
      year -= 1;
      month += 12;
    }
    final a = (year / 100).floor();
    final b = 2 - a + (a / 4).floor();
    final jd = (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day +
        b -
        1524;
    final days = jd - 1948440;
    final hYear = ((30 * days + 10646) / 10631).floor();
    final dayOfYear = days - ((10631 * hYear - 10617) / 30).floor() + 1;
    var hMonth = (dayOfYear / 29.5).ceil();
    if (hMonth > 12) hMonth = 12;
    if (hMonth < 1) hMonth = 1;
    final hDay = (dayOfYear - (29.5 * (hMonth - 1)).floor()).clamp(1, 30);

    const enMonths = [
      'Muharram',
      'Safar',
      'Rabi al-Awwal',
      'Rabi al-Thani',
      'Jumada al-Awwal',
      'Jumada al-Thani',
      'Rajab',
      "Sha'ban",
      'Ramadan',
      'Shawwal',
      'Dhu al-Qi\'dah',
      'Dhu al-Hijjah',
    ];
    const urMonths = [
      'محرم الحرام',
      'صفر المظفر',
      'ربیع الاول',
      'ربیع الثانی',
      'جمادی الاول',
      'جمادی الثانی',
      'رجب المرجب',
      'شعبان المعظم',
      'رمضان المبارک',
      'شوال المکرم',
      'ذی القعدہ',
      'ذی الحجہ',
    ];

    final monthName = urdu ? urMonths[hMonth - 1] : enMonths[hMonth - 1];
    return urdu ? '$hDay $monthName $hYear ھ' : '$hDay $monthName $hYear AH';
  }

  static String _gregorianDateString(DateTime dt) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    return '$dayName, ${dt.day} $monthName ${dt.year}';
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

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
  // Header Banner: Islamic Silhouette + Greeting + Single Search Bar
  // ------------------------------------------------------------------
  // ------------------------------------------------------------------
  // Header Banner: greeting + dates + search, sitting directly on the
  // photographic scenic background painted by build().
  // ------------------------------------------------------------------
  Widget _topHeaderBanner(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final prefs = Provider.of<PreferencesService>(context);
    final ur = prefs.isUrdu;
    final now = DateTime.now();
    final hijri = _hijriDateString(now, ur);
    final greg = _gregorianDateString(now);
    final isDark = theme.brightness == Brightness.dark;

    // Frosted circular button: stays legible over the photographic
    // background (bright sky in light themes, night sky in Royal Navy).
    Widget topButton({
      required IconData icon,
      required VoidCallback onTap,
      required String tooltip,
    }) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (isDark ? Colors.black : Colors.white)
              .withValues(alpha: isDark ? 0.30 : 0.55),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(icon,
              color: isDark ? Colors.white : cs.onSurface, size: 22),
          onPressed: onTap,
          tooltip: tooltip,
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top action bar: Menu (left), Bell & Bookmark (right)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                topButton(
                  icon: Icons.menu_rounded,
                  onTap: () => onSelectTab(4),
                  tooltip: 'Menu',
                ),
                Row(
                  children: [
                    topButton(
                      icon: Icons.notifications_none_rounded,
                      onTap: () => onSelectTab(3),
                      tooltip: ur ? 'اوقات الصلوٰۃ' : 'Prayer Times',
                    ),
                    const SizedBox(width: 8),
                    topButton(
                      icon: Icons.bookmark_outline_rounded,
                      onTap: () => _pushJumpable(
                          context,
                          (open) =>
                              BookmarksScreen(onOpenPage: open)),
                      tooltip: ur ? 'محفوظ آیات' : 'Bookmarks',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Greeting
            Text(
              ur ? 'السلام علیکم 👋' : 'Assalamu Alaikum 👋',
              style: TextStyle(
                color: isDark ? Colors.white : cs.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            // Hijri & Gregorian Dates
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 13,
                    color: (isDark ? Colors.white : cs.onSurface)
                        .withValues(alpha: 0.7)),
                const SizedBox(width: 5),
                Text(
                  hijri,
                  style: TextStyle(
                    color: (isDark ? Colors.white : cs.onSurface)
                        .withValues(alpha: 0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Text(
                greg,
                style: TextStyle(
                  color: (isDark ? Colors.white : cs.onSurface)
                      .withValues(alpha: 0.55),
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Single Top Search Bar (Only here!)
            Material(
              color: isDark ? const Color(0xFF142238) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: isDark ? 0 : 2,
              shadowColor: Colors.black.withValues(alpha: 0.06),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _pushJumpable(
                    context,
                    (open) =>
                        SearchQuranScreen(onOpenPage: open)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded,
                          color: cs.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ur
                              ? 'تلاش: قرآن، سورت، آیت، تفسیر...'
                              : 'Search Quran, Surah, Ayah, Tafsir, Hadith...',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: (isDark ? Colors.white : cs.onSurface)
                                .withValues(alpha: 0.50),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Icon(Icons.tune_rounded,
                          color: cs.primary.withValues(alpha: 0.75),
                          size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ------------------------------------------------------------------
  // Location & Prayer Times Widget
  // ------------------------------------------------------------------
  Widget _prayerTimesCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final prefs = Provider.of<PreferencesService>(context);
    final now = DateTime.now();
    final schedule = PrayerCalculationService.calculate(
      date: now,
      location: prefs.selectedCity,
      asrMode: prefs.asrMethod,
    );
    final nextPrayer = PrayerCalculationService.getNextPrayer(
      schedule,
      now,
      prefs.selectedCity,
    );

    final ur = prefs.isUrdu;
    final cityName = prefs.selectedCity.name.split('/')[0].trim();
    final isDark = theme.brightness == Brightness.dark;

    final prayers = [
      {'name': 'Fajr', 'ur': 'فجر', 'time': schedule.fajr.displayTime, 'icon': Icons.wb_twilight_rounded},
      {'name': 'Dhuhr', 'ur': 'ظہر', 'time': schedule.dhuhr.displayTime, 'icon': Icons.wb_sunny_rounded},
      {'name': 'Asr', 'ur': 'عصر', 'time': schedule.asr.displayTime, 'icon': Icons.sunny_snowing},
      {'name': 'Maghrib', 'ur': 'مغرب', 'time': schedule.maghrib.displayTime, 'icon': Icons.wb_twilight_outlined},
      {'name': 'Isha', 'ur': 'عشاء', 'time': schedule.isha.displayTime, 'icon': Icons.nightlight_round},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Location and Next Prayer link
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: cs.primary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      cityName,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => onSelectTab(3),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ur ? 'اگلی نماز >' : 'Next Prayer >',
                      style: TextStyle(
                        color: cs.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 5 prayer tiles: circular icon chip + name + time.
            // The next-prayer tile gets a soft theme-tinted background.
            Row(
              children: prayers.map((p) {
                final isCurrent = p['name'] == nextPrayer.nameEn;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? cs.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isCurrent
                          ? Border.all(
                              color: cs.primary.withValues(alpha: 0.25))
                          : null,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            p['icon'] as IconData,
                            size: 16,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ur ? (p['ur'] as String) : (p['name'] as String),
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.85),
                            fontSize: 11,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p['time'] as String,
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.65),
                            fontSize: 10,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Last Read Card with 3D Gold Quran Graphic
  // ------------------------------------------------------------------
  Widget _lastReadCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final prefs = Provider.of<PreferencesService>(context);
    final isDark = theme.brightness == Brightness.dark;

    if (prefs.lastReadAt.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last Read',
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start your journey',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => onOpenPage(1),
                icon: const Icon(Icons.menu_book_outlined, size: 16),
                label: const Text('Open the Quran'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final surahIndex = (prefs.lastReadSurah - 1).clamp(0, allSurahs.length - 1);
    final surah = allSurahs[surahIndex];
    final page = prefs.lastReadPage;
    final juz = juzForPage(page);
    final rel = _relativeTime(prefs.lastReadAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3D Quran graphic
                Container(
                  width: 72,
                  height: 92,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.15),
                        blurRadius: 10,
                        offset: const Offset(2, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/quran_cover.jpg',
                      width: 72,
                      height: 92,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Last Read',
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.65),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _dateChip(prefs.lastReadAt),
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.60),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${surah.number}',
                                style: TextStyle(
                                  color: cs.onPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              surah.nameEn,
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            surah.nameAr,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              color: cs.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: arabicFontFamily(prefs.scriptStyle),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Page $page • Juz $juz • $rel',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.60),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Continue Reading button + play button
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => onOpenPage(page),
                              icon: const Icon(Icons.menu_book, size: 15),
                              label: Text(
                                'Continue Reading (Page $page)',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: cs.primary,
                                foregroundColor: cs.onPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: cs.primary,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                showAyahPlayer(
                                  context,
                                  surah: prefs.lastReadSurah,
                                  ayah: prefs.lastReadAyah,
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(7),
                                child: Icon(Icons.play_arrow_rounded,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            showAyahPlayer(
                              context,
                              surah: prefs.lastReadSurah,
                              ayah: prefs.lastReadAyah,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.headphones_rounded,
                                    size: 13, color: cs.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Listen from Ayah ${prefs.lastReadAyah}',
                                  style: TextStyle(
                                    color: cs.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Reading Progress Card
  // ------------------------------------------------------------------
  Widget _readingProgressCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final prefs = Provider.of<PreferencesService>(context);
    final isDark = theme.brightness == Brightness.dark;

    final pagesRead = (prefs.lastReadPage - 1).clamp(0, totalPagesInMushaf);
    final target = prefs.dailyTargetPages;
    final remaining = totalPagesInMushaf - pagesRead;
    final daysLeft = (remaining / max(1, target)).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.menu_book_outlined,
                      color: cs.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Reading Progress',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '$pagesRead of $totalPagesInMushaf Pages',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.70),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (pagesRead / totalPagesInMushaf).clamp(0.01, 1.0),
                minHeight: 8,
                backgroundColor: cs.primary.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Target: $target pages / day  •  Est. $daysLeft days left',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.55),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Ayah of the Day Card with 4 buttons: Copy, Listen, Tafsir, Share
  // ------------------------------------------------------------------
  Widget _ayahOfDayCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final prefs = Provider.of<PreferencesService>(context);
    final a = ayahOfDayFor(DateTime.now());
    final surah = allSurahs[(a.surah - 1).clamp(0, allSurahs.length - 1)];
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.primary.withValues(alpha: 0.20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.wb_sunny_outlined,
                        color: cs.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Ayah of the Day',
                      style: TextStyle(
                        color: cs.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${surah.nameEn} • ${a.surah}:${a.ayah}',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.60),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Arabic Text (right-aligned, like the mockup)
            Text(
              normalizeArabicDisplay(a.ar),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: arabicFontFamily(prefs.scriptStyle),
                fontSize: 22 * prefs.ayahScale,
                color: cs.onSurface,
                height: 2.1,
              ),
            ),
            const SizedBox(height: 12),
            // Translation (left-aligned, like the mockup)
            Text(
              '"${a.en}"',
              textAlign: TextAlign.left,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.85),
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            // 4 Action Buttons: Copy, Listen, Tafsir, Share
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: '${a.ar}\n\n${a.en}'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ayah copied')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    label: const Text('Copy', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.primary,
                      side: BorderSide(color: cs.primary.withValues(alpha: 0.35)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showAyahPlayer(context, surah: a.surah, ayah: a.ayah);
                    },
                    icon: const Icon(Icons.headphones_rounded, size: 14),
                    label: const Text('Listen', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.primary,
                      side: BorderSide(color: cs.primary.withValues(alpha: 0.35)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _push(
                        context,
                        TafsirAyahDetailScreen(surah: a.surah, ayah: a.ayah),
                      );
                    },
                    icon: const Icon(Icons.menu_book_rounded, size: 14),
                    label: const Text('Tafsir', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.primary,
                      side: BorderSide(color: cs.primary.withValues(alpha: 0.35)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Share.share(
                        '${a.ar}\n\n"${a.en}"\n\n— Surah ${surah.nameEn} (${a.surah}:${a.ayah}) • Hafizi Quran & Tafsir',
                      );
                    },
                    icon: const Icon(Icons.share_rounded, size: 14),
                    label: const Text('Share', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.primary,
                      side: BorderSide(color: cs.primary.withValues(alpha: 0.35)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Surah quick-jump card (type a surah name -> opens its first page)
  // ------------------------------------------------------------------
  Widget _surahPickerCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final prefs = Provider.of<PreferencesService>(context);
    final ur = prefs.isUrdu;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.menu_book_outlined,
                      color: cs.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ur ? '۱۱۴ سورتیں' : '114 Surahs',
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ur ? 'کسی بھی سورت پر جائیں' : 'Jump directly to any surah',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.65),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => onSelectTab(2),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ur ? 'تمام دیکھیں >' : 'Browse All >',
                      style: TextStyle(
                        color: cs.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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
                    hintText: ur
                        ? 'سورت کا نام یا نمبر لکھیں... مثلاً یٰس، الفاتحة'
                        : 'Type surah name or number… e.g. Ya-Sin, 36',
                    hintStyle: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.5), fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: cs.primary, size: 20),
                    filled: true,
                    fillColor: cs.onSurface.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.15)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.15)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.primary, width: 1.5),
                    ),
                  ),
                  style: TextStyle(color: cs.onSurface, fontSize: 14),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    color: cs.surface,
                    elevation: 6,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: MediaQuery.of(context).size.width - 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 280),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final s = options.elementAt(index);
                            return ListTile(
                              dense: true,
                              leading: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${s.number}',
                                    style: TextStyle(
                                      color: cs.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(s.nameEn,
                                  style: TextStyle(
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '${s.meaning} • Page ${s.startPage}',
                                style: TextStyle(
                                    color: cs.onSurface.withValues(alpha: 0.6),
                                    fontSize: 11),
                              ),
                              trailing: Text(
                                s.nameAr,
                                style: TextStyle(
                                    color: cs.primary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
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
      ),
    );
  }

  // ------------------------------------------------------------------
  // Quick Access Section (Complete 15 features in 3-column grid)
  // ------------------------------------------------------------------
  Widget _quickAccessSection(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final prefs = Provider.of<PreferencesService>(context);
    final ur = prefs.isUrdu;
    final isDark = theme.brightness == Brightness.dark;

    final items = [
      _QuickItem(
        ur ? 'تمام ۱۱۴ سورتیں' : 'All 114 Surahs',
        Icons.menu_book_rounded,
        () => onSelectTab(2),
      ),
      _QuickItem(
        ur ? 'پارہ انڈیکس' : 'Juz Index',
        Icons.format_list_numbered_rounded,
        () => _pushJumpable(
            context, (open) => JuzIndexScreen(onOpenPage: open)),
      ),
      _QuickItem(
        ur ? 'ختم قرآن پلانر' : 'Khatm Planner',
        Icons.calendar_month_outlined,
        () => _pushJumpable(
            context, (open) => KhatmPlannerScreen(onOpenPage: open)),
      ),
      _QuickItem(
        ur ? 'محفوظ آیات' : 'Bookmarks',
        Icons.bookmark_outline_rounded,
        () => _pushJumpable(
            context, (open) => BookmarksScreen(onOpenPage: open)),
      ),
      _QuickItem(
        ur ? 'تلاش قرآن' : 'Search Quran',
        Icons.search_rounded,
        () => _pushJumpable(
            context, (open) => SearchQuranScreen(onOpenPage: open)),
      ),
      _QuickItem(
        ur ? 'تفسیر ابن کثیر' : 'Tafsir',
        Icons.auto_stories_rounded,
        () => _push(context, const TafsirHomeScreen()),
      ),
      _QuickItem(
        ur ? 'آڈیو تلاوت' : 'Audio Studio',
        Icons.headphones_rounded,
        () => _push(context, AudioStudioScreen()),
      ),
      _QuickItem(
        ur ? 'اوقات و اذان' : 'Prayer Times',
        Icons.access_time_filled_rounded,
        () => onSelectTab(3),
      ),
      _QuickItem(
        ur ? 'قبلہ رخ کمپاس' : 'Qiblah Compass',
        Icons.explore_outlined,
        () => _push(context, const QiblahScreen()),
      ),
      _QuickItem(
        ur ? 'رمضان و دعائیں' : 'Ramzan & Duas',
        Icons.nightlight_round,
        () => _pushJumpable(
            context, (open) => RamzanDuasScreen(onOpenPage: open)),
      ),
      _QuickItem(
        ur ? 'ترجیحات و سیٹنگز' : 'Settings',
        Icons.settings_outlined,
        () => _openSettings(context),
      ),
      _QuickItem(
        ur ? 'سوالات و جوابات' : 'FAQ & Help',
        Icons.help_outline_rounded,
        () => _push(context, const FaqScreen()),
      ),
      _QuickItem(
        ur ? 'بیک اپ و بحالی' : 'Backup & Restore',
        Icons.cloud_outlined,
        () => _push(context, BackupRestoreScreen()),
      ),
      _QuickItem(
        ur ? 'معلومات و لائسنس' : 'About & Licenses',
        Icons.info_outline_rounded,
        () => _push(context, const AboutScreen()),
      ),
      _QuickItem(
        ur ? 'آف لائن ڈاؤن لوڈ' : 'Downloads',
        Icons.cloud_download_outlined,
        () => _push(context, OfflineDownloadScreen()),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grid_view_rounded,
                  size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                ur ? 'فوری رسائی' : 'Quick Access',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, idx) {
              final item = items[idx];
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: item.onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.icon, color: cs.primary, size: 20),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
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

  // ------------------------------------------------------------------
  // 15-Line Mushaf info card (Feature preserved)
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
  // Saved Ayahs preview (Feature preserved)
  // ------------------------------------------------------------------
  Widget _savedAyahsSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final prefs = Provider.of<PreferencesService>(context);
    final saved = prefs.savedAyahs;

    if (saved.isEmpty) return const SizedBox.shrink();

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
                onPressed: () => _pushJumpable(
                    context, (open) => BookmarksScreen(onOpenPage: open)),
                child: Text('View All', style: TextStyle(color: cs.primary)),
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
    final theme = Theme.of(context);
    final prefs = Provider.of<PreferencesService>(context);
    // Photographic scenic background per theme (bundled, offline).
    final bgAsset = prefs.themeName == 'light_blue'
        ? 'assets/images/home_bg_blue.jpg'
        : prefs.themeName == 'royal_navy'
            ? 'assets/images/home_bg_navy.jpg'
            : 'assets/images/home_bg_green.jpg';
    final scaffoldBg = theme.scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Full-screen scenic mosque + palm background.
          Positioned.fill(
            child: Image.asset(
              bgAsset,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          // Fade into the solid scaffold background so the lower cards
          // stay readable, like the mockup's fading scenic backdrop.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scaffoldBg.withValues(alpha: 0.0),
                    scaffoldBg.withValues(alpha: 0.0),
                    scaffoldBg.withValues(alpha: 0.85),
                    scaffoldBg,
                  ],
                  stops: const [0.0, 0.35, 0.62, 0.8],
                ),
              ),
            ),
          ),
          ListView(
            padding: EdgeInsets.zero,
            children: [
              _topHeaderBanner(context),
              const SizedBox(height: 4),
              _prayerTimesCard(context),
              _lastReadCard(context),
              _readingProgressCard(context),
              _ayahOfDayCard(context),
              _surahPickerCard(context),
              _quickAccessSection(context),
              _mushafInfoCard(context),
              _savedAyahsSection(context),
              const SizedBox(height: 36),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickItem(this.title, this.icon, this.onTap);
}
