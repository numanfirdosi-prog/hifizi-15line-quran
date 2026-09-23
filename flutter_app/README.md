# Nur-ul-Quran (نور القرآن) - Standalone Flutter Application

نور القرآن (Nur-ul-Quran) 15-Line South Asian / Indo-Pak Hifzi Mushaf (القرآن الكريم) complete offline mobile and desktop application.

---

## 🌟 Features Included

1. **📖 15-Line Hifzi Mushaf (611 Pages)**
   - Authentic 15-line South Asian layout used by Huffaz across India, Pakistan, and Bangladesh.
   - Right-to-Left (RTL) realistic page swipe and page selector slider.
   - Pinch-to-zoom and pan via `InteractiveViewer`.
   - Page bookmarking and instant jump-to-page dialog.

2. **📋 114 Surahs Index with Voice Search**
   - Multi-language search: Hindi (सूरह यासीन), English (Yaseen), Urdu (یس), Arabic, and Surah number.
   - 549+ popular search aliases (Ayat-ul-Kursi, Amma, Tabarak, Inna Aataina, etc.).
   - Speech-to-Text voice recognition microphone button for Hindi, Urdu, and English.
   - 1-tap "Read" button to jump to the exact starting page of the Surah in the 15-line Mushaf.

3. **🕌 Prayer Times & Lockscreen Azan Alarm**
   - 100% offline astronomical solar calculations (Fajr, Sunrise, Zawal, Dhuhr, Asr, Sunset, Maghrib, Isha, Tahajjud, Sehri).
   - Hanafi (shadow factor 2) and Shafi'i / Standard (shadow factor 1) juristic calculation methods.
   - Background exact alarm scheduler (`AndroidAlarmManagerPlus` + `FlutterLocalNotificationsPlugin`) that rings full Azan sound even when phone is locked or screen is off.
   - Popular city presets across India, Pakistan, Bangladesh, Saudi Arabia, UAE, UK, US, etc.

4. **🧭 Kaaba Qiblah Compass**
   - Real-time magnetic compass integration using device sensors (`flutter_compass`).
   - Spherical trigonometry bearing calculation and distance to Makkah in kilometers.
   - Visual needle pointer with green highlight when facing Kaaba directly.

5. **🎧 Quran Audio Recitation**
   - Audio recitations with multiple world-renowned Qaris (Mishary Rashid Alafasy, Abdul Basit, Al-Husary, El-Minshawi, As-Sudais).
   - Background audio controls.

---

## 📱 Permissions Configured (Android & iOS)

All required permissions have been pre-configured in `android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist`:
- ✅ `android.permission.SCHEDULE_EXACT_ALARM` & `USE_EXACT_ALARM` (Lockscreen Azan alarm)
- ✅ `android.permission.WAKE_LOCK` (Wake device on prayer time)
- ✅ `android.permission.POST_NOTIFICATIONS` (Prayer notifications)
- ✅ `android.permission.RECORD_AUDIO` (Voice search)
- ✅ `android.permission.ACCESS_FINE_LOCATION` (GPS Prayer & Qiblah calculations)
- ✅ `android.permission.FOREGROUND_SERVICE` & `FOREGROUND_SERVICE_MEDIA_PLAYBACK` (Background audio recitation)

---

## 🛠️ How to Build and Run

### 1. Prerequisites
Install Flutter 3.x SDK and Dart on your machine:
```bash
flutter --version
```

### 2. Fetch Dependencies
```bash
cd flutter_app
flutter pub get
```

### 3. Run on Connected Device / Emulator
```bash
flutter run
```

### 4. Build Release Android APK
```bash
flutter build apk --release
```
The generated APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

### 5. Build for Windows Desktop
```bash
flutter build windows
```

### 6. Build for macOS Desktop
```bash
flutter build macos
```

