import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'services/azan_alarm_service.dart';
import 'services/preferences_service.dart';
import 'services/audio_recitation_service.dart';
import 'services/qari_download_service.dart';
import 'services/page_drawing_service.dart';
import 'services/nur_audio_handler.dart';
import 'services/deep_link_service.dart';
import 'views/splash_screen.dart';

/// Premium design tokens for Nur-ul-Quran: deep green + gold identity.
///
/// Every theme in [buildTheme] is re-based on these tokens so the brand
/// stays consistent across Night Slate, Emerald Day and Antique Parchment.
/// Gold is reserved for important actions, selected states, progress and
/// meaningful accents — never decoration.
abstract final class Nur {
  // Brand greens — re-based to the premium prompt palette (v1.0.91 redesign).
  // Deep Emerald #064E3B is the primary brand green; Dark Emerald #033B2D
  // is the deepest surface. Night Slate keeps its signature deep-green
  // identity — these are a subtle refinement, not a recolor.
  static const Color deepGreen = Color(0xFF064E3B); // primary deep emerald
  static const Color darkEmerald = Color(0xFF033B2D); // deepest emerald
  static const Color green = Color(0xFF0A5C46); // secondary green
  static const Color cardGreen = Color(0xFF0C4A38); // card green
  static const Color elevatedGreen = Color(0xFF10563F); // elevated green

  // Brand golds — Premium Gold #D4AF37, Soft Gold #E8D29A.
  // Gold is reserved for important actions, selected states, progress and
  // meaningful accents — never decoration, never pale gold on white.
  static const Color gold = Color(0xFFD4AF37); // primary premium gold
  static const Color softGold = Color(0xFFE8D29A); // soft gold highlight
  static const Color goldDeep = Color(0xFFB8963A); // secondary gold

  // Premium neutrals (prompt palette).
  static const Color ivory = Color(0xFFFFFDF5); // warm ivory light surface
  static const Color navy = Color(0xFF101B35); // dark navy
  static const Color darkSurface = Color(0xFF121A1A); // dark surface

  // Text on dark greens
  static const Color ink = Color(0xFFF7F5EC); // primary text
  static const Color sage = Color(0xFFB8C8C0); // secondary text
  static const Color muted = Color(0xFF849A90); // muted text

  // Light-theme ink
  static const Color inkDark = Color(0xFF0E2E23); // text on light greens
  static const Color inkWarm = Color(0xFF3A2C12); // text on parchment

  // Accessible error reds (AA on their backgrounds)
  static const Color errorDark = Color(0xFFE57373);
  static const Color errorLight = Color(0xFFB3261E);

  // ---- Spacing scale (single source of truth) ----
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double screenMargin = 16; // default horizontal screen margin

  // ---- Radii ----
  static const double cardRadius = 16;
  static const double buttonRadius = 12;
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusSheet = 24; // bottom-sheet top corners

  // ---- Control sizes ----
  static const double buttonHeight = 48; // min touch-friendly button height
  static const double iconSize = 24; // standard icon size
  static const double iconSizeSm = 20;
  static const double iconSizeLg = 28;
  static const double minTouchTarget = 48; // min tap target (a11y)

  // ---- Elevation / shadows (restrained, no heavy shadows) ----
  static const double elevationCard = 0; // flat cards with hairline borders
  static const double elevationSheet = 8;
  static const double elevationDialog = 12;

  // ---- Typography scale (English/labels; Arabic/Urdu via script_font.dart) ----
  static const double fontTitle = 18;
  static const double fontBody = 14;
  static const double fontCaption = 12;
  static const double fontSmall = 11;

  /// Subtle translucent gold border for premium cards on dark greens.
  static Color goldBorder([double alpha = 0.22]) =>
      gold.withValues(alpha: alpha);

  /// Subtle translucent green border for premium cards on light surfaces.
  static Color greenBorder([double alpha = 0.30]) =>
      deepGreen.withValues(alpha: alpha);
}

