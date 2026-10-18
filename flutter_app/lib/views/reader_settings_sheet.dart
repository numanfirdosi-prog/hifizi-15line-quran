import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/juz_data.dart';
import '../data/quran_data.dart';
import '../main.dart';
import '../services/audio_recitation_service.dart';
import '../services/preferences_service.dart';

/// Reader settings bottom sheet (3-dot menu on the Quran reading page).
///
/// Jump to Page/Juz/Surah/Manzil, Display Mode, Qari (Reciter), Ayah (Range),
/// Audio Mode and Background Playback — every option is fully functional.
/// Switches reflect the persisted preference state.
void showReaderSettingsSheet(BuildContext context,
    {ValueChanged<int>? onJumpToPage, Map<int, int>? surahFirstPage}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ReaderSettingsSheet(
      onJumpToPage: onJumpToPage,
      surahFirstPage: surahFirstPage,
    ),
  );
}

class _ReaderSettingsSheet extends StatelessWidget {
  final ValueChanged<int>? onJumpToPage;
  final Map<int, int>? surahFirstPage;
  const _ReaderSettingsSheet({this.onJumpToPage, this.surahFirstPage});

  static const _themes = <String, String>{
    'soft_green': 'Soft Green (Premium)',
    'light_blue': 'Light Blue (Modern)',
    'royal_navy': 'Royal Navy (Modern)',
  };

