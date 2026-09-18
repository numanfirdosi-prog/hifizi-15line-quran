# Nūr Al-Quran (نور القرآن)
### Premium 15-Line Quran Mushaf & Audio Sanctuary · Progressive Web App (PWA)

[![License: MIT](https://img.shields.io/badge/License-MIT-emerald.svg)](LICENSE)
[![Format: 15-Line Mushaf](https://img.shields.io/badge/Format-15--Line%20Mushaf-133829.svg)](#15-line-mushaf-tradition)
[![PWA: Ready](https://img.shields.io/badge/PWA-Offline%20Ready-d4af37.svg)](#offline-pwa-architecture)
[![IndexedDB: v1.0](https://img.shields.io/badge/Storage-IndexedDB%20%2B%20LocalStorage-blue.svg)](#data-preservation--privacy)

**Nūr Al-Quran** is a complete, production-grade Islamic web platform delivering the authentic **15-line Quran (Al-Mushaf)** experience used by Huffaz across South Asia, Turkey, and worldwide. Engineered with zero external heavyweight dependencies, pixel-perfect Islamic geometry borders, 12 world-renowned Qaris, full background lock-screen audio playback, and local-first data storage.

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

