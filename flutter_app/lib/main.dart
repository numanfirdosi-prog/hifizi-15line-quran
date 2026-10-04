import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'services/azan_alarm_service.dart';
import 'services/preferences_service.dart';
import 'services/audio_recitation_service.dart';
import 'services/qari_download_service.dart';
import 'services/page_drawing_service.dart';
import 'services/nur_audio_handler.dart';
import 'services/deep_link_service.dart';
import 'views/splash_screen.dart';

/// App theme palettes, switchable live from Preferences (themeName:
/// 'night' | 'emerald' | 'parchment').
ThemeData buildTheme(String name) {
  switch (name) {
    case 'emerald':
      // Emerald Day — light mint sanctuary with crisp emerald typography.
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFEAF5EF),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1B4D3E), // Deep Emerald
          secondary: Color(0xFFD4AF37), // Gold
          surface: Color(0xFFFFFFFF),
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Color(0xFF1A2B23),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B4D3E),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Color(0xFFD4AF37)),
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 1,
        ),
      );
    case 'parchment':
      // Antique Parchment — warm sepia, aged-manuscript feel.
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF3E9D2),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF8B5E34),
          secondary: Color(0xFF1B4D3E),
          surface: Color(0xFFFBF6E9),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFF3E2F1C),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF8B5E34),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Color(0xFFFFE9B8)),
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFFFBF6E9),
          elevation: 1,
        ),
      );
    case 'night':
    default:
      // Night Slate — the original dark emerald/gold theme.
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF071F17),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37), // Gold
          secondary: Color(0xFF1B4D3E), // Deep Emerald
          surface: Color(0xFF0F3A2C),
          onPrimary: Colors.black,
          onSecondary: Colors.white,
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F3A2C),
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Color(0xFFD4AF37)),
        ),
      );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // IANA timezone database — required for daylight-saving-correct prayer
  // times (M5) and scheduled notifications.
  tzdata.initializeTimeZones();

  // Initialize Core Services
  final preferencesService = PreferencesService();
  await preferencesService.init();

  // Audio service is created up-front so the background-audio bridge and
  // deep-link handler can attach to the same instance.
  final audioService = AudioRecitationService();

  // Page drawing service: loads persisted highlighter/pen strokes.
  final pageDrawingService = PageDrawingService();
  await pageDrawingService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<PreferencesService>.value(
            value: preferencesService),
        ChangeNotifierProvider<AudioRecitationService>.value(
            value: audioService),
        ChangeNotifierProvider<QariDownloadService>(
            create: (_) => QariDownloadService()),
        ChangeNotifierProvider<PageDrawingService>.value(
            value: pageDrawingService),
      ],
      child: const NurAlQuranApp(),
    ),
  );

  // Best-effort background services: guarded internally, never block or
  // crash startup, and the app works fully without them.
  initBackgroundAudio(audioService);
  DeepLinkService.init();
}

class NurAlQuranApp extends StatefulWidget {
  const NurAlQuranApp({Key? key}) : super(key: key);

  @override
  State<NurAlQuranApp> createState() => _NurAlQuranAppState();
}

class _NurAlQuranAppState extends State<NurAlQuranApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Background Playback toggle: when disabled, pause recitation as soon
    // as the app leaves the foreground.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      final prefs = Provider.of<PreferencesService>(context, listen: false);
      final audio = Provider.of<AudioRecitationService>(context, listen: false);
      if (!prefs.backgroundPlaybackEnabled && audio.isPlaying) {
        audio.pause();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild MaterialApp whenever the theme preference changes so the
    // palette applies live without restarting the app.
    return Consumer<PreferencesService>(
      builder: (context, prefs, _) {
        return MaterialApp(
          title: 'نور القرآن (Nur-ul-Quran)',
          debugShowCheckedModeBanner: false,
          navigatorKey: appNavigatorKey,
          theme: buildTheme(prefs.themeName),
          home: const SplashScreen(),
        );
      },
    );
  }
}
