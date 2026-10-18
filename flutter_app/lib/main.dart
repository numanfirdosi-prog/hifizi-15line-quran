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

/// Design tokens for Hafizi Quran & Tafsir.
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

/// App theme palettes from Image 1:
/// 1. Soft Green (Premium) — 'soft_green': Calm • Readable • Modern (#0E6848, #F4F8F5, #FFFFFF)
/// 2. Light Blue (Modern)  — 'light_blue': Fresh • Elegant • Premium (#0284C7, #F0F6FB, #FFFFFF)
/// 3. Royal Navy (Modern)  — 'royal_navy': Rich • Soft • Eye Friendly (#0B1324, #132035, #D4AF37)
ThemeData buildTheme(String name) {
  switch (name) {
    case 'light_blue':
      return _lightBlueTheme();
    case 'royal_navy':
      return _royalNavyTheme();
    case 'soft_green':
    default:
      return _softGreenTheme();
  }
}

// ---------------------------------------------------------------------------
// Theme 1: Soft Green (Premium) — Calm • Readable • Modern
// ---------------------------------------------------------------------------
ThemeData _softGreenTheme() {
  const primaryGreen = Color(0xFF0E6848);
  const secondaryGreen = Color(0xFF10B981);
  const bg = Color(0xFFF4F8F5);
  const surface = Color(0xFFFFFFFF);
  const containerHighest = Color(0xFFE8F3EE);
  const textDark = Color(0xFF16261E);
  const textMedium = Color(0xFF3E5147);
  const textMuted = Color(0xFF607369);
  const outline = Color(0xFFC7DCD2);
  const outlineVariant = Color(0xFFE2ECE7);

  const cs = ColorScheme.light(
    primary: primaryGreen,
    onPrimary: Colors.white,
    secondary: secondaryGreen,
    onSecondary: Colors.white,
    tertiary: primaryGreen,
    surface: surface,
    onSurface: textDark,
    surfaceContainerHighest: containerHighest,
    outline: outline,
    outlineVariant: outlineVariant,
    error: Color(0xFFB3261E),
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: bg,
    colorScheme: cs,
    hintColor: textMuted,
    dividerColor: outlineVariant,
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Nur.cardRadius),
        side: BorderSide(color: primaryGreen.withValues(alpha: 0.16)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryGreen,
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
        backgroundColor: primaryGreen,
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
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Nur.buttonRadius),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryGreen,
        side: const BorderSide(color: primaryGreen),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Nur.buttonRadius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primaryGreen),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      hintStyle: const TextStyle(color: textMuted),
      prefixIconColor: primaryGreen,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryGreen.withValues(alpha: 0.22)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: primaryGreen, width: 1.5),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? primaryGreen
              : const Color(0xFF88A89E)),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? secondaryGreen.withValues(alpha: 0.45)
              : const Color(0xFFD4E5DC)),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: primaryGreen,
      inactiveTrackColor: Color(0xFFD4E5DC),
      thumbColor: primaryGreen,
      overlayColor: Color(0x220E6848),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryGreen,
      linearTrackColor: Color(0xFFD4E5DC),
    ),
    chipTheme: const ChipThemeData(
      selectedColor: primaryGreen,
      backgroundColor: containerHighest,
      labelStyle: TextStyle(color: textDark, fontSize: 12),
      secondaryLabelStyle: TextStyle(
          color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      side: BorderSide(color: outline),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: surface,
      titleTextStyle: TextStyle(
          color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
      contentTextStyle: TextStyle(color: textMedium, fontSize: 14),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface,
      modalBackgroundColor: surface,
      elevation: Nur.elevationSheet,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(Nur.radiusSheet)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: bg,
      indicatorColor: primaryGreen.withValues(alpha: 0.16),
      iconTheme: WidgetStateProperty.resolveWith((states) =>
          IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? primaryGreen
                  : textMuted)),
      labelTextStyle: WidgetStateProperty.resolveWith((states) =>
          TextStyle(
              color: states.contains(WidgetState.selected)
                  ? primaryGreen
                  : textMuted,
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.bold
                  : FontWeight.normal)),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: primaryGreen,
      contentTextStyle: TextStyle(color: Colors.white),
      actionTextColor: secondaryGreen,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: primaryGreen,
      textColor: textDark,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: textDark, height: 1.5),
      bodyMedium: TextStyle(color: textMedium, height: 1.5),
      bodySmall: TextStyle(color: textMuted, height: 1.5),
      titleLarge: TextStyle(
          color: textDark, fontWeight: FontWeight.bold, height: 1.3),
      titleMedium: TextStyle(
          color: textDark, fontWeight: FontWeight.w600, height: 1.3),
      titleSmall: TextStyle(
          color: primaryGreen, fontWeight: FontWeight.bold, height: 1.3),
      labelLarge: TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );
}

