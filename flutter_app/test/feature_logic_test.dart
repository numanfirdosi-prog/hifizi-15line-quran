import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nur_al_quran/services/audio_recitation_service.dart';
import 'package:nur_al_quran/services/preferences_service.dart';
import 'package:nur_al_quran/views/dashboard_screen.dart';
import 'package:nur_al_quran/views/info_screens.dart';
import 'package:nur_al_quran/views/juz_index_screen.dart';
import 'package:nur_al_quran/views/search_quran_screen.dart';
import 'package:nur_al_quran/views/more_screen.dart';

Future<PreferencesService> _prefs() async {
  SharedPreferences.setMockInitialValues({});
  final p = PreferencesService();
  await p.init();
  return p;
}

/// Mock platform channels touched by just_audio / path_provider so the real
/// AudioRecitationService can be provided in widget tests.
void _mockAudioChannels() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('com.ryanheise.just_audio.methods'),
    (MethodCall call) async {
      // dispose responses are parsed via fromMap (content ignored).
      if (call.method == 'disposeAllPlayers' ||
          call.method == 'disposePlayer') {
        return <dynamic, dynamic>{};
      }
      return null;
    },
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall call) async {
      if (call.method == 'getTemporaryDirectory') return '/tmp';
      return null;
    },
  );
}

/// Test double: real service API, but playAyah never touches just_audio
/// platform channels (unmockable per-player channel ids).
class _NoAudioService extends AudioRecitationService {
  _NoAudioService() : super();

  @override
  Future<bool> playAyah({required int surah, required int ayah, bool keepRepeatRange = false, bool autoAdvance = false}) async {
    // No-op in tests.
    return true;
  }
}

Widget _wrap(Widget child, PreferencesService prefs,
    {AudioRecitationService? audio}) {
  _mockAudioChannels();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<PreferencesService>.value(value: prefs),
      ChangeNotifierProvider<AudioRecitationService>.value(
        value: audio ?? AudioRecitationService(),
      ),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('Dashboard: fresh install shows Start journey; Open Quran fires',
      (tester) async {
    await tester.runAsync(() async {
      // flutter_test mocks HTTP (all requests -> 400), breaking google_fonts.
      // Restore real HTTP inside the test so fonts can download.
      HttpOverrides.global = null;
      final prefs = await _prefs();
      int? openedPage;
      await tester.pumpWidget(_wrap(
        DashboardScreen(
          onOpenPage: (p) => openedPage = p,
          onSelectTab: (_) {},
        ),
        prefs,
      ));
      await tester.pump();
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.text('Start your journey'), findsOneWidget);
      expect(find.text('Ayah of the Day'), findsOneWidget);
      // Scroll to Quick Access.
      final listView = find.byType(ListView).first;
      for (var i = 0;
          i < 12 && find.text('Quick Access').evaluate().isEmpty;
          i++) {
        await tester.drag(listView, const Offset(0, -500));
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.text('Quick Access'), findsOneWidget);
      expect(find.text('All Surahs'), findsOneWidget);
      expect(find.text('Juz Index'), findsOneWidget);
      expect(find.text('Bookmarks'), findsOneWidget);
      // Back to the top for the Open-the-Quran button.
      for (var i = 0;
          i < 12 && find.text('Open the Quran').evaluate().isEmpty;
          i++) {
        await tester.drag(listView, const Offset(0, 500));
        await tester.pump(const Duration(milliseconds: 300));
      }
      await tester.tap(find.text('Open the Quran'));
      await tester.pump();
      expect(openedPage, 1);
    });
  });

  testWidgets('Dashboard Quick Access All Surahs triggers tab selection',
      (tester) async {
    await tester.runAsync(() async {
      HttpOverrides.global = null;
      final prefs = await _prefs();
      int? selectedTab;
      await tester.pumpWidget(_wrap(
        DashboardScreen(
          onOpenPage: (_) {},
          onSelectTab: (t) => selectedTab = t,
        ),
        prefs,
      ));
      await tester.pump();
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      final listView = find.byType(ListView).first;
      for (var i = 0;
          i < 12 && find.text('All Surahs').evaluate().isEmpty;
          i++) {
        await tester.drag(listView, const Offset(0, -300));
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.text('All Surahs'), findsOneWidget);
      await tester.tap(find.text('All Surahs'));
      await tester.pump();
      expect(selectedTab, 2);
    });
  });

  testWidgets('Search finds verses for "mercy" after submit', (tester) async {
    // Asset loading (bundled Quran text) needs real async, not the fake
    // async zone that testWidgets uses by default.
    await tester.runAsync(() async {
      // flutter_test mocks HTTP (all requests -> 400), breaking google_fonts.
      // Restore real HTTP inside the test so fonts can download.
      HttpOverrides.global = null;
      final prefs = await _prefs();
      await tester.pumpWidget(_wrap(
        SearchQuranScreen(onOpenPage: (_) {}),
        prefs,
        audio: _NoAudioService(),
      ));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'mercy');
      await tester.pump();
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed!();
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.textContaining('results'), findsOneWidget);
      // Tapping a result must open the ayah player sheet (highlight + audio).
      // Result cards are InkWells inside the results ListView.
      final resultInkWell = find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(InkWell),
          )
          .first;
      await tester.tap(resultInkWell);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(find.textContaining('Ayah-by-ayah'), findsOneWidget);
    });
  });

  testWidgets('Juz index shows 30 and Read Juz fires callback', (tester) async {
    await tester.runAsync(() async {
      // flutter_test mocks HTTP (all requests -> 400), breaking google_fonts.
      // Restore real HTTP inside the test so fonts can download.
      HttpOverrides.global = null;
      final prefs = await _prefs();
      int? openedPage;
      await tester.pumpWidget(_wrap(
        JuzIndexScreen(onOpenPage: (p) => openedPage = p),
        prefs,
      ));
      await tester.pump();
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.textContaining('Juz 1'), findsWidgets);
      await tester.tap(find.textContaining('Read Juz').first);
      await tester.pump();
      expect(openedPage, isNotNull);
    });
  });

  testWidgets('More screen navigates to FAQ', (tester) async {
    await tester.runAsync(() async {
      // flutter_test mocks HTTP (all requests -> 400), breaking google_fonts.
      // Restore real HTTP inside the test so fonts can download.
      HttpOverrides.global = null;
      final prefs = await _prefs();
      await tester.pumpWidget(_wrap(
        MoreScreen(onOpenPage: (_) {}, onSelectTab: (_) {}),
        prefs,
      ));
      await tester.pump();
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      // MoreScreen items are in a lazy list — scroll the FAQ entry into view.
      final listView = find.byType(Scrollable).first;
      await tester.drag(listView, const Offset(0, -1200));
      await tester.pump();
      expect(find.text('Questions & FAQ'), findsOneWidget);
      await tester.tap(find.text('Questions & FAQ'));
      await tester.pump();
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      // FAQ screen pushed on top of the More screen.
      expect(find.byType(FaqScreen), findsOneWidget);
    });
  });
}
