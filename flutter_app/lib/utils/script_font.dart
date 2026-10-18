import 'package:flutter/material.dart';

/// Maps a script-style preference to the bundled Arabic font family.
/// Fonts are bundled in assets/fonts so the style renders identically on
/// every device, online or offline.
/// 'kfgqpc' / 'uthmani': Authentic Madinah Quran script (KFGQPC Uthmanic)
/// 'amiri': Classical calligraphic Naskh (Amiri Quran)
/// 'sans': Modern plain Arabic (Noto Sans Arabic)
String arabicFontFamily(String scriptStyle) {
  switch (scriptStyle) {
    case 'sans':
      return 'Noto Sans Arabic';
    case 'amiri':
      return 'Amiri Quran';
    case 'kfgqpc':
    case 'uthmani':
    default:
      return 'KFGQPC Uthmanic';
  }
}

/// Display-layer normalization for Quranic Arabic text.
///
/// Fixes decomposed Unicode codepoints (alef/waw/ya + isolated combining hamza),
/// false ya-hamza-below (e.g. An-Nahl 16:90), inverted tatweel marks, and
/// non-joining Quranic sukun U+06E1 which break cursive joining ("harf alag alag")
/// in calligraphic fonts like KFGQPC Uthmanic Madinah.
const _splitTanweenMarks = 'ࣰًٌࣱٍ';

String normalizeArabicDisplay(String text) {
  var s = text;

  // 0. Map Open Tanween (U+08F0, U+08F1, U+08F2) which are missing in KFGQPC
  // and cause OS font fallback / glyph separation in calligraphic fonts
  s = s.replaceAll('\u08f0', '\u064b')
       .replaceAll('\u08f1', '\u064c')
       .replaceAll('\u08f2', '\u064d');

  // 1. False ya-hamza-below (e.g. 16:90 وَإِيتَاءِ instead of وَإِيتَآيِٕ)
  s = s.replaceAll('وَإِيتَآيِ', 'وَإِيتَاءِ')
       .replaceAll('وَإِيتَآيِ', 'وَإِيتَاءِ')
       .replaceAll('وَإِيتَآيِٕ', 'وَإِيتَاءِ')
       .replaceAll('إِيتَآيِ', 'إِيتَاءِ')
       .replaceAll('إِيتَآيِٕ', 'إِيتَاءِ');

  s = s.replaceAllMapped(
      RegExp(r'([اآءَُِٰۡٓ])ي[\u0650\u064e\u064f]?\u0655'),
      (m) => '${m[1]}ءِ');
  s = s.replaceAll(RegExp(r'ي[\u0650\u064e\u064f]?\u0655'), 'ئِ');
  s = s.replaceAll('ي\u0655', 'ئ');

  // 2. Decomposed Alef + Hamza Below (U+0655)
  s = s.replaceAll('\u0627\u0650\u0655', 'إِ');
  s = s.replaceAll('\u0627\u0655\u0650', 'إِ');
  s = s.replaceAll('\u0627\u0655', 'إ');

  // 3. Decomposed Alef + Hamza Above (U+0654)
  s = s.replaceAll('\u0627\u064e\u0654', 'أَ');
  s = s.replaceAll('\u0627\u0654\u064e', 'أَ');
  s = s.replaceAll('\u0627\u064f\u0654', 'أُ');
  s = s.replaceAll('\u0627\u0654\u064f', 'أُ');
  s = s.replaceAll('\u0627\u064b\u0654', 'أً');
  s = s.replaceAll('\u0627\u0654\u064b', 'أً');
  s = s.replaceAll('\u0627\u0654', 'أ');

  // 4. Decomposed Waw + Hamza
  s = s.replaceAll('\u0648\u064f\u0654', 'ؤُ');
  s = s.replaceAll('\u0648\u0654\u064f', 'ؤُ');
  s = s.replaceAll('\u0648\u064e\u0654', 'ؤَ');
  s = s.replaceAll('\u0648\u0654\u064e', 'ؤَ');
  s = s.replaceAll('\u0648\u06e1\u0654', 'ؤْ');
  s = s.replaceAll('\u0648\u0652\u0654', 'ؤْ');
  s = s.replaceAll('\u0648\u0654', 'ؤ');

  // 5. Decomposed Ya / Nabra + Hamza
  s = s.replaceAll('\u064a\u064e\u0654', 'ئَ');
  s = s.replaceAll('\u064a\u0654\u064e', 'ئَ');
  s = s.replaceAll('\u064a\u0650\u0654', 'ئِ');
  s = s.replaceAll('\u064a\u0654\u0650', 'ئِ');
  s = s.replaceAll('\u064a\u064f\u0654', 'ئُ');
  s = s.replaceAll('\u064a\u0654\u064f', 'ئُ');
  s = s.replaceAll('\u064a\u06e1\u0654', 'ئْ');
  s = s.replaceAll('\u064a\u0652\u0654', 'ئْ');
  s = s.replaceAll('\u064a\u0654', 'ئ');

  // 6. Tatweel order: \u0640 + harakah + \u0654 -> \u0640\u0654 + harakah
  s = s.replaceAllMapped(
      RegExp(r'(\u0640)([\u064e\u064f\u0650\u064b\u064c\u064d\u06e1\u0652])\u0654'),
      (m) => '${m[1]}\u0654${m[2]}');

  // 7. Sukun U+06E1 -> U+0652
  s = s.replaceAll('\u06e1', '\u0652');

  // 8. Split tanween before alef
  s = s.replaceAllMapped(
      RegExp('([$_splitTanweenMarks]) ا'), (m) => '${m[1]}ا');

  return s;
}

/// Dedicated Urdu text style using the bundled Noto Nastaliq Urdu font
/// (OFL licensed). Use for Urdu translations and Urdu UI text — never for
/// Quranic Arabic (use [arabicStyle] for that). Nastaliq needs generous
/// line height so glyphs are never clipped.
TextStyle urduStyle({
  double fontSize = 16,
  Color color = Colors.white,
  double scale = 1.0,
  FontWeight fontWeight = FontWeight.normal,
}) {
  return TextStyle(
    fontFamily: 'Noto Nastaliq Urdu',
    fontSize: fontSize * scale,
    color: color,
    fontWeight: fontWeight,
    height: 2.2,
  );
}

/// Arabic text style for the given script style, scaled by [scale].
TextStyle arabicStyle(
  String scriptStyle, {
  double fontSize = 24,
  Color color = Colors.white,
  double scale = 1.0,
  FontWeight fontWeight = FontWeight.normal,
  double? height,
}) {
  return TextStyle(
    fontFamily: arabicFontFamily(scriptStyle),
    fontSize: fontSize * scale,
    color: color,
    fontWeight: fontWeight,
    height: height,
  );
}
