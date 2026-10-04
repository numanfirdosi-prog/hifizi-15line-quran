import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import '../models/prayer_times.dart';
import '../models/city.dart';
import '../views/azan_alarm_screen.dart';
import 'prayer_calculation_service.dart';

/// Global navigator key so the azan notification handler can open the
/// full-screen alarm UI even when the callback fires outside a widget context.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// SharedPreferences flag used to tell the background audio isolate to stop
/// the azan (set by the Stop button / notification Stop action).
const String stopAzanFlag = 'nur_azan_stop';

/// Action id for the notification's Stop button.
const String stopAzanActionId = 'stop_azan_action';

const Map<int, String> _prayerKeysById = {
  101: 'fajr',
  102: 'dhuhr',
  103: 'asr',
  104: 'maghrib',
  105: 'isha',
};

const Map<int, String> _prayerNamesById = {
  101: 'Fajr',
  102: 'Dhuhr',
  103: 'Asr',
  104: 'Maghrib',
  105: 'Isha',
};

// Background alarm callback entrypoint (must be top-level static)
@pragma('vm:entry-point')
void azanNotificationBackgroundHandler(NotificationResponse response) async {
  // Runs in its own background isolate when the user taps the notification
  // Stop action while the app is in background/killed.
  if (response.actionId == stopAzanActionId) {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(stopAzanFlag, true);
    } catch (_) {}
  }
}

// Background alarm callback entrypoint (must be top-level static)
@pragma('vm:entry-point')
void azanAlarmCallback(int id) async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[AzanAlarm] Background alarm triggered with ID: $id');

  // The background isolate never runs main(), so initialize the IANA
  // timezone database here too (needed for DST-correct chaining).
  try {
    tzdata.initializeTimeZones();
  } catch (e) {
    debugPrint('[AzanAlarm] tz init failed: $e');
  }

  final prayerName = _prayerNamesById[id] ?? 'Prayer';

  SharedPreferences? sp;
  try {
    sp = await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('[AzanAlarm] SharedPreferences unavailable in background: $e');
  }

  // M1: Respect the "Play Azan Sound" toggle. The background isolate cannot
  // access the UI isolate's providers, so the pref is read fresh from storage.
  final soundOn = sp?.getBool('nur_azan_sound') ?? true;

  // Clear any stale stop request from a previous alarm before starting.
  try {
    await sp?.setBool(stopAzanFlag, false);
  } catch (_) {}

  final player = AudioPlayer();
  try {
    if (soundOn) {
      try {
        await player.setAsset('assets/audio/azan.mp3');
      } catch (_) {
        await player.setAsset('assets/audio/silence.wav');
      }
      await player.play();

      // FIX: just_audio's play() completes when playback STARTS, not when it
      // ends. Wait until the azan actually finishes — or the user hits Stop —
      // before disposing, otherwise the audio is cut off within milliseconds.
      final done = Completer<void>();
      StreamSubscription<PlayerState>? stateSub;
      stateSub = player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed &&
            !done.isCompleted) {
          done.complete();
        }
      });
      // Poll the stop flag so the Stop button / notification Stop action can
      // silence the azan mid-playback (isolates can't share the player).
      Timer? poll;
      poll = Timer.periodic(const Duration(milliseconds: 500), (_) async {
        if (done.isCompleted) {
          poll?.cancel();
          return;
        }
        try {
          final p = await SharedPreferences.getInstance();
          await p.reload();
          if ((p.getBool(stopAzanFlag) ?? false) && !done.isCompleted) {
            debugPrint('[AzanAlarm] Stop requested, silencing azan');
            done.complete();
          }
        } catch (_) {}
      });
      // Safety: never block the isolate forever.
      try {
        await done.future.timeout(const Duration(minutes: 12));
      } catch (_) {}
      poll.cancel();
      await stateSub.cancel();
      try {
        await player.stop();
      } catch (_) {}
    }
  } catch (e) {
    debugPrint('[AzanAlarm] Error playing audio in background: $e');
  } finally {
    await player.dispose(); // N6: no leaked AudioPlayer per alarm fire
  }

  // Show the alarm notification:
  // - Phone LOCKED  -> fullScreenIntent launches the full-screen alarm UI
  //   (MainActivity has showWhenLocked + turnScreenOn), with a Stop button.
  // - Phone UNLOCKED -> heads-up notification (SMS-style) with a Stop action.
  // Audio itself is bundled (assets/audio/azan.mp3) so this works offline.
  try {
    final plugin = FlutterLocalNotificationsPlugin();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await plugin.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveBackgroundNotificationResponse:
          azanNotificationBackgroundHandler,
    );
    final androidImpl = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl
        ?.createNotificationChannel(const AndroidNotificationChannel(
      'azan_alarm_channel',
      'Azan Prayers & Alarms',
      description: 'Plays Azan sound on prayer time even when phone is locked',
      importance: Importance.max,
      playSound: false, // audio is handled by the player above
      enableVibration: true,
    ));
    await plugin.show(
      id,
      '$prayerName — نماز کا وقت',
      soundOn ? 'Azan is playing — tap STOP to silence' : 'Prayer time has started',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'azan_alarm_channel',
          'Azan Prayers & Alarms',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              stopAzanActionId,
              'STOP',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
      ),
      payload: 'azan_alarm:$id:$prayerName',
    );
  } catch (e) {
    debugPrint('[AzanAlarm] Background notification failed: $e');
  }

  // C1: Chain the alarm — schedule this same prayer for tomorrow. oneShotAt
  // fires only once, so without chaining the "daily" alarm silently dies.
  try {
    final key = _prayerKeysById[id];
    if (key != null && sp != null && Platform.isAndroid) {
      var enabled = true;
      final lockscreenOn = sp.getBool('nur_lockscreen_alarm') ?? true;
      final alarmsJson = sp.getString('nur_prayer_alarms');
      if (alarmsJson != null) {
        try {
          enabled =
              (jsonDecode(alarmsJson) as Map<String, dynamic>)[key] as bool? ??
                  true;
        } catch (_) {}
      }
      if (enabled && lockscreenOn) {
        City city;
        try {
          final cityJson = sp.getString('nur_selected_city');
          city = cityJson != null
              ? City.fromJson(jsonDecode(cityJson) as Map<String, dynamic>)
              : presetFallbackCity;
        } catch (_) {
          city = presetFallbackCity;
        }
        final asrMode = sp.getString('nur_asr_method') ?? 'Hanafi';
        final tomorrow = PrayerCalculationService.cityToday(city)
            .add(const Duration(days: 1));
        final schedule = PrayerCalculationService.calculate(
          date: tomorrow,
          location: city,
          asrMode: asrMode,
        );
        final entry = schedule.getByName(key);
        if (entry != null) {
          final nextTime = PrayerCalculationService.cityWallTimeToAbsolute(
              city, entry, tomorrow);
          await AndroidAlarmManager.oneShotAt(
            nextTime,
            id,
            azanAlarmCallback,
            exact: true,
            wakeup: true,
            rescheduleOnReboot: true,
          );
          debugPrint(
              '[AzanAlarm] Chained $prayerName for ${nextTime.toIso8601String()}');
        }
      }
    }
  } catch (e) {
    debugPrint('[AzanAlarm] Chaining next-day alarm failed: $e');
  }
}

