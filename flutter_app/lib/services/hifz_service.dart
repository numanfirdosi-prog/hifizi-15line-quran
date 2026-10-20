import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hifz_model.dart';

class HifzService extends ChangeNotifier {
  static const String _kCurrentSabaqPage = 'nur_hifz_sabaq_page';
  static const String _kDailySabaqPages = 'nur_hifz_sabaq_daily_target';
  static const String _kLastSabaqDate = 'nur_hifz_last_sabaq_date';
  static const String _kSabaqHistory = 'nur_hifz_sabaq_history';

  static const String _kSabqiStartPage = 'nur_hifz_sabqi_start';
  static const String _kSabqiEndPage = 'nur_hifz_sabqi_end';
  static const String _kLastSabqiDate = 'nur_hifz_last_sabqi_date';
  static const String _kSabqiHistory = 'nur_hifz_sabqi_history';

  static const String _kManzilCurrentJuz = 'nur_hifz_manzil_juz';
  static const String _kManzilDailyTarget = 'nur_hifz_manzil_target';
  static const String _kLastManzilDate = 'nur_hifz_last_manzil_date';
  static const String _kManzilCompletedJuz = 'nur_hifz_manzil_completed_juz';

  static const String _kMistakes = 'nur_hifz_mistakes';

  SharedPreferences? _prefs;

  int _sabaqPage = 1;
  int _dailySabaqPages = 1;
  String? _lastSabaqDateStr;
  List<SabaqRecord> _sabaqHistory = [];

  int _sabqiStartPage = 1;
  int _sabqiEndPage = 5;
  String? _lastSabqiDateStr;
  List<SabqiRecord> _sabqiHistory = [];

  int _manzilCurrentJuz = 1;
  int _manzilDailyTarget = 1;
  String? _lastManzilDateStr;
  List<int> _manzilCompletedJuz = [];

  List<HifzMistake> _mistakes = [];

  // Getters
  int get sabaqPage => _sabaqPage;
  int get dailySabaqPages => _dailySabaqPages;
  List<SabaqRecord> get sabaqHistory => List.unmodifiable(_sabaqHistory);
  bool get isTodaySabaqDone {
    final today = _todayString();
    return _lastSabaqDateStr == today;
  }

  int get sabqiStartPage => _sabqiStartPage;
  int get sabqiEndPage => _sabqiEndPage;
  List<SabqiRecord> get sabqiHistory => List.unmodifiable(_sabqiHistory);
  bool get isTodaySabqiDone {
    final today = _todayString();
    return _lastSabqiDateStr == today;
  }

  int get manzilCurrentJuz => _manzilCurrentJuz;
  int get manzilDailyTarget => _manzilDailyTarget;
  List<int> get manzilCompletedJuz => List.unmodifiable(_manzilCompletedJuz);
  bool get isTodayManzilDone {
    final today = _todayString();
    return _lastManzilDateStr == today;
  }

  List<HifzMistake> get mistakes => List.unmodifiable(_mistakes);
  int get activeMistakesCount => _mistakes.where((m) => !m.isResolved).length;

  int get totalMemorizedPages {
    final set = <int>{};
    for (final s in _sabaqHistory) {
      if (s.isCompleted) set.add(s.page);
    }
    // Also include up to current sabaq page if sabaq has progressed
    if (_sabaqPage > 1) {
      for (int i = 1; i < _sabaqPage; i++) {
        set.add(i);
      }
    }
    return set.length;
  }

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();

