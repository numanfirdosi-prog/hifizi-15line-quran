import 'dart:convert';

import 'package:flutter/services.dart';

/// Bundled (offline) Tafsir Ibn Kathir (Urdu) service.
///
/// Loads per-surah bundled JSON files from
/// `assets/data/tafsir_ibn_kathir_urdu/surah_XXX.json`
/// (zero-padded 3-digit surah number), each mapping
/// "surah:ayah" → tafsir text (Urdu, HTML stripped).
///
/// Surah files are loaded lazily on first request for that surah
/// and cached in memory. This keeps the GitHub blob size small
/// (no single 48 MB file) and avoids loading all 6,236 ayahs
/// when only one surah is needed.
///
/// Tafsir source: Tafsir Ibn Kathir (Hafiz Imaduddin Ibn Kathir,
/// d. 774 AH / 1373 CE) — public domain. Urdu translation via
/// Quran.com API (Tafsir ID 160).
class TafsirService {
  static final TafsirService _instance = TafsirService._internal();
  factory TafsirService() => _instance;
  TafsirService._internal();

  /// Per-surah cache: surah number → ("surah:ayah" → tafsir text).
  final Map<int, Map<String, String>> _surahCache = {};

  /// Surahs whose file was attempted but failed to load
  /// (missing or malformed) — avoids repeated failed loads.
  final Set<int> _failedSurahs = {};

  /// Loads one surah's tafsir file into the cache.
  /// Returns the surah map, or null on any error.
  Future<Map<String, String>?> _loadSurah(int surah) async {
    if (_surahCache.containsKey(surah)) return _surahCache[surah];
    if (_failedSurahs.contains(surah)) return null;
    if (surah < 1 || surah > 114) return null;
    try {
      final name = 'surah_${surah.toString().padLeft(3, '0')}';
      final raw = await rootBundle
          .loadString('assets/data/tafsir_ibn_kathir_urdu/$name.json');
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final map = <String, String>{};
        for (final entry in decoded.entries) {
          final value = entry.value;
          if (value is String && value.trim().isNotEmpty) {
            map[entry.key] = value;
          }
        }
        _surahCache[surah] = map;
        return map;
      }
    } catch (_) {
      // Bundled file missing or malformed — treat as no tafsir available.
    }
    _failedSurahs.add(surah);
    return null;
  }

  /// Returns the Ibn Kathir Urdu tafsir text for [surah]:[ayah],
  /// or null if not found (data file incomplete) or on any error.
  /// Never throws.
  Future<String?> getTafsir(int surah, int ayah) async {
    try {
      final map = await _loadSurah(surah);
      if (map == null || map.isEmpty) return null;
      final text = map['$surah:$ayah'];
      if (text == null || text.trim().isEmpty) return null;
      return text;
    } catch (_) {
      return null;
    }
  }

  /// Returns true if the bundled tafsir data was loaded successfully.
  /// Checks surah 1 (Al-Fatiha) as a probe — if it loads, data exists.
  Future<bool> get hasData async {
    final map = await _loadSurah(1);
    return (map?.isNotEmpty ?? false);
  }

  /// Number of ayahs with tafsir loaded so far (only loaded surahs).
  /// With lazy per-surah loading this reflects cached surahs, not the
  /// full bundled total (6,236 when all surahs are loaded).
  int get coveredAyahCount {
    var total = 0;
    for (final map in _surahCache.values) {
      total += map.length;
    }
    return total;
  }
}