/// Fallback city used only if stored preferences are unreadable in background.
const City presetFallbackCity = City(
  id: 'delhi',
  name: 'Delhi / New Delhi',
  urdu: 'دہلی',
  country: 'India',
  lat: 28.6139,
  lng: 77.2090,
  tz: 5.5,
  ianaTz: 'Asia/Kolkata',
);

class AzanAlarmService {
  static final AzanAlarmService _instance = AzanAlarmService._internal();
  factory AzanAlarmService() => _instance;
  AzanAlarmService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _initialized = false;

  /// Payload stashed when a notification tap arrives before the navigator is
  /// ready (cold start via full-screen intent). The splash screen drains it.
  static String? pendingAlarmPayload;

  Future<void> init() async {
    if (_initialized) return;

    // 1. Android Alarm Manager (for exact lockscreen alarms)
    if (Platform.isAndroid) {
      await AndroidAlarmManager.initialize();
    }

    // 2. Notification Plugin Setup
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
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
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse:
          azanNotificationBackgroundHandler,
    );

    // Create high-priority Azan notification channel on Android
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'azan_alarm_channel',
        'Azan Prayers & Alarms',
        description:
            'Plays Azan sound on prayer time even when phone is locked',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.createNotificationChannel(channel);
    }

    _initialized = true;
  }

  /// Foreground notification tap handler: Stop action silences the azan,
  /// tapping the body opens the full-screen alarm UI.
  static void _onNotificationTap(NotificationResponse details) {
    debugPrint(
        '[Notification] Azan tap: action=${details.actionId} payload=${details.payload}');
    if (details.actionId == stopAzanActionId) {
      SharedPreferences.getInstance()
          .then((sp) => sp.setBool(stopAzanFlag, true))
          .catchError((_) {});
      return;
    }
    final payload = details.payload;
    if (payload != null && payload.startsWith('azan_alarm:')) {
      _openAlarmScreen(payload);
    }
  }

  /// Opens the full-screen alarm UI for the given `azan_alarm:<id>:<name>`
  /// payload. If the navigator isn't ready yet (cold start), stashes the
  /// payload for the splash screen to drain.
  static void _openAlarmScreen(String payload) {
    try {
      final parts = payload.split(':');
      if (parts.length < 3) return;
      final id = int.tryParse(parts[1]) ?? 0;
      final name = parts.sublist(2).join(':');
      final nav = appNavigatorKey.currentState;
      if (nav != null) {
        nav.push(
          MaterialPageRoute(
            builder: (_) => AzanAlarmScreen(prayerName: name, alarmId: id),
            fullscreenDialog: true,
          ),
        );
      } else {
        pendingAlarmPayload = payload;
      }
    } catch (e) {
      debugPrint('[AzanAlarm] openAlarmScreen failed: $e');
    }
  }

  /// Called by the splash screen after the first frame: opens the alarm UI
  /// if a notification tap arrived during cold start.
  static void drainPendingAlarm() {
    final payload = pendingAlarmPayload;
    if (payload != null) {
      pendingAlarmPayload = null;
      _openAlarmScreen(payload);
    }
  }

  /// Schedules today's remaining prayer alarms.
  ///
  /// On Android with [lockscreenAlarmEnabled] ON, exact wakeup alarms are used
  /// (they fire even when the phone is locked). Otherwise — iOS, or the
  /// lockscreen toggle OFF — scheduled notifications are used instead.
  Future<void> scheduleDailyPrayerAlarms({
    required City location,
    required String asrMode,
    required Map<String, bool> enabledAlarms,
    required bool azanSoundEnabled,
    required bool lockscreenAlarmEnabled,
  }) async {
    if (!_initialized) await init();

    // N10: use the city's own "today" so the schedule is right near midnight
    // when the device timezone differs from the city timezone.
    final today = PrayerCalculationService.cityToday(location);
    final now = DateTime.now();
    final schedule = PrayerCalculationService.calculate(
      date: today,
      location: location,
      asrMode: asrMode,
    );

    final prayers = [
      {'id': 101, 'key': 'fajr', 'name': 'Fajr', 'time': schedule.fajr},
      {'id': 102, 'key': 'dhuhr', 'name': 'Dhuhr', 'time': schedule.dhuhr},
      {'id': 103, 'key': 'asr', 'name': 'Asr', 'time': schedule.asr},
      {
        'id': 104,
        'key': 'maghrib',
        'name': 'Maghrib',
        'time': schedule.maghrib
      },
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

      var prayerTime = PrayerCalculationService.cityWallTimeToAbsolute(
          location, entry, today);
      if (prayerTime.isBefore(now)) {
        prayerTime = PrayerCalculationService.cityWallTimeToAbsolute(
            location, entry, today.add(const Duration(days: 1)));
      }

      final useExactAlarm = Platform.isAndroid && lockscreenAlarmEnabled;

      if (useExactAlarm) {
        // Exact lockscreen alarm; cancel any notification fallback for this id
        // so the user never gets a double alert.
        await _notificationsPlugin.cancel(alarmId);
        await AndroidAlarmManager.oneShotAt(
          prayerTime,
          alarmId,
          azanAlarmCallback,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
        );
      } else {
        // C2/M2: notification fallback — used on iOS and when the user turns
        // the lockscreen exact-alarm toggle OFF.
        if (Platform.isAndroid) {
          await AndroidAlarmManager.cancel(alarmId);
        }
        try {
          await _notificationsPlugin.zonedSchedule(
            alarmId,
            '$name — نماز کا وقت',
            azanSoundEnabled
                ? 'Azan time — tap to open'
                : 'Prayer time has started',
            tz.TZDateTime.from(prayerTime, tz.local),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'azan_alarm_channel',
                'Azan Prayers & Alarms',
                importance: Importance.max,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        } catch (e) {
          debugPrint('[AzanAlarm] zonedSchedule failed for $name: $e');
        }
      }

      debugPrint(
          '[AzanAlarm] Scheduled $name at ${prayerTime.toIso8601String()} '
          '(exact: $useExactAlarm)');
    }
  }

  /// M8: On Android 12+, exact alarms need a dedicated permission that is NOT
  /// granted by default. Returns true when exact alarms can be scheduled.
  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    try {
      return await Permission.scheduleExactAlarm.isGranted;
    } catch (_) {
      return true;
    }
  }

  /// M8: Asks for the exact-alarm permission (opens system Settings on
  /// Android 12+). Returns true if granted.
  Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final status = await Permission.scheduleExactAlarm.request();
      return status.isGranted;
    } catch (_) {
      return true;
    }
  }

  Future<void> cancelAllAlarms() async {
    for (final id in _prayerKeysById.keys) {
      if (Platform.isAndroid) {
        await AndroidAlarmManager.cancel(id);
      }
      await _notificationsPlugin.cancel(id);
    }
  }

  Future<void> playTestAzan() async {
    try {
      // M3: was silence.wav — the "Test Azan" button must actually play Azan.
      await _audioPlayer.setAsset('assets/audio/azan.mp3');
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('[AzanAlarm] Test azan error: $e');
    }
  }

  Future<void> stopAzan() async {
    await _audioPlayer.stop();
  }
}
