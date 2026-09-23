import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../data/quran_data.dart';
import '../data/surah_aliases.dart';
import '../models/surah.dart';

class VoiceSearchService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;

  bool get isAvailable => _isAvailable;
  bool get isListening => _speech.isListening;

  Future<bool> init() async {
    try {
      _isAvailable = await _speech.initialize(
        onError: (val) => debugPrint('[Speech] Error: $val'),
        onStatus: (val) => debugPrint('[Speech] Status: $val'),
      );
      return _isAvailable;
    } catch (e) {
      debugPrint('[Speech] Init error: $e');
      return false;
    }
  }

  Future<void> startListening({
    required Function(String spokenText, List<Surah> matchedSurahs) onResult,
    String localeId = 'hi_IN', // Default to Hindi, also supports 'ur_PK', 'en_US'
  }) async {
    if (!_isAvailable) {
      final ok = await init();
      if (!ok) return;
    }

    await _speech.listen(
      localeId: localeId,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      onResult: (result) {
        final words = result.recognizedWords;
        final matches = searchSurahs(words);
        onResult(words, matches);
      },
    );
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  List<Surah> searchSurahs(String query) {
    final raw = query.trim();
    if (raw.isEmpty) return [];

    final clean = cleanSurahPrefix(raw);
    final cleanNorm = clean.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
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
      final sEnNorm = s.nameEn.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

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

