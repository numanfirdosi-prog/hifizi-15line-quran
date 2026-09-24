import 'package:flutter_test/flutter_test.dart';
import 'package:nur_al_quran/data/quran_data.dart';
import 'package:nur_al_quran/data/surah_aliases.dart';
import 'package:nur_al_quran/data/preset_cities.dart';
import 'package:nur_al_quran/services/prayer_calculation_service.dart';
import 'package:nur_al_quran/services/voice_search_service.dart';

void main() {
  group('1. 114 Surahs Dataset & 15-Line Mushaf Mappings', () {
    test('Should have exactly 114 Surahs with valid fields', () {
      expect(allSurahs.length, equals(114));
      for (final s in allSurahs) {
        expect(s.number, inInclusiveRange(1, 114));
        expect(s.nameEn.isNotEmpty, isTrue);
        expect(s.nameAr.isNotEmpty, isTrue);
        expect(s.nameHi.isNotEmpty, isTrue);
        expect(s.totalAyahs, greaterThan(0));
        expect(s.startPage, inInclusiveRange(1, totalPagesInMushaf));
      }
    });

    test('Al-Fatihah and Al-Baqarah start pages in 15-line Mushaf', () {
      final fatihah = allSurahs[0];
      final baqarah = allSurahs[1];
      expect(fatihah.nameEn, equals('Al-Fatihah'));
      expect(fatihah.startPage, equals(2));
      expect(baqarah.nameEn, equals('Al-Baqarah'));
      expect(baqarah.startPage, equals(3));
    });

    test('Ya-Sin start page in 15-line Mushaf', () {
      final yasin = allSurahs.firstWhere((s) => s.number == 36);
      expect(yasin.nameEn, equals('Ya-Sin'));
      expect(yasin.startPage, equals(441));
    });
  });

  group('2. Hindi & English Aliases & Search Matching', () {
    test('Should contain comprehensive Hindi aliases and search properly', () {
      final voiceService = VoiceSearchService();

      expect(surahAliasesMap.isNotEmpty, isTrue);
      expect(surahAliasesMap['यासीन'], equals(36));
      expect(surahAliasesMap['yasin'], equals(36));
      expect(surahAliasesMap['yaseen'], equals(36));
      expect(surahAliasesMap['बकरा'], equals(2));
      expect(surahAliasesMap['रहमान'], equals(55));
      expect(surahAliasesMap['मुल्क'], equals(67));
      expect(surahAliasesMap['तबारक'], equals(67));
      expect(surahAliasesMap['कहफ'], equals(18));
      expect(surahAliasesMap['अम्मा'], equals(78));
      expect(surahAliasesMap['कुल हुवल्लाह'], equals(112));
      expect(surahAliasesMap['ayatul kursi'], equals(2));
      expect(surahAliasesMap['आयतुल कुर्सी'], equals(2));

      // Voice / Text search query with prefix
      final yasinMatches = voiceService.searchSurahs('सूरह यासीन');
      expect(yasinMatches.isNotEmpty, isTrue);
      expect(yasinMatches.first.number, equals(36));

      final baqarahMatches = voiceService.searchSurahs('बकरा');
      expect(baqarahMatches.isNotEmpty, isTrue);
      expect(baqarahMatches.first.number, equals(2));

      final kursiMatches = voiceService.searchSurahs('आयतुल कुर्सी');
      expect(kursiMatches.isNotEmpty, isTrue);
      expect(kursiMatches.first.number, equals(2));
    });
  });

  group('3. Offline Mathematical Prayer Calculation', () {
    test('Calculates 5 daily prayer times without network', () {
      final delhi = presetCities.firstWhere((c) => c.name.contains('Delhi'));
      final date = DateTime(2026, 9, 24);
      final times = PrayerCalculationService.calculate(
        date: date,
        location: delhi,
        asrMode: 'Hanafi',
      );

      expect(times.fajr.toDateTime(date).isBefore(times.sunrise.toDateTime(date)), isTrue);
      expect(times.sunrise.toDateTime(date).isBefore(times.dhuhr.toDateTime(date)), isTrue);
      expect(times.dhuhr.toDateTime(date).isBefore(times.asr.toDateTime(date)), isTrue);
      expect(times.asr.toDateTime(date).isBefore(times.maghrib.toDateTime(date)), isTrue);
      expect(times.maghrib.toDateTime(date).isBefore(times.isha.toDateTime(date)), isTrue);
    });
  });

  group('4. Offline Qiblah Calculation', () {
    test('Calculates valid Qiblah bearing for Delhi', () {
      final delhi = presetCities.firstWhere((c) => c.name.contains('Delhi'));
      final qiblah = PrayerCalculationService.calculateQiblah(
        delhi.lat,
        delhi.lng,
      );

      // Delhi to Makkah is approximately 267-270 degrees (West)
      expect(qiblah.bearing, inInclusiveRange(250.0, 280.0));
      expect(qiblah.distanceKm, greaterThan(3000));
    });
  });
}
