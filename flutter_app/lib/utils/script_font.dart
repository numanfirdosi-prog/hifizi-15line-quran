import 'package:flutter/material.dart';

/// Maps a script-style preference to the bundled Arabic font family.
/// Both fonts are bundled in assets/fonts (OFL licensed) so the style
/// renders identically on every device, online or offline.
String arabicFontFamily(String scriptStyle) =>
    scriptStyle == 'uthmani' ? 'Amiri Quran' : 'Noto Sans Arabic';

/// Display-layer normalization for Quranic Arabic text.
///
/// The bundled Quran text marks sukun with U+06E1 (ARABIC SMALL HIGH
/// DOTLESS HEAD OF KHAH). U+06E1 has Unicode joining type "U"
/// (non-joining), so the text shaper breaks cursive joining around it and
/// letters render isolated/disconnected ("harf alag alag"). Replacing it
/// with the standard U+0652 ARABIC SUKUN (joining type "T", transparent)
/// restores correct joining. This only affects rendering — the data files
/// stay untouched and the meaning is identical.
String normalizeArabicDisplay(String text) =>
    text.replaceAll('\u06E1', '\u0652');

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