// ---------------------------------------------------------------------------
// Theme 2: Light Blue (Modern) — Fresh • Elegant • Premium
// ---------------------------------------------------------------------------
ThemeData _lightBlueTheme() {
  const primaryBlue = Color(0xFF0284C7);
  const secondaryBlue = Color(0xFF0EA5E9);
  const bg = Color(0xFFF0F6FB);
  const surface = Color(0xFFFFFFFF);
  const containerHighest = Color(0xFFE0F2FE);
  const textDark = Color(0xFF0F1D33);
  const textMedium = Color(0xFF33475B);
  const textMuted = Color(0xFF5B7288);
  const outline = Color(0xFFBAD7E9);
  const outlineVariant = Color(0xFFDFECF5);

  const cs = ColorScheme.light(
    primary: primaryBlue,
    onPrimary: Colors.white,
    secondary: secondaryBlue,
    onSecondary: Colors.white,
    tertiary: primaryBlue,
    surface: surface,
    onSurface: textDark,
    surfaceContainerHighest: containerHighest,
    outline: outline,
    outlineVariant: outlineVariant,
    error: Color(0xFFB3261E),
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: bg,
    colorScheme: cs,
    hintColor: textMuted,
    dividerColor: outlineVariant,
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Nur.cardRadius),
        side: BorderSide(color: primaryBlue.withValues(alpha: 0.16)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryBlue,
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
        backgroundColor: primaryBlue,
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
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Nur.buttonRadius),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        side: const BorderSide(color: primaryBlue),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Nur.buttonRadius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primaryBlue),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      hintStyle: const TextStyle(color: textMuted),
      prefixIconColor: primaryBlue,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryBlue.withValues(alpha: 0.22)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: primaryBlue, width: 1.5),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? primaryBlue
              : const Color(0xFF94A3B8)),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? secondaryBlue.withValues(alpha: 0.45)
              : const Color(0xFFD6E6F2)),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: primaryBlue,
      inactiveTrackColor: Color(0xFFD6E6F2),
      thumbColor: primaryBlue,
      overlayColor: Color(0x220284C7),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryBlue,
      linearTrackColor: Color(0xFFD6E6F2),
    ),
    chipTheme: const ChipThemeData(
      selectedColor: primaryBlue,
      backgroundColor: containerHighest,
      labelStyle: TextStyle(color: textDark, fontSize: 12),
      secondaryLabelStyle: TextStyle(
          color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      side: BorderSide(color: outline),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: surface,
      titleTextStyle: TextStyle(
          color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
      contentTextStyle: TextStyle(color: textMedium, fontSize: 14),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface,
      modalBackgroundColor: surface,
      elevation: Nur.elevationSheet,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(Nur.radiusSheet)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: bg,
      indicatorColor: primaryBlue.withValues(alpha: 0.16),
      iconTheme: WidgetStateProperty.resolveWith((states) =>
          IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? primaryBlue
                  : textMuted)),
      labelTextStyle: WidgetStateProperty.resolveWith((states) =>
          TextStyle(
              color: states.contains(WidgetState.selected)
                  ? primaryBlue
                  : textMuted,
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.bold
                  : FontWeight.normal)),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: primaryBlue,
      contentTextStyle: TextStyle(color: Colors.white),
      actionTextColor: secondaryBlue,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: primaryBlue,
      textColor: textDark,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: textDark, height: 1.5),
      bodyMedium: TextStyle(color: textMedium, height: 1.5),
      bodySmall: TextStyle(color: textMuted, height: 1.5),
      titleLarge: TextStyle(
          color: textDark, fontWeight: FontWeight.bold, height: 1.3),
      titleMedium: TextStyle(
          color: textDark, fontWeight: FontWeight.w600, height: 1.3),
      titleSmall: TextStyle(
          color: primaryBlue, fontWeight: FontWeight.bold, height: 1.3),
      labelLarge: TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );
}