/// App theme palettes, switchable live from Preferences (themeName:
/// 'night' | 'emerald' | 'parchment' | 'modern'). Theme changes apply immediately
/// (Consumer rebuild in [NurAlQuranApp]) and persist via
/// PreferencesService ('nur_theme_name').
ThemeData buildTheme(String name) {
  switch (name) {
    case 'emerald':
      return _emeraldTheme();
    case 'parchment':
      return _parchmentTheme();
    case 'modern':
      return _modernTheme();
    case 'night':
    default:
      return _nightTheme();
  }
}

// ---------------------------------------------------------------------------
// Night Slate — deep green + gold (the signature premium theme).
// ---------------------------------------------------------------------------
ThemeData _nightTheme() {
  const cs = ColorScheme.dark(
    primary: Nur.gold,
    onPrimary: Nur.deepGreen,
    secondary: Nur.goldDeep,
    onSecondary: Nur.deepGreen,
    tertiary: Nur.elevatedGreen,
    onTertiary: Nur.ink,
    surface: Nur.cardGreen,
    onSurface: Nur.ink,
    surfaceContainerHighest: Nur.elevatedGreen,
    outline: Color(0xFF2E5B49),
    outlineVariant: Color(0xFF24493B),
    error: Nur.errorDark,
    onError: Nur.deepGreen,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Nur.deepGreen,
    colorScheme: cs,
    hintColor: Nur.muted,
    dividerColor: const Color(0xFF285344),
    cardTheme: CardThemeData(
      color: Nur.cardGreen,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Nur.cardRadius),
        side: BorderSide(color: Nur.goldBorder(0.18)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Nur.deepGreen,
      foregroundColor: Nur.ink,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: Nur.gold),
      titleTextStyle: TextStyle(
        color: Nur.ink,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Nur.gold,
        foregroundColor: Nur.deepGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Nur.buttonRadius),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Nur.gold,
        foregroundColor: Nur.deepGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Nur.buttonRadius),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Nur.gold,
        side: BorderSide(color: Nur.goldBorder(0.55)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Nur.buttonRadius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Nur.gold),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Nur.ink.withValues(alpha: 0.06),
      hintStyle: const TextStyle(color: Nur.muted),
      prefixIconColor: Nur.gold,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Nur.goldBorder(0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Nur.gold, width: 1.5),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? Nur.gold : Nur.sage),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? Nur.gold.withValues(alpha: 0.35)
              : Nur.elevatedGreen),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: Nur.gold,
      inactiveTrackColor: Color(0xFF2E5B49),
      thumbColor: Nur.gold,
      overlayColor: Color(0x33E7C547),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Nur.gold,
      linearTrackColor: Color(0xFF2E5B49),
    ),
    chipTheme: const ChipThemeData(
      selectedColor: Nur.gold,
      backgroundColor: Nur.elevatedGreen,
      labelStyle: TextStyle(color: Nur.ink, fontSize: 12),
      secondaryLabelStyle: TextStyle(
          color: Nur.deepGreen, fontSize: 12, fontWeight: FontWeight.bold),
      side: BorderSide(color: Color(0xFF2E5B49)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Nur.cardGreen,
      titleTextStyle: TextStyle(
          color: Nur.ink, fontSize: 18, fontWeight: FontWeight.bold),
      contentTextStyle: TextStyle(color: Nur.sage, fontSize: 14),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Nur.cardGreen,
      modalBackgroundColor: Nur.cardGreen,
      elevation: Nur.elevationSheet,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(Nur.radiusSheet)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Nur.deepGreen,
      indicatorColor: Nur.gold.withValues(alpha: 0.20),
      iconTheme: WidgetStateProperty.resolveWith((states) =>
          IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? Nur.gold
                  : Nur.sage)),
      labelTextStyle: WidgetStateProperty.resolveWith((states) =>
          TextStyle(
              color: states.contains(WidgetState.selected)
                  ? Nur.gold
                  : Nur.sage,
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.bold
                  : FontWeight.normal)),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Nur.elevatedGreen,
      contentTextStyle: TextStyle(color: Nur.ink),
      actionTextColor: Nur.gold,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: Nur.gold,
      textColor: Nur.ink,
    ),
    textTheme: const TextTheme(
      // Legible English defaults; Arabic/Urdu use the bundled fonts via
      // arabicStyle()/urduStyle() in utils/script_font.dart.
      bodyLarge: TextStyle(color: Nur.ink, height: 1.5),
      bodyMedium: TextStyle(color: Nur.sage, height: 1.5),
      bodySmall: TextStyle(color: Nur.muted, height: 1.5),
      titleLarge: TextStyle(
          color: Nur.ink, fontWeight: FontWeight.bold, height: 1.3),
      titleMedium: TextStyle(
          color: Nur.ink, fontWeight: FontWeight.w600, height: 1.3),
      titleSmall: TextStyle(
          color: Nur.gold, fontWeight: FontWeight.bold, height: 1.3),
      labelLarge: TextStyle(
          color: Nur.deepGreen, fontWeight: FontWeight.bold),
    ),
  );
}

