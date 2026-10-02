import 'package:flutter_test/flutter_test.dart';
import 'package:nur_al_quran/data/ayah_layout.dart';
import 'package:nur_al_quran/data/juz_data.dart';
import 'package:nur_al_quran/data/quran_data.dart';
import 'package:nur_al_quran/data/surah_intros.dart';
import 'package:nur_al_quran/models/city.dart';
import 'package:nur_al_quran/services/prayer_calculation_service.dart';

const _testCity = City(
  id: 'test-delhi',
  name: 'Delhi',
  urdu: 'دہلی',
  country: 'India',
  lat: 28.6139,
  lng: 77.2090,
  tz: 5.5,
  ianaTz: 'Asia/Kolkata',
);

void main() {
  group('Khatm Planner day ranges', () {
    test('day 1 = Juz 1 pages', () {
      final (start, end) = khatmDayPages(1);
      expect(start, 2);
      expect(end, 22); // juz 2 starts at page 23
    });

    test('day 30 ends at the last mushaf page', () {
      final (start, end) = khatmDayPages(30);
      expect(start, 587);
      expect(end, totalPagesInMushaf);
      expect(end, 611);
    });

    test('consecutive days are contiguous', () {
      for (var d = 1; d < 30; d++) {
        final (_, end) = khatmDayPages(d);
        final (nextStart, _) = khatmDayPages(d + 1);
        expect(nextStart, end + 1, reason: 'day $d -> ${d + 1}');
      }
    });
  });

  group('Asr juristic method', () {
    test('Hanafi asr is later than Shafii asr', () {
      final date = DateTime(2026, 10, 2);
      final hanafi = PrayerCalculationService.calculate(
        date: date,
        location: _testCity,
        asrMode: 'Hanafi',
      );
      final shafii = PrayerCalculationService.calculate(
        date: date,
        location: _testCity,
        asrMode: 'Shafii',
      );
      int mins(String t) {
        final p = t.split(':');
        return int.parse(p[0]) * 60 + int.parse(p[1]);
      }
      final h = mins(hanafi.asr.time24);
      final s = mins(shafii.asr.time24);
      expect(h, greaterThan(s),
          reason: 'Hanafi (shadow x2) must be later than Shafii (shadow x1)');
      // Sanity: roughly 30-60 min apart in Delhi in October.
      expect(h - s, inInclusiveRange(20, 90));
    });
  });

  group('Audio Studio filters', () {
    test("Juz 'Amma (78-114) = 37 surahs", () {
      final list = allSurahs.where((s) => s.number >= 78).toList();
      expect(list.length, 37);
      expect(list.first.number, 78);
      expect(list.last.number, 114);
    });

    test('Makki + Madani = 114', () {
      final makki = allSurahs.where((s) => s.isMeccan).length;
      final madani = allSurahs.where((s) => !s.isMeccan).length;
      expect(makki + madani, 114);
      expect(makki, 86);
      expect(madani, 28);
    });
  });

  group('Surah intros', () {
    test('exactly 114 entries, all non-empty', () {
      expect(surahIntros.length, 114);
      for (var i = 1; i <= 114; i++) {
        expect(surahIntros.containsKey(i), isTrue, reason: 'surah $i');
        expect(surahIntros[i]!.trim().isNotEmpty, isTrue,
            reason: 'surah $i empty');
      }
    });

    test('intros mention revelation context', () {
      // Spot-check a few well-known facts.
      expect(surahIntros[1]!.contains('seven verses'), isTrue);
      expect(surahIntros[2]!.contains('longest'), isTrue);
      expect(surahIntros[96]!.contains('first revelation'), isTrue);
      expect(surahIntros[112]!.contains('one-third'), isTrue);
    });
  });

  group('Ayah pills (distinctAyahs)', () {
    test('dedupes segments to one entry per ayah, in order', () {
      const segs = [
        AyahSeg(surah: 2, ayah: 255, line: 2, right: 70, width: 30),
        AyahSeg(surah: 2, ayah: 255, line: 3, right: 0, width: 100),
        AyahSeg(surah: 2, ayah: 256, line: 4, right: 10, width: 50),
      ];
      final distinct = distinctAyahs(segs);
      expect(distinct.length, 2);
      expect(distinct[0].ayah, 255);
      expect(distinct[1].ayah, 256);
    });

    test('sample page 2 has Al-Fatihah ayahs', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final map = await loadPageAyahSegments();
      final distinct = distinctAyahs(map[2]!);
      expect(distinct, isNotEmpty);
      expect(distinct.first.surah, 1);
      expect(distinct.first.ayah, 1);
      // No duplicate verseKeys.
      final keys = distinct.map((s) => '${s.surah}:${s.ayah}').toSet();
      expect(keys.length, distinct.length);
    });
  });
}