// ---------------------------------------------------------------------------
// Theme 3: Royal Navy (Modern) — Rich • Soft • Eye Friendly
// ---------------------------------------------------------------------------
ThemeData _royalNavyTheme() {
  const gold = Color(0xFFD4AF37);
  const skyBlue = Color(0xFF38BDF8);
  const bg = Color(0xFF0B1324);
  const surface = Color(0xFF132035);
  const containerHighest = Color(0xFF1D2C46);
  const textLight = Color(0xFFF8FAFC);
  const textMuted = Color(0xFF8295AF);
  const outline = Color(0xFF2C3E5E);
  const outlineVariant = Color(0xFF1E2D47);

  const cs = ColorScheme.dark(
    primary: gold,
    onPrimary: Color(0xFF0B1324),
    secondary: skyBlue,
    onSecondary: Color(0xFF0B1324),
    tertiary: Color(0xFF2563EB),
    onTertiary: Colors.white,
    surface: surface,
    onSurface: textLight,
    surfaceContainerHighest: containerHighest,
    outline: outline,
    outlineVariant: outlineVariant,
    error: Color(0xFFE57373),
    onError: Color(0xFF0B1324),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: cs,
    hintColor: textMuted,
    dividerColor: outlineVariant,
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Nur.cardRadius),
        side: BorderSide(color: gold.withValues(alpha: 0.22)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: textLight,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: gold),
      titleTextStyle: TextStyle(
        color: textLight,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: Color(0xFF0B1324),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Nur.buttonRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: Color(0xFF0B1324),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Nur.buttonRadius),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: gold,
        side: const BorderSide(color: gold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Nur.buttonRadius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: gold),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      hintStyle: const TextStyle(color: textMuted),
      prefixIconColor: gold,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: gold.withValues(alpha: 0.28)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: gold, width: 1.5),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? gold
              : const Color(0xFF8295AF)),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? gold.withValues(alpha: 0.35)
              : containerHighest),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: gold,
      inactiveTrackColor: outline,
      thumbColor: gold,
      overlayColor: Color(0x33D4AF37),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: gold,
      linearTrackColor: outline,
    ),
    chipTheme: const ChipThemeData(
      selectedColor: gold,
      backgroundColor: containerHighest,
      labelStyle: TextStyle(color: textLight, fontSize: 12),
      secondaryLabelStyle: TextStyle(
          color: Color(0xFF0B1324), fontSize: 12, fontWeight: FontWeight.bold),
      side: BorderSide(color: outline),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: surface,
      titleTextStyle: TextStyle(
          color: textLight, fontSize: 18, fontWeight: FontWeight.bold),
      contentTextStyle: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface,
      modalBackgroundColor: surface,
      elevation: Nur.elevationSheet,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(Nur.radiusSheet)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: bg,
      indicatorColor: gold.withValues(alpha: 0.20),
      iconTheme: WidgetStateProperty.resolveWith((states) =>
          IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? gold
                  : textMuted)),
      labelTextStyle: WidgetStateProperty.resolveWith((states) =>
          TextStyle(
              color: states.contains(WidgetState.selected)
                  ? gold
                  : textMuted,
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.bold
                  : FontWeight.normal)),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: containerHighest,
      contentTextStyle: TextStyle(color: textLight),
      actionTextColor: gold,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: gold,
      textColor: textLight,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: textLight, height: 1.5),
      bodyMedium: TextStyle(color: Color(0xFFCBD5E1), height: 1.5),
      bodySmall: TextStyle(color: textMuted, height: 1.5),
      titleLarge: TextStyle(
          color: textLight, fontWeight: FontWeight.bold, height: 1.3),
      titleMedium: TextStyle(
          color: textLight, fontWeight: FontWeight.w600, height: 1.3),
      titleSmall: TextStyle(
          color: gold, fontWeight: FontWeight.bold, height: 1.3),
      labelLarge: TextStyle(
          color: Color(0xFF0B1324), fontWeight: FontWeight.bold),
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
          title: 'Hafizi Quran & Tafsir',
          debugShowCheckedModeBanner: false,
          navigatorKey: appNavigatorKey,
          theme: buildTheme(prefs.themeName),
          home: const SplashScreen(),
        );
      },
    );
  }
}
