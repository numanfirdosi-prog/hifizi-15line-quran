import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Maps a script-style preference to the Arabic font family to use.
String arabicFontFamily(String scriptStyle) =>
    scriptStyle == 'uthmani' ? 'Amiri Quran' : 'Gulzar';

/// Arabic text style for the given script style, scaled by [scale].
TextStyle arabicStyle(
  String scriptStyle, {
  double fontSize = 24,
  Color color = Colors.white,
  double scale = 1.0,
  FontWeight fontWeight = FontWeight.normal,
  double? height,
}) {
  return GoogleFonts.getFont(
    arabicFontFamily(scriptStyle),
    fontSize: fontSize * scale,
    color: color,
    fontWeight: fontWeight,
    height: height,
  );
}