// ---------------------------------------------------------------------------
// Emerald Day — light mint sanctuary; actions in deep green, gold accents.
// ---------------------------------------------------------------------------
ThemeData _emeraldTheme() {
  const cs = ColorScheme.light(
    primary: Nur.deepGreen,
    onPrimary: Nur.ink,
    secondary: Nur.goldDeep,
    onSecondary: Nur.deepGreen,
    tertiary: Color(0xFFDDE9DE),
    surface: Color(0xFFFDFEFB),
    onSurface: Nur.inkDark,
    surfaceContainerHighest: Color(0xFFE7EFE8),
    outline: Color(0xFFB9CDBF),
    outlineVariant: Color(0xFFD4E2D6),
    error: Nur.errorLight,
    onError: Nur.ink,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFE9F1EB),
    colorScheme: cs,
    hintColor: const Color(0xFF6E857A),
    dividerColor: const Color(0xFFCBDCCF),
    cardTheme: CardThemeData(
      color: const Color(0xFFFDFEFB),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Nur.cardRadius),
        side: BorderSide(color: Nur.greenBorder(0.28)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Nur.deepGreen,
      foregroundColor: Nur.ink,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: Nur.gold),
      titleTextStyle: TextStyle(
        color: Nur.ink,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Nur.deepGreen,
        foregroundColor: Nur.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Nur.buttonRadius),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Nur.deepGreen,
        foregroundColor: Nur.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Nur.buttonRadius),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Nur.deepGreen,
        side: BorderSide(color: Nur.greenBorder(0.6)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Nur.buttonRadius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Nur.deepGreen),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Nur.deepGreen.withValues(alpha: 0.05),
      hintStyle: const TextStyle(color: Color(0xFF6E857A)),
      prefixIconColor: Nur.deepGreen,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Nur.greenBorder(0.35)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Nur.deepGreen, width: 1.5),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? Nur.deepGreen
              : const Color(0xFF9DB3A7)),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? Nur.goldDeep.withValues(alpha: 0.5)
              : const Color(0xFFD4E2D6)),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: Nur.deepGreen,
      inactiveTrackColor: Color(0xFFD4E2D6),
      thumbColor: Nur.deepGreen,
      overlayColor: Color(0x220B3027),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Nur.goldDeep,
      linearTrackColor: Color(0xFFD4E2D6),
    ),
    chipTheme: const ChipThemeData(
      selectedColor: Nur.deepGreen,
      backgroundColor: Color(0xFFE7EFE8),
      labelStyle: TextStyle(color: Nur.inkDark, fontSize: 12),
      secondaryLabelStyle: TextStyle(
          color: Nur.ink, fontSize: 12, fontWeight: FontWeight.bold),
      side: BorderSide(color: Color(0xFFB9CDBF)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Color(0xFFFDFEFB),
      titleTextStyle: TextStyle(
          color: Nur.inkDark, fontSize: 18, fontWeight: FontWeight.bold),
      contentTextStyle: TextStyle(color: Color(0xFF41564C), fontSize: 14),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Nur.ivory,
      modalBackgroundColor: Nur.ivory,
      elevation: Nur.elevationSheet,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(Nur.radiusSheet)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFFE9F1EB),
      indicatorColor: Nur.deepGreen.withValues(alpha: 0.12),
      iconTheme: WidgetStateProperty.resolveWith((states) =>
          IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? Nur.deepGreen
                  : const Color(0xFF6E857A))),
      labelTextStyle: WidgetStateProperty.resolveWith((states) =>
          TextStyle(
              color: states.contains(WidgetState.selected)
                  ? Nur.deepGreen
                  : const Color(0xFF6E857A),
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.bold
                  : FontWeight.normal)),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Nur.deepGreen,
      contentTextStyle: TextStyle(color: Nur.ink),
      actionTextColor: Nur.gold,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: Nur.deepGreen,
      textColor: Nur.inkDark,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Nur.inkDark, height: 1.5),
      bodyMedium: TextStyle(color: Color(0xFF41564C), height: 1.5),
      bodySmall: TextStyle(color: Color(0xFF6E857A), height: 1.5),
      titleLarge: TextStyle(
          color: Nur.inkDark, fontWeight: FontWeight.bold, height: 1.3),
      titleMedium: TextStyle(
          color: Nur.inkDark, fontWeight: FontWeight.w600, height: 1.3),
      titleSmall: TextStyle(
          color: Nur.deepGreen, fontWeight: FontWeight.bold, height: 1.3),
      labelLarge: TextStyle(
          color: Nur.ink, fontWeight: FontWeight.bold),
    ),
  );
}

