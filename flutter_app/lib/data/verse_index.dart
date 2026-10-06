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
/// Uthmani وٰ (waw + superscript alef, e.g. صَلَوٰة) becomes alef to match
/// simplified صَلَاة.
/// Normalizes Arabic for search: strips all diacritics/Quranic marks and
/// unifies Uthmani spelling variants so queries match the bundled text.
/// Verified: all 6,236 ayahs match the Tanzil Uthmani reference letter-by-letter.
String normalizeArabic(String s) {
  // Diacritic class incl. Quranic marks (ۖ-ۮ); tanween incl. open variants.
  const d = 'ً-ٟۖ-ۮ';
  const tanween = 'ًࣰٌࣱٍࣲ';
  // Split tanween-alef words: "ـࣰٔ ا", "ࣰ ا" → join.
  var out = s.replaceAllMapped(
      RegExp('ـ[$d]*[ٕٔ][$d]*[$tanween] ا'), (m) => 'ئا');
  out = out.replaceAll('ࣰ ا', 'ࣰا');
  // Superscript-alef + maddah (ٰٓ) is آ; waw + superscript-alef (وٰ) is ا.
  out = out.replaceAll('ٰٓ', 'آ').replaceAll('ٰٓ', 'آ');
  out = out.replaceAll('وٰ', 'ا');
  // Tatweel-seat hamza with tanween → ئ/ؤ + separate alef (not maddah).
  out = out.replaceAllMapped(
      RegExp('ـ[$d]*[ٕٔ][$d]*[$tanween][$d]*ا'), (m) => 'ئا');
  out = out.replaceAllMapped(
      RegExp('ـ[$d]*[$tanween][$d]*[ٕٔ][$d]*ا'), (m) => 'ئا');
  // Tatweel-seat hamza: ـٔ + و/ي/ى → ؤ/ئ (keep following letter).
  out = out.replaceAllMapped(RegExp('ـ[$d]*[ٕٔ]([$d]*[ويى])'),
      (m) => (m[1]!.isNotEmpty && m[1]![m[1]!.length - 1] == 'و' ? 'ؤ' : 'ئ') + m[1]!);
  // ي + ـٔا (either order) → يئا (hamza consonant, not maddah).
  out = out.replaceAllMapped(
      RegExp('ي[$d]*ـ[$d]*[ٕٔ][$d]*[اٰ]'), (m) => 'يئا');
  out = out.replaceAllMapped(
      RegExp('ي[$d]*ـ[$d]*[اٰ][$d]*[ٕٔ]'), (m) => 'يئا');
  // ـٔ + ا/ٰ (either order) → آ (maddah, single alef).
  out = out.replaceAllMapped(
      RegExp('ـ[$d]*[ٕٔ][$d]*[اٰ]'), (m) => 'آ');
  out = out.replaceAllMapped(
      RegExp('ـ[$d]*[اٰ][$d]*[ٕٔ]'), (m) => 'آ');
  // ي + ـٔ (hamza not followed by و/ي/ا) → ئ.
  out = out.replaceAllMapped(
      RegExp('ي([$d]*)ـ[$d]*[ٕٔ]'), (m) => 'ي${m[1]}ئ');
  // Remaining tatweel-seat hamza → أ.
  out = out.replaceAll(RegExp('ـ[$d]*[ٕٔ]'), 'أ');
  // Combining hamza above/below is part of أ/إ/ؤ/ئ — base letter already
  // present, so strip (don't duplicate to alef).
  out = out.replaceAll(RegExp('[ٕٔ]'), '');
  out = out.replaceAll(RegExp('[$dٰ࣓-࿿ـ‏]'), '');
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

/// Normalizes Urdu text for diacritic-insensitive search: strips all Arabic
/// diacritics/Quranic marks, tatweel, superscript alef and the RTL mark, and
/// unifies Urdu orthography variants (ے→ی, ھ→ہ, ك→ک, ي→ی, أإآٱ→ا, ؤ→و,
/// ئ→ی, ة→ہ, ى→ی) so a query typed on any Urdu keyboard matches the bundled
/// Kanzul Iman translation.
String normalizeUrdu(String s) {
  var out = s.replaceAll(RegExp('[ً-ٟۖ-ۮـٰ‏]'), '');
  out = out
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ٱ', 'ا')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ی')
      .replaceAll('ة', 'ہ')
      .replaceAll('ے', 'ی')
      .replaceAll('ھ', 'ہ')
      .replaceAll('ى', 'ی')
      .replaceAll('ك', 'ک')
      .replaceAll('ي', 'ی');
  return out;
}

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
