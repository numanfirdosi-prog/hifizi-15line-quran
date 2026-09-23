import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  void _showCityPickerDialog(PreferencesService prefs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F3A2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ListView.builder(
        itemCount: presetCities.length,
        itemBuilder: (ctx, idx) {
          final c = presetCities[idx];
          final isSelected = c.id == prefs.selectedCity.id;
          return ListTile(
            leading: Icon(
              isSelected ? Icons.location_on : Icons.location_city,
              color: isSelected ? const Color(0xFFD4AF37) : Colors.white60,
            ),
            title: Text(c.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('${c.country} • ${c.urdu}', style: const TextStyle(color: Colors.white54)),
            trailing: isSelected
                ? const Icon(Icons.check, color: Color(0xFFD4AF37))
                : null,
            onTap: () {
              prefs.setSelectedCity(c);
              AzanAlarmService().scheduleDailyPrayerAlarms(
                location: c,
                asrMode: prefs.asrMethod,
                enabledAlarms: prefs.prayerAlarms,
                azanSoundEnabled: prefs.azanSoundEnabled,
              );
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
    final schedule = PrayerCalculationService.calculate(
      date: _now,
      location: prefs.selectedCity,
      asrMode: prefs.asrMethod,
    );
    final nextPrayer = PrayerCalculationService.getNextPrayer(schedule, _now);

    final prayerCards = [
      {'key': 'fajr', 'name': 'Fajr', 'urdu': 'فجر', 'hi': 'फ़ज्र', 'entry': schedule.fajr, 'hasAlarm': true},
      {'key': 'sunrise', 'name': 'Sunrise', 'urdu': 'طلوع آفتاب', 'hi': 'सूर्योदय', 'entry': schedule.sunrise, 'hasAlarm': false},
      {'key': 'zawal', 'name': 'Zawal / Noon', 'urdu': 'زوال آفتاب', 'hi': 'ज़वाल', 'entry': schedule.zawal, 'hasAlarm': false},
      {'key': 'dhuhr', 'name': 'Dhuhr', 'urdu': 'ظہر', 'hi': 'ज़ुहर', 'entry': schedule.dhuhr, 'hasAlarm': true},
      {'key': 'asr', 'name': 'Asr (${prefs.asrMethod})', 'urdu': 'عصر', 'hi': 'असर', 'entry': schedule.asr, 'hasAlarm': true},
      {'key': 'sunset', 'name': 'Sunset', 'urdu': 'غروب آفتاب', 'hi': 'सूर्यास्त', 'entry': schedule.sunset, 'hasAlarm': false},
      {'key': 'maghrib', 'name': 'Maghrib', 'urdu': 'مغرب', 'hi': 'मग़रिब', 'entry': schedule.maghrib, 'hasAlarm': true},
      {'key': 'isha', 'name': 'Isha', 'urdu': 'عشاء', 'hi': 'इशा', 'entry': schedule.isha, 'hasAlarm': true},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF071F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3A2C),
        title: const Text(
          'اوقات الصلوٰۃ (Prayer Times)',
          style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.location_on, color: Color(0xFFD4AF37), size: 18),
            label: Text(
              prefs.selectedCity.name.split('/')[0].trim(),
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            onPressed: () => _showCityPickerDialog(prefs),
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
              gradient: const LinearGradient(
                colors: [Color(0xFF0F3A2C), Color(0xFF1B4D3E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
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
                          'Next: ${nextPrayer.nameEn} (${nextPrayer.nameUrdu})',
                          style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Adhan at ${nextPrayer.time.time12}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    const Icon(Icons.access_time_filled, color: Color(0xFFD4AF37), size: 36),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    _formatDuration(nextPrayer.remaining),
                    style: const TextStyle(
                      color: Colors.white,
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
              color: const Color(0xFF0F3A2C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_active, color: Color(0xFFD4AF37), size: 20),
                    const SizedBox(width: 8),
                    const Text('Lockscreen Azan Alarm', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.volume_up, size: 16),
                  label: const Text('Test Azan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    AzanAlarmService().playTestAzan();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Playing test Azan sound (locks & notifications active)...'),
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
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          urdu,
                          style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontFamily: 'serif'),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    entry.time12,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (hasAlarm)
                    Switch(
                      value: isAlarmOn,
                      activeColor: const Color(0xFFD4AF37),
                      onChanged: (val) {
                        prefs.setPrayerAlarm(key, val);
                        AzanAlarmService().scheduleDailyPrayerAlarms(
                          location: prefs.selectedCity,
                          asrMode: prefs.asrMethod,
                          enabledAlarms: prefs.prayerAlarms,
                          azanSoundEnabled: prefs.azanSoundEnabled,
                        );
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

