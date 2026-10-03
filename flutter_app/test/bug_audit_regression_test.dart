import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nur_al_quran/services/audio_recitation_service.dart';
import 'package:nur_al_quran/services/preferences_service.dart';

/// Regression tests for logic bugs found and fixed in the 2026-10-03
/// full-app bug audit (workers A–E). Pure logic / service-level only.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<PreferencesService> freshPrefs() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PreferencesService();
    await prefs.init();
    return prefs;
  }

  group('PreferencesService.resetAll (audit fix E1)', () {
    test('clears in-memory khatm/onboarding/backup/hint state', () async {
      final prefs = await freshPrefs();
      await prefs.toggleKhatmDay(5);
      await prefs.setOnboardingDone(true);
      await prefs.setAutoBackup(true);
      await prefs.setLastAutoBackup('2026-10-03T00:00:00Z');
      await prefs.setAyahTapHintShown(true);

      expect(prefs.khatmDays, contains(5));
      expect(prefs.onboardingDone, isTrue);

      await prefs.resetAll();

      expect(prefs.khatmDays, isEmpty);
      expect(prefs.onboardingDone, isFalse);
      expect(prefs.autoBackup, isFalse);
      expect(prefs.lastAutoBackup, isEmpty);
      expect(prefs.ayahTapHintShown, isFalse);
    });
  });

  group('PreferencesService export/import (audit fix E2)', () {
    test('round-trips the previously dropped prefs', () async {
      final prefs = await freshPrefs();
      await prefs.toggleKhatmDay(7);
      await prefs.setOnboardingDone(true);
      await prefs.setAutoBackup(true);
      await prefs.setLastAutoBackup('2026-10-03T00:00:00Z');
      await prefs.setAyahTapHintShown(true);

      final blob = prefs.exportJson();
      expect(blob, contains('khatmDays'));
      expect(blob, contains('onboardingDone'));
      expect(blob, contains('autoBackup'));
      expect(blob, contains('lastAutoBackup'));
      expect(blob, contains('ayahTapHintShown'));

      final restored = await freshPrefs();
      expect(await restored.importJson(blob), isTrue);
      expect(restored.khatmDays, contains(7));
      expect(restored.onboardingDone, isTrue);
      expect(restored.autoBackup, isTrue);
      expect(restored.lastAutoBackup, '2026-10-03T00:00:00Z');
      expect(restored.ayahTapHintShown, isTrue);
    });

    test('old backups missing the new keys still import with defaults',
        () async {
      final prefs = await freshPrefs();
      expect(await prefs.importJson('{"themeName":"emerald"}'), isTrue);
      expect(prefs.khatmDays, isEmpty);
      expect(prefs.onboardingDone, isFalse);
      expect(prefs.autoBackup, isFalse);
      expect(prefs.lastAutoBackup, isEmpty);
      expect(prefs.ayahTapHintShown, isFalse);
    });
  });

  group('AudioRecitationService.playSurah (audit fix E4)', () {
    test('clears a stale ayah repeat range', () async {
      SharedPreferences.setMockInitialValues({});
      final audio = AudioRecitationService();
      addTearDown(audio.dispose);

      await audio.setAyahRepeatRange(surah: 2, startAyah: 1, endAyah: 5);
      expect(audio.hasAyahRepeatRange, isTrue);

      await audio.playSurah(surahNumber: 3);
      expect(audio.hasAyahRepeatRange, isFalse);
      expect(audio.repeatRangeStart, isNull);
      expect(audio.repeatRangeEnd, isNull);
    });
  });
}
