import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../main.dart';
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
  final List<int> _tabHistory = [];

  // Bottom-bar visual order (mockup): Home, Surahs, Quran, Prayer, More.
  // Maps visual position -> internal tab index (Quran opens the Mushaf
  // reader tab, which is internal index 1).
  static const _navTabIndex = [0, 2, 1, 3, 4];
  static const _navLabels = ['Home', 'Surahs', 'Quran', 'Prayer', 'More'];
  static const _navIcons = [
    Icons.home_outlined,
    Icons.format_list_bulleted_outlined,
    Icons.menu_book_outlined,
    Icons.access_time_outlined,
    Icons.grid_view_outlined,
  ];
  static const _navIconsSelected = [
    Icons.home,
    Icons.format_list_bulleted,
    Icons.menu_book,
    Icons.access_time_filled,
    Icons.grid_view,
  ];

  @override
  void initState() {
    super.initState();
    DeepLinkService.pendingPage.addListener(_onDeepLinkPage);
    DeepLinkService.onInvalidLink = _onInvalidDeepLink;
    // A cold-start deep link may already be waiting.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onDeepLinkPage());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = Provider.of<PreferencesService>(context, listen: false);
      // Restore the last-read page into the Mushaf tab (setState: without
      // it the tab would stay stuck on the field-initializer page 2).
      final lastPage = prefs.lastReadPage;
      if (lastPage != _mushafTargetPage && mounted) {
        setState(() => _mushafTargetPage = lastPage);
      }

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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Nur.cardRadius),
              ),
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
    if (_currentIndex != 1) {
      _tabHistory.add(_currentIndex);
    }
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
    if (index != _currentIndex) {
      _tabHistory.add(_currentIndex);
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _handleBackNavigation() {
    while (_tabHistory.isNotEmpty && _tabHistory.last == _currentIndex) {
      _tabHistory.removeLast();
    }
    if (_tabHistory.isNotEmpty) {
      final prevIndex = _tabHistory.removeLast();
      setState(() => _currentIndex = prevIndex);
      return;
    }
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }
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
        key: ValueKey(_mushafTargetPage),
        initialPage: _mushafTargetPage,
        onBackToPreviousTab: _handleBackNavigation,
      ),
      SurahsScreen(onOpenPage: _jumpToMushafPage),
      const PrayerScreen(),
      MoreScreen(
        onOpenPage: _jumpToMushafPage,
        onSelectTab: _selectTab,
      ),
    ];

    // Back button: navigate backwards through tab history; on root Home ask for
    // confirmation before closing the app.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        while (_tabHistory.isNotEmpty && _tabHistory.last == _currentIndex) {
          _tabHistory.removeLast();
        }
        if (_tabHistory.isNotEmpty) {
          final prevIndex = _tabHistory.removeLast();
          setState(() => _currentIndex = prevIndex);
          return;
        }
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }
        final exit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Nur.cardRadius),
            ),
            title: const Text('App band karein?'),
            content:
                const Text('Kya aap Hafizi Quran & Tafsir app band karna chahte hain?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Nahi'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Haan'),
              ),
            ],
          ),
        );
        if (exit == true && mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
        // The bottom tab bar stays on Home/Surahs/Prayer/More, but is
        // hidden on the Mushaf reader tab so the Quran page gets the
        // full screen. System back returns to Home.
        bottomNavigationBar: _currentIndex == 1
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: List.generate(5, (pos) {
                          final tabIndex = _navTabIndex[pos];
                          final selected = tabIndex == _currentIndex;
                          return Expanded(
                            child: InkWell(
                              onTap: () => _selectTab(tabIndex),
                              borderRadius: BorderRadius.circular(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? cs.primary
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      selected
                                          ? _navIconsSelected[pos]
                                          : _navIcons[pos],
                                      color: selected
                                          ? cs.onPrimary
                                          : cs.onSurface
                                              .withValues(alpha: 0.55),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _navLabels[pos],
                                    style: TextStyle(
                                      color: selected
                                          ? cs.primary
                                          : cs.onSurface
                                              .withValues(alpha: 0.55),
                                      fontSize: 11,
                                      fontWeight: selected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