  @override
  Widget build(BuildContext context) {
    final prefs = Provider.of<PreferencesService>(context);
    final audio = Provider.of<AudioRecitationService>(context);
    final cs = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(
        // Properly sized on small screens: never taller than 88% of the
        // screen; the option list scrolls inside.
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(Nur.radiusSheet)),
          border: Border(
            top: BorderSide(color: Nur.goldBorder(), width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: Nur.s12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: Nur.s8),
            Text(
              prefs.isUrdu ? 'ریڈر سیٹنگز' : 'Reader Settings',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: Nur.fontTitle,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Nur.s4),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewPadding.bottom + Nur.s24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionLabel(
                        context, prefs.isUrdu ? 'رہنمائی' : 'NAVIGATION'),
                    // Jump to Page / Juz / Surah / Manzil
                    ListTile(
                      leading:
                          Icon(Icons.auto_stories_outlined, color: cs.primary),
                      title: Text(
                        prefs.isUrdu
                            ? 'صفحہ / پارہ / سورۃ / منزل پر جائیں'
                            : 'Jump to Page / Juz / Surah / Manzil',
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        prefs.isUrdu
                            ? 'پارہ (1-30) + صفحہ (1-20)، براہ راست صفحہ، سورۃ یا منزل'
                            : 'Juz (1-30) + page, direct page, surah or manzil',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right,
                          color: cs.onSurface.withValues(alpha: 0.5)),
                      onTap: () {
                        Navigator.of(context).pop();
                        _showJumpDialog(context, prefs.isUrdu, onJumpToPage);
                      },
                    ),
                    Divider(
                        height: 1,
                        color: cs.onSurface.withValues(alpha: 0.12)),
                    _sectionLabel(
                        context, prefs.isUrdu ? 'ڈسپلے' : 'DISPLAY'),
                    // Display Mode
                    ListTile(
                      title: Text('Display Mode',
                          style:
                              TextStyle(color: cs.onSurface, fontSize: 15)),
                      subtitle: Text(
                          _themes[prefs.themeName] ?? prefs.themeName,
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.6),
                              fontSize: 13)),
                      trailing: Icon(Icons.chevron_right,
                          color: cs.onSurface.withValues(alpha: 0.5)),
                      onTap: () => _showThemeDialog(context),
                    ),
                    Divider(
                        height: 1,
                        color: cs.onSurface.withValues(alpha: 0.12)),
                    _sectionLabel(context, prefs.isUrdu ? 'آڈیو' : 'AUDIO'),
                    // Qari (Reciter)
                    ListTile(
                      title: Text('Qari (Reciter)',
                          style:
                              TextStyle(color: cs.onSurface, fontSize: 15)),
                      subtitle: Text(audio.selectedQari.name,
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.6),
                              fontSize: 13)),
                      trailing: Icon(Icons.chevron_right,
                          color: cs.onSurface.withValues(alpha: 0.5)),
                      onTap: () => _showQariDialog(context),
                    ),
                    Divider(
                        height: 1,
                        color: cs.onSurface.withValues(alpha: 0.12)),
                    // Ayah (Range)
                    ListTile(
                      title: Text('Ayah (Range)',
                          style:
                              TextStyle(color: cs.onSurface, fontSize: 15)),
                      subtitle: Text(
                        audio.repeatRangeLabel ??
                            'Select range of ayat for playback',
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.6),
                            fontSize: 13)),
                      trailing: Icon(Icons.chevron_right,
                          color: cs.onSurface.withValues(alpha: 0.5)),
                      onTap: () => _showAyahRangeDialog(context),
                    ),
                    Divider(
                        height: 1,
                        color: cs.onSurface.withValues(alpha: 0.12)),
                    // Audio Mode
                    SwitchListTile(
                      title: Text('Audio Mode',
                          style:
                              TextStyle(color: cs.onSurface, fontSize: 15)),
                      subtitle: Text(
                        'Enable audio recitation with ayat highlighting',
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.6),
                            fontSize: 13)),
                      value: prefs.audioHighlightEnabled,
                      activeColor: cs.primary,
                      onChanged: (v) async {
                        await prefs.setAudioHighlightEnabled(v);
                        // The toggle must actually control audio, not just the
                        // highlight: turning it off pauses the recitation, turning
                        // it on resumes a paused recitation (it never starts a new
                        // one — resume only applies when a source is already loaded).
                        if (v) {
                          if (!audio.isPlaying &&
                              audio.player.audioSource != null) {
                            await audio.resume();
                          }
                        } else if (audio.isPlaying) {
                          await audio.pause();
                        }
                      },
                    ),
                    Divider(
                        height: 1,
                        color: cs.onSurface.withValues(alpha: 0.12)),
                    // Background Playback
                    SwitchListTile(
                      title: Text('Background Playback',
                          style:
                              TextStyle(color: cs.onSurface, fontSize: 15)),
                      subtitle: Text(
                        'Continue playing audio when app is in background',
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.6),
                            fontSize: 13)),
                      value: prefs.backgroundPlaybackEnabled,
                      activeColor: cs.primary,
                      onChanged: (v) =>
                          prefs.setBackgroundPlaybackEnabled(v),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Small gold section heading inside the sheet.
  Widget _sectionLabel(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Nur.s16, Nur.s12, Nur.s16, Nur.s4),
      child: Text(
        text,
        style: TextStyle(
          color: cs.primary,
          fontSize: Nur.fontCaption,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Nur.radiusLg)),
        title: Text('Display Mode', style: TextStyle(color: cs.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _themes.entries
              .map(
                (e) => RadioListTile<String>(
                  title: Text(e.value,
                      style: TextStyle(color: cs.onSurface, fontSize: 14)),
                  value: e.key,
                  groupValue: prefs.themeName,
                  activeColor: cs.primary,
                  onChanged: (v) {
                    if (v != null) {
                      prefs.setThemeName(v);
                      Navigator.of(dctx).pop();
                    }
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showQariDialog(BuildContext context) {
    final audio = Provider.of<AudioRecitationService>(context, listen: false);
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Nur.radiusLg)),
        title: Text('Qari (Reciter)', style: TextStyle(color: cs.onSurface)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableQaris.length,
            itemBuilder: (_, i) {
              final q = availableQaris[i];
              final selected = q.id == audio.selectedQari.id;
              return RadioListTile<String>(
                title: Text(q.name,
                    style: TextStyle(color: cs.onSurface, fontSize: 14)),
                subtitle: q.country.isNotEmpty
                    ? Text(q.country,
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.6),
                            fontSize: 12))
                    : null,
                value: q.id,
                groupValue: selected ? q.id : '__none__',
                activeColor: cs.primary,
                onChanged: (_) async {
                  await audio.setQari(q);
                  if (dctx.mounted) Navigator.of(dctx).pop();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAyahRangeDialog(BuildContext context) {
    final audio = Provider.of<AudioRecitationService>(context, listen: false);
    final cs = Theme.of(context).colorScheme;
    int surah = audio.currentSurah;
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (dctx, setState) => AlertDialog(
          backgroundColor: cs.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Nur.radiusLg)),
          title: Text('Ayah (Range)', style: TextStyle(color: cs.onSurface)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select range of ayat for playback',
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.6),
                      fontSize: 13)),
              const SizedBox(height: 12),
              DropdownButton<int>(
                value: surah,
                isExpanded: true,
                dropdownColor: cs.surface,
                style: TextStyle(color: cs.onSurface, fontSize: 14),
                items: allSurahs
                    .map((s) => DropdownMenuItem<int>(
                          value: s.number,
                          child: Text('${s.number}. ${s.nameEn}'),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => surah = v);
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: cs.onSurface),
                      decoration: InputDecoration(
                        labelText: 'From ayah',
                        labelStyle: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.6)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: endCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: cs.onSurface),
                      decoration: InputDecoration(
                        labelText: 'To ayah',
                        labelStyle: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.6)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                audio.clearAyahRepeatRange();
                Navigator.of(dctx).pop();
              },
              child: Text('Clear', style: TextStyle(color: cs.primary)),
            ),
            FilledButton(
              onPressed: () async {
                final start = int.tryParse(startCtrl.text.trim());
                final end = int.tryParse(endCtrl.text.trim());
                if (start == null || end == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ayah numbers likhein')),
                  );
                  return;
                }
                final ok = await audio.setAyahRepeatRange(
                    surah: surah, startAyah: start, endAyah: end);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ghalat range hai')),
                  );
                  return;
                }
                if (dctx.mounted) Navigator.of(dctx).pop();
              },
              child: const Text('Play Range'),
            ),
          ],
        ),
      ),
    ).then((_) {
      // The dialog is closed: release the controllers.
      startCtrl.dispose();
      endCtrl.dispose();
    });
  }

  void _showJumpDialog(
    BuildContext context,
    bool isUrdu,
    ValueChanged<int>? onJumpToPage,
  ) {
    showDialog(
      context: context,
      builder: (dctx) => _JumpDialog(
        isUrdu: isUrdu,
        surahFirstPage: surahFirstPage,
        onJump: (page) {
          Navigator.of(dctx).pop();
          onJumpToPage?.call(page);
        },
      ),
    );
  }
}

