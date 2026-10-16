# REDESIGN INVENTORY — Nur-ul-Quran (v1.0.90+91 baseline)
# Generated 2026-10-16 as Phase 1 of premium redesign. REGRESSION CHECKLIST:
# every item below must still exist + work after redesign. NOTHING may be removed.

## Stack
- Flutter (Dart, Material 3, `useMaterial3: true`), Provider state management.
- Navigation: imperative `Navigator.push` + `MaterialPageRoute` (no named routes),
  `appNavigatorKey` in main.dart. Bottom nav in HomeNavigationScreen.
- Persistence: SharedPreferences via PreferencesService (`nur_*` keys) + backup JSON.
- Audio: just_audio + audio_service + audio_session (AudioRecitationService,
  NurAudioHandler). Qari MP3s: per-ayah, offline cache + streaming.
- Fonts (DO NOT CHANGE): Noto Sans Arabic, Amiri Quran, Noto Nastaliq Urdu.
- Assets: assets/audio/, assets/icons/, assets/images/, assets/data/,
  assets/data/tafsir_ibn_kathir_urdu/ (114 files), assets/pages/ (611 pages).

## Themes (PreferencesService.themeName: 'night' | 'emerald' | 'parchment')
1. Night Slate ('night', default) — deep green + gold. USER: greenish Theme 1 is FINE.
2. Emerald Day ('emerald') — light mint; actions deep green, gold accents.
3. Antique Parchment ('parchment') — warm sepia; actions bronze, gold accents.
- Extra toggle: nightPageMode ('nur_night_page_mode') — inverts mushaf page
  (black bg, white text). Footer palette derives from it (v1.0.90 fix: keep).
- Theme builder: buildTheme() in lib/main.dart. Tokens: Nur class in main.dart.

## Preferences keys (DO NOT rename/change)
nur_theme_name, nur_night_page_mode, language ('ur'|'en'), scriptStyle,
ayahScale, readingMode, repeatMode, playbackSpeed, lastReadPage/Surah/Ayah,
lastReadAt, bookmarks, savedAyahs, pageNotes, pageTint, readPages,
dailyTargetPages, khatmDays, prayerAlarms, azanSoundEnabled,
lockscreenAlarmEnabled, asrMethod, selectedCity, autoBackup, lastAutoBackup,
audioHighlightEnabled, backgroundPlaybackEnabled, onboardingDone, ayahTapHintShown.

## Screens (lib/views/) + every action — ALL MUST SURVIVE
### 1. splash_screen.dart — SplashScreen
- Shows splash, then routes to Onboarding (first run) or HomeNavigationScreen.
### 2. onboarding_screen.dart — OnboardingScreen + _OnboardPage
- Multi-page onboarding; button → HomeNavigationScreen.
### 3. home_navigation_screen.dart — HomeNavigationScreen (BOTTOM NAV, 5 tabs)
- Tabs: ہوم Home | مصحف Mushaf | سورتیں Surahs | نماز و اذان Prayer | مزید More.
- Exit-confirm AlertDialog on back press; permission AlertDialog (first run).
- NEVER remove/rename tabs. Icons: outlined unselected / filled selected.
### 4. dashboard_screen.dart — DashboardScreen (HOME)
- Header: app title/logo, menu_book icon card.
- Continue Reading (Page N) → MushafScreen at last page.
- Listen from Ayah N → audio from last ayah.
- Ayah of the Day: Copy button, Listen button.
- Surah browser: search field + surah list rows → Surah detail/Mushaf.
- Quick grid (14 items, ALL keep destination): Juz Index, Khatm Planner,
  Bookmarks & Saved, Search Quran, Tafsir, Audio Recitations, Qiblah Compass,
  Ramzan & Duas, Preferences, Questions & FAQ, Backup & Restore,
  About & Licenses, Offline Downloads (+1: see file lines 589-617).
- Saved/bookmarks preview section; arrow-forward navigation.
### 5. mushaf_screen.dart — MushafScreen (READER) — HIGHEST RISK
- PRESERVE EXACTLY: Quran page image (15-line layout), page turning (PageView),
  pinch-zoom arbitration (2nd-finger lock, scale>1.01 pan lock, boundaryMargin 80),
  landscape SizedBox(width, height=w/aspect) fix, ayah highlight geometry/segments,
  reading position, page notes/drawing (PageDrawingService + _PageDrawingPainter),
  _ResilientPageImage, Bismillah cartouche/header, _NeutralTopOrnament,
  _StarMedallionPainter, _ManzilBadge, _RibbonPainter, _OrnamentPatternPainter.
- CHROME ONLY (may restyle): bottom control bar (Speed/Play/Repeat/Night/More),
  floating Note (+) button, bookmark ribbon, chevrons, back button, palette row,
  footer palette (incl. lightThemeNightPage v1.0.90 fix — keep logic).
- Sheets/dialogs from reader: reader_settings_sheet, ayah_player_sheet,
  note dialog, bookmark dialog, page-jump (showModalBottomSheet x3, AlertDialog x2).
