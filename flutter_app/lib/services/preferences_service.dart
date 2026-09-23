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

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _lastReadPage = _prefs.getInt('nur_last_read_page') ?? 2;
    _themeMode = _prefs.getString('nur_theme_mode') ?? 'emerald';
    _asrMethod = _prefs.getString('nur_asr_method') ?? 'Hanafi';
    _azanSoundEnabled = _prefs.getBool('nur_azan_sound') ?? true;
    _lockscreenAlarmEnabled = _prefs.getBool('nur_lockscreen_alarm') ?? true;

    final cityJson = _prefs.getString('nur_selected_city');
    if (cityJson != null) {
      try {
        _selectedCity = City.fromJson(jsonDecode(cityJson) as Map<String, dynamic>);
      } catch (_) {
        _selectedCity = presetCities[0];
      }
    }

    final bookmarksList = _prefs.getStringList('nur_bookmarks');
    if (bookmarksList != null) {
      _bookmarks = bookmarksList.map((e) => int.tryParse(e) ?? 2).toList();
    }

    final alarmsJson = _prefs.getString('nur_prayer_alarms');
    if (alarmsJson != null) {
      try {
        final decoded = jsonDecode(alarmsJson) as Map<String, dynamic>;
        _prayerAlarms = decoded.map((key, value) => MapEntry(key, value as bool));
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
    await _prefs.setStringList('nur_bookmarks', _bookmarks.map((e) => e.toString()).toList());
    notifyListeners();
  }

  Future<void> setPrayerAlarm(String prayer, bool enabled) async {
    _prayerAlarms[prayer] = enabled;
    await _prefs.setString('nur_prayer_alarms', jsonEncode(_prayerAlarms));
    notifyListeners();
  }
}

