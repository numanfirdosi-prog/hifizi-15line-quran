import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/juz_data.dart';
import '../data/quran_data.dart';
import '../data/surah_intros.dart';
import '../models/surah.dart';
import '../services/voice_search_service.dart';
import '../services/audio_recitation_service.dart';
import '../services/preferences_service.dart';
import '../utils/script_font.dart';

class SurahsScreen extends StatefulWidget {
  final void Function(int page) onOpenPage;
  const SurahsScreen({required this.onOpenPage, super.key});

  @override
  State<SurahsScreen> createState() => _SurahsScreenState();
}

class _SurahsScreenState extends State<SurahsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final VoiceSearchService _voiceService = VoiceSearchService();
  String _query = '';
  // 0 = All, 1 = Makki, 2 = Madani, 3 = Bookmarked
  int _filterIndex = 0;
  String _sort = 'Mushaf Order';
  bool _isListening = false;
  String _voiceFeedback = '';

  @override
  void initState() {
    super.initState();
    _voiceService.init();
  }

  @override
  void dispose() {
    // Never leave the mic listening after the screen is gone.
    _voiceService.stopListening();
    _searchController.dispose();
    super.dispose();
  }

  List<Surah> _filteredSurahs(List<int> bookmarks) {
    List<Surah> base = _query.trim().isEmpty
        ? List<Surah>.from(allSurahs)
        : _voiceService.searchSurahs(_query);
    if (_filterIndex == 1) {
      base = base.where((s) => s.isMeccan).toList();
    } else if (_filterIndex == 2) {
      base = base.where((s) => !s.isMeccan).toList();
    } else if (_filterIndex == 3) {
      base = base.where((s) => bookmarks.contains(s.startPage)).toList();
    }
    if (_sort == 'Alphabetical') {
      base.sort((a, b) => a.nameEn.compareTo(b.nameEn));
    }
    return base;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _query = query;
      _voiceFeedback = '';
    });
  }

  Future<void> _toggleVoiceSearch() async {
    if (_isListening) {
      await _voiceService.stopListening();
      if (!mounted) return;
      setState(() {
        _isListening = false;
      });
      return;
    }

    setState(() {
      _isListening = true;
      _voiceFeedback = 'Listening in Hindi / English / Urdu...';
    });

    final started = await _voiceService.startListening(
      localeId: 'hi_IN',
      onResult: (spokenText, matchedSurahs) {
        if (!mounted) return;
        setState(() {
          _searchController.text = spokenText;
          _query = spokenText;
          _voiceFeedback = 'Heard: "$spokenText"';
          _isListening = false;
        });
      },
    );
    if (!mounted) return;
    if (!started) {
      // Speech recognition unavailable (e.g. permission denied): reset the
      // mic UI instead of leaving it stuck on "Listening...".
      setState(() {
        _isListening = false;
        _voiceFeedback = 'Voice search unavailable on this device.';
      });
    }
  }

  /// Surah intro bottom sheet: names, meaning, revelation type, verse
  /// count, commentary, and Read / Play actions.
  void _showSurahIntro(BuildContext context, Surah surah) {
    final cs = Theme.of(context).colorScheme;
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    final audio = Provider.of<AudioRecitationService>(context, listen: false);
    final intro = surahIntros[surah.number] ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${surah.number}. ${surah.nameEn}',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Text(
                    surah.nameAr,
                    style: arabicStyle(prefs.scriptStyle,
                        fontSize: 26, color: cs.primary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                surah.meaning,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(surah.isMeccan ? 'Makki' : 'Madani'),
                    backgroundColor:
                        cs.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                        color: cs.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    label: Text('${surah.totalAyahs} verses'),
                    backgroundColor:
                        cs.onSurface.withValues(alpha: 0.08),
                    labelStyle: TextStyle(
                        color: cs.onSurface, fontSize: 12),
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    label: Text('Page ${surah.startPage}'),
                    backgroundColor:
                        cs.onSurface.withValues(alpha: 0.08),
                    labelStyle: TextStyle(
                        color: cs.onSurface, fontSize: 12),
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                intro,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.85),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.menu_book, size: 18),
                      label: const Text('Read'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        widget.onOpenPage(surah.startPage);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Play'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.primary,
                        side: BorderSide(color: cs.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        audio.playSurah(surahNumber: surah.number);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final audio = Provider.of<AudioRecitationService>(context);
    final prefs = Provider.of<PreferencesService>(context);
    final bookmarked = prefs.bookmarks;
    final displayedSurahs = _filteredSurahs(bookmarked);

    final makkiCount = allSurahs.where((s) => s.isMeccan).length;
    final madaniCount = allSurahs.length - makkiCount;
    final filterLabels = [
      'All ${allSurahs.length}',
      'Makki $makkiCount',
      'Madani $madaniCount',
      'Bookmarked (${bookmarked.length})',
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'فہرست سورتیں (114 Surahs)',
          style: TextStyle(
              color: cs.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Search & Voice Action Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF0B2D22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search Surah (Hindi / English / 1-114)...',
                          hintStyle: const TextStyle(
                              color: Colors.white54, fontSize: 13),
                          prefixIcon: Icon(Icons.search, color: cs.primary),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: Colors.white54),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFF144234),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Voice Search Mic Button
                    GestureDetector(
                      onTap: _toggleVoiceSearch,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isListening
                              ? Colors.redAccent
                              : cs.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _isListening
                                  ? Colors.redAccent.withValues(alpha: 0.5)
                                  : cs.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: cs.onPrimary,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_voiceFeedback.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 8),
                    child: Text(
                      _voiceFeedback,
                      style: TextStyle(
                        color:
                            _isListening ? Colors.amberAccent : Colors.white70,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                // Filter chips: All / Makki / Madani / Bookmarked
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(filterLabels.length, (i) {
                      final selected = _filterIndex == i;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filterLabels[i]),
                          selected: selected,
                          onSelected: (_) => setState(() => _filterIndex = i),
                          selectedColor: cs.primary,
                          backgroundColor: const Color(0xFF144234),
                          labelStyle: TextStyle(
                            color: selected ? cs.onPrimary : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 4),
                // Sort dropdown
                Row(
                  children: [
                    const Text('Sort:',
                        style: TextStyle(color: Colors.white60, fontSize: 12)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _sort,
                      dropdownColor: cs.surface,
                      style: TextStyle(color: cs.primary, fontSize: 13),
                      underline: const SizedBox(),
                      icon: Icon(Icons.arrow_drop_down, color: cs.primary),
                      items: const ['Mushaf Order', 'Alphabetical']
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _sort = v);
                      },
                    ),
                    const Spacer(),
                    Text('${displayedSurahs.length} surahs',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),

          // Surah List
          Expanded(
            child: displayedSurahs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 54,
                            color: cs.onSurface.withValues(alpha: 0.38)),
                        SizedBox(height: 12),
                        Text(
                          'No Surah matched your search.\nTry Hindi (सूरह यासीन) or English (Yaseen)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color:
                                  cs.onSurface.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: displayedSurahs.length,
                    separatorBuilder: (ctx, i) =>
                        Divider(
                            color: cs.onSurface.withValues(alpha: 0.12),
                            height: 1),
                    itemBuilder: (context, index) {
                      final surah = displayedSurahs[index];
                      final isCurrentlyPlaying =
                          audio.isPlaying && audio.currentSurah == surah.number;
                      final isBookmarked = bookmarked.contains(surah.startPage);

                      return Container(
                        color: isCurrentlyPlaying
                            ? const Color(0xFF144234)
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            // Surah Number Badge
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: cs.primary, width: 1.5),
                                color: cs.surface,
                              ),
                              child: Center(
                                child: Text(
                                  surah.number.toString(),
                                  style: TextStyle(
                                    color: cs.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Surah Details (trilingual)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          surah.nameEn,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: cs.onSurface,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: cs.onSurface.withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          surah.nameHi,
                                          style: TextStyle(
                                            color: cs.primary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${surah.totalAyahs} verses • Page ${surah.startPage} • Juz ${juzForPage(surah.startPage)}',
                                    style: TextStyle(
                                        color: cs.onSurface
                                            .withValues(alpha: 0.6),
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),

                            // Arabic Name (flexible: long names must not push the
                            // trailing buttons off-screen on narrow phones)
                            Flexible(
                              child: Text(
                                surah.nameAr,
                                overflow: TextOverflow.ellipsis,
                                style: arabicStyle(prefs.scriptStyle,
                                    fontSize: 20, color: cs.primary),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // Surah intro (tafsir-style commentary)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: Icon(Icons.info_outline,
                                  color: cs.primary.withValues(alpha: 0.8),
                                  size: 20),
                              tooltip: 'About this surah',
                              onPressed: () =>
                                  _showSurahIntro(context, surah),
                            ),

                            // Bookmark toggle
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                isBookmarked
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: cs.primary,
                                size: 22,
                              ),
                              tooltip: isBookmarked
                                  ? 'Remove bookmark'
                                  : 'Bookmark this surah',
                              onPressed: () {
                                prefs.toggleBookmark(surah.startPage);
                              },
                            ),

                            // Read Button (opens Mushaf)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: Icon(Icons.menu_book, color: cs.primary, size: 22),
                              tooltip: 'Read (p. ${surah.startPage})',
                              onPressed: () =>
                                  widget.onOpenPage(surah.startPage),
                            ),

                            // Audio Recite Button
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                isCurrentlyPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_outline,
                                color: cs.primary,
                                size: 24,
                              ),
                              tooltip: 'Listen Audio',
                              onPressed: () {
                                if (isCurrentlyPlaying) {
                                  audio.pause();
                                } else {
                                  audio.playSurah(surahNumber: surah.number);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
