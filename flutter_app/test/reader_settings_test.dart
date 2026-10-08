import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nur_al_quran/services/audio_recitation_service.dart';
import 'package:nur_al_quran/services/preferences_service.dart';
import 'package:nur_al_quran/utils/script_font.dart';

Future<PreferencesService> _prefs(
    [Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  final p = PreferencesService();
  await p.init();
  return p;
}

/// Test double: real service API, but playAyah never touches audio.
class _NoAudioService extends AudioRecitationService {
  _NoAudioService() : super();

  @override
  Future<bool> playAyah({required int surah, required int ayah, bool keepRepeatRange = false, bool autoAdvance = false}) async =>
      true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('script style (Noto Sans Arabic)', () {
    test('default style is sans', () async {
      final p = await _prefs();
      expect(p.scriptStyle, 'sans');
    });

    test('retired nastaliq migrates to sans', () async {
      final p = await _prefs({'nur_script_style': 'nastaliq'});
      expect(p.scriptStyle, 'sans');
    });

    test('uthmani is preserved', () async {
      final p = await _prefs({'nur_script_style': 'uthmani'});
      expect(p.scriptStyle, 'uthmani');
    });

    test('setScriptStyle accepts sans and uthmani only', () async {
      final p = await _prefs();
      await p.setScriptStyle('uthmani');
      expect(p.scriptStyle, 'uthmani');
      await p.setScriptStyle('nastaliq'); // rejected
      expect(p.scriptStyle, 'uthmani');
      await p.setScriptStyle('sans');
      expect(p.scriptStyle, 'sans');
    });

    test('font families resolve correctly', () {
      expect(arabicFontFamily('sans'), 'Noto Sans Arabic');
      expect(arabicFontFamily('uthmani'), 'Amiri Quran');
    });
  });

  group('reader settings prefs', () {
    test('audio highlight defaults to on and persists', () async {
      final p = await _prefs();
      expect(p.audioHighlightEnabled, isTrue);
      await p.setAudioHighlightEnabled(false);
      expect(p.audioHighlightEnabled, isFalse);
    });

    test('background playback defaults to on and persists', () async {
      final p = await _prefs();
      expect(p.backgroundPlaybackEnabled, isTrue);
      await p.setBackgroundPlaybackEnabled(false);
      expect(p.backgroundPlaybackEnabled, isFalse);
    });

    test('new prefs are included in export/import', () async {
      final p = await _prefs();
      await p.setAudioHighlightEnabled(false);
      await p.setBackgroundPlaybackEnabled(false);
      final json = p.exportJson();

      SharedPreferences.setMockInitialValues({});
      final p2 = PreferencesService();
      await p2.init();
      await p2.importJson(json);
      expect(p2.audioHighlightEnabled, isFalse);
      expect(p2.backgroundPlaybackEnabled, isFalse);
    });
  });

  group('ayah repeat range', () {
    test('isValidAyahRange validates ranges', () {
      expect(
          AudioRecitationService.isValidAyahRange(2, 255, 260), isTrue);
      expect(
          AudioRecitationService.isValidAyahRange(2, 260, 255), isFalse);
      expect(AudioRecitationService.isValidAyahRange(2, 0, 5), isFalse);
      expect(AudioRecitationService.isValidAyahRange(115, 1, 5), isFalse);
    });

    test('repeatRangeLabel reflects the active range', () async {
      final audio = _NoAudioService();
      expect(audio.repeatRangeLabel, isNull);
      final ok = await audio.setAyahRepeatRange(
          surah: 2, startAyah: 255, endAyah: 260);
      expect(ok, isTrue);
      expect(audio.repeatRangeLabel, 'Surah 2: 255–260 (loop)');
      audio.clearAyahRepeatRange();
      expect(audio.repeatRangeLabel, isNull);
    });
  });
}
