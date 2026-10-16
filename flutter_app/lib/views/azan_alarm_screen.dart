import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/azan_alarm_service.dart';
import '../services/lock_screen_service.dart';

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

  @override
  void initState() {
    super.initState();
    // Show over the lock screen only while the alarm UI is visible.
    LockScreenService.setShowWhenLocked(true);
  }

  @override
  void dispose() {
    // Never bypass the lock screen outside the alarm UI.
    LockScreenService.setShowWhenLocked(false);
    super.dispose();
  }

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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
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
                      color: cs.primary,
                      width: 3,
                    ),
                    color: cs.primary.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    Icons.mosque,
                    size: 56,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  widget.prayerName,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'نماز کا وقت',
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 30,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Azan is playing',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 48),
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
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
