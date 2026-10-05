import 'dart:convert';
import 'package:flutter/services.dart';

import '../utils/script_font.dart';

/// Pure helpers for the 15-line mushaf verse index and Quran text data.

/// Builds 's:v' -> page number from the decoded page_ayahs_15lines.json map.
/// Page keys are page-number strings; values are lists of maps with 'verseKey'.
Map<String, int> buildVersePageIndex(Map<String, dynamic> pageAyahs) {
  final index = <String, int>{};
  pageAyahs.forEach((pageKey, entries) {
    final page = int.tryParse(pageKey);
    if (page == null || entries is! List) return;
    for (final entry in entries) {
      if (entry is Map<String, dynamic>) {
        final verseKey = entry['verseKey'];
        if (verseKey is String && verseKey.isNotEmpty) {
          index[verseKey] = page;
        }
      }
    }
  });
  return index;
}

/// Builds page number -> first 's:v' on that page (skips empty pages).
Map<int, String> buildPageFirstVerseIndex(Map<String, dynamic> pageAyahs) {
  final index = <int, String>{};
  pageAyahs.forEach((pageKey, entries) {
    final page = int.tryParse(pageKey);
    if (page == null || entries is! List || entries.isEmpty) return;
    final first = entries.first;
    if (first is Map<String, dynamic>) {
      final verseKey = first['verseKey'];
      if (verseKey is String && verseKey.isNotEmpty) {
        index[page] = verseKey;
      }
    }
  });
  return index;
}

/// Loads the raw page->ayahs map from the bundled asset.
Future<Map<String, dynamic>> loadPageAyahsJson() async {
  final raw =
      await rootBundle.loadString('assets/data/page_ayahs_15lines.json');
  return jsonDecode(raw) as Map<String, dynamic>;
}

Future<Map<String, int>> loadVersePageIndex() async =>
    buildVersePageIndex(await loadPageAyahsJson());

Future<Map<int, String>> loadPageFirstVerseIndex() async =>
    buildPageFirstVerseIndex(await loadPageAyahsJson());

/// Strips ALL Arabic diacritics — basic harakat (U+064B..U+065F), superscript
/// alef (U+0670), Quranic marks (U+06D6..U+06ED, U+08D3..U+08FF), tatweel
/// (U+0640) and the RTL mark (U+200F) — and normalizes alef/hamza variants,
/// for diacritic-insensitive search. The bundled Quran text uses Quranic
/// Unicode marks (e.g. ۡ U+06E1, ٓ U+0653) that the basic harakat range
/// missed, causing valid verses to return 0 results. Hamza-above/below
/// (U+0654/U+0655, e.g. in ـٔ) become alef so they match أ/إ/آ in queries.
String normalizeArabic(String s) {
  var out = s.replaceAll('ٔ', 'ا').replaceAll('ٕ', 'ا');
  out = out.replaceAll(RegExp('[ً-ٰٟۖ-ۭ࣓-࿿ـ‏]'), '');
  out = out
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ٱ', 'ا')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي');
  return out;
}

/// Lenient variant for search fallback: additionally strips alef so
/// Uthmani spellings (فَسْأَلُوا) match simplified queries (فَاسْأَلُوا).
String normalizeArabicLenient(String s) =>
    normalizeArabic(s).replaceAll('ا', '');

class QuranTextEntry {
  final int s;
  final int v;
  final String ar;
  final String en;

  const QuranTextEntry({
    required this.s,
    required this.v,
    required this.ar,
    required this.en,
  });

  factory QuranTextEntry.fromJson(Map<String, dynamic> json) => QuranTextEntry(
        s: (json['s'] as num).toInt(),
        v: (json['v'] as num).toInt(),
        ar: normalizeArabicDisplay(json['ar'] as String),
        en: json['en'] as String,
      );
}

/// Loads the Urdu (Kanzul Iman, Ahmad Raza Khan) translation, keyed "s:v".
/// Returns an empty map if the asset is missing.
Future<Map<String, String>> loadUrduKanzulIman() async {
  try {
    final raw =
        await rootBundle.loadString('assets/data/quran_urdu_kanzuliman.json');
    final list = jsonDecode(raw) as List<dynamic>;
    final map = <String, String>{};
    for (final e in list) {
      final m = e as Map<String, dynamic>;
      map['${m['s']}:${m['v']}'] = m['ur'] as String;
    }
    return map;
  } catch (_) {
    return {};
  }
}

/// Loads the full Quran text (list of {s,v,ar,en}) from the bundled asset.
Future<List<QuranTextEntry>> loadQuranText() async {
  final raw = await rootBundle.loadString('assets/data/quran_text.json');
  final list = jsonDecode(raw) as List<dynamic>;
  return list
      .map((e) => QuranTextEntry.fromJson(e as Map<String, dynamic>))
      .toList();
}
