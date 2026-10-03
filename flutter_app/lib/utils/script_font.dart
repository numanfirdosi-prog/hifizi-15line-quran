import 'package:flutter/material.dart';

/// Maps a script-style preference to the bundled Arabic font family.
/// Both fonts are bundled in assets/fonts (OFL licensed) so the style
/// renders identically on every device, online or offline.
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
  return TextStyle(
    fontFamily: arabicFontFamily(scriptStyle),
    fontSize: fontSize * scale,
    color: color,
    fontWeight: fontWeight,
    height: height,
  );
}
