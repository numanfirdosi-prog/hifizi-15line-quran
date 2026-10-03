import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nur_al_quran/main.dart' show buildTheme;
import 'package:nur_al_quran/services/audio_recitation_service.dart';
import 'package:nur_al_quran/services/page_drawing_service.dart';
import 'package:nur_al_quran/services/preferences_service.dart';
import 'package:nur_al_quran/views/home_navigation_screen.dart';

void main() {
  testWidgets(
      'emerald theme visibly recolors HomeNavigationScreen chrome',
      (tester) async {
    // Azan alarm scheduling in initState touches the notifications plugin;
    // mock its channel so the widget can build in tests.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (MethodCall call) async => true,
    );

    SharedPreferences.setMockInitialValues({'nur_theme_name': 'emerald'});
    final prefs = PreferencesService();
    await prefs.init();
    expect(prefs.themeName, 'emerald');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PreferencesService>.value(value: prefs),
          ChangeNotifierProvider<AudioRecitationService>(
              create: (_) => AudioRecitationService()),
          ChangeNotifierProvider<PageDrawingService>(
              create: (_) => PageDrawingService()),
        ],
        child: Consumer<PreferencesService>(
          builder: (context, p, _) => MaterialApp(
            theme: buildTheme(p.themeName),
            home: const HomeNavigationScreen(),
          ),
        ),
      ),
    );
    await tester.pump();

    // The Scaffold background must follow the emerald theme, not the old
    // hardcoded night color. (Scaffold.backgroundColor is null because it
    // inherits the theme's scaffoldBackgroundColor — assert the effective.)
    final scaffoldCtx = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(scaffoldCtx).scaffoldBackgroundColor,
        const Color(0xFFEAF5EF));

    // The bottom NavigationBar must also be theme-aware (emerald surface).
    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    final navTheme =
        tester.widget<NavigationBarTheme>(find.byType(NavigationBarTheme));
    expect(navTheme.data.backgroundColor, buildTheme('emerald').colorScheme.surface);
    expect(navBar.selectedIndex, 0);
  });
}
