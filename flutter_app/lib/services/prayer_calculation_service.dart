import 'dart:math' as math;
import '../models/city.dart';
import '../models/prayer_times.dart';

class QiblahResult {
  final double bearing;
  final int distanceKm;
  final String cardinal;

  const QiblahResult({
    required this.bearing,
    required this.distanceKm,
    required this.cardinal,
  });
}

class PrayerCalculationService {
  static const double kaabaLat = 21.422487;
  static const double kaabaLng = 39.826206;

  static const double d2r = math.pi / 180.0;
  static const double r2d = 180.0 / math.pi;

  static double sinD(double d) => math.sin(d * d2r);
  static double cosD(double d) => math.cos(d * d2r);
  static double tanD(double d) => math.tan(d * d2r);
  static double asinD(double x) => math.asin(x) * r2d;
  static double acosD(double x) => math.acos(x) * r2d;
  static double atanD(double x) => math.atan(x) * r2d;

  static double fixAngle(double a) => a - 360.0 * (a / 360.0).floor();
  static double fixHour(double h) => h - 24.0 * (h / 24.0).floor();

  static double julianDate(int year, int month, int day) {
    var y = year;
    var m = month;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (y + 4716)).floor() + (30.6001 * (m + 1)).floor() + day + b - 1524.5;
  }

  static Map<String, double> sunPosition(double jd) {
    final d = jd - 2451545.0;
    final g = fixAngle(357.529 + 0.98560028 * d);
    final q = fixAngle(280.459 + 0.98564736 * d);
    final l = fixAngle(q + 1.915 * sinD(g) + 0.020 * sinD(2 * g));
    final e = 23.439 - 0.00000036 * d;
    final dec = asinD(sinD(e) * sinD(l));
    var ra = atanD(cosD(e) * sinD(l) / cosD(l)) / 15.0;
    if (cosD(l) < 0) {
      ra += 12.0;
    } else if (sinD(l) < 0) {
      ra += 24.0;
    }
    final eqt = q / 15.0 - fixHour(ra);
    return {'declination': dec, 'equationOfTime': eqt};
  }

  static PrayerSchedule calculate({
    required DateTime date,
    required City location,
    String asrMode = 'Hanafi',
  }) {
    final lat = location.lat;
    final lng = location.lng;
    final tz = location.tz;

    final jd = julianDate(date.year, date.month, date.day);
    final sun = sunPosition(jd);
    final d = sun['declination']!;
    final eqt = sun['equationOfTime']!;

    // Solar noon (Zawal / Nisf-un-Nahar)
    final noon = fixHour(12.0 + tz - (lng / 15.0) - eqt);

    double? hourAngle(double alpha) {
      final cosHa = (sinD(alpha) - sinD(lat) * sinD(d)) / (cosD(lat) * cosD(d));
      if (cosHa > 1.0 || cosHa < -1.0) return null;
      return acosD(cosHa) / 15.0;
    }

    // Sunrise & Sunset: -0.8333 degrees
    final haSun = hourAngle(-0.8333);
    final sunrise = haSun != null ? noon - haSun : noon - 6.0;
    final sunset = haSun != null ? noon + haSun : noon + 6.0;

    // Fajr (18 degrees, Karachi Standard)
    final haFajr = hourAngle(-18.0);
    final fajr = haFajr != null ? noon - haFajr : sunrise - 1.5;

    // Isha (18 degrees)
    final haIsha = hourAngle(-18.0);
    final isha = haIsha != null ? noon + haIsha : sunset + 1.5;

    // Asr (Hanafi: shadow factor 2, Standard: shadow factor 1)
    final shadowFactor = asrMode == 'Hanafi' ? 2.0 : 1.0;
    final asrAngle = atanD(1.0 / (shadowFactor + tanD((lat - d).abs())));
    final haAsr = hourAngle(asrAngle);
    final asr = haAsr != null ? noon + haAsr : noon + 3.5;

    final zawalStart = noon - (12.0 / 60.0);
    final zawalEnd = noon;
    final nightDuration = fixHour(fajr + 24.0 - sunset);
    final tahajjud = fixHour(sunset + (nightDuration * 2.0 / 3.0));
    final sehriEnd = fajr - (10.0 / 60.0);

    return PrayerSchedule(
      fajr: floatToTime(fajr),
      sunrise: floatToTime(sunrise),
      zawalStart: floatToTime(zawalStart),
      zawal: floatToTime(zawalEnd),
      dhuhr: floatToTime(noon + (2.0 / 60.0)),
      asr: floatToTime(asr),
      sunset: floatToTime(sunset),
      maghrib: floatToTime(sunset + (2.0 / 60.0)),
      isha: floatToTime(isha),
      tahajjud: floatToTime(tahajjud),
      sehriEnd: floatToTime(sehriEnd),
    );
  }

  static PrayerTimeEntry floatToTime(double h) {
    final fixedH = fixHour(h);
    final hours24 = fixedH.floor();
    final mins = ((fixedH - hours24) * 60.0).floor();
    final secs = ((((fixedH - hours24) * 60.0) - mins) * 60.0).floor();

    final period = hours24 >= 12 ? 'PM' : 'AM';
    var hours12 = hours24 % 12;
    if (hours12 == 0) hours12 = 12;

    final padH = hours24.toString().padLeft(2, '0');
    final padM = mins.toString().padLeft(2, '0');
    final padH12 = hours12.toString().padLeft(2, '0');

    return PrayerTimeEntry(
      hours24: hours24,
      mins: mins,
      secs: secs,
      time24: '$padH:$padM',
      time12: '$padH12:$padM $period',
      displayTime: '$padH12:$padM',
      period: period,
    );
  }

  static QiblahResult calculateQiblah(double userLat, double userLng) {
    final phi1 = userLat * d2r;
    final phi2 = kaabaLat * d2r;
    final deltaLambda = (kaabaLng - userLng) * d2r;

    final y = math.sin(deltaLambda);
    final x = math.cos(phi1) * math.tan(phi2) - math.sin(phi1) * math.cos(deltaLambda);

    var qiblahAngle = math.atan2(y, x) * r2d;
    qiblahAngle = (qiblahAngle + 360.0) % 360.0;

    // Haversine distance
    const r = 6371.0;
    final dLat = (kaabaLat - userLat) * d2r;
    final dLng = (kaabaLng - userLng) * d2r;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(phi1) * math.cos(phi2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a));
    final distanceKm = (r * c).round();

    const cardinals = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    final cardIdx = (qiblahAngle / 22.5).round() % 16;

    return QiblahResult(
      bearing: ((qiblahAngle * 10).round()) / 10.0,
      distanceKm: distanceKm,
      cardinal: cardinals[cardIdx],
    );
  }

  static NextPrayerInfo getNextPrayer(PrayerSchedule schedule, DateTime now) {
    final times = [
      {'nameEn': 'Fajr', 'nameUrdu': 'فجر', 'nameHi': 'फ़ज्र', 'entry': schedule.fajr},
      {'nameEn': 'Sunrise', 'nameUrdu': 'طلوع آفتاب', 'nameHi': 'सूर्योदय', 'entry': schedule.sunrise},
      {'nameEn': 'Dhuhr', 'nameUrdu': 'ظہر', 'nameHi': 'ज़ुहर', 'entry': schedule.dhuhr},
      {'nameEn': 'Asr', 'nameUrdu': 'عصر', 'nameHi': 'असर', 'entry': schedule.asr},
      {'nameEn': 'Maghrib', 'nameUrdu': 'مغرب', 'nameHi': 'मग़रिब', 'entry': schedule.maghrib},
      {'nameEn': 'Isha', 'nameUrdu': 'عشاء', 'nameHi': 'इशा', 'entry': schedule.isha},
    ];

    for (final t in times) {
      final entry = t['entry'] as PrayerTimeEntry;
      final dt = entry.toDateTime(now);
      if (dt.isAfter(now)) {
        final diff = dt.difference(now);
        return NextPrayerInfo(
          nameEn: t['nameEn'] as String,
          nameUrdu: t['nameUrdu'] as String,
          nameHi: t['nameHi'] as String,
          time: entry,
          remaining: diff,
          progress: 0.5,
        );
      }
    }

    // Next is tomorrow's Fajr
    final tomorrowFajr = schedule.fajr.toDateTime(now.add(const Duration(days: 1)));
    final diff = tomorrowFajr.difference(now);
    return NextPrayerInfo(
      nameEn: 'Fajr (Tomorrow)',
      nameUrdu: 'فجر (کل)',
      nameHi: 'फ़ज्र (कल)',
      time: schedule.fajr,
      remaining: diff,
      progress: 0.5,
    );
  }
}
