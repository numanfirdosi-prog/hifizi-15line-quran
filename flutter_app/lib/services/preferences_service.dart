import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/city.dart';
import '../data/preset_cities.dart';

class PreferencesService extends ChangeNotifier {
  late SharedPreferences _prefs;

  int _lastReadPage = 2;
  String _themeMode = 'emerald'; // emerald, parchment, night
  City _selectedCity = presetCities[0];
  String _asrMethod = 'Hanafi';
  bool _azanSoundEnabled = true;
  bool _lockscreenAlarmEnabled = true;
  List<int> _bookmarks = [];

  // STEP 1 additions: reader progress, appearance, audio, saved data.
  int _lastReadSurah = 1;
  int _lastReadAyah = 1;
  String _lastReadAt = '';
  int _dailyTargetPages = 4;
  String _themeName = 'night'; // night | emerald | parchment
  String _scriptStyle = 'nastaliq'; // nastaliq | uthmani
  double _ayahScale = 1.0;
  String _readingMode = 'slide'; // slide | scroll | turn
  int _repeatMode = 0; // 0=off, 1/3/5, -1=infinite
  double _playbackSpeed = 1.0;
  List<String> _savedAyahs = []; // 's:v'
  Map<String, String> _pageNotes = {}; // page -> note
  Map<String, String> _pageTint = {}; // page -> color hex
  bool _ayahTapHintShown = false;
  List<int> _khatmDays = []; // completed khatm day numbers (1..30)
  Set<int> _readPages = {}; // mushaf pages the user has opened (1..611)
  bool _onboardingDone = false;
  bool _autoBackup = false;
  String _lastAutoBackup = '';

  Map<String, bool> _prayerAlarms = {
    'fajr': true,
    'dhuhr': true,
    'asr': true,
    'maghrib': true,
    'isha': true,
  };

  int get lastReadPage => _lastReadPage;
  String get themeMode => _themeMode;
  City get selectedCity => _selectedCity;
  String get asrMethod => _asrMethod;
  bool get azanSoundEnabled => _azanSoundEnabled;
  bool get lockscreenAlarmEnabled => _lockscreenAlarmEnabled;
  List<int> get bookmarks => _bookmarks;
  Map<String, bool> get prayerAlarms => _prayerAlarms;

  int get lastReadSurah => _lastReadSurah;
  int get lastReadAyah => _lastReadAyah;
  String get lastReadAt => _lastReadAt;
  int get dailyTargetPages => _dailyTargetPages;
  String get themeName => _themeName;
  String get scriptStyle => _scriptStyle;
  double get ayahScale => _ayahScale;
  String get readingMode => _readingMode;
  int get repeatMode => _repeatMode;
  double get playbackSpeed => _playbackSpeed;
  List<String> get savedAyahs => _savedAyahs;
  Map<String, String> get pageNotes => _pageNotes;
  Map<String, String> get pageTint => _pageTint;
  bool get ayahTapHintShown => _ayahTapHintShown;
  bool get onboardingDone => _onboardingDone;
  bool get autoBackup => _autoBackup;
  String get lastAutoBackup => _lastAutoBackup;
  List<int> get khatmDays => _khatmDays;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _lastReadPage = _prefs.getInt('nur_last_read_page') ?? 2;
    _themeMode = _prefs.getString('nur_theme_mode') ?? 'emerald';
    _asrMethod = _prefs.getString('nur_asr_method') ?? 'Hanafi';
    _azanSoundEnabled = _prefs.getBool('nur_azan_sound') ?? true;
    _lockscreenAlarmEnabled = _prefs.getBool('nur_lockscreen_alarm') ?? true;

