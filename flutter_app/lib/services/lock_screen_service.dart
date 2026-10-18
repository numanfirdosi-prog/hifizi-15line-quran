import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Controls whether the app's activity may appear over the system lock screen
/// and receives hardware lock / power button silence events.
class LockScreenService {
  static const _channel =
      MethodChannel('com.nuralquran.nur_al_quran/lock_screen');

  static VoidCallback? onAzanSilenced;
  static bool _handlerInitialized = false;

  static void initialize() {
    if (_handlerInitialized) return;
    _handlerInitialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'azanSilenced') {
        onAzanSilenced?.call();
      }
    });
  }

  static Future<void> setShowWhenLocked(bool show) async {
    try {
      await _channel.invokeMethod('setShowWhenLocked', {'show': show});
    } catch (_) {
      // Non-Android platforms or old engines: ignore.
    }
  }
}