// ---------------------------------------------------------------------------
// Antique Parchment — warm sepia manuscript; actions in bronze, gold accents.
// ---------------------------------------------------------------------------
ThemeData _parchmentTheme() {
  const bronze = Color(0xFF7C5A1E);
  const cs = ColorScheme.light(
    primary: bronze,
    onPrimary: Color(0xFFFFF6DC),
    secondary: Nur.goldDeep,
    onSecondary: Color(0xFF3A2C12),
    tertiary: Color(0xFFEFE0B8),
    surface: Color(0xFFFFF9E8),
    onSurface: Nur.inkWarm,
    surfaceContainerHighest: Color(0xFFF3E7C4),
    outline: Color(0xFFD8C49A),
    outlineVariant: Color(0xFFE6D5AC),
    error: Nur.errorLight,
    onError: Color(0xFFFFF6DC),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF3E6C3),
    colorScheme: cs,
    hintColor: const Color(0xFF8A7350),
    dividerColor: const Color(0xFFDCC9A2),
    cardTheme: CardThemeData(
      color: const Color(0xFFFFF9E8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Nur.cardRadius),
        side: const BorderSide(color: Color(0xFFD8C49A)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bronze,
      foregroundColor: Color(0xFFFFF4D9),
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: Nur.gold),
      titleTextStyle: TextStyle(
        color: Color(0xFFFFF4D9),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: bronze,
        foregroundColor: const Color(0xFFFFF6DC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Nur.buttonRadius),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: bronze,
        foregroundColor: const Color(0xFFFFF6DC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Nur.buttonRadius),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: bronze,
        side: const BorderSide(color: Color(0xFFB99B5F)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Nur.buttonRadius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: bronze),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bronze.withValues(alpha: 0.06),
      hintStyle: const TextStyle(color: Color(0xFF8A7350)),
      prefixIconColor: bronze,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD8C49A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: bronze, width: 1.5),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? bronze
              : const Color(0xFFB39B6D)),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? Nur.goldDeep.withValues(alpha: 0.5)
              : const Color(0xFFE6D5AC)),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: bronze,
      inactiveTrackColor: Color(0xFFE6D5AC),
      thumbColor: bronze,
      overlayColor: Color(0x227C5A1E),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Nur.goldDeep,
      linearTrackColor: Color(0xFFE6D5AC),
    ),
    chipTheme: const ChipThemeData(
      selectedColor: bronze,
      backgroundColor: Color(0xFFF3E7C4),
      labelStyle: TextStyle(color: Nur.inkWarm, fontSize: 12),
      secondaryLabelStyle: TextStyle(
          color: Color(0xFFFFF6DC),
          fontSize: 12,
          fontWeight: FontWeight.bold),
      side: BorderSide(color: Color(0xFFD8C49A)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Color(0xFFFFF9E8),
      titleTextStyle: TextStyle(
          color: Nur.inkWarm, fontSize: 18, fontWeight: FontWeight.bold),
      contentTextStyle: TextStyle(color: Color(0xFF6B5636), fontSize: 14),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: const Color(0xFFFFF9E8),
      modalBackgroundColor: const Color(0xFFFFF9E8),
      elevation: Nur.elevationSheet,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(Nur.radiusSheet)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFFF3E6C3),
      indicatorColor: bronze.withValues(alpha: 0.12),
      iconTheme: WidgetStateProperty.resolveWith((states) =>
          IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? bronze
                  : const Color(0xFF8A7350))),
      labelTextStyle: WidgetStateProperty.resolveWith((states) =>
          TextStyle(
              color: states.contains(WidgetState.selected)
                  ? bronze
                  : const Color(0xFF8A7350),
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.bold
                  : FontWeight.normal)),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: bronze,
      contentTextStyle: TextStyle(color: Color(0xFFFFF6DC)),
      actionTextColor: Nur.gold,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: bronze,
      textColor: Nur.inkWarm,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Nur.inkWarm, height: 1.5),
      bodyMedium: TextStyle(color: Color(0xFF6B5636), height: 1.5),
      bodySmall: TextStyle(color: Color(0xFF8A7350), height: 1.5),
      titleLarge: TextStyle(
          color: Nur.inkWarm, fontWeight: FontWeight.bold, height: 1.3),
      titleMedium: TextStyle(
          color: Nur.inkWarm, fontWeight: FontWeight.w600, height: 1.3),
      titleSmall: TextStyle(
          color: bronze, fontWeight: FontWeight.bold, height: 1.3),
      labelLarge: TextStyle(
          color: Color(0xFFFFF6DC), fontWeight: FontWeight.bold),
    ),
  );
}

