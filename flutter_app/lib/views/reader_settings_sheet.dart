import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/quran_data.dart';
import '../services/audio_recitation_service.dart';
import '../services/preferences_service.dart';

/// Reader settings bottom sheet (3-dot menu on the Quran reading page).
///
/// Mirrors the reference design: Display Mode, Qari (Reciter), Ayah (Range),
/// Audio Mode and Background Playback — every option is fully functional.
void showReaderSettingsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _ReaderSettingsSheet(),
  );
}

class _ReaderSettingsSheet extends StatelessWidget {
  const _ReaderSettingsSheet();

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
                    color: cs.onSurface.withValues(alpha: 0.6),
                    fontSize: 13)),
            trailing: Icon(Icons.chevron_right,
                color: cs.onSurface.withValues(alpha: 0.5)),
            onTap: () => _showThemeDialog(context),
          ),
          Divider(
              height: 1,
              color: cs.onSurface.withValues(alpha: 0.12)),
          // Qari (Reciter)
          ListTile(
            title: Text('Qari (Reciter)',
                style: TextStyle(color: cs.onSurface, fontSize: 15)),
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
                style: TextStyle(color: cs.onSurface, fontSize: 15)),
            subtitle: Text(
              audio.repeatRangeLabel ??
                  'Select range of ayat for playback',
              style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.6), fontSize: 13),
            ),
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
                style: TextStyle(color: cs.onSurface, fontSize: 15)),
            subtitle: Text(
              'Enable audio recitation with ayat highlighting',
              style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.6), fontSize: 13),
            ),
            value: prefs.audioHighlightEnabled,
            activeColor: cs.primary,
            onChanged: (v) => prefs.setAudioHighlightEnabled(v),
          ),
          Divider(
              height: 1,
              color: cs.onSurface.withValues(alpha: 0.12)),
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
    final prefs =
        Provider.of<PreferencesService>(context, listen: false);
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text('Display Mode',
            style: TextStyle(color: cs.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _themes.entries
              .map(
                (e) => RadioListTile<String>(
                  title: Text(e.value,
                      style:
                          TextStyle(color: cs.onSurface, fontSize: 14)),
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
    final audio =
        Provider.of<AudioRecitationService>(context, listen: false);
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: cs.surface,
        title:
            Text('Qari (Reciter)', style: TextStyle(color: cs.onSurface)),
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
                groupValue:
                    selected ? q.id : '__none__',
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
    final audio =
        Provider.of<AudioRecitationService>(context, listen: false);
    final cs = Theme.of(context).colorScheme;
    int surah = audio.currentSurah;
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (dctx, setState) => AlertDialog(
          backgroundColor: cs.surface,
          title: Text('Ayah (Range)',
              style: TextStyle(color: cs.onSurface)),
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
              child:
                  Text('Clear', style: TextStyle(color: cs.primary)),
            ),
            FilledButton(
              onPressed: () async {
                final start = int.tryParse(startCtrl.text.trim());
                final end = int.tryParse(endCtrl.text.trim());
                if (start == null || end == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Ayah numbers likhein')),
                  );
                  return;
                }
                final ok = await audio.setAyahRepeatRange(
                    surah: surah, startAyah: start, endAyah: end);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Ghalat range hai')),
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
    );
  }
}
