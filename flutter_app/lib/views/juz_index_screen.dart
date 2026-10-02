import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/juz_data.dart';
import '../data/quran_data.dart' show totalPagesInMushaf;
import '../services/audio_recitation_service.dart';
import '../services/preferences_service.dart';
import '../utils/script_font.dart';

/// Browse the 30 Ajza' of the Quran and jump to a juz's start page.
class JuzIndexScreen extends StatefulWidget {
  final void Function(int page) onOpenPage;
  const JuzIndexScreen({required this.onOpenPage, super.key});

  @override
  State<JuzIndexScreen> createState() => _JuzIndexScreenState();
}

class _JuzIndexScreenState extends State<JuzIndexScreen> {
  /// 0: all, 1: juz 1-10, 2: juz 11-20, 3: juz 21-30
  int _filter = 0;

  List<JuzInfo> get _filteredJuz {
    if (_filter == 0) return juzList;
    final min = (_filter - 1) * 10 + 1;
    final max = _filter * 10;
    return juzList.where((j) => j.number >= min && j.number <= max).toList();
  }

  int _juzLength(JuzInfo j) {
    final idx = juzList.indexWhere((x) => x.number == j.number);
    if (idx >= 0 && idx < juzList.length - 1) {
      return juzList[idx + 1].startPage - j.startPage;
    }
    return totalPagesInMushaf - j.startPage + 1;
  }

  Future<void> _playJuz(JuzInfo j) async {
    final surahNumber = int.tryParse(j.startVerse.split(':').first) ?? 1;
    final audio = Provider.of<AudioRecitationService>(context, listen: false);
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    audio.setRepeatMode(prefs.repeatMode);
    await audio.setSpeed(prefs.playbackSpeed);
    await audio.playSurah(surahNumber: surahNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Juz Index پارے'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                _statChip(context, "30 Sacred Ajza'"),
                const SizedBox(width: 8),
                _statChip(context, '20 Pages Per Juz'),
                const SizedBox(width: 8),
                _statChip(context, '60 Ahzab • 240 Quarters'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(context, 0, 'All 30'),
                  const SizedBox(width: 8),
                  _filterChip(context, 1, 'Juz 1–10'),
                  const SizedBox(width: 8),
                  _filterChip(context, 2, 'Juz 11–20'),
                  const SizedBox(width: 8),
                  _filterChip(context, 3, 'Juz 21–30'),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _filteredJuz.length,
              itemBuilder: (context, index) =>
                  _buildJuzCard(context, _filteredJuz[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(BuildContext context, String label) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _filterChip(BuildContext context, int value, String label) {
    final cs = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: _filter == value,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: cs.primary,
      labelStyle: TextStyle(
        color: _filter == value ? cs.onPrimary : cs.onSurface,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildJuzCard(BuildContext context, JuzInfo j) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final badge = j.number.toString().padLeft(2, '0');
    final length = _juzLength(j);

    return Card(
      color: cs.surface,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary,
                  ),
                  child: Center(
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer<PreferencesService>(
                        builder: (context, prefs, _) => Text(
                          j.nameAr,
                          textDirection: TextDirection.rtl,
                          style: arabicStyle(
                            prefs.scriptStyle,
                            fontSize: 20,
                            color: cs.onSurface,
                            scale: prefs.ayahScale,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Juz $badge • ${j.nameTr}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.play_circle_fill, color: cs.primary),
                  tooltip: 'Play recitation',
                  onPressed: () => _playJuz(j),
                ),
                Consumer<PreferencesService>(
                  builder: (context, prefs, _) {
                    final saved = prefs.bookmarks.contains(j.startPage);
                    return IconButton(
                      icon: Icon(
                        saved ? Icons.bookmark : Icons.bookmark_border,
                      ),
                      color: cs.primary,
                      tooltip:
                          saved ? 'Remove bookmark' : 'Bookmark start page',
                      onPressed: () => prefs.toggleBookmark(j.startPage),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Start Page p. ${j.startPage}  •  Length $length Pages  •  2 Hizb',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              j.surahRange,
              style: TextStyle(fontSize: 13, color: cs.onSurface),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => widget.onOpenPage(j.startPage),
                child: Text('Read Juz (p. ${j.startPage})'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
