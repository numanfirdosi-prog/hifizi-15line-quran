import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:nur_al_quran/models/city.dart';
import 'package:nur_al_quran/models/prayer_times.dart';
import 'package:nur_al_quran/services/prayer_calculation_service.dart';

/// DST / timezone-awareness tests for the prayer engine.
///
/// Prayer times are wall-clock times *in the selected city*. When the device
/// timezone differs from the city timezone (or the city observes daylight
/// saving), a naive fixed-offset conversion schedules alarms and countdowns
/// at the wrong absolute instant. These tests pin the DST behaviour.
void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
  });

  const london = City(
    id: 'london',
    name: 'London',
    urdu: 'لندن',
    country: 'UK',
    lat: 51.5074,
    lng: -0.1278,
    tz: 0,
    ianaTz: 'Europe/London',
  );
  const newYork = City(
    id: 'new_york',
    name: 'New York',
    urdu: 'نیو یارک',
    country: 'USA',
    lat: 40.7128,
    lng: -74.0060,
    tz: -5,
    ianaTz: 'America/New_York',
  );
  const gpsCity = City(
    id: 'gps',
    name: 'GPS Location',
    urdu: 'جی پی ایس',
    country: '',
    lat: 28.6,
    lng: 77.2,
    tz: 5.5,
    ianaTz: null,
  );

  group('effectiveTzOffset honours DST', () {
    test('London is UTC+0 in January, UTC+1 in July', () {
      expect(
        PrayerCalculationService.effectiveTzOffset(
            london, DateTime(2026, 1, 15)),
        0.0,
      );
      expect(
        PrayerCalculationService.effectiveTzOffset(
            london, DateTime(2026, 7, 15)),
        1.0,
      );
    });

    test('New York is UTC-5 in January, UTC-4 in July', () {
      expect(
        PrayerCalculationService.effectiveTzOffset(
            newYork, DateTime(2026, 1, 15)),
        -5.0,
      );
      expect(
        PrayerCalculationService.effectiveTzOffset(
            newYork, DateTime(2026, 7, 15)),
        -4.0,
      );
    });

    test('GPS city without IANA zone falls back to fixed offset', () {
      expect(
        PrayerCalculationService.effectiveTzOffset(
            gpsCity, DateTime(2026, 7, 15)),
        5.5,
      );
    });
  });

  group('cityWallTimeToAbsolute converts wall-clock correctly', () {
    const noon = PrayerTimeEntry(
      hours24: 12,
      mins: 0,
      secs: 0,
      time24: '12:00',
      time12: '12:00 PM',
      displayTime: '12:00',
      period: 'PM',
    );

    test('London noon wall-clock maps to the right UTC instant', () {
      // January (GMT): 12:00 London == 12:00 UTC.
      final jan = PrayerCalculationService.cityWallTimeToAbsolute(
          london, noon, DateTime(2026, 1, 15));
      expect(jan.toUtc(), DateTime.utc(2026, 1, 15, 12, 0));

      // July (BST): 12:00 London == 11:00 UTC.
      final jul = PrayerCalculationService.cityWallTimeToAbsolute(
          london, noon, DateTime(2026, 7, 15));
      expect(jul.toUtc(), DateTime.utc(2026, 7, 15, 11, 0));
    });

    test('New York noon wall-clock maps to the right UTC instant', () {
      // January (EST, UTC-5): 12:00 NY == 17:00 UTC.
      final jan = PrayerCalculationService.cityWallTimeToAbsolute(
          newYork, noon, DateTime(2026, 1, 15));
      expect(jan.toUtc(), DateTime.utc(2026, 1, 15, 17, 0));

      // July (EDT, UTC-4): 12:00 NY == 16:00 UTC.
      final jul = PrayerCalculationService.cityWallTimeToAbsolute(
          newYork, noon, DateTime(2026, 7, 15));
      expect(jul.toUtc(), DateTime.utc(2026, 7, 15, 16, 0));
    });
  });

  group('next-prayer countdown is location-aware', () {
    test('getNextPrayer returns progress between 0 and 1', () {
      final schedule = PrayerCalculationService.calculate(
        date: DateTime(2026, 7, 15),
        location: london,
      );
      final now = DateTime(2026, 7, 15, 10, 0);
      final next = PrayerCalculationService.getNextPrayer(
        schedule,
        now,
        london,
      );
      expect(next.progress, greaterThanOrEqualTo(0.0));
      expect(next.progress, lessThanOrEqualTo(1.0));
      expect(next.nameEn.isNotEmpty, isTrue);
    });
  });
}
