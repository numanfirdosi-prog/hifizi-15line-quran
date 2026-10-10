import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/city.dart';
import '../data/preset_cities.dart';
import 'auto_backup_service.dart';

class PreferencesService extends ChangeNotifier {
  late SharedPreferences _prefs;

  int _lastReadPage = 2;
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
  String _scriptStyle = 'sans'; // sans | uthmani
  String _language = 'ur'; // 'ur' | 'en' — UI language toggle (Settings)
  double _ayahScale = 1.0;
  String _readingMode = 'slide'; // slide | scroll | turn
  int _repeatMode = 0; // 0=off, 1/3/5, -1=infinite
  double _playbackSpeed = 1.0;
  bool _audioHighlightEnabled = true; // highlight ayahs during audio
  bool _backgroundPlaybackEnabled = true; // keep audio in background
  bool _nightPageMode = false; // invert mushaf page: black bg, white text
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
  String get language => _language; // 'ur' | 'en'
  bool get isUrdu => _language == 'ur';
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
  bool get audioHighlightEnabled => _audioHighlightEnabled;
  bool get backgroundPlaybackEnabled => _backgroundPlaybackEnabled;
  bool get nightPageMode => _nightPageMode;
  String get lastAutoBackup => _lastAutoBackup;
  List<int> get khatmDays => _khatmDays;

  /// The retired 'nastaliq' (Gulzar) script style migrates to Noto Sans
  /// Arabic ('sans'). Applied both at startup and on backup import so old
  /// stored values and old backups can never bypass the migration.
  static String _migrateScriptStyle(String style) =>
      style == 'nastaliq' ? 'sans' : style;

  /// Parses an int from a num or a numeric String; null when corrupt.
  static int? _tryParseInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _lastReadPage = _prefs.getInt('nur_last_read_page') ?? 2;
    _asrMethod = _prefs.getString('nur_asr_method') ?? 'Hanafi';
    _azanSoundEnabled = _prefs.getBool('nur_azan_sound') ?? true;
    _lockscreenAlarmEnabled = _prefs.getBool('nur_lockscreen_alarm') ?? true;

