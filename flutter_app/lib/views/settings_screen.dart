import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/preferences_service.dart';
import '../services/azan_alarm_service.dart';

class SettingsScreen extends StatelessWidget {
  final Function(int page) onOpenPage;
  const SettingsScreen({Key? key, required this.onOpenPage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final prefs = Provider.of<PreferencesService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF071F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3A2C),
        title: const Text(
          'تنظیمات (Settings & Bookmarks)',
          style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Juristic Method Card
          Card(
            color: const Color(0xFF0F3A2C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Asr Juristic Method / عصر کا طریقہ',
                    style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<String>(
                    title: const Text('Hanafi / حنفی (Double shadow factor)', style: TextStyle(color: Colors.white, fontSize: 14)),
                    value: 'Hanafi',
                    groupValue: prefs.asrMethod,
                    activeColor: const Color(0xFFD4AF37),
                    onChanged: (val) {
                      if (val != null) {
                        prefs.setAsrMethod(val);
                        AzanAlarmService().scheduleDailyPrayerAlarms(
                          location: prefs.selectedCity,
                          asrMode: val,
                          enabledAlarms: prefs.prayerAlarms,
                          azanSoundEnabled: prefs.azanSoundEnabled,
                        );
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Shafi\'i / Maliki / Hanbali / شافعی (Single shadow)', style: TextStyle(color: Colors.white, fontSize: 14)),
                    value: 'Standard',
                    groupValue: prefs.asrMethod,
                    activeColor: const Color(0xFFD4AF37),
                    onChanged: (val) {
                      if (val != null) {
                        prefs.setAsrMethod(val);
                        AzanAlarmService().scheduleDailyPrayerAlarms(
                          location: prefs.selectedCity,
                          asrMode: val,
                          enabledAlarms: prefs.prayerAlarms,
                          azanSoundEnabled: prefs.azanSoundEnabled,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Alarm & Azan Sound Switches
          Card(
            color: const Color(0xFF0F3A2C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Play Azan Sound', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Play full Azan audio when prayer time starts', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  value: prefs.azanSoundEnabled,
                  activeColor: const Color(0xFFD4AF37),
                  onChanged: (val) => prefs.setAzanSoundEnabled(val),
                ),
                const Divider(color: Colors.white12, height: 1),
                SwitchListTile(
                  title: const Text('Lockscreen Exact Alarm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Wake up locked phone & display prayer alarm', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  value: prefs.lockscreenAlarmEnabled,
                  activeColor: const Color(0xFFD4AF37),
                  onChanged: (val) => prefs.setLockscreenAlarmEnabled(val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Bookmarks Section
          Card(
            color: const Color(0xFF0F3A2C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'علامات / محفوظ شدہ صفحات (Bookmarks)',
                        style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text('${prefs.bookmarks.length} saved', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (prefs.bookmarks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No bookmarked pages yet. Tap the bookmark icon on any Mushaf page.', style: TextStyle(color: Colors.white60, fontSize: 13)),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: prefs.bookmarks.map((p) {
                        return ActionChip(
                          backgroundColor: const Color(0xFF144234),
                          avatar: const Icon(Icons.bookmark, color: Color(0xFFD4AF37), size: 16),
                          label: Text('Page $p', style: const TextStyle(color: Colors.white)),
                          onPressed: () => onOpenPage(p),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // About App
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0B2D22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'About Nur-ul-Quran (نور القرآن)',
                  style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 6),
                Text(
                  '15-Line South Asian / Indo-Pak Hifzi Mushaf (القرآن الكريم). 100% offline, exact astronomical prayer times with lockscreen Azan, Kaaba Qiblah compass, and multi-language voice search.',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
                SizedBox(height: 6),
                Text(
                  'Version 1.0.0 (Flutter Standalone Edition)',
                  style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

