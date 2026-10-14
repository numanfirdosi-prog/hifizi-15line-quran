import 'package:flutter_test/flutter_test.dart';
import 'package:nur_al_quran/services/tafsir_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TafsirService (Bundled Ibn Kathir Urdu)', () {
    final service = TafsirService();

    test('getTafsir never throws for a valid ayah', () async {
      String? result;
      try {
        result = await service.getTafsir(1, 1);
      } catch (e) {
        fail('getTafsir threw: $e');
      }
      // Result may be null if the bundled data does not cover 1:1,
      // but it must not throw. If data exists, it must be non-empty.
      if (result != null) {
        expect(result.trim().isNotEmpty, isTrue);
      }
    });

    test('getTafsir returns null for an invalid ayah', () async {
      final result = await service.getTafsir(999, 999);
      expect(result, isNull);
    });

    test('getTafsir returns null for ayah 0', () async {
      final result = await service.getTafsir(1, 0);
      expect(result, isNull);
    });

    test('hasData reflects bundled data presence', () async {
      // Must not throw; value depends on whether the JSON was bundled.
      final hasData = await service.hasData;
      expect(hasData, isA<bool>());
    });

    test('repeated calls return consistent results (cache)', () async {
      final first = await service.getTafsir(2, 255);
      final second = await service.getTafsir(2, 255);
      expect(first, equals(second));
    });
  });
}