    _lastReadSurah = _prefs.getInt('nur_last_read_surah') ?? 1;
    _lastReadAyah = _prefs.getInt('nur_last_read_ayah') ?? 1;
    _lastReadAt = _prefs.getString('nur_last_read_at') ?? '';
    _dailyTargetPages = _prefs.getInt('nur_daily_target_pages') ?? 4;
    _themeName = _prefs.getString('nur_theme_name') ?? 'night';
    _language = _prefs.getString('nur_language') ?? 'ur';
    _scriptStyle = _prefs.getString('nur_script_style') ?? 'sans';
    // Migrate the retired 'nastaliq' (Gulzar) style to Noto Sans Arabic.
    final migratedStyle = _migrateScriptStyle(_scriptStyle);
    if (migratedStyle != _scriptStyle) {
      _scriptStyle = migratedStyle;
      await _prefs.setString('nur_script_style', migratedStyle);
    }
    _ayahScale = _prefs.getDouble('nur_ayah_scale') ?? 1.0;
    _readingMode = _prefs.getString('nur_reading_mode') ?? 'slide';
    _repeatMode = _prefs.getInt('nur_repeat_mode') ?? 0;
    _playbackSpeed = _prefs.getDouble('nur_playback_speed') ?? 1.0;
    _ayahTapHintShown = _prefs.getBool('nur_ayah_tap_hint_shown') ?? false;
    _onboardingDone = _prefs.getBool('nur_onboarding_done') ?? false;
    _autoBackup = _prefs.getBool('nur_auto_backup') ?? false;
    _audioHighlightEnabled = _prefs.getBool('nur_audio_highlight') ?? true;
    _backgroundPlaybackEnabled =
        _prefs.getBool('nur_background_playback') ?? true;
    _nightPageMode = _prefs.getBool('nur_night_page_mode') ?? false;
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
      // Corrupt entries are skipped, never defaulted to a real page.
      _bookmarks =
          bookmarksList.map(_tryParseInt).whereType<int>().toList();
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
        // Per-alarm fallback: keep the good stored values, default only
        // the bad ones — one corrupt value no longer resets all five.
        for (final entry in decoded.entries) {
          if (_prayerAlarms.containsKey(entry.key) &&
              entry.value is bool) {
            _prayerAlarms[entry.key] = entry.value as bool;
          }
        }
      } catch (_) {}
    }

    notifyListeners();
  }

  Future<void> setLastReadPage(int page) async {
    _lastReadPage = page;
    await _prefs.setInt('nur_last_read_page', page);
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

  /// UI language toggle: 'ur' (Urdu) or 'en' (English). Quran translations
  /// always stay bilingual regardless of this setting.
  Future<void> setLanguage(String lang) async {
    if (lang != 'ur' && lang != 'en') return;
    _language = lang;
    await _prefs.setString('nur_language', lang);
    notifyListeners();
  }

  Future<void> setScriptStyle(String style) async {
    // Only 'sans' (Noto Sans Arabic) and 'uthmani' (Amiri Quran) are offered.
    if (style != 'sans' && style != 'uthmani') return;
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

  Future<void> setAudioHighlightEnabled(bool enabled) async {
    _audioHighlightEnabled = enabled;
    await _prefs.setBool('nur_audio_highlight', enabled);
    notifyListeners();
  }

  Future<void> setNightPageMode(bool enabled) async {
    _nightPageMode = enabled;
    await _prefs.setBool('nur_night_page_mode', enabled);
    notifyListeners();
  }

  Future<void> setBackgroundPlaybackEnabled(bool enabled) async {
    _backgroundPlaybackEnabled = enabled;
    await _prefs.setBool('nur_background_playback', enabled);
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
    await _prefs.remove('nur_page_drawings');
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
      'audioHighlightEnabled': _audioHighlightEnabled,
      'backgroundPlaybackEnabled': _backgroundPlaybackEnabled,
      'nightPageMode': _nightPageMode,
      'lastAutoBackup': _lastAutoBackup,
    });
  }


  /// Validates a backup JSON blob and stages every present field. Returns
  /// null when the blob itself is malformed (bad JSON, non-object top level,
  /// or a field that cannot be parsed, e.g. a corrupt city map) — in that
  /// case [importJson] persists nothing at all. Never throws.
  static _ParsedBackup? _parseBackupJson(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) return null;
      final m = decoded;
      final data = _ParsedBackup();

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

      data.lastReadPage = asInt(m['lastReadPage']);

      final cityMap = m['selectedCity'];
      if (cityMap is Map<String, dynamic>) {
        // Throws on malformed maps (e.g. a String where a number belongs) —
        // that invalidates the whole backup instead of half-applying it.
        data.selectedCity = City.fromJson(cityMap);
      }

      data.asrMethod = asString(m['asrMethod']);
      data.azanSoundEnabled = asBool(m['azanSoundEnabled']);
      data.lockscreenAlarmEnabled = asBool(m['lockscreenAlarmEnabled']);

      final bookmarks = m['bookmarks'];
      if (bookmarks is List) {
        // Corrupt entries are skipped, never defaulted to a real page.
        data.bookmarks =
            bookmarks.map(_tryParseInt).whereType<int>().toList();
      }

      final alarms = m['prayerAlarms'];
      if (alarms is Map) {
        // Per-alarm fallback: keep the backup's valid entries, default only
        // the bad ones — one bad value no longer wipes all five alarms.
        final parsed = <String, bool>{
          'fajr': true,
          'dhuhr': true,
          'asr': true,
          'maghrib': true,
          'isha': true,
        };
        for (final entry in alarms.entries) {
          final key = entry.key.toString();
          if (parsed.containsKey(key) && entry.value is bool) {
            parsed[key] = entry.value as bool;
          }
        }
        data.prayerAlarms = parsed;
      }

      data.lastReadSurah = asInt(m['lastReadSurah']);
      data.lastReadAyah = asInt(m['lastReadAyah']);
      data.lastReadAt = asString(m['lastReadAt']);
      data.dailyTargetPages = asInt(m['dailyTargetPages']);
      data.themeName = asString(m['themeName']);

      final scriptStyle = asString(m['scriptStyle']);
      if (scriptStyle != null) {
        // Old backups may still carry the retired 'nastaliq' style —
        // run the same migration as app startup.
        data.scriptStyle = _migrateScriptStyle(scriptStyle);
      }

      data.ayahScale = asDouble(m['ayahScale']);
      data.readingMode = asString(m['readingMode']);
      data.repeatMode = asInt(m['repeatMode']);
      data.playbackSpeed = asDouble(m['playbackSpeed']);

      final savedAyahs = m['savedAyahs'];
      if (savedAyahs is List) {
        data.savedAyahs = savedAyahs.map((e) => e.toString()).toList();
      }

      final pageNotes = m['pageNotes'];
      if (pageNotes is Map) {
        data.pageNotes =
            pageNotes.map((k, v) => MapEntry(k.toString(), v.toString()));
      }

      final pageTint = m['pageTint'];
      if (pageTint is Map) {
        data.pageTint =
            pageTint.map((k, v) => MapEntry(k.toString(), v.toString()));
      }

      // Page drawings (freehand highlighter/pen strokes). Old backups
      // without this key import fine — nothing is overwritten.
      final pageDrawings = m['pageDrawings'];
      if (pageDrawings is String && pageDrawings.isNotEmpty) {
        try {
          if (jsonDecode(pageDrawings) is Map) {
            data.pageDrawings = pageDrawings;
          }
        } catch (_) {
          // Corrupt drawings blob: skip it, keep the current one.
        }
      }

      data.ayahTapHintShown = asBool(m['ayahTapHintShown']);

      final khatmDays = m['khatmDays'];
      if (khatmDays is List) {
        data.khatmDays = khatmDays
            .map(_tryParseInt)
            .whereType<int>()
            .where((d) => d >= 1 && d <= 30)
            .toList();
      }

      final readPages = m['readPages'];
      if (readPages is List) {
        data.readPages = readPages
            .map(_tryParseInt)
            .whereType<int>()
            .where((p) => p >= 1 && p <= 611)
            .toSet();
      }

      data.onboardingDone = asBool(m['onboardingDone']);
      data.autoBackup = asBool(m['autoBackup']);
      data.audioHighlightEnabled = asBool(m['audioHighlightEnabled']);
      data.backgroundPlaybackEnabled =
          asBool(m['backgroundPlaybackEnabled']);
      data.nightPageMode = asBool(m['nightPageMode']);
      data.lastAutoBackup = asString(m['lastAutoBackup']);

      return data;
    } catch (_) {
      return null;
    }
  }

  /// Applies a JSON blob produced by [exportJson]. The whole blob is
  /// validated first (see [_parseBackupJson]) and only then is anything
  /// persisted, so a malformed backup can never half-overwrite the current
  /// data. Returns false on bad input and never throws.
  Future<bool> importJson(String jsonStr) async {
    final data = _parseBackupJson(jsonStr);
    if (data == null) return false;

    if (data.lastReadPage != null) {
      _lastReadPage = data.lastReadPage!;
      await _prefs.setInt('nur_last_read_page', _lastReadPage);
    }

    if (data.selectedCity != null) {
      _selectedCity = data.selectedCity!;
      await _prefs.setString(
          'nur_selected_city', jsonEncode(_selectedCity.toJson()));
    }

    if (data.asrMethod != null) {
      _asrMethod = data.asrMethod!;
      await _prefs.setString('nur_asr_method', _asrMethod);
    }

    if (data.azanSoundEnabled != null) {
      _azanSoundEnabled = data.azanSoundEnabled!;
      await _prefs.setBool('nur_azan_sound', _azanSoundEnabled);
    }

    if (data.lockscreenAlarmEnabled != null) {
      _lockscreenAlarmEnabled = data.lockscreenAlarmEnabled!;
      await _prefs.setBool('nur_lockscreen_alarm', _lockscreenAlarmEnabled);
    }

    if (data.bookmarks != null) {
      _bookmarks = data.bookmarks!;
      await _prefs.setStringList(
          'nur_bookmarks', _bookmarks.map((e) => e.toString()).toList());
    }

    if (data.prayerAlarms != null) {
      _prayerAlarms = data.prayerAlarms!;
      await _prefs.setString('nur_prayer_alarms', jsonEncode(_prayerAlarms));
    }

    if (data.lastReadSurah != null) {
      _lastReadSurah = data.lastReadSurah!;
      await _prefs.setInt('nur_last_read_surah', _lastReadSurah);
    }

    if (data.lastReadAyah != null) {
      _lastReadAyah = data.lastReadAyah!;
      await _prefs.setInt('nur_last_read_ayah', _lastReadAyah);
    }

    if (data.lastReadAt != null) {
      _lastReadAt = data.lastReadAt!;
      await _prefs.setString('nur_last_read_at', _lastReadAt);
    }

    if (data.dailyTargetPages != null) {
      _dailyTargetPages = data.dailyTargetPages!;
      await _prefs.setInt('nur_daily_target_pages', _dailyTargetPages);
    }

    if (data.themeName != null) {
      _themeName = data.themeName!;
      await _prefs.setString('nur_theme_name', _themeName);
    }

    if (data.scriptStyle != null) {
      _scriptStyle = data.scriptStyle!;
      await _prefs.setString('nur_script_style', _scriptStyle);
    }

    if (data.ayahScale != null) {
      _ayahScale = data.ayahScale!;
      await _prefs.setDouble('nur_ayah_scale', _ayahScale);
    }

    if (data.readingMode != null) {
      _readingMode = data.readingMode!;
      await _prefs.setString('nur_reading_mode', _readingMode);
    }

    if (data.repeatMode != null) {
      _repeatMode = data.repeatMode!;
      await _prefs.setInt('nur_repeat_mode', _repeatMode);
    }

    if (data.playbackSpeed != null) {
      _playbackSpeed = data.playbackSpeed!;
      await _prefs.setDouble('nur_playback_speed', _playbackSpeed);
    }

    if (data.savedAyahs != null) {
      _savedAyahs = data.savedAyahs!;
      await _prefs.setString('nur_saved_ayahs', jsonEncode(_savedAyahs));
    }

    if (data.pageNotes != null) {
      _pageNotes = data.pageNotes!;
      await _prefs.setString('nur_page_notes', jsonEncode(_pageNotes));
    }

    if (data.pageTint != null) {
      _pageTint = data.pageTint!;
      await _prefs.setString('nur_page_tint', jsonEncode(_pageTint));
    }

    if (data.pageDrawings != null) {
      await _prefs.setString('nur_page_drawings', data.pageDrawings!);
    }

    if (data.ayahTapHintShown != null) {
      _ayahTapHintShown = data.ayahTapHintShown!;
      await _prefs.setBool('nur_ayah_tap_hint_shown', _ayahTapHintShown);
    }

    if (data.khatmDays != null) {
      _khatmDays = data.khatmDays!;
      await _prefs.setStringList(
          'nur_khatm_days', _khatmDays.map((e) => e.toString()).toList());
    }

    if (data.readPages != null) {
      _readPages = data.readPages!;
      await _prefs.setStringList(
          'nur_read_pages', _readPages.map((e) => e.toString()).toList());
    }

    if (data.onboardingDone != null) {
      _onboardingDone = data.onboardingDone!;
      await _prefs.setBool('nur_onboarding_done', _onboardingDone);
    }

    if (data.autoBackup != null) {
      _autoBackup = data.autoBackup!;
      await _prefs.setBool('nur_auto_backup', _autoBackup);
    }

    if (data.audioHighlightEnabled != null) {
      _audioHighlightEnabled = data.audioHighlightEnabled!;
      await _prefs.setBool('nur_audio_highlight', _audioHighlightEnabled);
    }

    if (data.backgroundPlaybackEnabled != null) {
      _backgroundPlaybackEnabled = data.backgroundPlaybackEnabled!;
      await _prefs.setBool(
          'nur_background_playback', _backgroundPlaybackEnabled);
    }

    if (data.nightPageMode != null) {
      _nightPageMode = data.nightPageMode!;
      await _prefs.setBool('nur_night_page_mode', _nightPageMode);
    }

    if (data.lastAutoBackup != null) {
      _lastAutoBackup = data.lastAutoBackup!;
      await _prefs.setString('nur_last_auto_backup', _lastAutoBackup);
    }

    notifyListeners();
    return true;
  }

  /// Clears everything from storage and restores all in-memory defaults.
  Future<void> resetAll() async {
    await _prefs.clear();
    // A full reset must not leave the weekly auto-backup alarm firing while
    // the toggle now reads OFF.
    await AutoBackupService.cancel();
    _lastReadPage = 2;
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
    _scriptStyle = 'sans';
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
    _audioHighlightEnabled = true;
    _backgroundPlaybackEnabled = true;
    _nightPageMode = false;
    _lastAutoBackup = '';
    notifyListeners();
  }
}

/// Staged, fully validated backup data for [PreferencesService.importJson].
/// A null field means "absent from the backup — keep the current value".
/// Used to validate the whole blob before persisting anything, so a
/// malformed backup is rejected cleanly without half-overwriting data.
class _ParsedBackup {
  int? lastReadPage;
  City? selectedCity;
  String? asrMethod;
  bool? azanSoundEnabled;
  bool? lockscreenAlarmEnabled;
  List<int>? bookmarks;
  Map<String, bool>? prayerAlarms;
  int? lastReadSurah;
  int? lastReadAyah;
  String? lastReadAt;
  int? dailyTargetPages;
  String? themeName;
  String? scriptStyle;
  double? ayahScale;
  String? readingMode;
  int? repeatMode;
  double? playbackSpeed;
  List<String>? savedAyahs;
  Map<String, String>? pageNotes;
  Map<String, String>? pageTint;
  String? pageDrawings;
  bool? ayahTapHintShown;
  List<int>? khatmDays;
  Set<int>? readPages;
  bool? onboardingDone;
  bool? autoBackup;
  bool? audioHighlightEnabled;
  bool? backgroundPlaybackEnabled;
  bool? nightPageMode;
  String? lastAutoBackup;
}
