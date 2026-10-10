import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/juz_data.dart';
import '../data/quran_data.dart';
import '../services/audio_recitation_service.dart';
import '../services/preferences_service.dart';

/// Reader settings bottom sheet (3-dot menu on the Quran reading page).
///
/// Mirrors the reference design: Jump to Page/Parah, Display Mode, Qari (Reciter),
/// Ayah (Range), Audio Mode and Background Playback — every option is fully functional.
void showReaderSettingsSheet(BuildContext context, {ValueChanged<int>? onJumpToPage}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ReaderSettingsSheet(onJumpToPage: onJumpToPage),
  );
}

class _ReaderSettingsSheet extends StatelessWidget {
  final ValueChanged<int>? onJumpToPage;
  const _ReaderSettingsSheet({this.onJumpToPage});

  static const _themes = <String, String>{
    'night': 'Night Slate',
    'emerald': 'Emerald Day',
    'parchment': 'Antique Parchment',
  };

  @override
  Widget build(BuildContext context) {
    final prefs = Provider.of<PreferencesService>(context);
    final audio = Provider.of<AudioRecitationService>(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            prefs.isUrdu ? 'ریڈر سیٹنگز' : 'Reader Settings',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Jump to Page / Parah
          ListTile(
            leading: Icon(Icons.auto_stories_outlined, color: cs.primary),
            title: Text(
              prefs.isUrdu ? 'پارہ / صفحہ پر جائیں' : 'Jump to Page / Parah',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              prefs.isUrdu
                  ? 'پارہ (1-30) + صفحہ (1-20) یا براہ راست صفحہ نمبر'
                  : 'Parah (1-30) + Page in Parah (1-20), or direct page',
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
          Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.12)),
          // Display Mode
          ListTile(
            title: Text('Display Mode',
                style: TextStyle(color: cs.onSurface, fontSize: 15)),
            subtitle: Text(_themes[prefs.themeName] ?? prefs.themeName,
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.6), fontSize: 13)),
            trailing: Icon(Icons.chevron_right,
                color: cs.onSurface.withValues(alpha: 0.5)),
            onTap: () => _showThemeDialog(context),
          ),
          Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.12)),
          // Qari (Reciter)
          ListTile(
            title: Text('Qari (Reciter)',
                style: TextStyle(color: cs.onSurface, fontSize: 15)),
            subtitle: Text(audio.selectedQari.name,
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.6), fontSize: 13)),
            trailing: Icon(Icons.chevron_right,
                color: cs.onSurface.withValues(alpha: 0.5)),
            onTap: () => _showQariDialog(context),
          ),
          Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.12)),
          // Ayah (Range)
          ListTile(
            title: Text('Ayah (Range)',
                style: TextStyle(color: cs.onSurface, fontSize: 15)),
            subtitle: Text(
              audio.repeatRangeLabel ?? 'Select range of ayat for playback',
              style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.6), fontSize: 13),
            ),
            trailing: Icon(Icons.chevron_right,
                color: cs.onSurface.withValues(alpha: 0.5)),
            onTap: () => _showAyahRangeDialog(context),
          ),
          Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.12)),
          // Audio Mode
          SwitchListTile(
            title: Text('Audio Mode',
                style: TextStyle(color: cs.onSurface, fontSize: 15)),
            subtitle: Text(
              'Enable audio recitation with ayat highlighting',
              style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.6), fontSize: 13),
            ),
            value: prefs.audioHighlightEnabled,
            activeColor: cs.primary,
            onChanged: (v) async {
              await prefs.setAudioHighlightEnabled(v);
              // The toggle must actually control audio, not just the
              // highlight: turning it off pauses the recitation, turning
              // it on resumes a paused recitation (it never starts a new
              // one — resume only applies when a source is already loaded).
              if (v) {
                if (!audio.isPlaying && audio.player.audioSource != null) {
                  await audio.resume();
                }
              } else if (audio.isPlaying) {
                await audio.pause();
              }
            },
          ),
          Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.12)),
          // Background Playback
          SwitchListTile(
            title: Text('Background Playback',
                style: TextStyle(color: cs.onSurface, fontSize: 15)),
            subtitle: Text(
              'Continue playing audio when app is in background',
              style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.6), fontSize: 13),
            ),
            value: prefs.backgroundPlaybackEnabled,
            activeColor: cs.primary,
            onChanged: (v) => prefs.setBackgroundPlaybackEnabled(v),
          ),
        ],
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

  const _JumpDialog({required this.isUrdu, required this.onJump});

  @override
  State<_JumpDialog> createState() => _JumpDialogState();
}

class _JumpDialogState extends State<_JumpDialog> {
  int _mode = 0; // 0: Parah & Page, 1: Direct Page
  final _parahCtrl = TextEditingController();
  final _pageInParahCtrl = TextEditingController();
  final _directPageCtrl = TextEditingController();
  String? _previewText;

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

  void _submit() {
    if (_mode == 0) {
      final p = int.tryParse(_parahCtrl.text.trim());
      final pip = int.tryParse(_pageInParahCtrl.text.trim());
      if (p == null || p < 1 || p > 30 || pip == null || pip < 1 || pip > 20) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isUrdu
                ? 'درست پارہ (1-30) اور صفحہ (1-20) درج کریں'
                : 'Enter valid Parah (1-30) and Page (1-20)'),
          ),
        );
        return;
      }
      final target =
          (juzList[p - 1].startPage + pip - 1).clamp(1, totalPagesInMushaf);
      widget.onJump(target);
    } else {
      final page = int.tryParse(_directPageCtrl.text.trim());
      if (page == null || page < 1 || page > totalPagesInMushaf) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isUrdu
                ? 'درست صفحہ نمبر (1-611) درج کریں'
                : 'Enter a valid page number (1-611)'),
          ),
        );
        return;
      }
      widget.onJump(page.clamp(1, totalPagesInMushaf));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.auto_stories, color: cs.primary, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.isUrdu ? 'پارہ / صفحہ پر جائیں' : 'Jump to Page / Parah',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 18,
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
            // Mode selector
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Center(
                      child: Text(
                        widget.isUrdu ? 'پارہ اور صفحہ' : 'Parah & Page',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _mode == 0 ? cs.onPrimary : cs.onSurface,
                        ),
                      ),
                    ),
                    selected: _mode == 0,
                    selectedColor: cs.primary,
                    onSelected: (_) => setState(() {
                      _mode = 0;
                      _updatePreview();
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Center(
                      child: Text(
                        widget.isUrdu ? 'براہ راست صفحہ' : 'Direct Page',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _mode == 1 ? cs.onPrimary : cs.onSurface,
                        ),
                      ),
                    ),
                    selected: _mode == 1,
                    selectedColor: cs.primary,
                    onSelected: (_) => setState(() => _mode = 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_mode == 0) ...[
              Text(
                widget.isUrdu
                    ? 'ہر پارے میں 20 صفحات ہوتے ہیں (مثال: پارہ 2، صفحہ 10)'
                    : 'Each Parah has 20 pages (e.g. Parah 2, Page 10)',
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
                            widget.isUrdu ? 'پارہ (1-30)' : 'Parah (1-30)',
                        labelStyle: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.7)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_previewText != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _previewText!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ] else ...[
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
                    borderRadius: BorderRadius.circular(12),
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
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
