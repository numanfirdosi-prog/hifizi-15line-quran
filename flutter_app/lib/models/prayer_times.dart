class PrayerTimeEntry {
  final int hours24;
  final int mins;
  final int secs;
  final String time24;
  final String time12;
  final String displayTime;
  final String period;

  const PrayerTimeEntry({
    required this.hours24,
    required this.mins,
    required this.secs,
    required this.time24,
    required this.time12,
    required this.displayTime,
    required this.period,
  });

  DateTime toDateTime(DateTime forDate) {
    return DateTime(forDate.year, forDate.month, forDate.day, hours24, mins, secs);
  }
}

class PrayerSchedule {
  final PrayerTimeEntry fajr;
  final PrayerTimeEntry sunrise;
  final PrayerTimeEntry zawalStart;
  final PrayerTimeEntry zawal;
  final PrayerTimeEntry dhuhr;
  final PrayerTimeEntry asr;
  final PrayerTimeEntry sunset;
  final PrayerTimeEntry maghrib;
  final PrayerTimeEntry isha;
  final PrayerTimeEntry tahajjud;
  final PrayerTimeEntry sehriEnd;

  const PrayerSchedule({
    required this.fajr,
    required this.sunrise,
    required this.zawalStart,
    required this.zawal,
    required this.dhuhr,
    required this.asr,
    required this.sunset,
    required this.maghrib,
    required this.isha,
    required this.tahajjud,
    required this.sehriEnd,
  });

  PrayerTimeEntry? getByName(String name) {
    switch (name.toLowerCase()) {
      case 'fajr': return fajr;
      case 'sunrise': return sunrise;
      case 'dhuhr': return dhuhr;
      case 'asr': return asr;
      case 'maghrib': return maghrib;
      case 'isha': return isha;
      default: return null;
    }
  }
}

class NextPrayerInfo {
  final String nameEn;
  final String nameUrdu;
  final String nameHi;
  final PrayerTimeEntry time;
  final Duration remaining;
  final double progress; // 0.0 to 1.0

  const NextPrayerInfo({
    required this.nameEn,
    required this.nameUrdu,
    required this.nameHi,
    required this.time,
    required this.remaining,
    required this.progress,
  });
}

