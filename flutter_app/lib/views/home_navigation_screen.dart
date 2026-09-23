import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/preferences_service.dart';
import '../services/azan_alarm_service.dart';
import 'mushaf_screen.dart';
import 'surahs_screen.dart';
import 'prayer_screen.dart';
import 'qiblah_screen.dart';
import 'settings_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefs = Provider.of<PreferencesService>(context, listen: false);
      _mushafTargetPage = prefs.lastReadPage;

      // Schedule background alarms for prayer times
      AzanAlarmService().scheduleDailyPrayerAlarms(
        location: prefs.selectedCity,
        asrMode: prefs.asrMethod,
        enabledAlarms: prefs.prayerAlarms,
        azanSoundEnabled: prefs.azanSoundEnabled,
      );
    });
  }

  void _jumpToMushafPage(int page) {
    setState(() {
      _mushafTargetPage = page;
      _currentIndex = 0; // Switch to Mushaf tab
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      MushafScreen(key: ValueKey(_mushafTargetPage), initialPage: _mushafTargetPage),
      SurahsScreen(onOpenPage: _jumpToMushafPage),
      const PrayerScreen(),
      const QiblahScreen(),
      SettingsScreen(onOpenPage: _jumpToMushafPage),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: const Color(0xFF0F3A2C),
          indicatorColor: const Color(0xFFD4AF37).withOpacity(0.2),
          labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>((states) {
            if (states.contains(MaterialState.selected)) {
              return const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 11);
            }
            return const TextStyle(color: Colors.white60, fontSize: 11);
          }),
          iconTheme: MaterialStateProperty.resolveWith<IconThemeData>((states) {
            if (states.contains(MaterialState.selected)) {
              return const IconThemeData(color: Color(0xFFD4AF37), size: 24);
            }
            return const IconThemeData(color: Colors.white60, size: 22);
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
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'قبلہ',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'تنظیمات',
            ),
          ],
        ),
      ),
    );
  }
}

