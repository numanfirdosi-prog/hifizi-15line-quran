import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:just_audio/just_audio.dart';
import '../models/prayer_times.dart';
import '../models/city.dart';
import 'prayer_calculation_service.dart';

// Background alarm callback entrypoint (must be top-level static)
@pragma('vm:entry-point')
void azanAlarmCallback(int id) async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[AzanAlarm] Background alarm triggered with ID: $id');

  final player = AudioPlayer();
  try {
    // Play Azan audio alert
    try {
      await player.setAsset('assets/audio/azan.mp3');
    } catch (_) {
      await player.setAsset('assets/audio/silence.wav');
    }
    await player.play();
  } catch (e) {
    debugPrint('[AzanAlarm] Error playing audio in background: $e');
  }
}

class AzanAlarmService {
  static final AzanAlarmService _instance = AzanAlarmService._internal();
  factory AzanAlarmService() => _instance;
  AzanAlarmService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // 1. Android Alarm Manager (for exact lockscreen alarms)
    if (Platform.isAndroid) {
      await AndroidAlarmManager.initialize();
    }

    // 2. Notification Plugin Setup
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('[Notification] Tapped on azan notification: ${details.payload}');
      },
    );

    // Create high-priority Azan notification channel on Android
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'azan_alarm_channel',
        'Azan Prayers & Alarms',
        description: 'Plays Azan sound on prayer time even when phone is locked',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.createNotificationChannel(channel);
    }

    _initialized = true;
  }

  Future<void> scheduleDailyPrayerAlarms({
    required City location,
    required String asrMode,
    required Map<String, bool> enabledAlarms,
    required bool azanSoundEnabled,
  }) async {
    if (!_initialized) await init();

    final now = DateTime.now();
    final schedule = PrayerCalculationService.calculate(
      date: now,
      location: location,
      asrMode: asrMode,
    );

    final prayers = [
      {'id': 101, 'key': 'fajr', 'name': 'Fajr', 'time': schedule.fajr},
      {'id': 102, 'key': 'dhuhr', 'name': 'Dhuhr', 'time': schedule.dhuhr},
      {'id': 103, 'key': 'asr', 'name': 'Asr', 'time': schedule.asr},
      {'id': 104, 'key': 'maghrib', 'name': 'Maghrib', 'time': schedule.maghrib},
      {'id': 105, 'key': 'isha', 'name': 'Isha', 'time': schedule.isha},
    ];

    for (final p in prayers) {
      final key = p['key'] as String;
      final alarmId = p['id'] as int;
      final name = p['name'] as String;
      final entry = p['time'] as PrayerTimeEntry;

      if (enabledAlarms[key] != true) {
        if (Platform.isAndroid) {
          await AndroidAlarmManager.cancel(alarmId);
        }
        await _notificationsPlugin.cancel(alarmId);
        continue;
      }

      var prayerTime = entry.toDateTime(now);
      if (prayerTime.isBefore(now)) {
        prayerTime = prayerTime.add(const Duration(days: 1));
      }

      if (Platform.isAndroid) {
        await AndroidAlarmManager.oneShotAt(
          prayerTime,
          alarmId,
          azanAlarmCallback,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
        );
      }

      debugPrint('[AzanAlarm] Scheduled $name at ${prayerTime.toIso8601String()}');
    }
  }

  Future<void> playTestAzan() async {
    try {
      await _audioPlayer.setAsset('assets/audio/silence.wav');
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('[AzanAlarm] Test azan error: $e');
    }
  }

  Future<void> stopAzan() async {
    await _audioPlayer.stop();
  }
}

