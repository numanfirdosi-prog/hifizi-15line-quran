import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/preset_cities.dart';
import '../models/city.dart';
import '../models/prayer_times.dart';
import '../services/prayer_calculation_service.dart';
import '../services/preferences_service.dart';
import '../services/azan_alarm_service.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({Key? key}) : super(key: key);

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  // N4: cache the astronomical schedule — it only changes when the day, the
  // city or the Asr method changes. Recomputing it every second is wasteful.
  PrayerSchedule? _cachedSchedule;
  DateTime? _cachedDay;
  String? _cachedCityId;
  String? _cachedAsrMethod;
  double? _cachedTzOffset;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  PrayerSchedule _scheduleFor(PreferencesService prefs) {
    var city = prefs.selectedCity;
    final day = PrayerCalculationService.cityToday(city);
    // GPS cities have no IANA zone: the stored offset was captured when GPS
    // was picked and goes stale across DST transitions (times off by 1h
    // until GPS is re-picked). Recompute the device timezone's DST-aware
    // offset for the displayed day before calculating. Noon avoids edge
    // cases on DST transition days.
    var tzOffset = city.tz;
    if (city.ianaTz == null) {
      tzOffset =
          DateTime(day.year, day.month, day.day, 12).timeZoneOffset.inMinutes /
              60.0;
      city = City(
        id: city.id,
        name: city.name,
        urdu: city.urdu,
        country: city.country,
        lat: city.lat,
        lng: city.lng,
        tz: tzOffset,
        ianaTz: null,
      );
    }
    final cityId = city.id;
    final asrMethod = prefs.asrMethod;
    if (_cachedSchedule == null ||
        _cachedDay != day ||
        _cachedCityId != cityId ||
        _cachedAsrMethod != asrMethod ||
        _cachedTzOffset != tzOffset) {
      _cachedSchedule = PrayerCalculationService.calculate(
        date: day,
        location: city,
        asrMode: asrMethod,
      );
      _cachedDay = day;
      _cachedCityId = cityId;
      _cachedAsrMethod = asrMethod;
      _cachedTzOffset = tzOffset;
    }
    return _cachedSchedule!;
  }

  Future<void> _rescheduleAlarms(PreferencesService prefs) {
    return AzanAlarmService().scheduleDailyPrayerAlarms(
      location: prefs.selectedCity,
      asrMode: prefs.asrMethod,
      enabledAlarms: prefs.prayerAlarms,
      azanSoundEnabled: prefs.azanSoundEnabled,
      lockscreenAlarmEnabled: prefs.lockscreenAlarmEnabled,
    );
  }

  /// M4: Use the device's live GPS position instead of a city preset.
  Future<void> _useGpsLocation(
      PreferencesService prefs, BuildContext sheetCtx) async {
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please turn on Location Services (GPS) first.')),
      );
      return;
    }

    var status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      status = await Permission.locationWhenInUse.request();
    }
    if (!status.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Location permission denied — cannot use GPS.')),
      );
      return;
    }

    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Getting GPS location…'),
            duration: Duration(seconds: 2)),
      );
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      ).timeout(const Duration(seconds: 20));
      final deviceOffset = DateTime.now().timeZoneOffset.inMinutes / 60.0;
      final gpsCity = City(
        id: 'gps',
        name: 'GPS Location',
        urdu: 'موجودہ مقام',
        country: 'Device GPS',
        lat: pos.latitude,
        lng: pos.longitude,
        tz: deviceOffset,
        ianaTz: null, // falls back to the device's current UTC offset
      );
      await prefs.setSelectedCity(gpsCity);
      // Drop the cached schedule so it recomputes for the new coordinates.
      _cachedCityId = null;
      await _rescheduleAlarms(prefs);
      if (mounted) {
        Navigator.pop(sheetCtx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'GPS set: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get GPS location: $e')),
      );
    }
  }

  void _showCityPickerDialog(PreferencesService prefs) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ListView.builder(
        // +1 for the "Use Device GPS" header row (M4)
        itemCount: presetCities.length + 1,
        itemBuilder: (ctx2, idx) {
          if (idx == 0) {
            // M4: live GPS option on top of the preset list
            final isGps = prefs.selectedCity.id == 'gps';
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.my_location, color: cs.primary),
                  title: Text(
                      prefs.isUrdu
                          ? 'ڈیوائس GPS استعمال کریں (لائیو لوکیشن)'
                          : 'Use Device GPS (Live Location)',
                      style: TextStyle(
                          color: cs.onSurface, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      prefs.isUrdu
                          ? 'سب سے درست قبلہ اور نماز کے اوقات'
                          : 'Most accurate Qiblah & prayer times',
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.54))),
                  trailing: isGps
                      ? Icon(Icons.check, color: cs.primary)
                      : null,
                  onTap: () => _useGpsLocation(prefs, ctx),
                ),
                Divider(
                    color: cs.onSurface.withValues(alpha: 0.12), height: 1),
              ],
            );
          }
          final c = presetCities[idx - 1];
          final isSelected = c.id == prefs.selectedCity.id;
          return ListTile(
            leading: Icon(
              isSelected ? Icons.location_on : Icons.location_city,
              color: isSelected
                  ? cs.primary
                  : cs.onSurface.withValues(alpha: 0.6),
            ),
            title: Text(c.name,
                style: TextStyle(
                    color: cs.onSurface, fontWeight: FontWeight.bold)),
            subtitle: Text('${c.country} • ${c.urdu}',
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.54))),
            trailing: isSelected
                ? Icon(Icons.check, color: cs.primary)
                : null,
            onTap: () {
              prefs.setSelectedCity(c);
              _cachedCityId = null;
              _rescheduleAlarms(prefs);
              Navigator.pop(ctx);
            },
          );
        },
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final prefs = Provider.of<PreferencesService>(context);
    final cs = Theme.of(context).colorScheme;
    final schedule = _scheduleFor(prefs);
    final nextPrayer = PrayerCalculationService.getNextPrayer(
        schedule, _now, prefs.selectedCity);

    final prayerCards = [
      {
        'key': 'fajr',
        'name': 'Fajr',
        'urdu': 'فجر',
        'hi': 'फ़ज्र',
        'entry': schedule.fajr,
        'hasAlarm': true
      },
      {
        'key': 'sunrise',
        'name': 'Sunrise',
        'urdu': 'طلوع آفتاب',
        'hi': 'सूर्योदय',
        'entry': schedule.sunrise,
        'hasAlarm': false
      },
      {
        'key': 'zawal',
        'name': 'Zawal / Noon',
        'urdu': 'زوال آفتاب',
        'hi': 'ज़वाल',
        'entry': schedule.zawal,
        'hasAlarm': false
      },
      {
        'key': 'dhuhr',
        'name': 'Dhuhr',
        'urdu': 'ظہر',
        'hi': 'ज़ुहर',
        'entry': schedule.dhuhr,
        'hasAlarm': true
      },
      {
        'key': 'asr',
        'name': 'Asr (${prefs.asrMethod})',
        'urdu': 'عصر',
        'hi': 'असर',
        'entry': schedule.asr,
        'hasAlarm': true
      },
      {
        'key': 'sunset',
        'name': 'Sunset',
        'urdu': 'غروب آفتاب',
        'hi': 'सूर्यास्त',
        'entry': schedule.sunset,
        'hasAlarm': false
      },
      {
        'key': 'maghrib',
        'name': 'Maghrib',
        'urdu': 'مغرب',
        'hi': 'मग़रिब',
        'entry': schedule.maghrib,
        'hasAlarm': true
      },
      {
        'key': 'isha',
        'name': 'Isha',
        'urdu': 'عشاء',
        'hi': 'इशा',
        'entry': schedule.isha,
        'hasAlarm': true
      },
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'اوقات الصلوٰۃ (Prayer Times)',
          style: TextStyle(
              color: cs.primary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Tooltip(
            message: prefs.isUrdu ? 'شہر بدلیں' : 'Change city',
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: cs.primary.withValues(alpha: 0.4)),
              ),
              child: TextButton.icon(
                icon: Icon(Icons.location_on, color: cs.primary, size: 18),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      prefs.selectedCity.name.split('/')[0].trim(),
                      style: TextStyle(color: cs.onSurface, fontSize: 13),
                    ),
                    Icon(Icons.arrow_drop_down,
                        color: cs.primary, size: 18),
                  ],
                ),
                onPressed: () => _showCityPickerDialog(prefs),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Next Prayer Live Countdown Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.surface, cs.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: cs.primary.withValues(alpha: 0.5), width: 1.5),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prefs.isUrdu
                              ? 'اگلی نماز: ${nextPrayer.nameUrdu}'
                              : 'Next: ${nextPrayer.nameEn}',
                          style: TextStyle(
                              color: cs.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prefs.isUrdu
                              ? 'اذان کا وقت ${nextPrayer.time.time12}'
                              : 'Adhan at ${nextPrayer.time.time12}',
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.7),
                              fontSize: 13),
                        ),
                      ],
                    ),
                    Icon(Icons.access_time_filled,
                        color: cs.primary, size: 36),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    _formatDuration(nextPrayer.remaining),
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Test Azan & Sound Toggle Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications_active,
                        color: cs.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                        prefs.isUrdu
                            ? 'لاک اسکرین اذان الارم'
                            : 'Lockscreen Azan Alarm',
                        style: TextStyle(color: cs.onSurface, fontSize: 13)),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.volume_up, size: 16),
                  label: Text(
                      prefs.isUrdu ? 'اذان سن کر دیکھیں' : 'Test Azan',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    AzanAlarmService().playTestAzan();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(prefs.isUrdu
                            ? 'ٹیسٹ اذان چل رہی ہے…'
                            : 'Playing test Azan sound...'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Daily Prayer Timings Table
          ...prayerCards.map((p) {
            final key = p['key'] as String;
            final name = p['name'] as String;
            final urdu = p['urdu'] as String;
            final entry = p['entry'] as PrayerTimeEntry;
            final hasAlarm = p['hasAlarm'] as bool;
            final isAlarmOn = prefs.prayerAlarms[key] == true;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B2D22),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                              color: Color(0xFFFFF8E7),
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                        Text(
                          urdu,
                          style: const TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 12,
                              fontFamily: 'serif'),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    entry.time12,
                    style: const TextStyle(
                      color: Color(0xFFFFF8E7),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (hasAlarm)
                    Switch(
                      value: isAlarmOn,
                      activeColor: cs.primary,
                      onChanged: (val) {
                        prefs.setPrayerAlarm(key, val);
                        _rescheduleAlarms(prefs);
                      },
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