// ---------------------------------------------------------------------------
// Modern Teal — contemporary glassmorphic aesthetic; vibrant teal, soft mint
// background, crisp translucent white cards and elegant accents.
// ---------------------------------------------------------------------------
ThemeData _modernTheme() {
  const modernTeal = Color(0xFF0C7B70);
  const modernTealDark = Color(0xFF08544D);
  const modernTealAccent = Color(0xFF26A69A);
  const modernScaffold = Color(0xFFE4F3EF);
  const modernSurface = Color(0xFFFFFFFF);
  const modernInk = Color(0xFF0F3B35);
  const modernMuted = Color(0xFF5A7B76);

  const cs = ColorScheme.light(
    primary: modernTeal,
    onPrimary: Colors.white,
    secondary: modernTealAccent,
    onSecondary: Colors.white,
    tertiary: Color(0xFFD4EFE8),
    surface: modernSurface,
    onSurface: modernInk,
    surfaceContainerHighest: Color(0xFFE2F1ED),
    outline: Color(0xFFB0D8CF),
    outlineVariant: Color(0xFFCCE8E1),
    error: Nur.errorLight,
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: modernScaffold,
    colorScheme: cs,
    hintColor: modernMuted,
    dividerColor: const Color(0xFFCCE4DD),
    cardTheme: CardThemeData(
      color: modernSurface,
      elevation: 0,
      shadowColor: modernTeal.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Nur.cardRadius),
        side: BorderSide(color: modernTeal.withValues(alpha: 0.18)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: modernTeal,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: modernTeal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Nur.buttonRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: modernTeal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Nur.buttonRadius),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: modernTeal,
        side: const BorderSide(color: modernTeal),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Nur.buttonRadius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: modernTeal),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: modernMuted),
      prefixIconColor: modernTeal,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: modernTeal.withValues(alpha: 0.22)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: modernTeal, width: 1.5),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? modernTeal
              : const Color(0xFF90ABA4)),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? modernTeal.withValues(alpha: 0.45)
              : const Color(0xFFD0E6E0)),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: modernTeal,
      inactiveTrackColor: Color(0xFFCCE8E1),
      thumbColor: modernTeal,
      overlayColor: Color(0x220C7B70),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: modernTeal,
      linearTrackColor: Color(0xFFCCE8E1),
    ),
    chipTheme: const ChipThemeData(
      selectedColor: modernTeal,
      backgroundColor: Color(0xFFE2F1ED),
      labelStyle: TextStyle(color: modernInk, fontSize: 12),
      secondaryLabelStyle: TextStyle(
          color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      side: BorderSide(color: Color(0xFFB0D8CF)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: modernSurface,
      titleTextStyle: TextStyle(
          color: modernInk, fontSize: 18, fontWeight: FontWeight.bold),
      contentTextStyle: TextStyle(color: modernMuted, fontSize: 14),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: modernSurface,
      modalBackgroundColor: modernSurface,
      elevation: Nur.elevationSheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(Nur.radiusSheet)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFFF3FBF8),
      indicatorColor: modernTeal.withValues(alpha: 0.18),
      iconTheme: WidgetStateProperty.resolveWith((states) =>
          IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? modernTeal
                  : modernMuted)),
      labelTextStyle: WidgetStateProperty.resolveWith((states) =>
          TextStyle(
              color: states.contains(WidgetState.selected)
                  ? modernTeal
                  : modernMuted,
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.bold
                  : FontWeight.normal)),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: modernTealDark,
      contentTextStyle: TextStyle(color: Colors.white),
      actionTextColor: Nur.gold,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: modernTeal,
      textColor: modernInk,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: modernInk, height: 1.5),
      bodyMedium: TextStyle(color: Color(0xFF335C55), height: 1.5),
      bodySmall: TextStyle(color: modernMuted, height: 1.5),
      titleLarge: TextStyle(
          color: modernInk, fontWeight: FontWeight.bold, height: 1.3),
      titleMedium: TextStyle(
          color: modernInk, fontWeight: FontWeight.w600, height: 1.3),
      titleSmall: TextStyle(
          color: modernTeal, fontWeight: FontWeight.bold, height: 1.3),
      labelLarge: TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // IANA timezone database — required for daylight-saving-correct prayer
  // times (M5) and scheduled notifications.
  tzdata.initializeTimeZones();

  // Initialize Core Services
  final preferencesService = PreferencesService();
  await preferencesService.init();

  // Audio service is created up-front so the background-audio bridge and
  // deep-link handler can attach to the same instance.
  final audioService = AudioRecitationService();

  // Page drawing service: loads persisted highlighter/pen strokes.
  final pageDrawingService = PageDrawingService();
  await pageDrawingService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<PreferencesService>.value(
            value: preferencesService),
        ChangeNotifierProvider<AudioRecitationService>.value(
            value: audioService),
        ChangeNotifierProvider<QariDownloadService>(
            create: (_) => QariDownloadService()),
        ChangeNotifierProvider<PageDrawingService>.value(
            value: pageDrawingService),
      ],
      child: const NurAlQuranApp(),
    ),
  );

  // Best-effort background services: guarded internally, never block or
  // crash startup, and the app works fully without them.
  initBackgroundAudio(audioService);
  DeepLinkService.init();
}

class NurAlQuranApp extends StatefulWidget {
  const NurAlQuranApp({Key? key}) : super(key: key);

  @override
  State<NurAlQuranApp> createState() => _NurAlQuranAppState();
}

class _NurAlQuranAppState extends State<NurAlQuranApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Background Playback toggle: when disabled, pause recitation as soon
    // as the app leaves the foreground.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      final prefs = Provider.of<PreferencesService>(context, listen: false);
      final audio = Provider.of<AudioRecitationService>(context, listen: false);
      if (!prefs.backgroundPlaybackEnabled && audio.isPlaying) {
        audio.pause();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild MaterialApp whenever the theme preference changes so the
    // palette applies live without restarting the app. The preference is
    // persisted in SharedPreferences ('nur_theme_name') inside
    // PreferencesService.setThemeName.
    return Consumer<PreferencesService>(
      builder: (context, prefs, _) {
        return MaterialApp(
          title: 'نور القرآن (Nur-ul-Quran)',
          debugShowCheckedModeBanner: false,
          navigatorKey: appNavigatorKey,
          theme: buildTheme(prefs.themeName),
          home: const SplashScreen(),
        );
      },
    );
  }
}
