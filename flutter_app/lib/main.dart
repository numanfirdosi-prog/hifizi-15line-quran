import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/preferences_service.dart';
import 'services/audio_recitation_service.dart';
import 'services/azan_alarm_service.dart';
import 'views/home_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Core Services
  final preferencesService = PreferencesService();
  await preferencesService.init();

  final azanAlarmService = AzanAlarmService();
  await azanAlarmService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<PreferencesService>.value(value: preferencesService),
        ChangeNotifierProvider<AudioRecitationService>(create: (_) => AudioRecitationService()),
      ],
      child: const NurAlQuranApp(),
    ),
  );
}

class NurAlQuranApp extends StatelessWidget {
  const NurAlQuranApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نور القرآن (Nur-ul-Quran)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
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
      ),
      home: const HomeNavigationScreen(),
    );
  }
}

