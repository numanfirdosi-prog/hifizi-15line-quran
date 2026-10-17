import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../data/quran_data.dart';
import '../data/surah_aliases.dart';
import '../models/surah.dart';

class VoiceSearchService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  List<stt.LocaleName> _availableLocales = [];

  bool get isAvailable => _isAvailable;
  bool get isListening => _speech.isListening;
  List<stt.LocaleName> get availableLocales => _availableLocales;

  Future<bool> init() async {
    try {
      _isAvailable = await _speech.initialize(
        onError: (val) => debugPrint('[Speech] Error: $val'),
        onStatus: (val) => debugPrint('[Speech] Status: $val'),
      );
      if (_isAvailable) {
        try {
          _availableLocales = await _speech.locales();
        } catch (_) {}
      }
      return _isAvailable;
    } catch (e) {
      debugPrint('[Speech] Init error: $e');
      return false;
    }
  }

  /// Finds the best matching installed locale on the device.
  String? _findBestLocale(List<String> candidates) {
    if (_availableLocales.isEmpty) {
      return candidates.isNotEmpty ? candidates.first : null;
    }
    for (final cand in candidates) {
      final candNorm = cand.toLowerCase().replaceAll('-', '_');
      for (final loc in _availableLocales) {
        final locIdNorm = loc.localeId.toLowerCase().replaceAll('-', '_');
        if (locIdNorm == candNorm || locIdNorm.startsWith('${candNorm}_')) {
          return loc.localeId;
        }
      }
    }
    // Prefix fallback (e.g. 'ur' matching 'ur_PK' or 'ur_IN')
    for (final cand in candidates) {
      final prefix = cand.split(RegExp(r'[-_]')).first.toLowerCase();
      for (final loc in _availableLocales) {
        final locPrefix =
            loc.localeId.split(RegExp(r'[-_]')).first.toLowerCase();
        if (locPrefix == prefix) {
          return loc.localeId;
        }
      }
    }
    return candidates.isNotEmpty ? candidates.first : null;
  }

  /// Resolves the speech recognition locale matching the user's active keyboard,
  /// selected language, or app context — never forcing Hindi.
  String resolveLocale({
    String? preferred,
    String? textContext,
    Locale? systemLocale,
    bool isUrduApp = true,
  }) {
    // 1. Explicit preference from voice selector or settings ('ur', 'ar', 'en', 'hi')
    if (preferred != null && preferred.isNotEmpty && preferred != 'auto') {
      switch (preferred.toLowerCase()) {
        case 'ur':
        case 'ur_pk':
        case 'ur_in':
        case 'urdu':
          return _findBestLocale(['ur_PK', 'ur_IN', 'ur']) ?? 'ur_PK';
        case 'ar':
        case 'ar_sa':
        case 'arabic':
          return _findBestLocale(['ar_SA', 'ar_EG', 'ar_AE', 'ar']) ?? 'ar_SA';
        case 'en':
        case 'en_us':
        case 'english':
          return _findBestLocale(['en_US', 'en_GB', 'en_IN', 'en']) ?? 'en_US';
        case 'hi':
        case 'hi_in':
        case 'hindi':
          return _findBestLocale(['hi_IN', 'hi']) ?? 'hi_IN';
      }
    }

    // 2. Active keyboard / search field text inspection
    if (textContext != null && textContext.trim().isNotEmpty) {
      final text = textContext.trim();
      // Devanagari script -> Hindi
      if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) {
        return _findBestLocale(['hi_IN', 'hi']) ?? 'hi_IN';
      }
      // Urdu-specific characters -> Urdu
      if (RegExp(r'[ٹڈڑئےںپچژگہٹھڈھڑھکھگھبھپھتھجھچھ]').hasMatch(text)) {
        return _findBestLocale(['ur_PK', 'ur_IN', 'ur']) ?? 'ur_PK';
      }
      // Arabic script
      if (RegExp(r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]')
          .hasMatch(text)) {
        return isUrduApp
            ? (_findBestLocale(['ur_PK', 'ur_IN', 'ur']) ?? 'ur_PK')
            : (_findBestLocale(['ar_SA', 'ar_EG', 'ar']) ?? 'ar_SA');
      }
      // English / Latin script
      if (RegExp(r'[a-zA-Z]').hasMatch(text)) {
        return _findBestLocale(['en_US', 'en_GB', 'en_IN', 'en']) ?? 'en_US';
      }
    }

    // 3. System / device keyboard locale
    if (systemLocale != null) {
      final code = systemLocale.languageCode.toLowerCase();
      if (code == 'ur') {
        return _findBestLocale(['ur_PK', 'ur_IN', 'ur']) ?? 'ur_PK';
      }
      if (code == 'ar') {
        return _findBestLocale(['ar_SA', 'ar']) ?? 'ar_SA';
      }
      if (code == 'en') {
        return _findBestLocale(['en_US', 'en']) ?? 'en_US';
      }
      if (code == 'hi') {
        return _findBestLocale(['hi_IN', 'hi']) ?? 'hi_IN';
      }
    }

    // 4. Default based on app language
    return isUrduApp
        ? (_findBestLocale(['ur_PK', 'ur_IN', 'ur']) ?? 'ur_PK')
        : (_findBestLocale(['en_US', 'en']) ?? 'en_US');
  }

  /// Starts listening and reports the recognized words through [onResult].
  /// [localeId] can be passed explicitly, or resolved automatically via [resolveLocale].
  Future<bool> startListening({
    required Function(String spokenText, List<Surah> matchedSurahs) onResult,
    String? localeId,
  }) async {
    if (!_isAvailable) {
      final ok = await init();
      if (!ok) return false;
    }

    final targetLocale = (localeId != null && localeId.isNotEmpty)
        ? localeId
        : resolveLocale();

    try {
      await _speech.listen(
        onResult: (result) {
          final words = result.recognizedWords;
          final matches = searchSurahs(words);
          onResult(words, matches);
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: targetLocale,
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint('[Speech] listen failed: $e');
      return false;
    }
    return _speech.isListening;
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  /// Releases the speech recognizer. Call from the owning widget's
  /// dispose so the plugin doesn't linger after the screen is gone.
  Future<void> dispose() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
      _speech.cancel();
    } catch (_) {}
  }

  List<Surah> searchSurahs(String query) {
    final raw = query.trim();
    if (raw.isEmpty) return [];

    final clean = cleanSurahPrefix(raw);
    // Diacritics-only queries (no actual letters) normalize to an empty
    // string, and `contains('')` matches every surah — return zero results
    // instead of bogus matches. Digits alone are a valid surah-number query
    // (matched below), so they pass the guard.
    if (!RegExp('[؀-ۿa-zA-Zऀ-ॿ0-9]').hasMatch(clean)) {
      return [];
    }
    final cleanNorm =
        clean.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    final cleanHindiNorm = normalizeHindi(clean);

    // 1. Direct Alias Match (supports 549+ aliases like 'सूरह यासीन', 'yaseen', 'kursi', etc.)
    final aliasTarget = surahAliasesMap[clean.toLowerCase()] ??
        surahAliasesMap[cleanNorm] ??
        surahAliasesMap[cleanHindiNorm];

    if (aliasTarget != null && aliasTarget >= 1 && aliasTarget <= 114) {
      return [allSurahs[aliasTarget - 1]];
    }

    // 2. Direct Surah number match (e.g. "36")
    final numMatch = int.tryParse(cleanNorm);
    if (numMatch != null && numMatch >= 1 && numMatch <= 114) {
      return [allSurahs[numMatch - 1]];
    }

    // 3. Multi-field search across English, Hindi, Arabic, Meaning
    final lowerQ = clean.toLowerCase();
    final results = <Surah>[];

    for (final s in allSurahs) {
      final sHindiNorm = normalizeHindi(s.nameHi);
      final sEnNorm =
          s.nameEn.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

      if (s.nameEn.toLowerCase().contains(lowerQ) ||
          sEnNorm.contains(cleanNorm) ||
          s.nameHi.contains(clean) ||
          sHindiNorm.contains(cleanHindiNorm) ||
          s.nameAr.contains(clean) ||
          s.meaning.toLowerCase().contains(lowerQ)) {
        results.add(s);
      }
    }

    return results;
  }
}
