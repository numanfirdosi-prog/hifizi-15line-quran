import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/preferences_service.dart';
import '../services/azan_alarm_service.dart';
import '../services/deep_link_service.dart';
import 'dashboard_screen.dart';
import 'mushaf_screen.dart';
import 'surahs_screen.dart';
import 'prayer_screen.dart';
import 'more_screen.dart';

class HomeNavigationScreen extends StatefulWidget {
  const HomeNavigationScreen({Key? key}) : super(key: key);

  @override
  State<HomeNavigationScreen> createState() => _HomeNavigationScreenState();
}

class _HomeNavigationScreenState extends State<HomeNavigationScreen> {
  int _currentIndex = 0;
  int _mushafTargetPage = 2;

  @override
  void initState() {
    super.initState();
    DeepLinkService.pendingPage.addListener(_onDeepLinkPage);
    DeepLinkService.onInvalidLink = _onInvalidDeepLink;
    // A cold-start deep link may already be waiting.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onDeepLinkPage());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = Provider.of<PreferencesService>(context, listen: false);
      _mushafTargetPage = prefs.lastReadPage;

      // M8: On Android 12+, exact alarms need a dedicated permission. If the
      // user has the lockscreen alarm ON but the permission is missing, ask
      // once — otherwise alarms would silently never fire.
      if (prefs.lockscreenAlarmEnabled) {
        final canSchedule = await AzanAlarmService().canScheduleExactAlarms();
        if (!canSchedule && mounted) {
          final cs = Theme.of(context).colorScheme;
          final granted = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: cs.surface,
              title: Text('Allow Exact Alarms?',
                  style: TextStyle(
                      color: cs.onSurface, fontWeight: FontWeight.bold)),
              content: Text(
                'To play the Azan exactly on time even when your phone is locked, please allow "Alarms & reminders" on the next screen.',
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.7),
                    fontSize: 13,
                    height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Not now',
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.6))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Allow'),
                ),
              ],
            ),
          );
          if (granted == true) {
            await AzanAlarmService().requestExactAlarmPermission();
          }
        }
      }

      // Schedule background alarms for prayer times
      AzanAlarmService().scheduleDailyPrayerAlarms(
        location: prefs.selectedCity,
        asrMode: prefs.asrMethod,
        enabledAlarms: prefs.prayerAlarms,
        azanSoundEnabled: prefs.azanSoundEnabled,
        lockscreenAlarmEnabled: prefs.lockscreenAlarmEnabled,
      );
    });
  }

  void _jumpToMushafPage(int page) {
    setState(() {
      _mushafTargetPage = page;
      _currentIndex = 1; // Switch to Mushaf tab
    });
  }

  /// Handles `quranapp://page/<n>` deep links (validated 1..611).
  void _onDeepLinkPage() {
    final page = DeepLinkService.pendingPage.value;
    if (page == null || !mounted) return;
    DeepLinkService.pendingPage.value = null;
    _jumpToMushafPage(page);
  }

  void _onInvalidDeepLink() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid page link')),
    );
  }

  @override
  void dispose() {
    DeepLinkService.pendingPage.removeListener(_onDeepLinkPage);
    if (DeepLinkService.onInvalidLink == _onInvalidDeepLink) {
      DeepLinkService.onInvalidLink = null;
    }
    super.dispose();
  }

  void _selectTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screens = [
      DashboardScreen(
        onOpenPage: _jumpToMushafPage,
        onSelectTab: _selectTab,
      ),
      MushafScreen(
          key: ValueKey(_mushafTargetPage), initialPage: _mushafTargetPage),
      SurahsScreen(onOpenPage: _jumpToMushafPage),
      const PrayerScreen(),
      MoreScreen(
        onOpenPage: _jumpToMushafPage,
        onSelectTab: _selectTab,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: cs.surface,
          indicatorColor: cs.primary.withValues(alpha: 0.2),
          labelTextStyle:
              MaterialStateProperty.resolveWith<TextStyle>((states) {
            if (states.contains(MaterialState.selected)) {
              return TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11);
            }
            return TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 11);
          }),
          iconTheme: MaterialStateProperty.resolveWith<IconThemeData>((states) {
            if (states.contains(MaterialState.selected)) {
              return IconThemeData(color: cs.primary, size: 24);
            }
            return IconThemeData(color: cs.onSurface.withValues(alpha: 0.6), size: 22);
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) {
            setState(() {
              _currentIndex = idx;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'ہوم',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'مصحف',
            ),
            NavigationDestination(
              icon: Icon(Icons.format_list_bulleted_outlined),
              selectedIcon: Icon(Icons.format_list_bulleted),
              label: 'سورتیں',
            ),
            NavigationDestination(
              icon: Icon(Icons.access_time_outlined),
              selectedIcon: Icon(Icons.access_time_filled),
              label: 'نماز و اذان',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view),
              label: 'مزید',
            ),
          ],
        ),
      ),
    );
  }
}
