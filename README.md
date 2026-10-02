# Nūr Al-Quran (نور القرآن)
### Premium 15-Line Quran Mushaf & Audio Sanctuary · Progressive Web App (PWA)

[![License: MIT](https://img.shields.io/badge/License-MIT-emerald.svg)](LICENSE)
[![Format: 15-Line Mushaf](https://img.shields.io/badge/Format-15--Line%20Mushaf-133829.svg)](#15-line-mushaf-tradition)
[![PWA: Ready](https://img.shields.io/badge/PWA-Offline%20Ready-d4af37.svg)](#offline-pwa-architecture)
[![IndexedDB: v1.0](https://img.shields.io/badge/Storage-IndexedDB%20%2B%20LocalStorage-blue.svg)](#data-preservation--privacy)

**Nūr Al-Quran** is a complete, production-grade Islamic web platform delivering the authentic **15-line Quran (Al-Mushaf)** experience used by Huffaz across South Asia, Turkey, and worldwide. Engineered with zero external heavyweight dependencies, pixel-perfect Islamic geometry borders, 12 world-renowned Qaris, full background lock-screen audio playback, and local-first data storage.

---

## 📱 Flutter App (Android) — `flutter_app/`

The repo also ships a native Android app built with **Flutter 3.47.6** that
mirrors the website: 15-line mushaf reader (611 pages), tap-to-ayah audio,
prayer times, and offline caching.

### Features

- **Mushaf reader** — 611 pages (15-line layout), slide / scroll / **page-turn**
  reading modes, pinch-to-zoom, gold ayah highlight with RTL progressive fill
  synced to audio progress, ayah quick-jump pills, tap-any-ayah to play with
  auto-advance and auto page-turn.
- **Audio** — 12 qaris; per-surah MP3s (mp3quran.net) and per-ayah MP3s
  (everyayah.com); surah repeat, **ayah-range repeat** (loop any ayah span of
  a surah), playback speed, background playback with lock-screen/media
  notification, auto-pause on phone calls and headset unplug.
- **Study tools** — Arabic + English search (6236 verses), page bookmarks,
  saved ayahs, per-page notes, per-page tint, 30-day khatm planner,
  114 English surah intros.
- **Backup & restore** — manual JSON export/import plus optional **weekly
  auto-backup** to the device (offline).
- **Deep links** — `quranapp://page/<n>` (n = 1..611) opens the reader at
  page n; invalid links show a toast, never crash.
- **Share** — share any ayah (Arabic + English + reference) or the current
  page via the Android share sheet. Private notes are never shared.
- Splash screen with real init + validation, and a 3-page first-launch
  onboarding.

### Tech stack

Flutter 3.47.6 · Provider · SharedPreferences (`nur_` keys) · just_audio ·
audio_service (bridge wraps the player — app works even if its init fails) ·
audio_session (call/headset interruptions) · share_plus · uni_links ·
android_alarm_manager_plus 5.1.2 (azan + auto-backup) ·
flutter_local_notifications · timezone (IANA DB) · cached_network_image ·
google_fonts (runtime).

### Architecture

```
flutter_app/lib/
  main.dart          Entry: providers, splash route, background audio +
                     deep-link init (best-effort, guarded)
  views/             splash, onboarding, home navigation, mushaf, dashboard,
                     surahs, prayer, audio studio, search, bookmarks,
                     khatm planner, settings, backup & restore, ayah player …
  services/          AudioRecitationService (just_audio), NurAudioHandler
                     (audio_service bridge), PreferencesService,
                     AzanAlarmService, AutoBackupService, DeepLinkService
  data/              quran_data.dart (114 surahs), verse_index.dart,
                     ayah_layout.dart (website-exact hit-test geometry),
                     juz_data.dart, surah_intros.dart
flutter_app/assets/data/
  quran_text.json           6236 verses: Arabic + English
  page_ayahs_15lines.json   Per-page ayah segments (1-based lines 1–15;
                            pages 2–3 use the Lauh absolute layout)
```

`audio_service` manifest entries (`AudioService`, `MediaButtonReceiver`,
`FOREGROUND_SERVICE` permissions) are declared; the Dart bridge
(`NurAudioHandler`) wraps the existing `AudioRecitationService` player, so its
public API (`playSurah/playAyah/pause/resume/stop/next/prev`) is unchanged.

### Setup

```bash
cd flutter_app
flutter pub get
flutter analyze        # must report 0 errors
flutter test           # full suite must pass
flutter build apk --release
```

`.github/workflows/build-apk.yml` pins Flutter 3.47.6 and, on every push to
`main` touching `flutter_app/`, builds an **unsigned** release APK **and** an
unsigned release AAB (`app-release.aab`) as workflow artifacts.

### Release signing

The release keystore is kept **outside the repo** and never committed. CI
produces unsigned artifacts; the APK is signed afterwards (e.g. with
`apksigner`) and published as a GitHub Release asset.

### Data sources

- **Mushaf pages**: 15-line, 611 pages — webp images from this repo
  (`https://raw.githubusercontent.com/numanfirdosi-prog/hifizi-15line-quran/main/assets/pages/<n>.webp`),
  cached on-device by `cached_network_image` for offline reading.
- **Verse text**: bundled `assets/data/quran_text.json` (Arabic + English).
- **Ayah geometry**: bundled `assets/data/page_ayahs_15lines.json` — matches
  the website overlay exactly (text area top 6.62% / height 86.89% /
  left 10.97% / right 10.69%; pages 2–3 absolute Lauh layout). Never edit
  Arabic text or invent mappings.
- **Audio**: per-surah MP3s from `mp3quran.net`, per-ayah MP3s from
  `everyayah.com` (12 qaris).

### Fonts & image licenses

- Arabic script styles load at runtime via `google_fonts` (Amiri,
  Scheherazade New — SIL Open Font License).
- Mushaf page images come from this project's own repo (see Data sources).

### Backup format

`PreferencesService.exportJson()` → JSON object with keys: `lastReadPage`,
`themeMode`, `selectedCity`, `asrMethod`, `azanSoundEnabled`,
`lockscreenAlarmEnabled`, `bookmarks`, `prayerAlarms`, `lastReadSurah`,
`lastReadAyah`, `lastReadAt`, `dailyTargetPages`, `themeName`, `scriptStyle`,
`ayahScale`, `readingMode`, `repeatMode`, `playbackSpeed`, `savedAyahs`,
`pageNotes`, `pageTint` (no version field yet; import tolerates missing keys).
Weekly auto-backup writes the same JSON to
`<app documents>/nur_al_quran_auto_backup.json`.

### Deep-link format

```
quranapp://page/<n>     n = 1..611
```

Declared via an `intent-filter` on the main activity
(`scheme="quranapp"`, `host="page"`). Opens the reader at page `n` on cold
start and while running.

### Troubleshooting (app)

- **Audio doesn't play**: streams need internet on first play; check
  connectivity, then try another qari.
- **Tapped ayah plays the wrong ayah**: make sure you're on the latest build
  (older builds had an off-by-one line mapping).
- **Azan alarm silent/late**: grant "Alarms & reminders" (Android 12+) when
  prompted; keep "Play Azan Sound" on in Settings.
- **No background-audio notification**: exempt the app from battery
  optimization on some OEMs.
- **Build fails locally**: release APKs build via GitHub Actions; local
  Gradle builds need the Android SDK + JDK 17.

### Play Store prep notes

- CI already uploads `app-release.aab` as a workflow artifact — sign it with
  the release keystore before Play Console upload.
- Permissions to declare: `FOREGROUND_SERVICE` (+ media playback),
  `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`, notifications.
- Bump `versionCode`/`versionName` in `pubspec.yaml` before each upload; keep
  the same keystore for all updates.

---

## 🌟 Key Features

### 1. 📖 Verified 15-Line Mushaf Reading Experience
- **Authentic 15-Line Geometry**: Exactly 15 lines per page with strict *Ayat-al-Hifz* alignment (every page starts and ends on complete Ayah boundaries).
- **604 Canonical Pages**: Identical page numbers to the physical printed Pakistani, Turkish, and Ottoman editions (e.g. Surah Al-Baqarah begins on Page 2).
- **Three Reading Modes**:
  - **Page Slide**: Smooth horizontal sliding transition between pages.
  - **Scroll**: Continuous vertical reading flow ideal for long reading sessions.
  - **Page Turn**: Skeuomorphic 3D book-page flip animation simulating holding a physical Mushaf.
- **Dynamic Font Scaling**: Slider with instant percentage preview (80% to 150%) optimized for high-DPI retina screens and mobile devices.
- **Lauh & Rasm Ornamentation**: Dual golden cartouches (*Lauh*) for Surah headers, Bismillah calligraphy banners, and ornate Ayah medallions.

### 2. 🎙️ High-Fidelity Audio Recitation & Bismillah Sequencing
- **12 Renowned Qaris**:
  1. Mishary Rashid Alafasy (*Murattal*, Kuwait)
  2. Abdul Basit Abdus Samad (*Murattal*, Egypt)
  3. Abdul Basit Abdus Samad (*Mujawwad*, Egypt)
  4. Mahmoud Khalil Al-Husary (*Murattal*, Egypt)
  5. Mahmoud Khalil Al-Husary (*Mu'allim / Student Repetition*, Egypt)
  6. Mohamed Siddiq El-Minshawi (*Murattal*, Egypt)
  7. Mohamed Siddiq El-Minshawi (*Mujawwad*, Egypt)
  8. Abdur-Rahman As-Sudais (*Murattal*, Masjid al-Haram, Makkah)
  9. Maher Al-Muaiqly (*Murattal*, Masjid al-Haram, Makkah)
  10. Sa'ood Ash-Shuraym (*Murattal*, Masjid al-Haram, Makkah)
  11. Abu Bakr Ash-Shaatree (*Murattal*, Saudi Arabia)
  12. Ali Abdur-Rahman Al-Hudhaify (*Murattal*, Masjid an-Nabawi, Madinah)
- **Authentic Bismillah Sequencing**:
  - Automatically plays the sacred Bismillah invocation before Ayah 1 across Surahs 2 through 114 with a glowing golden cartouche.
  - Strictly omits the Bismillah preamble for Surah At-Tawbah (Surah 9) in accordance with prophetic tradition.
  - Surah Al-Fatihah plays its own Ayah 1 (the Bismillah) directly.
- **Lock-Screen Media Session API**: Background audio with lock-screen track controls, Qari artist metadata, and artwork on Android, iOS, Windows, and macOS.
- **Audio Glow Synchronization**: Smooth automatic scrolling and golden verse illumination as the reciter progresses.

### 3. 💾 Local-First Data Architecture & Privacy
- **Dual-Storage Engine (`NurQuranDB`)**: High-performance IndexedDB paired with automated `localStorage` migration and fallbacks.
- **100% Private**: Zero analytics, zero cookies, zero third-party telemetry. All private study reflections, notes, bookmarks, and Khatm progress stay strictly in the browser.
- **Backup & Restore Sanctuary**:
  - One-click JSON vault export (`nur-quran-backup.json`).
  - Drag-and-drop file restore with schema verification and error prevention.

### 4. 🌙 Ramzan & Khatm Sanctuary
- **Daily Target Planner**: Set custom Khatm completion windows (e.g. 15, 30, or 60 days) and track daily page quotas.
- **Interactive Duas**: Authentic prophetic supplications organized into Sehri/Iftari, Ashrah 1 (Mercy), Ashrah 2 (Forgiveness), Ashrah 3 (Najat), and Laylatul Qadr.
- **Reflection Notes & Tafsir Drawer**: Slide-out commentary drawer for logging private personal insights.

### 5. ⚡ Offline PWA (Progressive Web Application)
- **Service Worker (`sw.js`)**: Cache-first for offline static UI assets, fonts, and stylesheets; network-first with automatic cache-fallback for API data.
- **Installable**: Full Web App Manifest (`manifest.json`) supporting standalone fullscreen installation on mobile and desktop devices.
- **Client-Side Hash Routing**: Deep-linkable bookmarkable routes (`#/home`, `#/surahs`, `#/juz`, `#/quran/page/42`, `#/bookmarks`, `#/search`, `#/audio`, `#/ramadan`, `#/settings`, `#/backup`, `#/faq`, `#/about`, `#/privacy`).

---

## 🎨 Color Palettes & Theming

Nūr Al-Quran features three mathematically calibrated color schemes:
- **Emerald Day** (Default): `#113628` deep emerald headers, parchment card accents, and gilded `#c59b27` gold trim.
- **Antique Parchment**: `#fcf8ed` soothing cream canvas, `#3b2d18` sepia calligraphy text, designed to mimic classical paper manuscripts.
- **Night Slate**: `#0b131c` deep OLED night mode with muted cyan-emerald contrasts to protect eyesight during Tahajjud and nighttime recitation.

---

## 🚀 Getting Started

### Local Setup (Zero Install Necessary)
Because Nūr Al-Quran is built with vanilla web technologies, you can preview it immediately without installing any build tools:

```bash
# Option A: Run via Python 3 built-in HTTP server
python -m http.server 8000

# Option B: Run via Node.js serve
npx serve .

# Option C: Direct browser viewing
# Simply double-click index.html in any modern browser!
```

### Verification & Syntax Tests
Run the project's syntax verification suite:
```bash
npm test
```

---

## 📂 Project Architecture

```
nur-al-quran/
├── index.html              # Single-page application shell with all 13 semantic views
├── code.js                 # Complete application engine, audio player, DB, and routing
├── style.css               # Core CSS system, themes, typography, and responsive grid
├── mushaf-15line.css       # Canonical 15-line page container, borders, and margins
├── mushaf-redesign.css     # Redesigned cartouches, surah banners, and ayah medallions
├── audio-advanced.css      # Persistent audio toolbar, speed controls, and glow states
├── ramadan.css             # Khatm planner, daily messages, and Dua tabs
├── faq.css                 # FAQ accordion and expandable help cards
├── manifest.json           # Web App Manifest for mobile/desktop PWA installation
├── sw.js                   # Service worker for offline caching and network fallbacks
├── package.json            # Project manifest, metadata, and npm scripts
└── README.md               # Production documentation
```

---

## 🌐 1-Click Deployment

Deploy Nūr Al-Quran to any static hosting service with zero build configuration:

### GitHub Pages
1. Push this repository to GitHub.
2. Go to **Settings > Pages**.
3. Under **Branch**, select `main` and root `/`.
4. Click **Save**. Your site is live!

### Vercel / Netlify
1. Connect your GitHub repository.
2. Leave build command empty and set publish directory to `.` (root).
3. Click **Deploy**.

---

## 📜 Font Licensing & Attribution
- **Arabic Calligraphy Fonts**: Amiri Quran, Scheherazade New, and Lateef are licensed under the [SIL Open Font License (OFL)](https://scripts.sil.org/OFL).
- **Text & Metadata Grounding**: Verified against Tanzil Project and the King Fahd Complex for the Printing of the Holy Quran (Madinah Munawwarah).
- **Audio Recitations**: Provided via Islamic Network CDN and licensed for educational and religious use.

---

*بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ*  
*May this project be a source of continuous benefit (Sadaqah Jariyah) for everyone seeking closeness to the Holy Quran.*

