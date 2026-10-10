import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../services/preferences_service.dart';
import '../services/audio_recitation_service.dart';
import '../services/azan_alarm_service.dart';
import '../utils/script_font.dart';

class SettingsScreen extends StatelessWidget {
  final void Function(int page) onOpenPage;
  const SettingsScreen({super.key, required this.onOpenPage});

  /// Installed app version, loaded once for the About box.
  static final Future<PackageInfo> _packageInfoFuture =
      PackageInfo.fromPlatform();

  Future<void> _reschedule(PreferencesService prefs) {
    return AzanAlarmService().scheduleDailyPrayerAlarms(
      location: prefs.selectedCity,
      asrMode: prefs.asrMethod,
      enabledAlarms: prefs.prayerAlarms,
      azanSoundEnabled: prefs.azanSoundEnabled,
      lockscreenAlarmEnabled: prefs.lockscreenAlarmEnabled,
    );
  }

  Widget _scriptCard(
    BuildContext context, {
    required String style,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? cs.primary.withValues(alpha: 0.15)
                : cs.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? cs.primary
                  : cs.onSurface.withValues(alpha: 0.15),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: arabicStyle(style, fontSize: 18, color: cs.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _themeCard(
    BuildContext context, {
    required String label,
    required Color previewBg,
    required Color previewText,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: previewBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.25),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  'آ',
                  style: TextStyle(
                      color: previewText,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formats a daily reading target: under 20 pages shows pages, 20+
  /// shows parahs (1 parah = 20 pages), e.g. 25 -> "1 parah aur 5 pages".
  String _formatReadingGoal(int pages, bool urdu) {
    if (pages < 20) {
      return urdu ? '$pages صفحات روزانہ' : '$pages pages / day';
    }
    final parah = pages ~/ 20;
    final rem = pages % 20;
    final parahWord = urdu ? 'پارہ' : 'parah';
    if (rem == 0) {
      return urdu ? '$parah $parahWord روزانہ' : '$parah $parahWord / day';
    }
    return urdu
        ? '$parah $parahWord اور $rem صفحات روزانہ'
        : '$parah $parahWord and $rem pages / day';
  }

  Widget _langOption(
    BuildContext context, {
    required String lang,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? cs.primary.withValues(alpha: 0.15)
                : cs.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? cs.primary
                  : cs.onSurface.withValues(alpha: 0.15),
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.8),
                fontSize: 15,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = Provider.of<PreferencesService>(context);
    final cs = Theme.of(context).colorScheme;
    final ur = prefs.isUrdu;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          ur ? 'تنظیمات' : 'Settings',
          style: TextStyle(
              color: cs.primary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Juristic Method Card
          Card(
            color: cs.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ur ? 'عصر کا فقہی طریقہ' : 'Asr Juristic Method',
                    style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<String>(
                    title: Text(ur ? 'حنفی (دوگنا سایہ)' : 'Hanafi (Double shadow factor)',
                        style: TextStyle(color: cs.onSurface, fontSize: 14)),
                    value: 'Hanafi',
                    groupValue: prefs.asrMethod,
                    activeColor: cs.primary,
                    onChanged: (val) {
                      if (val != null) {
                        prefs.setAsrMethod(val);
                        _reschedule(prefs);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: Text(
                        ur ? 'شافعی / مالکی / حنبلی (اکہرا سایہ)' : 'Shafi\'i / Maliki / Hanbali (Single shadow)',
                        style: TextStyle(color: cs.onSurface, fontSize: 14)),
                    value: 'Standard',
                    groupValue: prefs.asrMethod,
                    activeColor: cs.primary,
                    onChanged: (val) {
                      if (val != null) {
                        prefs.setAsrMethod(val);
                        _reschedule(prefs);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Alarm & Azan Sound Switches
          Card(
            color: cs.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(ur ? 'اذان کی آواز' : 'Play Azan Sound',
                      style: TextStyle(
                          color: cs.onSurface, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      ur ? 'نماز کا وقت شروع ہونے پر مکمل اذان چلائیں'
                         : 'Play full Azan audio when prayer time starts',
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 12)),
                  value: prefs.azanSoundEnabled,
                  activeColor: cs.primary,
                  onChanged: (val) {
                    prefs.setAzanSoundEnabled(val);
                    _reschedule(prefs);
                  },
                ),
                Divider(color: cs.onSurface.withValues(alpha: 0.12), height: 1),
                SwitchListTile(
                  title: Text(ur ? 'لاک اسکرین اذان الارم' : 'Lockscreen Exact Alarm',
                      style: TextStyle(
                          color: cs.onSurface, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      ur ? 'بند فون کو جگائیں اور نماز کا الارم دکھائیں'
                         : 'Wake up locked phone & display prayer alarm',
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 12)),
                  value: prefs.lockscreenAlarmEnabled,
                  activeColor: cs.primary,
                  onChanged: (val) {
                    prefs.setLockscreenAlarmEnabled(val);
                    // M2: the toggle now actually takes effect — turning it OFF
                    // cancels exact alarms and falls back to notifications.
                    _reschedule(prefs);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Reading Section (mode, script, theme, ayah scale)
          Card(
            color: cs.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ur ? 'مطالعہ' : 'Reading',
                    style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ur ? 'مطالعے کا انداز' : 'Reading Mode',
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontSize: 13),
                  ),
                  RadioListTile<String>(
                    title: Text(ur ? 'صفحہ بہ صفحہ' : 'Page Slide',
                        style: TextStyle(color: cs.onSurface, fontSize: 14)),
                    value: 'slide',
                    groupValue: prefs.readingMode,
                    activeColor: cs.primary,
                    onChanged: (val) {
                      if (val != null) prefs.setReadingMode(val);
                    },
                  ),
                  RadioListTile<String>(
                    title: Text(ur ? 'مسلسل اسکرول' : 'Continuous Scroll',
                        style: TextStyle(color: cs.onSurface, fontSize: 14)),
                    value: 'scroll',
                    groupValue: prefs.readingMode,
                    activeColor: cs.primary,
                    onChanged: (val) {
                      if (val != null) prefs.setReadingMode(val);
                    },
                  ),
                  RadioListTile<String>(
                    title: Text(ur ? 'ورق پلٹنا' : 'Page Turn',
                        style: TextStyle(color: cs.onSurface, fontSize: 14)),
                    value: 'turn',
                    groupValue: prefs.readingMode,
                    activeColor: cs.primary,
                    onChanged: (val) {
                      if (val != null) prefs.setReadingMode(val);
                    },
                  ),
                  Divider(color: cs.onSurface.withValues(alpha: 0.12)),
                  const SizedBox(height: 4),
                  Text(
                    ur ? 'رسم الخط' : 'Script Style',
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _scriptCard(
                        context,
                        style: 'sans',
                        label: 'Noto Sans Arabic',
                        selected: prefs.scriptStyle == 'sans',
                        onTap: () => prefs.setScriptStyle('sans'),
                      ),
                      const SizedBox(width: 8),
                      _scriptCard(
                        context,
                        style: 'uthmani',
                        label: 'Uthmani Madinah',
                        selected: prefs.scriptStyle == 'uthmani',
                        onTap: () => prefs.setScriptStyle('uthmani'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ur ? 'تھیم' : 'Theme',
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _themeCard(
                        context,
                        label: 'Night Slate',
                        previewBg: const Color(0xFF09251D),
                        previewText: const Color(0xFFE0BD45),
                        selected: prefs.themeName == 'night',
                        onTap: () => prefs.setThemeName('night'),
                      ),
                      const SizedBox(width: 8),
                      _themeCard(
                        context,
                        label: 'Emerald Day',
                        previewBg: const Color(0xFFE8F5E9),
                        previewText: const Color(0xFF176B3A),
                        selected: prefs.themeName == 'emerald',
                        onTap: () => prefs.setThemeName('emerald'),
                      ),
                      const SizedBox(width: 8),
                      _themeCard(
                        context,
                        label: 'Antique Parchment',
                        previewBg: const Color(0xFFF5E8C8),
                        previewText: const Color(0xFF80551C),
                        selected: prefs.themeName == 'parchment',
                        onTap: () => prefs.setThemeName('parchment'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ur ? 'آیت کے متن کا سائز' : 'Ayah Text Size',
                        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontSize: 13),
                      ),
                      Text(
                        '${(prefs.ayahScale * 100).round()}%',
                        style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ],
                  ),
                  Slider(
                    value: prefs.ayahScale,
                    min: 0.8,
                    max: 1.3,
                    divisions: 10,
                    label: '${(prefs.ayahScale * 100).round()}%',
                    activeColor: cs.primary,
                    inactiveColor: cs.onSurface.withValues(alpha: 0.24),
                    onChanged: (v) => prefs.setAyahScale(v),
                  ),
                  Center(
                    child: Text(
                      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                      textDirection: TextDirection.rtl,
                      style: arabicStyle(prefs.scriptStyle,
                          fontSize: 20, scale: prefs.ayahScale,
                          color: cs.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Language Section (UI language toggle)
          Card(
            color: cs.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ur ? 'زبان' : 'Language',
                    style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ur
                        ? 'ایپ کی زبان منتخب کریں'
                        : 'Choose the app language',
                    style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.7),
                        fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _langOption(
                        context,
                        lang: 'ur',
                        label: 'اردو',
                        selected: prefs.language == 'ur',
                        onTap: () => prefs.setLanguage('ur'),
                      ),
                      const SizedBox(width: 8),
                      _langOption(
                        context,
                        lang: 'en',
                        label: 'English',
                        selected: prefs.language == 'en',
                        onTap: () => prefs.setLanguage('en'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ur
                        ? 'نوٹ: قرآن کا ترجمہ ہمیشہ اردو اور انگریزی دونوں میں دکھایا جائے گا۔'
                        : 'Note: Quran translations are always shown in both Urdu and English.',
                    style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.6),
                        fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Audio Section (default qari, repeat, speed)
          Card(
            color: cs.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Consumer<AudioRecitationService>(
                builder: (context, audio, _) {
                  const repeatModes = [0, 1, 3, 5, -1];
                  const repeatLabels = {
                    0: 'Off',
                    1: '1x',
                    3: '3x',
                    5: '5x',
                    -1: '∞'
                  };
                  const speeds = [0.5, 1.0, 1.25, 1.5, 2.0];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ur ? 'تلاوت' : 'Audio',
                        style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ur ? 'قاری کا انتخاب' : 'Default Qari',
                        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      DropdownButton<Qari>(
                        value: audio.selectedQari,
                        dropdownColor: cs.surface,
                        style:
                            TextStyle(color: cs.onSurface, fontSize: 14),
                        isExpanded: true,
                        items: availableQaris
                            .map((q) => DropdownMenuItem<Qari>(
                                  value: q,
                                  child: Text(
                                    '${q.name} (${q.style})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (q) {
                          if (q != null) audio.setQari(q);
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ur ? 'تکرار' : 'Repeat',
                        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: repeatModes.map((m) {
                          final selected = prefs.repeatMode == m;
                          return ChoiceChip(
                            label: Text(repeatLabels[m]!),
                            selected: selected,
                            selectedColor: cs.primary,
                            backgroundColor: cs.surface,
                            labelStyle: TextStyle(
                              color: selected
                                  ? cs.onPrimary
                                  : cs.onSurface.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                            onSelected: (_) {
                              prefs.setRepeatMode(m);
                              audio.setRepeatMode(m);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ur ? 'چلانے کی رفتار' : 'Playback Speed',
                        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: speeds.map((v) {
                          final selected = prefs.playbackSpeed == v;
                          return ChoiceChip(
                            label: Text(v == v.roundToDouble()
                                ? '${v.toInt()}x'
                                : '${v}x'),
                            selected: selected,
                            selectedColor: cs.primary,
                            backgroundColor: cs.surface,
                            labelStyle: TextStyle(
                              color: selected
                                  ? cs.onPrimary
                                  : cs.onSurface.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                            onSelected: (_) {
                              prefs.setPlaybackSpeed(v);
                              audio.setSpeed(v);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Reading Goal Section
          Card(
            color: cs.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ur ? 'روزانہ ہدف' : 'Reading Goal',
                    style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove,
                            color: cs.onSurface.withValues(alpha: 0.7), size: 20),
                        onPressed: prefs.dailyTargetPages > 1
                            ? () => prefs
                                .setDailyTargetPages(prefs.dailyTargetPages - 1)
                            : null,
                      ),
                      Text(
                        _formatReadingGoal(prefs.dailyTargetPages, ur),
                        style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      IconButton(
                        icon: Icon(Icons.add,
                            color: cs.onSurface.withValues(alpha: 0.7), size: 20),
                        onPressed: prefs.dailyTargetPages < 611
                            ? () => prefs
                                .setDailyTargetPages(prefs.dailyTargetPages + 1)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Bookmarks Section
          Card(
            color: cs.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          ur ? 'محفوظ شدہ صفحات' : 'Bookmarks',
                          style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ),
                      Text(ur ? '${prefs.bookmarks.length} محفوظ شدہ' : '${prefs.bookmarks.length} saved',
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.54), fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (prefs.bookmarks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                          ur ? 'ابھی کوئی صفحہ محفوظ نہیں ہے۔ کسی بھی صفحے پر بک مارک آئیکن دبائیں۔'
                             : 'No bookmarked pages yet. Tap the bookmark icon on any Mushaf page.',
                          style:
                              TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 13)),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: prefs.bookmarks.map((p) {
                        return ActionChip(
                          backgroundColor: cs.surface,
                          avatar: Icon(Icons.bookmark, color: cs.primary, size: 16),
                          label: Text('Page $p',
                              style: TextStyle(color: cs.onSurface)),
                          onPressed: () => onOpenPage(p),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // About App
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: cs.onSurface.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ur ? 'نور القرآن کے بارے میں' : 'About Nur-ul-Quran (نور القرآن)',
                  style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  ur
                      ? '15 سطری جنوبی ایشیائی حفظی مصحف (القرآن الكريم)۔ 100% آف لائن، لاک اسکرین اذان کے ساتھ درست فلکیاتی نماز کے اوقات، قبلہ کمپاس اور کثیر لسانی تلاش۔'
                      : '15-Line South Asian / Indo-Pak Hifzi Mushaf (القرآن الكريم). 100% offline, exact astronomical prayer times with lockscreen Azan, Kaaba Qiblah compass, and multi-language voice search.',
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.7),
                      fontSize: 12,
                      height: 1.4),
                ),
                const SizedBox(height: 6),
                FutureBuilder<PackageInfo>(
                  future: _packageInfoFuture,
                  builder: (context, snapshot) {
                    final version = snapshot.data?.version;
                    return Text(
                      version == null || version.isEmpty
                          ? 'Version…'
                          : 'Version $version',
                      style: TextStyle(color: cs.primary, fontSize: 11),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
