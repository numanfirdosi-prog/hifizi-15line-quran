import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/juz_data.dart';
import '../data/quran_data.dart';
import '../services/audio_recitation_service.dart';
import '../services/preferences_service.dart';

/// Reader settings bottom sheet (3-dot menu on the Quran reading page).
///
/// Mirrors the reference design: Display Mode, Qari (Reciter), Ayah (Range),
/// Audio Mode and Background Playback — every option is fully functional.
void showReaderSettingsSheet(BuildContext context,
    {void Function(int page)? onJumpToPage}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ReaderSettingsSheet(onJumpToPage: onJumpToPage),
  );
}

class _ReaderSettingsSheet extends StatelessWidget {
  final void Function(int page)? onJumpToPage;
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
            'Settings',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
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
          // Jump to Page / Parah
          ListTile(
            leading: Icon(Icons.explore_outlined, color: cs.primary),
            title: Text('Jump to Page / Parah',
                style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            subtitle: Text('صفحہ یا پارہ پر جائیں (Parah 1-30, Page 1-20)',
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.6), fontSize: 13)),
            trailing: Icon(Icons.chevron_right,
                color: cs.onSurface.withValues(alpha: 0.5)),
            onTap: () {
              Navigator.pop(context);
              _showJumpToPageDialog(context, onJumpToPage);
            },
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

  void _showJumpToPageDialog(
      BuildContext context, void Function(int page)? onJumpToPage) {
    final cs = Theme.of(context).colorScheme;
    int selectedMode = 0; // 0: By Parah, 1: By Page
    int paraNum = 1;
    final paraPageCtrl = TextEditingController(text: '1');
    final directPageCtrl = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (ctx, setState) {
          int computedPage;
          if (selectedMode == 0) {
            final p = paraNum.clamp(1, 30);
            final pg = int.tryParse(paraPageCtrl.text.trim()) ?? 1;
            final clampedPg = pg.clamp(1, 20);
            if (p == 1) {
              computedPage = clampedPg;
            } else {
              computedPage =
                  (juzList[p - 1].startPage + (clampedPg - 1))
                      .clamp(1, totalPagesInMushaf);
            }
          } else {
            final dp = int.tryParse(directPageCtrl.text.trim()) ?? 1;
            computedPage = dp.clamp(1, totalPagesInMushaf);
          }

          return AlertDialog(
            backgroundColor: cs.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
            ),
            title: Row(
              children: [
                Icon(Icons.menu_book, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Jump to Page / Parah',
                    style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mode Selector Tabs
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        label: Text('By Parah\nپارہ سے',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12)),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Text('By Page\nصفحہ سے',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    selected: {selectedMode},
                    onSelectionChanged: (set) {
                      setState(() {
                        selectedMode = set.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  if (selectedMode == 0) ...[
                    // Parah Selector Dropdown
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Parah / Juz (1 - 30)',
                        labelStyle: TextStyle(color: cs.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: paraNum,
                          isExpanded: true,
                          dropdownColor: cs.surface,
                          items: List.generate(30, (i) {
                            final j = juzList[i];
                            return DropdownMenuItem(
                              value: i + 1,
                              child: Text(
                                'Para ${i + 1}: ${j.nameAr} (${j.nameTr})',
                                style: TextStyle(
                                    color: cs.onSurface, fontSize: 13),
                              ),
                            );
                          }),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                paraNum = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Page inside Parah
                    TextField(
                      controller: paraPageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Page in Parah (1 - 20)',
                        hintText: 'e.g. 10',
                        helperText: 'Standard 20 pages per Parah',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon:
                            Icon(Icons.auto_stories, color: cs.primary),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ] else ...[
                    // Direct Page
                    TextField(
                      controller: directPageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Mushaf Page (1 - 611)',
                        hintText: 'e.g. 32',
                        helperText: 'Total 611 pages in Mushaf',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon:
                            Icon(Icons.find_in_page, color: cs.primary),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: cs.primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Destination:',
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.7),
                              fontSize: 13),
                        ),
                        Text(
                          'Page $computedPage of $totalPagesInMushaf',
                          style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dctx),
                child: Text('Cancel',
                    style:
                        TextStyle(color: cs.onSurface.withValues(alpha: 0.7))),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(dctx);
                  onJumpToPage?.call(computedPage);
                },
                child: const Text('Go to Page • جائیں'),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      paraPageCtrl.dispose();
      directPageCtrl.dispose();
    });
  }
}