- DO NOT move Bismillah, DO NOT change edition rules, DO NOT touch audio calls.
### 6. reader_settings_sheet.dart — ReaderSettingsSheet (bottom sheet)
- Reading settings controls + 4 AlertDialogs (incl. StatefulBuilder dialog).
### 7. ayah_player_sheet.dart — AyahPlayerSheet (bottom sheet)
- Play/pause, speed, repeat, _RepeatRangeRow, _TafsirSection (per-ayah tafsir).
- Audio auto-advance behavior UNCHANGED.
### 8. surahs_screen.dart — Surahs list
- Surah list rows → reader/tafsir; bottom sheet (quick jump); AlertDialog.
### 9. juz_index_screen.dart — JuzIndexScreen (30 Juz list → reader).
### 10. search_quran_screen.dart — SearchQuranScreen
- Quran Word/Text search + voice search (speech_to_text, Hindi/Urdu/English).
- Search Engine (Al-Bahith/Lughat/web) was REMOVED by user (commit 2259d8d)
  for a separate project — DO NOT restore it.
### 11. bookmarks_screen.dart — BookmarksScreen + tabs
- Tabs: All Saved / Saved Ayahs; 5 AlertDialogs (edit/delete/confirm).
### 12. tafsir_home_screen.dart — TafsirHomeScreen (114 surah list).
### 13. tafsir_surah_screen.dart — TafsirSurahScreen (ayah list; per-ayah audio
  button, singleAyah:true — plays ONE ayah then stops. DO NOT re-add auto-advance).
### 14. tafsir_ayah_detail_screen.dart — TafsirAyahDetailScreen (ayah + Urdu
  Kanzul Iman + English + full Ibn Kathir + single-ayah audio). NO Tafsir Jump
  (removed by user — DO NOT restore).
### 15. audio_studio_screen.dart — AudioStudioScreen (+ _ResumeLastSessionButton,
  _QuickPlayChip, _RepeatChip) + AlertDialog confirm.
### 16. prayer_screen.dart — PrayerScreen (prayer times, azan alarms per prayer,
  Asr Hanafi/Shafi'i) + bottom sheet.
### 17. qiblah_screen.dart — QiblahScreen (compass via flutter_compass).
### 18. khatm_planner_screen.dart — KhatmPlannerScreen (30-day, Day N = Juz N,
  per-juz %) + AlertDialog confirm.
### 19. ramzan_duas_screen.dart — RamzanDuasScreen.
### 20. offline_download_screen.dart — OfflineDownloadScreen + _QariAudioSection
  + _QariRow (per-Qari full-pack download, offline-first playback).
### 21. settings_screen.dart — SettingsScreen (all preferences toggles).
### 22. more_screen.dart — MoreScreen (16 entries: Surahs, Search Quran, Tafsir,
  Juz Index, Bookmarks & Saved, Khatm Planner, Prayer Times & Azan, Qiblah
  Compass, Ramzan & Duas, Audio Studio, Offline Download Center, Preferences,
  Backup & Restore, Questions & FAQ, About & Licenses, Privacy Policy
  + CheckUpdateTile). ALL entries keep destination.
### 23. backup_restore_screen.dart — BackupRestoreScreen + _ImportField,
  2 AlertDialogs (export/import confirm).
### 24. info_screens.dart — FaqScreen, AboutScreen, PrivacyScreen
  (+ AlertDialog for description; FAQ mailto numanfirdosi@gmail.com).
### 25. azan_alarm_screen.dart — AzanAlarmScreen (full-screen, STOP button,
  fullScreenIntent). DO NOT change alarm behavior.
### 26. check_update_tile.dart — CheckUpdateTile (in-app Check Update;
  in-place install, NEVER uninstall).

## Widgets (lib/widgets/)
- premium_card.dart — PremiumCard (shared card).
- section_header.dart — NurSectionHeader (shared section header).

## Services (DO NOT change behavior)
audio_recitation_service, auto_backup_service, azan_alarm_service,
deep_link_service, lock_screen_service, nur_audio_handler,
page_drawing_service, page_image_service, prayer_calculation_service,
preferences_service, qari_audio_storage, qari_download_service,
tafsir_service, voice_search_service.

## Data (DO NOT modify content)
ayah_layout, ayah_of_day, duas_data, juz_data, preset_cities, quran_data,
static_content, surah_aliases, surah_intros, surah_intros_urdu, verse_index.
Quran Arabic text: NEVER regenerated/rewritten/normalized by redesign.

## Dialogs / Sheets count (all must keep working)
- AlertDialog: audio_studio(1), backup_restore(2), bookmarks(5),
  home_navigation(2), info_screens(1), khatm(1), mushaf(2),
  reader_settings(4), surahs(1). Bottom sheets: ayah_player(1),
  mushaf(3), prayer(1), reader_settings(1), surahs(1).

## Hard bans (from user + history)
- No feature/button/screen/option removal. No route changes.
- No Quran text/page-layout/highlight-geometry changes.
- No audio-logic changes (incl. Tafsir single-ayah, read-page auto-advance).
- No Bismillah/edition-rule changes. No search-engine restoration.
- No Tafsir Jump restoration. No RUSHRAIL. No app-icon change (parent).
- No pubspec.yaml change (no version bump — parent does that). No git push.
- No new dependencies (prefer zero). Theme 1 (Night Slate) identity preserved.
