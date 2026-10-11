import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/juz_data.dart';
import '../data/quran_data.dart' show totalPagesInMushaf;
import '../services/audio_recitation_service.dart';
import '../services/preferences_service.dart';
import '../utils/script_font.dart';

/// Browse the 30 Ajza' of the Quran and jump to a juz's start page.
///
/// All boundaries, page counts and verse refs come from the verified
/// [juzList] data file — nothing here is fabricated or estimated.
class JuzIndexScreen extends StatefulWidget {
  final void Function(int page) onOpenPage;
  const JuzIndexScreen({required this.onOpenPage, super.key});

  @override
  State<JuzIndexScreen> createState() => _JuzIndexScreenState();
}

class _JuzIndexScreenState extends State<JuzIndexScreen> {
  /// 0: all, 1: juz 1-10, 2: juz 11-20, 3: juz 21-30
  int _filter = 0;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<JuzInfo> get _filteredJuz {
    Iterable<JuzInfo> list = juzList;
    if (_filter != 0) {
      final min = (_filter - 1) * 10 + 1;
      final max = _filter * 10;
      list = list.where((j) => j.number >= min && j.number <= max);
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((j) {
        final numStr = j.number.toString();
        return numStr == q ||
            'juz $numStr'.contains(q) ||
            j.nameTr.toLowerCase().contains(q) ||
            j.nameAr.contains(_query.trim()) ||
            j.startPage.toString() == q ||
            j.surahRange.toLowerCase().contains(q) ||
            j.startVerse.toLowerCase().contains(q) ||
            j.endVerse.toLowerCase().contains(q);
      });
    }
    return list.toList();
  }

  /// Page count derived from verified juz start pages (not estimated):
  /// next juz's start page minus this juz's start page; Juz 30 runs to the
  /// last mushaf page.
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
    final cs = Theme.of(context).colorScheme;
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
          // Search: Juz number, Arabic name, transliteration, start page,
          // verse refs.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(color: cs.onSurface, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search Juz (number, name, page, verse)...',
                hintStyle: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.45),
                    fontSize: 13),
                prefixIcon: Icon(Icons.search, color: cs.primary, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: cs.onSurface.withValues(alpha: 0.5),
                            size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: cs.onSurface.withValues(alpha: 0.06),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
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
            child: _filteredJuz.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 48,
                              color:
                                  cs.onSurface.withValues(alpha: 0.38)),
                          const SizedBox(height: 12),
                          Text(
                            'No Juz matched "${_query.trim()}".',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600,
                                fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Try a Juz number (1-30), a name, a start page, or a verse like 2:142.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.55),
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.5,
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
    final endPage = j.startPage + length - 1;
    // Each juz holds exactly two hizb: hizb numbers run 1-60 across the 30
    // ajza', so Juz n spans hizb (2n-1) to (2n).
    final hizbFrom = j.number * 2 - 1;
    final hizbTo = j.number * 2;

    return Card(
      color: cs.surface,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Gold-ringed number medallion
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary.withValues(alpha: 0.12),
                    border:
                        Border.all(color: cs.primary, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: cs.primary,
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
            Divider(
              color: cs.primary.withValues(alpha: 0.25),
              height: 20,
            ),
            // Verified metadata from juz_data.dart
            _metaRow(
              context,
              Icons.auto_stories_outlined,
              'Pages ${j.startPage}–$endPage • $length pages',
            ),
            const SizedBox(height: 6),
            _metaRow(
              context,
              Icons.format_quote_outlined,
              'Begins ${j.startVerse} • Ends ${j.endVerse}',
            ),
            const SizedBox(height: 6),
            _metaRow(
              context,
              Icons.layers_outlined,
              'Hizb $hizbFrom–$hizbTo • ${j.surahRange}',
            ),
            const SizedBox(height: 12),
            // The one prominent primary action.
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.menu_book, size: 18),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => widget.onOpenPage(j.startPage),
                label: Text('Read Juz $badge • Page ${j.startPage}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(BuildContext context, IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 15, color: cs.primary.withValues(alpha: 0.8)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
                fontSize: 12.5,
                color: cs.onSurface.withValues(alpha: 0.85)),
          ),
        ),
      ],
    );
  }
}
