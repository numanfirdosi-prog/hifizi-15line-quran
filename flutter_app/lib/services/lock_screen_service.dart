import 'package:flutter/services.dart';

/// Controls whether the app's activity may appear over the system lock screen.
///
/// The manifest intentionally does NOT set `showWhenLocked`, so normal app
/// use never bypasses the lock screen. Only the azan alarm screen enables
/// this (via [setShowWhenLocked]) while it is visible, and disables it again
/// when dismissed.
class LockScreenService {
  static const _channel =
      MethodChannel('com.nuralquran.nur_al_quran/lock_screen');

  static Future<void> setShowWhenLocked(bool show) async {
    try {
      await _channel.invokeMethod('setShowWhenLocked', {'show': show});
    } catch (_) {
      // Non-Android platforms or old engines: ignore.
    }
  }
}