    _lastReadSurah = _prefs.getInt('nur_last_read_surah') ?? 1;
    _lastReadAyah = _prefs.getInt('nur_last_read_ayah') ?? 1;
    _lastReadAt = _prefs.getString('nur_last_read_at') ?? '';
    _dailyTargetPages = _prefs.getInt('nur_daily_target_pages') ?? 4;
    _themeName = _prefs.getString('nur_theme_name') ?? 'night';
    _scriptStyle = _prefs.getString('nur_script_style') ?? 'nastaliq';
    _ayahScale = _prefs.getDouble('nur_ayah_scale') ?? 1.0;
    _readingMode = _prefs.getString('nur_reading_mode') ?? 'slide';
    _repeatMode = _prefs.getInt('nur_repeat_mode') ?? 0;
    _playbackSpeed = _prefs.getDouble('nur_playback_speed') ?? 1.0;
    _ayahTapHintShown = _prefs.getBool('nur_ayah_tap_hint_shown') ?? false;
    _onboardingDone = _prefs.getBool('nur_onboarding_done') ?? false;
    _autoBackup = _prefs.getBool('nur_auto_backup') ?? false;
    _lastAutoBackup = _prefs.getString('nur_last_auto_backup') ?? '';

    final savedAyahsJson = _prefs.getString('nur_saved_ayahs');
    if (savedAyahsJson != null) {
      try {
        final decoded = jsonDecode(savedAyahsJson);
        if (decoded is List) {
          _savedAyahs = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    final notesJson = _prefs.getString('nur_page_notes');
    if (notesJson != null) {
      try {
        final decoded = jsonDecode(notesJson);
        if (decoded is Map) {
          _pageNotes =
              decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      } catch (_) {}
    }

    final tintJson = _prefs.getString('nur_page_tint');
    if (tintJson != null) {
      try {
        final decoded = jsonDecode(tintJson);
        if (decoded is Map) {
          _pageTint =
              decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      } catch (_) {}
    }

    final cityJson = _prefs.getString('nur_selected_city');
    if (cityJson != null) {
      try {
        _selectedCity =
            City.fromJson(jsonDecode(cityJson) as Map<String, dynamic>);
      } catch (_) {
        _selectedCity = presetCities[0];
      }
    }

    final bookmarksList = _prefs.getStringList('nur_bookmarks');
    if (bookmarksList != null) {
      _bookmarks = bookmarksList.map((e) => int.tryParse(e) ?? 2).toList();
    }

    final khatmList = _prefs.getStringList('nur_khatm_days');
    if (khatmList != null) {
      _khatmDays = khatmList
          .map((e) => int.tryParse(e) ?? 0)
          .where((d) => d >= 1 && d <= 30)
          .toList();
    }

    final readPagesList = _prefs.getStringList('nur_read_pages');
    if (readPagesList != null) {
      _readPages = readPagesList
          .map((e) => int.tryParse(e) ?? 0)
          .where((p) => p >= 1 && p <= 611)
          .toSet();
    }

    final alarmsJson = _prefs.getString('nur_prayer_alarms');
    if (alarmsJson != null) {
      try {
        final decoded = jsonDecode(alarmsJson) as Map<String, dynamic>;
        _prayerAlarms =
            decoded.map((key, value) => MapEntry(key, value as bool));
      } catch (_) {}
    }

    notifyListeners();
  }

  Future<void> setLastReadPage(int page) async {
    _lastReadPage = page;
    await _prefs.setInt('nur_last_read_page', page);
    notifyListeners();
  }

  Future<void> setThemeMode(String mode) async {
    _themeMode = mode;
    await _prefs.setString('nur_theme_mode', mode);
    notifyListeners();
  }

  Future<void> setSelectedCity(City city) async {
    _selectedCity = city;
    await _prefs.setString('nur_selected_city', jsonEncode(city.toJson()));
    notifyListeners();
  }

  Future<void> setAsrMethod(String method) async {
    _asrMethod = method;
    await _prefs.setString('nur_asr_method', method);
    notifyListeners();
  }

  Future<void> setAzanSoundEnabled(bool enabled) async {
    _azanSoundEnabled = enabled;
    await _prefs.setBool('nur_azan_sound', enabled);
    notifyListeners();
  }

  Future<void> setLockscreenAlarmEnabled(bool enabled) async {
    _lockscreenAlarmEnabled = enabled;
    await _prefs.setBool('nur_lockscreen_alarm', enabled);
    notifyListeners();
  }

  Future<void> toggleBookmark(int page) async {
    if (_bookmarks.contains(page)) {
      _bookmarks.remove(page);
    } else {
      _bookmarks.add(page);
    }
    await _prefs.setStringList(
        'nur_bookmarks', _bookmarks.map((e) => e.toString()).toList());
    notifyListeners();
  }

  Future<void> setPrayerAlarm(String prayer, bool enabled) async {
    _prayerAlarms[prayer] = enabled;
    await _prefs.setString('nur_prayer_alarms', jsonEncode(_prayerAlarms));
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // STEP 1: new persisted settings
  // ------------------------------------------------------------------

  Future<void> setLastReadSurah(int surah) async {
    _lastReadSurah = surah;
    await _prefs.setInt('nur_last_read_surah', surah);
    notifyListeners();
  }

  Future<void> setLastReadAyah(int ayah) async {
    _lastReadAyah = ayah;
    await _prefs.setInt('nur_last_read_ayah', ayah);
    notifyListeners();
  }

  Future<void> setDailyTargetPages(int pages) async {
    _dailyTargetPages = pages;
    await _prefs.setInt('nur_daily_target_pages', pages);
    notifyListeners();
  }

  Future<void> setThemeName(String name) async {
    _themeName = name;
    await _prefs.setString('nur_theme_name', name);
    notifyListeners();
  }

  Future<void> setScriptStyle(String style) async {
    _scriptStyle = style;
    await _prefs.setString('nur_script_style', style);
    notifyListeners();
  }

  Future<void> setAyahScale(double scale) async {
    _ayahScale = scale;
    await _prefs.setDouble('nur_ayah_scale', scale);
    notifyListeners();
  }

  Future<void> setReadingMode(String mode) async {
    _readingMode = mode;
    await _prefs.setString('nur_reading_mode', mode);
    notifyListeners();
  }

  Future<void> setRepeatMode(int mode) async {
    _repeatMode = mode;
    await _prefs.setInt('nur_repeat_mode', mode);
    notifyListeners();
  }

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _prefs.setDouble('nur_playback_speed', speed);
    notifyListeners();
  }

  Future<void> setAyahTapHintShown(bool shown) async {
    _ayahTapHintShown = shown;
    await _prefs.setBool('nur_ayah_tap_hint_shown', shown);
    notifyListeners();
  }

  Future<void> setOnboardingDone(bool done) async {
    _onboardingDone = done;
    await _prefs.setBool('nur_onboarding_done', done);
    notifyListeners();
  }

  Future<void> setAutoBackup(bool enabled) async {
    _autoBackup = enabled;
    await _prefs.setBool('nur_auto_backup', enabled);
    notifyListeners();
  }

  Future<void> setLastAutoBackup(String isoTime) async {
    _lastAutoBackup = isoTime;
    await _prefs.setString('nur_last_auto_backup', isoTime);
    notifyListeners();
  }

  /// Mushaf pages the user has opened (1..611), for per-Juz read %.
  Set<int> get readPages => _readPages;

  /// Records that the user opened mushaf [page] (for per-Juz read %).
  Future<void> addReadPage(int page) async {
    if (page < 1 || page > 611) return;
    if (_readPages.add(page)) {
      await _prefs.setStringList(
          'nur_read_pages', _readPages.map((e) => e.toString()).toList());
      notifyListeners();
    }
  }

  /// Toggles a Khatm Planner day (1..30) as completed.
  Future<void> toggleKhatmDay(int day) async {
    if (_khatmDays.contains(day)) {
      _khatmDays.remove(day);
    } else {
      _khatmDays.add(day);
    }
    await _prefs.setStringList(
        'nur_khatm_days', _khatmDays.map((e) => e.toString()).toList());
    notifyListeners();
  }

  Future<void> toggleSavedAyah(String verseKey) async {
    if (_savedAyahs.contains(verseKey)) {
      _savedAyahs.remove(verseKey);
    } else {
      _savedAyahs.add(verseKey);
    }
    await _prefs.setString('nur_saved_ayahs', jsonEncode(_savedAyahs));
    notifyListeners();
  }

  Future<void> setPageNote(int page, String? note) async {
    final key = page.toString();
    if (note == null || note.isEmpty) {
      _pageNotes.remove(key);
    } else {
      _pageNotes[key] = note;
    }
    await _prefs.setString('nur_page_notes', jsonEncode(_pageNotes));
    notifyListeners();
  }

  Future<void> setPageTint(int page, String? hex) async {
    final key = page.toString();
    if (hex == null || hex.isEmpty) {
      _pageTint.remove(key);
    } else {
      _pageTint[key] = hex;
    }
    await _prefs.setString('nur_page_tint', jsonEncode(_pageTint));
    notifyListeners();
  }

  Future<void> markRead(
      {required int surah, required int ayah, required int page}) async {
    _lastReadSurah = surah;
    _lastReadAyah = ayah;
    _lastReadPage = page;
    _lastReadAt = DateTime.now().toIso8601String();
    await _prefs.setInt('nur_last_read_surah', surah);
    await _prefs.setInt('nur_last_read_ayah', ayah);
    await _prefs.setInt('nur_last_read_page', page);
    await _prefs.setString('nur_last_read_at', _lastReadAt);
    notifyListeners();
  }

  /// Clears user-saved data (bookmarks, saved ayahs, notes, tints, last-read
  /// position) while keeping settings like city, alarms, and theme.
  Future<void> clearSavedData() async {
    _bookmarks = [];
    _savedAyahs = [];
    _pageNotes = {};
    _pageTint = {};
    _readPages = {};
    _lastReadPage = 2;
    _lastReadSurah = 1;
    _lastReadAyah = 1;
    _lastReadAt = '';
    await _prefs.remove('nur_bookmarks');
    await _prefs.remove('nur_saved_ayahs');
    await _prefs.remove('nur_page_notes');
    await _prefs.remove('nur_page_tint');
    await _prefs.remove('nur_read_pages');
    await _prefs.remove('nur_last_read_page');
    await _prefs.remove('nur_last_read_surah');
    await _prefs.remove('nur_last_read_ayah');
    await _prefs.remove('nur_last_read_at');
    notifyListeners();
  }

  /// Serializes ALL preferences (settings + saved data) to JSON.
  String exportJson() {
    return jsonEncode({
      'lastReadPage': _lastReadPage,
      'themeMode': _themeMode,
      'selectedCity': _selectedCity.toJson(),
      'asrMethod': _asrMethod,
      'azanSoundEnabled': _azanSoundEnabled,
      'lockscreenAlarmEnabled': _lockscreenAlarmEnabled,
      'bookmarks': _bookmarks,
      'prayerAlarms': _prayerAlarms,
      'lastReadSurah': _lastReadSurah,
      'lastReadAyah': _lastReadAyah,
      'lastReadAt': _lastReadAt,
      'dailyTargetPages': _dailyTargetPages,
      'themeName': _themeName,
      'scriptStyle': _scriptStyle,
      'ayahScale': _ayahScale,
      'readingMode': _readingMode,
      'repeatMode': _repeatMode,
      'playbackSpeed': _playbackSpeed,
      'savedAyahs': _savedAyahs,
      'pageNotes': _pageNotes,
      'pageTint': _pageTint,
      'pageDrawings': _prefs.getString('nur_page_drawings') ?? '{}',
      'ayahTapHintShown': _ayahTapHintShown,
      'khatmDays': _khatmDays,
      'readPages': _readPages.toList(),
      'onboardingDone': _onboardingDone,
      'autoBackup': _autoBackup,
      'lastAutoBackup': _lastAutoBackup,
    });
  }

  /// Applies a JSON blob produced by [exportJson]. Applies, persists and
  /// notifies on success. Returns false on bad input and never throws.
  Future<bool> importJson(String jsonStr) async {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) return false;
      final m = decoded;

      int? asInt(dynamic v) {
        if (v is num) return v.toInt();
        if (v is String) return int.tryParse(v);
        return null;
      }

      double? asDouble(dynamic v) {
        if (v is num) return v.toDouble();
        if (v is String) return double.tryParse(v);
        return null;
      }

      String? asString(dynamic v) => v is String ? v : null;
      bool? asBool(dynamic v) => v is bool ? v : null;

      final lastReadPage = asInt(m['lastReadPage']);
      if (lastReadPage != null) {
        _lastReadPage = lastReadPage;
        await _prefs.setInt('nur_last_read_page', lastReadPage);
      }

      final themeMode = asString(m['themeMode']);
      if (themeMode != null) {
        _themeMode = themeMode;
        await _prefs.setString('nur_theme_mode', themeMode);
      }

      final cityMap = m['selectedCity'];
      if (cityMap is Map<String, dynamic>) {
        _selectedCity = City.fromJson(cityMap);
        await _prefs.setString('nur_selected_city', jsonEncode(cityMap));
      }

      final asrMethod = asString(m['asrMethod']);
      if (asrMethod != null) {
        _asrMethod = asrMethod;
        await _prefs.setString('nur_asr_method', asrMethod);
      }

      final azanSound = asBool(m['azanSoundEnabled']);
      if (azanSound != null) {
        _azanSoundEnabled = azanSound;
        await _prefs.setBool('nur_azan_sound', azanSound);
      }

      final lockAlarm = asBool(m['lockscreenAlarmEnabled']);
      if (lockAlarm != null) {
        _lockscreenAlarmEnabled = lockAlarm;
        await _prefs.setBool('nur_lockscreen_alarm', lockAlarm);
      }

      final bookmarks = m['bookmarks'];
      if (bookmarks is List) {
        _bookmarks = bookmarks
            .map(
                (e) => e is num ? e.toInt() : (int.tryParse(e.toString()) ?? 2))
            .toList();
        await _prefs.setStringList(
            'nur_bookmarks', _bookmarks.map((e) => e.toString()).toList());
      }

      final alarms = m['prayerAlarms'];
      if (alarms is Map) {
        _prayerAlarms = alarms.map((k, v) => MapEntry(k.toString(), v == true));
        await _prefs.setString('nur_prayer_alarms', jsonEncode(_prayerAlarms));
      }

      final lastReadSurah = asInt(m['lastReadSurah']);
      if (lastReadSurah != null) {
        _lastReadSurah = lastReadSurah;
        await _prefs.setInt('nur_last_read_surah', lastReadSurah);
      }

      final lastReadAyah = asInt(m['lastReadAyah']);
      if (lastReadAyah != null) {
        _lastReadAyah = lastReadAyah;
        await _prefs.setInt('nur_last_read_ayah', lastReadAyah);
      }

      final lastReadAt = asString(m['lastReadAt']);
      if (lastReadAt != null) {
        _lastReadAt = lastReadAt;
        await _prefs.setString('nur_last_read_at', lastReadAt);
      }

      final dailyTarget = asInt(m['dailyTargetPages']);
      if (dailyTarget != null) {
        _dailyTargetPages = dailyTarget;
        await _prefs.setInt('nur_daily_target_pages', dailyTarget);
      }

      final themeName = asString(m['themeName']);
      if (themeName != null) {
        _themeName = themeName;
        await _prefs.setString('nur_theme_name', themeName);
      }

      final scriptStyle = asString(m['scriptStyle']);
      if (scriptStyle != null) {
        _scriptStyle = scriptStyle;
        await _prefs.setString('nur_script_style', scriptStyle);
      }

      final ayahScale = asDouble(m['ayahScale']);
      if (ayahScale != null) {
        _ayahScale = ayahScale;
        await _prefs.setDouble('nur_ayah_scale', ayahScale);
      }

      final readingMode = asString(m['readingMode']);
      if (readingMode != null) {
        _readingMode = readingMode;
        await _prefs.setString('nur_reading_mode', readingMode);
      }

      final repeatMode = asInt(m['repeatMode']);
      if (repeatMode != null) {
        _repeatMode = repeatMode;
        await _prefs.setInt('nur_repeat_mode', repeatMode);
      }

      final playbackSpeed = asDouble(m['playbackSpeed']);
      if (playbackSpeed != null) {
        _playbackSpeed = playbackSpeed;
        await _prefs.setDouble('nur_playback_speed', playbackSpeed);
      }

      final savedAyahs = m['savedAyahs'];
      if (savedAyahs is List) {
        _savedAyahs = savedAyahs.map((e) => e.toString()).toList();
        await _prefs.setString('nur_saved_ayahs', jsonEncode(_savedAyahs));
      }

      final pageNotes = m['pageNotes'];
      if (pageNotes is Map) {
        _pageNotes =
            pageNotes.map((k, v) => MapEntry(k.toString(), v.toString()));
        await _prefs.setString('nur_page_notes', jsonEncode(_pageNotes));
      }

      final pageTint = m['pageTint'];
      if (pageTint is Map) {
        _pageTint =
            pageTint.map((k, v) => MapEntry(k.toString(), v.toString()));
        await _prefs.setString('nur_page_tint', jsonEncode(_pageTint));
      }
      // Page drawings (freehand highlighter/pen strokes). Old backups
      // without this key import fine — nothing is overwritten.
      final pageDrawings = m['pageDrawings'];
      if (pageDrawings is String && pageDrawings.isNotEmpty) {
        await _prefs.setString('nur_page_drawings', pageDrawings);
      }

      final ayahTapHintShown = asBool(m['ayahTapHintShown']);
      if (ayahTapHintShown != null) {
        _ayahTapHintShown = ayahTapHintShown;
        await _prefs.setBool('nur_ayah_tap_hint_shown', ayahTapHintShown);
      }

      final khatmDays = m['khatmDays'];
      if (khatmDays is List) {
        _khatmDays = khatmDays
            .map((e) =>
                e is num ? e.toInt() : (int.tryParse(e.toString()) ?? 0))
            .where((d) => d >= 1 && d <= 30)
            .toList();
        await _prefs.setStringList(
            'nur_khatm_days', _khatmDays.map((e) => e.toString()).toList());
      }

      final readPages = m['readPages'];
      if (readPages is List) {
        _readPages = readPages
            .map((e) =>
                e is num ? e.toInt() : (int.tryParse(e.toString()) ?? 0))
            .where((p) => p >= 1 && p <= 611)
            .toSet();
        await _prefs.setStringList(
            'nur_read_pages', _readPages.map((e) => e.toString()).toList());
      }

      final onboardingDone = asBool(m['onboardingDone']);
      if (onboardingDone != null) {
        _onboardingDone = onboardingDone;
        await _prefs.setBool('nur_onboarding_done', onboardingDone);
      }

      final autoBackup = asBool(m['autoBackup']);
      if (autoBackup != null) {
        _autoBackup = autoBackup;
        await _prefs.setBool('nur_auto_backup', autoBackup);
      }

      final lastAutoBackup = asString(m['lastAutoBackup']);
      if (lastAutoBackup != null) {
        _lastAutoBackup = lastAutoBackup;
        await _prefs.setString('nur_last_auto_backup', lastAutoBackup);
      }

      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Clears everything from storage and restores all in-memory defaults.
  Future<void> resetAll() async {
    await _prefs.clear();
    _lastReadPage = 2;
    _themeMode = 'emerald';
    _selectedCity = presetCities[0];
    _asrMethod = 'Hanafi';
    _azanSoundEnabled = true;
    _lockscreenAlarmEnabled = true;
    _bookmarks = [];
    _prayerAlarms = {
      'fajr': true,
      'dhuhr': true,
      'asr': true,
      'maghrib': true,
      'isha': true,
    };
    _lastReadSurah = 1;
    _lastReadAyah = 1;
    _lastReadAt = '';
    _dailyTargetPages = 4;
    _themeName = 'night';
    _scriptStyle = 'nastaliq';
    _ayahScale = 1.0;
    _readingMode = 'slide';
    _repeatMode = 0;
    _playbackSpeed = 1.0;
    _savedAyahs = [];
    _pageNotes = {};
    _pageTint = {};
    _ayahTapHintShown = false;
    _khatmDays = [];
    _readPages = {};
    _onboardingDone = false;
    _autoBackup = false;
    _lastAutoBackup = '';
    notifyListeners();
  }
}
