import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'preferences_service.dart';

/// Weekly local auto-backup, reusing the android_alarm_manager_plus pattern
/// from the azan alarms. Writes the standard backup JSON
/// ([PreferencesService.exportJson]) to the app documents directory —
/// fully offline, no network. Never throws.
class AutoBackupService {
  /// Distinct alarm id (must not collide with azan alarm ids).
  static const int alarmId = 0xBA6C0; // 763072
  static const String fileName = 'nur_al_quran_auto_backup.json';

  /// Whether the weekly scheduler can actually run on this platform.
  /// AndroidAlarmManager is Android-only — the Backup & Restore screen
  /// should gate/disable its auto-backup toggle on `!isSupported` instead
  /// of showing a fake ON.
  static bool get isSupported => Platform.isAndroid;

  /// Schedules the next weekly backup from now.
  static Future<void> scheduleWeekly() async {
    // iOS path: AndroidAlarmManager does not exist here, so do not
    // pretend to schedule (no-op instead of a fake toggle-ON state).
    if (!Platform.isAndroid) return;
    try {
      final next = DateTime.now().add(const Duration(days: 7));
      // BUG3 FIX: exact:false — with exact:true, Android 12+ throws
      // SecurityException when SCHEDULE_EXACT_ALARM was denied, so the
      // toggle showed ON but zero backups ever ran.
      await AndroidAlarmManager.oneShotAt(
        next,
        alarmId,
        autoBackupAlarmCallback,
        exact: false,
        wakeup: true,
        rescheduleOnReboot: true,
      );
      debugPrint('[AutoBackup] scheduled for ${next.toIso8601String()}');
    } catch (e) {
      debugPrint('[AutoBackup] schedule failed: $e');
    }
  }

  static Future<void> cancel() async {
    // iOS path: nothing was ever scheduled, nothing to cancel.
    if (!Platform.isAndroid) return;
    try {
      await AndroidAlarmManager.cancel(alarmId);
    } catch (e) {
      debugPrint('[AutoBackup] cancel failed: $e');
    }
  }

  /// Performs the backup immediately (used by the Backup screen).
  /// Returns true on success.
  static Future<bool> runNow() async {
    try {
      final prefs = PreferencesService();
      await prefs.init();
      final json = prefs.exportJson();
      final dir = await getApplicationDocumentsDirectory();
      await File('${dir.path}/$fileName').writeAsString(json);
      await prefs.setLastAutoBackup(DateTime.now().toIso8601String());
      return true;
    } catch (e) {
      debugPrint('[AutoBackup] runNow failed: $e');
      return false;
    }
  }
}

/// Alarm-manager entry point: writes the backup, stamps the time, and
/// chains the next weekly run.
@pragma('vm:entry-point')
Future<void> autoBackupAlarmCallback() async {
  try {
    final ok = await AutoBackupService.runNow();
    if (ok) await AutoBackupService.scheduleWeekly();
  } catch (e) {
    debugPrint('[AutoBackup] alarm callback failed: $e');
  }
}
