import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/azan_alarm_service.dart';

/// Full-screen alarm UI shown when a prayer-time azan fires.
///
/// Opened automatically on the lock screen via the notification's
/// full-screen intent, or when the user taps the azan notification.
/// The big Stop button signals the background audio isolate to stop
/// (via the `nur_azan_stop` SharedPreferences flag) and closes this screen.
class AzanAlarmScreen extends StatefulWidget {
  final String prayerName;
  final int alarmId;

  const AzanAlarmScreen({
    super.key,
    required this.prayerName,
    required this.alarmId,
  });

  @override
  State<AzanAlarmScreen> createState() => _AzanAlarmScreenState();
}

class _AzanAlarmScreenState extends State<AzanAlarmScreen> {
  bool _stopping = false;

  Future<void> _stopAzan() async {
    if (_stopping) return;
    setState(() => _stopping = true);
    try {
      // Signal the background isolate (which owns the AudioPlayer) to stop.
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(stopAzanFlag, true);
      // Also stop any in-app test playback, just in case.
      await AzanAlarmService().stopAzan();
    } catch (_) {}
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1F17),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD4AF37),
                      width: 3,
                    ),
                    color: const Color(0xFF143527),
                  ),
                  child: const Icon(
                    Icons.mosque,
                    size: 56,
                    color: Color(0xFFD4AF37),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  widget.prayerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'نماز کا وقت',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 30,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Azan is playing',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 56),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton.icon(
                    onPressed: _stopping ? null : _stopAzan,
                    icon: const Icon(Icons.stop, size: 28),
                    label: Text(
                      _stopping ? 'Stopping…' : 'STOP',
                      style: const TextStyle(fontSize: 22),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
