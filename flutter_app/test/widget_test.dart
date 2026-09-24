import 'package:flutter_test/flutter_test.dart';
import 'package:nur_al_quran/main.dart';
import 'package:provider/provider.dart';
import 'package:nur_al_quran/services/preferences_service.dart';
import 'package:nur_al_quran/services/audio_recitation_service.dart';

void main() {
  testWidgets('NurAlQuranApp smoke test', (WidgetTester tester) async {
    final prefs = PreferencesService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PreferencesService>.value(value: prefs),
          ChangeNotifierProvider<AudioRecitationService>(create: (_) => AudioRecitationService()),
        ],
        child: const NurAlQuranApp(),
      ),
    );

    expect(find.byType(NurAlQuranApp), findsOneWidget);
  });
}