class _JumpDialog extends StatefulWidget {
  final bool isUrdu;
  final ValueChanged<int> onJump;
  final Map<int, int>? surahFirstPage;

  const _JumpDialog(
      {required this.isUrdu, required this.onJump, this.surahFirstPage});

  @override
  State<_JumpDialog> createState() => _JumpDialogState();
}

class _JumpDialogState extends State<_JumpDialog> {
  int _mode = 0; // 0: Juz (Parah) & Page, 1: Direct Page, 2: Surah, 3: Manzil
  final _parahCtrl = TextEditingController();
  final _pageInParahCtrl = TextEditingController();
  final _directPageCtrl = TextEditingController();
  String? _previewText;
  int _surah = 1;
  int _manzil = 1;

  /// First surah of each manzil (manzil boundaries of the 7 manazil).
  static const _manzilStartSurahs = [1, 5, 10, 17, 26, 37, 50];

  @override
  void initState() {
    super.initState();
    _parahCtrl.addListener(_updatePreview);
    _pageInParahCtrl.addListener(_updatePreview);
  }

  void _updatePreview() {
    if (_mode != 0) return;
    final p = int.tryParse(_parahCtrl.text.trim());
    final pip = int.tryParse(_pageInParahCtrl.text.trim());
    if (p != null && p >= 1 && p <= 30 && pip != null && pip >= 1 && pip <= 20) {
      final target =
          (juzList[p - 1].startPage + pip - 1).clamp(1, totalPagesInMushaf);
      setState(() {
        _previewText = widget.isUrdu
            ? '➔ مصحف صفحہ $target'
            : '➔ Mushaf Page $target';
      });
    } else {
      if (_previewText != null) {
        setState(() {
          _previewText = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _parahCtrl.dispose();
    _pageInParahCtrl.dispose();
    _directPageCtrl.dispose();
    super.dispose();
  }

  void _deny(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit() {
    if (_mode == 0) {
      final p = int.tryParse(_parahCtrl.text.trim());
      final pip = int.tryParse(_pageInParahCtrl.text.trim());
      if (p == null || p < 1 || p > 30 || pip == null || pip < 1 || pip > 20) {
        _deny(widget.isUrdu
            ? 'درست پارہ (1-30) اور صفحہ (1-20) درج کریں'
            : 'Enter valid Parah (1-30) and Page (1-20)');
        return;
      }
      final target =
          (juzList[p - 1].startPage + pip - 1).clamp(1, totalPagesInMushaf);
      widget.onJump(target);
    } else if (_mode == 1) {
      final page = int.tryParse(_directPageCtrl.text.trim());
      if (page == null || page < 1 || page > totalPagesInMushaf) {
        _deny(widget.isUrdu
            ? 'درست صفحہ نمبر (1-611) درج کریں'
            : 'Enter a valid page number (1-611)');
        return;
      }
      widget.onJump(page.clamp(1, totalPagesInMushaf));
    } else if (_mode == 2) {
      final page = widget.surahFirstPage?[_surah];
      if (page == null) {
        _deny(widget.isUrdu
            ? 'سورۃ کی فہرست لوڈ ہو رہی ہے — تھوڑی دیر بعد کوشش کریں'
            : 'Surah list is still loading — try again in a moment');
        return;
      }
      widget.onJump(page);
    } else {
      final startSurah = _manzilStartSurahs[_manzil - 1];
      final page = widget.surahFirstPage?[startSurah];
      if (page == null) {
        _deny(widget.isUrdu
            ? 'منزل کی فہرست لوڈ ہو رہی ہے — تھوڑی دیر بعد کوشش کریں'
            : 'Manzil list is still loading — try again in a moment');
        return;
      }
      widget.onJump(page);
    }
  }

  /// Target-page preview for the Surah / Manzil modes (validated by
  /// construction — the user picks from fixed lists).
  String? _modeTargetPreview() {
    final map = widget.surahFirstPage;
    if (_mode == 2) {
      final pg = map?[_surah];
      if (pg == null) return null;
      return widget.isUrdu ? '➔ مصحف صفحہ $pg' : '➔ Mushaf Page $pg';
    }
    if (_mode == 3) {
      final s0 = _manzilStartSurahs[_manzil - 1];
      final pg = map?[s0];
      if (pg == null) return null;
      final name = allSurahs[s0 - 1].nameEn;
      return widget.isUrdu
          ? '➔ منزل $_manzil • $name • صفحہ $pg'
          : '➔ Manzil $_manzil • $name • Page $pg';
    }
    return null;
  }

  Widget _modeChip(BuildContext context, int mode, String label) {
    final cs = Theme.of(context).colorScheme;
    final selected = _mode == mode;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: selected ? cs.onPrimary : cs.onSurface,
        ),
      ),
      selected: selected,
      selectedColor: cs.primary,
      onSelected: (_) => setState(() {
        _mode = mode;
        _updatePreview();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final preview = _mode == 0 ? _previewText : _modeTargetPreview();
    return AlertDialog(
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Nur.radiusLg)),
      title: Row(
        children: [
          Icon(Icons.auto_stories, color: cs.primary, size: Nur.iconSize),
          const SizedBox(width: Nur.s8),
          Expanded(
            child: Text(
              widget.isUrdu ? 'پارہ / صفحہ پر جائیں' : 'Jump to Page / Juz',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: Nur.fontTitle,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode selector (wraps on narrow screens — no horizontal overflow)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _modeChip(context, 0,
                    widget.isUrdu ? 'پارہ اور صفحہ' : 'Juz & Page'),
                _modeChip(context, 1,
                    widget.isUrdu ? 'براہ راست صفحہ' : 'Direct Page'),
                _modeChip(context, 2, widget.isUrdu ? 'سورۃ' : 'Surah'),
                _modeChip(context, 3, widget.isUrdu ? 'منزل' : 'Manzil'),
              ],
            ),
            const SizedBox(height: 16),
            if (_mode == 0) ...[
              Text(
                widget.isUrdu
                    ? 'ہر پارے میں 20 صفحات ہوتے ہیں (مثال: پارہ 2، صفحہ 10)'
                    : 'Each Juz (Parah) has 20 pages (e.g. Juz 2, Page 10)',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.65),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _parahCtrl,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: TextStyle(color: cs.onSurface),
                      decoration: InputDecoration(
                        labelText:
                            widget.isUrdu ? 'پارہ (1-30)' : 'Juz (1-30)',
                        labelStyle: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.7)),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(Nur.buttonRadius),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _pageInParahCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: cs.onSurface),
                      decoration: InputDecoration(
                        labelText:
                            widget.isUrdu ? 'صفحہ (1-20)' : 'Page (1-20)',
                        labelStyle: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.7)),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(Nur.buttonRadius),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (_mode == 1) ...[
              Text(
                widget.isUrdu
                    ? 'مصحف کا کوئی بھی صفحہ نمبر درج کریں (1 سے 611)'
                    : 'Enter any Mushaf page number (1 to 611)',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.65),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _directPageCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: TextStyle(color: cs.onSurface),
                decoration: InputDecoration(
                  labelText: widget.isUrdu
                      ? 'صفحہ نمبر (1-611)'
                      : 'Page Number (1-611)',
                  labelStyle: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.7)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Nur.buttonRadius),
                  ),
                ),
              ),
            ] else if (_mode == 2) ...[
              Text(
                widget.isUrdu
                    ? 'سورۃ منتخب کریں — اس کے پہلے صفحے پر جائیں گے'
                    : 'Pick a surah to jump to its first page',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.65),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButton<int>(
                value: _surah,
                isExpanded: true,
                dropdownColor: cs.surface,
                style: TextStyle(color: cs.onSurface, fontSize: 14),
                items: allSurahs.map((s) {
                  final pg = widget.surahFirstPage?[s.number];
                  return DropdownMenuItem<int>(
                    value: s.number,
                    child: Text(
                        '${s.number}. ${s.nameEn}${pg != null ? '  •  p. $pg' : ''}'),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _surah = v);
                },
              ),
            ] else ...[
              Text(
                widget.isUrdu
                    ? 'منزل منتخب کریں — اس کے پہلے صفحے پر جائیں گے'
                    : 'Pick a manzil to jump to its first page',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.65),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var m = 1; m <= 7; m++)
                    ChoiceChip(
                      label: Text(
                        widget.isUrdu ? 'منزل $m' : 'Manzil $m',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _manzil == m ? cs.onPrimary : cs.onSurface,
                        ),
                      ),
                      selected: _manzil == m,
                      selectedColor: cs.primary,
                      onSelected: (_) => setState(() => _manzil = m),
                    ),
                ],
              ),
            ],
            if (preview != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: Nur.s12, vertical: Nur.s4),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(Nur.s8),
                ),
                child: Text(
                  preview,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            widget.isUrdu ? 'منسوخ' : 'Cancel',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
          ),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: Text(widget.isUrdu ? 'جائیں' : 'Jump'),
          style: FilledButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Nur.buttonRadius),
            ),
          ),
        ),
      ],
    );
  }
}