    _sabaqPage = _prefs!.getInt(_kCurrentSabaqPage) ?? 1;
    _dailySabaqPages = _prefs!.getInt(_kDailySabaqPages) ?? 1;
    _lastSabaqDateStr = _prefs!.getString(_kLastSabaqDate);
    final rawSabaq = _prefs!.getString(_kSabaqHistory);
    if (rawSabaq != null && rawSabaq.isNotEmpty) {
      try {
        final list = jsonDecode(rawSabaq) as List;
        _sabaqHistory = list
            .map((item) => SabaqRecord.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    _sabqiStartPage = _prefs!.getInt(_kSabqiStartPage) ?? 1;
    _sabqiEndPage = _prefs!.getInt(_kSabqiEndPage) ?? 5;
    _lastSabqiDateStr = _prefs!.getString(_kLastSabqiDate);
    final rawSabqi = _prefs!.getString(_kSabqiHistory);
    if (rawSabqi != null && rawSabqi.isNotEmpty) {
      try {
        final list = jsonDecode(rawSabqi) as List;
        _sabqiHistory = list
            .map((item) => SabqiRecord.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    _manzilCurrentJuz = _prefs!.getInt(_kManzilCurrentJuz) ?? 1;
    _manzilDailyTarget = _prefs!.getInt(_kManzilDailyTarget) ?? 1;
    _lastManzilDateStr = _prefs!.getString(_kLastManzilDate);
    final rawCompleted = _prefs!.getStringList(_kManzilCompletedJuz);
    if (rawCompleted != null) {
      _manzilCompletedJuz = rawCompleted.map((e) => int.tryParse(e) ?? 1).toList();
    }

    final rawMistakes = _prefs!.getString(_kMistakes);
    if (rawMistakes != null && rawMistakes.isNotEmpty) {
      try {
        final list = jsonDecode(rawMistakes) as List;
        _mistakes = list
            .map((item) => HifzMistake.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    notifyListeners();
  }

  // --- Sabaq Actions ---
  Future<void> setSabaqTarget({required int page, int dailyPages = 1}) async {
    _sabaqPage = page.clamp(1, 611);
    _dailySabaqPages = dailyPages.clamp(1, 20);
    await _prefs?.setInt(_kCurrentSabaqPage, _sabaqPage);
    await _prefs?.setInt(_kDailySabaqPages, _dailySabaqPages);
    notifyListeners();
  }

  Future<void> toggleTodaySabaq() async {
    final today = _todayString();
    if (isTodaySabaqDone) {
      _lastSabaqDateStr = null;
      await _prefs?.remove(_kLastSabaqDate);
    } else {
      _lastSabaqDateStr = today;
      await _prefs?.setString(_kLastSabaqDate, today);
      final rec = SabaqRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        page: _sabaqPage,
        date: DateTime.now(),
        isCompleted: true,
      );
      _sabaqHistory.insert(0, rec);
      await _prefs?.setString(
          _kSabaqHistory, jsonEncode(_sabaqHistory.map((s) => s.toJson()).toList()));

      // Advance Sabaq to next target page
      if (_sabaqPage < 611) {
        _sabaqPage = (_sabaqPage + _dailySabaqPages).clamp(1, 611);
        await _prefs?.setInt(_kCurrentSabaqPage, _sabaqPage);
      }
    }
    notifyListeners();
  }

  // --- Sabqi Actions ---
  Future<void> setSabqiRange({required int startPage, required int endPage}) async {
    _sabqiStartPage = startPage.clamp(1, 611);
    _sabqiEndPage = endPage.clamp(_sabqiStartPage, 611);
    await _prefs?.setInt(_kSabqiStartPage, _sabqiStartPage);
    await _prefs?.setInt(_kSabqiEndPage, _sabqiEndPage);
    notifyListeners();
  }

  Future<void> toggleTodaySabqi() async {
    final today = _todayString();
    if (isTodaySabqiDone) {
      _lastSabqiDateStr = null;
      await _prefs?.remove(_kLastSabqiDate);
    } else {
      _lastSabqiDateStr = today;
      await _prefs?.setString(_kLastSabqiDate, today);
      final rec = SabqiRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startPage: _sabqiStartPage,
        endPage: _sabqiEndPage,
        date: DateTime.now(),
        isCompleted: true,
      );
      _sabqiHistory.insert(0, rec);
      await _prefs?.setString(
          _kSabqiHistory, jsonEncode(_sabqiHistory.map((s) => s.toJson()).toList()));
    }
    notifyListeners();
  }

  // --- Manzil Actions ---
  Future<void> setManzilConfig({required int currentJuz, int dailyTarget = 1}) async {
    _manzilCurrentJuz = currentJuz.clamp(1, 30);
    _manzilDailyTarget = dailyTarget.clamp(1, 5);
    await _prefs?.setInt(_kManzilCurrentJuz, _manzilCurrentJuz);
    await _prefs?.setInt(_kManzilDailyTarget, _manzilDailyTarget);
    notifyListeners();
  }

  Future<void> toggleTodayManzil() async {
    final today = _todayString();
    if (isTodayManzilDone) {
      _lastManzilDateStr = null;
      await _prefs?.remove(_kLastManzilDate);
      _manzilCompletedJuz.remove(_manzilCurrentJuz);
      await _prefs?.setStringList(
          _kManzilCompletedJuz, _manzilCompletedJuz.map((e) => e.toString()).toList());
    } else {
      _lastManzilDateStr = today;
      await _prefs?.setString(_kLastManzilDate, today);
      if (!_manzilCompletedJuz.contains(_manzilCurrentJuz)) {
        _manzilCompletedJuz.add(_manzilCurrentJuz);
      }
      await _prefs?.setStringList(
          _kManzilCompletedJuz, _manzilCompletedJuz.map((e) => e.toString()).toList());

      // Advance Manzil to next Juz
      _manzilCurrentJuz = (_manzilCurrentJuz % 30) + 1;
      await _prefs?.setInt(_kManzilCurrentJuz, _manzilCurrentJuz);
    }
    notifyListeners();
  }

  Future<void> resetManzilCycle() async {
    _manzilCompletedJuz.clear();
    _manzilCurrentJuz = 1;
    _lastManzilDateStr = null;
    await _prefs?.remove(_kManzilCompletedJuz);
    await _prefs?.setInt(_kManzilCurrentJuz, 1);
    await _prefs?.remove(_kLastManzilDate);
    notifyListeners();
  }

  // --- Mistakes Actions ---
  Future<void> addMistake({
    required int surah,
    required int ayah,
    required int page,
    required String mistakeType,
    String? notes,
  }) async {
    final existingIdx = _mistakes.indexWhere(
        (m) => m.surah == surah && m.ayah == ayah && m.page == page);
    if (existingIdx >= 0) {
      final existing = _mistakes[existingIdx];
      _mistakes[existingIdx] = existing.copyWith(
        count: existing.count + 1,
        notes: notes ?? existing.notes,
        isResolved: false,
      );
    } else {
      final m = HifzMistake(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        surah: surah,
        ayah: ayah,
        page: page,
        mistakeType: mistakeType,
        notes: notes,
        date: DateTime.now(),
      );
      _mistakes.insert(0, m);
    }
    await _saveMistakes();
    notifyListeners();
  }

  Future<void> toggleMistakeResolved(String id) async {
    final idx = _mistakes.indexWhere((m) => m.id == id);
    if (idx >= 0) {
      final m = _mistakes[idx];
      _mistakes[idx] = m.copyWith(isResolved: !m.isResolved);
      await _saveMistakes();
      notifyListeners();
    }
  }

  Future<void> deleteMistake(String id) async {
    _mistakes.removeWhere((m) => m.id == id);
    await _saveMistakes();
    notifyListeners();
  }

  Future<void> incrementMistakeCount(String id) async {
    final idx = _mistakes.indexWhere((m) => m.id == id);
    if (idx >= 0) {
      final m = _mistakes[idx];
      _mistakes[idx] = m.copyWith(count: m.count + 1, isResolved: false);
      await _saveMistakes();
      notifyListeners();
    }
  }

  Future<void> _saveMistakes() async {
    await _prefs?.setString(
        _kMistakes, jsonEncode(_mistakes.map((m) => m.toJson()).toList()));
  }

  // Export / Import for backup
  Map<String, dynamic> exportBackup() => {
        'sabaqPage': _sabaqPage,
        'dailySabaqPages': _dailySabaqPages,
        'lastSabaqDate': _lastSabaqDateStr,
        'sabaqHistory': _sabaqHistory.map((s) => s.toJson()).toList(),
        'sabqiStartPage': _sabqiStartPage,
        'sabqiEndPage': _sabqiEndPage,
        'lastSabqiDate': _lastSabqiDateStr,
        'sabqiHistory': _sabqiHistory.map((s) => s.toJson()).toList(),
        'manzilCurrentJuz': _manzilCurrentJuz,
        'manzilDailyTarget': _manzilDailyTarget,
        'lastManzilDate': _lastManzilDateStr,
        'manzilCompletedJuz': _manzilCompletedJuz,
        'mistakes': _mistakes.map((m) => m.toJson()).toList(),
      };

  Future<void> importBackup(Map<String, dynamic> m) async {
    if (m['sabaqPage'] is int) _sabaqPage = m['sabaqPage'];
    if (m['dailySabaqPages'] is int) _dailySabaqPages = m['dailySabaqPages'];
    if (m['lastSabaqDate'] is String) _lastSabaqDateStr = m['lastSabaqDate'];
    if (m['sabaqHistory'] is List) {
      _sabaqHistory = (m['sabaqHistory'] as List)
          .map((item) => SabaqRecord.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    if (m['sabqiStartPage'] is int) _sabqiStartPage = m['sabqiStartPage'];
    if (m['sabqiEndPage'] is int) _sabqiEndPage = m['sabqiEndPage'];
    if (m['lastSabqiDate'] is String) _lastSabqiDateStr = m['lastSabqiDate'];
    if (m['sabqiHistory'] is List) {
      _sabqiHistory = (m['sabqiHistory'] as List)
          .map((item) => SabqiRecord.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    if (m['manzilCurrentJuz'] is int) _manzilCurrentJuz = m['manzilCurrentJuz'];
    if (m['manzilDailyTarget'] is int) _manzilDailyTarget = m['manzilDailyTarget'];
    if (m['lastManzilDate'] is String) _lastManzilDateStr = m['lastManzilDate'];
    if (m['manzilCompletedJuz'] is List) {
      _manzilCompletedJuz = (m['manzilCompletedJuz'] as List)
          .map((e) => (e as num).toInt())
          .toList();
    }

    if (m['mistakes'] is List) {
      _mistakes = (m['mistakes'] as List)
          .map((item) => HifzMistake.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    await _prefs?.setInt(_kCurrentSabaqPage, _sabaqPage);
    await _prefs?.setInt(_kDailySabaqPages, _dailySabaqPages);
    if (_lastSabaqDateStr != null) {
      await _prefs?.setString(_kLastSabaqDate, _lastSabaqDateStr!);
    }
    await _prefs?.setString(
        _kSabaqHistory, jsonEncode(_sabaqHistory.map((s) => s.toJson()).toList()));

    await _prefs?.setInt(_kSabqiStartPage, _sabqiStartPage);
    await _prefs?.setInt(_kSabqiEndPage, _sabqiEndPage);
    if (_lastSabqiDateStr != null) {
      await _prefs?.setString(_kLastSabqiDate, _lastSabqiDateStr!);
    }
    await _prefs?.setString(
        _kSabqiHistory, jsonEncode(_sabqiHistory.map((s) => s.toJson()).toList()));

    await _prefs?.setInt(_kManzilCurrentJuz, _manzilCurrentJuz);
    await _prefs?.setInt(_kManzilDailyTarget, _manzilDailyTarget);
    if (_lastManzilDateStr != null) {
      await _prefs?.setString(_kLastManzilDate, _lastManzilDateStr!);
    }
    await _prefs?.setStringList(
        _kManzilCompletedJuz, _manzilCompletedJuz.map((e) => e.toString()).toList());
    await _saveMistakes();

    notifyListeners();
  }
}
