import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/azan_alarm_service.dart';
import '../services/lock_screen_service.dart';

/// Full-screen alarm UI shown when a prayer-time azan fires.
///
/// Fully styled to match whichever of the 3 themes (Soft Green, Light Blue,
/// Royal Navy) is selected by the user.
/// Pressing the mobile's hardware lock/power switch button or tapping STOP
/// silences the alarm and dismisses this screen.
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
  Timer? _stopWatcher;

  @override
  void initState() {
    super.initState();
    // Allow showing over the system lock screen during active alarm
    LockScreenService.initialize();
    LockScreenService.setShowWhenLocked(true);

    // Hardware lock / power switch button listener
    LockScreenService.onAzanSilenced = () {
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    };

    // Poll SharedPreferences stop flag in case stopped by background receiver or notification action
    _stopWatcher = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      try {
        final sp = await SharedPreferences.getInstance();
        await sp.reload();
        if (sp.getBool(stopAzanFlag) == true) {
          timer.cancel();
          if (mounted) {
            Navigator.of(context).maybePop();
          }
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _stopWatcher?.cancel();
    LockScreenService.onAzanSilenced = null;
    LockScreenService.setShowWhenLocked(false);
    super.dispose();
  }

  Future<void> _stopAzan() async {
    if (_stopping) return;
    setState(() => _stopping = true);
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(stopAzanFlag, true);
      await AzanAlarmService().stopAzan();
    } catch (_) {}
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _stopAzan();
        }
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                cs.primary.withValues(alpha: isDark ? 0.22 : 0.08),
                cs.surface,
                cs.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Themed glowing emblem
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cs.primary,
                          width: 3.5,
                        ),
                        color: cs.primary.withValues(alpha: 0.15),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.25),
                            blurRadius: 28,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.mosque,
                        size: 60,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Prayer Name
                    Text(
                      widget.prayerName,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Arabic Subtitle
                    Text(
                      'حَيَّ عَلَى الصَّلَاةِ',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: cs.primary,
                        fontSize: 30,
                        fontFamily: 'Amiri',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Playing indicator badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.volume_up_rounded,
                            size: 18,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Azan is playing • اذان جاری ہے',
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.85),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Big Themed STOP Button
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton.icon(
                        onPressed: _stopping ? null : _stopAzan,
                        icon: const Icon(Icons.stop_circle_rounded, size: 30),
                        label: Text(
                          _stopping ? 'Stopping…' : 'STOP (اذان بند کریں)',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Hardware Power / Lock Switch hint
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.power_settings_new_rounded,
                            size: 20,
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Press mobile lock / power switch button to stop',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
