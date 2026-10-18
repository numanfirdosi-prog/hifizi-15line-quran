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
      'soft_green theme visibly recolors HomeNavigationScreen chrome',
      (tester) async {
    // Azan alarm scheduling in initState touches the notifications plugin;
    // mock its channel so the widget can build in tests.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (MethodCall call) async => true,
    );

    SharedPreferences.setMockInitialValues({'nur_theme_name': 'soft_green'});
    final prefs = PreferencesService();
    await prefs.init();
    expect(prefs.themeName, 'soft_green');

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

    final scaffoldCtx = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(scaffoldCtx).scaffoldBackgroundColor,
        const Color(0xFFF4F8F5));

    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    final navTheme =
        tester.widget<NavigationBarTheme>(find.byType(NavigationBarTheme));
    expect(navTheme.data.backgroundColor, const Color(0xFFF4F8F5));
    expect(navBar.selectedIndex, 0);
  });

  test('all 3 new themes build without error and match token specifications', () {
    final green = buildTheme('soft_green');
    expect(green.colorScheme.primary, const Color(0xFF0E6848));
    expect(green.colorScheme.tertiary, const Color(0xFFD4AF37));
    expect(green.scaffoldBackgroundColor, const Color(0xFFF4F8F5));
    expect(green.colorScheme.surface, const Color(0xFFFFFFFF));
    expect(green.colorScheme.surfaceContainerHighest, const Color(0xFFE8F3EE));
    expect(green.colorScheme.onSurface, const Color(0xFF16261E));

    final blue = buildTheme('light_blue');
    expect(blue.colorScheme.primary, const Color(0xFF0284C7));
    expect(blue.colorScheme.tertiary, const Color(0xFFD4AF37));
    expect(blue.scaffoldBackgroundColor, const Color(0xFFF0F6FB));
    expect(blue.colorScheme.surface, const Color(0xFFFFFFFF));
    expect(blue.colorScheme.surfaceContainerHighest, const Color(0xFFE0F2FE));
    expect(blue.colorScheme.onSurface, const Color(0xFF0F1D33));

    final navy = buildTheme('royal_navy');
    expect(navy.colorScheme.primary, const Color(0xFFD4AF37));
    expect(navy.colorScheme.tertiary, const Color(0xFFE8D29A));
    expect(navy.scaffoldBackgroundColor, const Color(0xFF0B1324));
    expect(navy.colorScheme.surface, const Color(0xFF132035));
    expect(navy.colorScheme.surfaceContainerHighest, const Color(0xFF1D2C46));
    expect(navy.colorScheme.onSurface, const Color(0xFFF8FAFC));
    expect(navy.brightness, Brightness.dark);
  });
}
