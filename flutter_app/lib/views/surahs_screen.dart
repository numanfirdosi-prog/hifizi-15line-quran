import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/juz_data.dart';
import '../data/quran_data.dart';
import '../data/surah_intros.dart';
import '../data/surah_intros_urdu.dart';
import '../models/surah.dart';
import '../services/voice_search_service.dart';
import '../services/audio_recitation_service.dart';
import '../services/preferences_service.dart';
import '../utils/script_font.dart';

/// Surah Index: all 114 surahs with trilingual search, Makki/Madani +
/// bookmark filters, sorting, per-surah info / bookmark / read / audio
/// actions, and the Parah→Page jump dialog.
///
/// Bottom navigation is provided by the parent HomeNavigationScreen
/// (this screen is one of its tabs), so no nested bar is built here.
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

  static const _sortOptions = [
    'Mushaf Order',
    'Alphabetical',
    'Longest First',
    'Shortest First',
  ];

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
    switch (_sort) {
      case 'Alphabetical':
        base.sort((a, b) => a.nameEn.compareTo(b.nameEn));
      case 'Longest First':
        base.sort((a, b) => b.totalAyahs.compareTo(a.totalAyahs));
      case 'Shortest First':
        base.sort((a, b) => a.totalAyahs.compareTo(b.totalAyahs));
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
    final urduIntro = surahIntrosUrdu[surah.number] ?? '';
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
                  Flexible(
                    child: Text(
                      surah.nameAr,
                      overflow: TextOverflow.ellipsis,
                      style: arabicStyle(prefs.scriptStyle,
                          fontSize: 26, color: cs.primary),
                    ),
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
                    label: Text(prefs.isUrdu
                        ? '${surah.totalAyahs} آیات'
                        : '${surah.totalAyahs} verses'),
                    backgroundColor:
                        cs.onSurface.withValues(alpha: 0.08),
                    labelStyle: TextStyle(
                        color: cs.onSurface, fontSize: 12),
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    label: Text(prefs.isUrdu
                        ? 'صفحہ ${surah.startPage}'
                        : 'Page ${surah.startPage}'),
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
              if (urduIntro.isNotEmpty) ...[
                Text(
                  urduIntro,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.9),
                    fontSize: 14,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 8),
                Divider(
                  color: cs.onSurface.withValues(alpha: 0.15),
                  height: 1,
                ),
                const SizedBox(height: 8),
              ],
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
                      label: Text(prefs.isUrdu ? 'پڑھیں' : 'Read'),
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

  /// Parah/Page jump dialog: Parah (1-30) + page-in-parah (1-20).
  /// Computes the global mushaf page via juzList and opens it.
  void _showParahPageDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    final isUrdu = prefs.isUrdu;
    final parahCtrl = TextEditingController();
    final pageCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        String? error;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text(isUrdu ? 'پارہ / صفحہ' : 'Parah / Page'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isUrdu
                      ? 'ہر پارے میں 20 صفحات'
                      : 'Each parah has 20 pages',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: parahCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isUrdu ? 'پارہ (1-30)' : 'Parah (1-30)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isUrdu
                        ? 'پارے کا صفحہ (1-20)'
                        : 'Page in Parah (1-20)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    style: TextStyle(color: cs.error, fontSize: 12),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(isUrdu ? 'منسوخ' : 'Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final parah = int.tryParse(parahCtrl.text.trim());
                  final pageInParah = int.tryParse(pageCtrl.text.trim());
                  if (parah == null ||
                      parah < 1 ||
                      parah > 30 ||
                      pageInParah == null ||
                      pageInParah < 1 ||
                      pageInParah > 20) {
                    setDialogState(() {
                      error = isUrdu
                          ? 'براہ کرم درست نمبر درج کریں'
                          : 'Please enter valid numbers';
                    });
                    return;
                  }
                  final globalPage = (juzList[parah - 1].startPage +
                          pageInParah -
                          1)
                      .clamp(1, 611);
                  Navigator.of(ctx).pop();
                  widget.onOpenPage(globalPage);
                },
                child: Text(isUrdu ? 'کھولیں' : 'Go'),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      parahCtrl.dispose();
      pageCtrl.dispose();
    });
  }

  /// Premium surah card matching the Juz Index card design: gold-ringed
  /// number medallion, Arabic + English names, play / bookmark / info
  /// actions, verified metadata rows, and a full-width gold Read button.
  /// All four overflow-menu actions are integrated: Read (gold button +
  /// card tap), Play (toggle), Bookmark (toggle), About (info sheet).
  Widget _buildSurahCard(
    BuildContext context,
    Surah surah, {
    required bool isCurrentlyPlaying,
    required bool isBookmarked,
  }) {
    final cs = Theme.of(context).colorScheme;
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    final audio = Provider.of<AudioRecitationService>(context, listen: false);
    final badge = surah.number.toString().padLeft(2, '0');

    return Card(
      color: cs.surface,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          // Full gold ring while its recitation is playing.
          color: isCurrentlyPlaying
              ? cs.primary
              : cs.primary.withValues(alpha: 0.25),
          width: isCurrentlyPlaying ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => widget.onOpenPage(surah.startPage),
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
                      border: Border.all(color: cs.primary, width: 1.5),
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
                        Text(
                          surah.nameAr,
                          textDirection: TextDirection.rtl,
                          style: arabicStyle(
                            prefs.scriptStyle,
                            fontSize: 20,
                            color: cs.onSurface,
                            scale: prefs.ayahScale,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Surah $badge \u2022 ${surah.nameEn}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Play / pause recitation
                  _cardIconButton(
                    context,
                    icon: isCurrentlyPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    tooltip: isCurrentlyPlaying
                        ? 'Pause recitation'
                        : 'Play recitation',
                    onPressed: () {
                      if (isCurrentlyPlaying) {
                        audio.pause();
                      } else {
                        audio.playSurah(surahNumber: surah.number);
                      }
                    },
                  ),
                  // Bookmark start page
                  _cardIconButton(
                    context,
                    icon: isBookmarked
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    tooltip: isBookmarked
                        ? 'Remove bookmark'
                        : 'Bookmark this surah',
                    onPressed: () => prefs.toggleBookmark(surah.startPage),
                  ),
                  // Surah info sheet (About this surah)
                  _cardIconButton(
                    context,
                    icon: Icons.info_outline,
                    tooltip: 'About this surah',
                    onPressed: () => _showSurahIntro(context, surah),
                  ),
                ],
              ),
              Divider(
                color: cs.primary.withValues(alpha: 0.25),
                height: 20,
              ),
              // Verified metadata
              _metaRow(
                context,
                Icons.auto_stories_outlined,
                '${surah.totalAyahs} verses \u2022 ${surah.isMeccan ? 'Makki' : 'Madani'}',
              ),
              const SizedBox(height: 6),
              _metaRow(
                context,
                Icons.menu_book_outlined,
                'Starts on Page ${surah.startPage} \u2022 Juz ${juzForPage(surah.startPage)}',
              ),
              const SizedBox(height: 6),
              _metaRow(
                context,
                Icons.translate_outlined,
                surah.nameHi,
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
                  onPressed: () => widget.onOpenPage(surah.startPage),
                  label:
                      Text('Read Surah $badge \u2022 Page ${surah.startPage}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact header icon button: a 36px hit area keeps three actions from
  /// crowding the surah names on narrow phones.
  Widget _cardIconButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      icon: Icon(icon, color: cs.primary),
      tooltip: tooltip,
      onPressed: onPressed,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.find_in_page),
            tooltip: prefs.isUrdu ? 'پارہ / صفحہ' : 'Parah / Page',
            onPressed: () => _showParahPageDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Voice Action Header (theme-driven so it matches the
          // active Night Slate / Emerald Day / Antique Parchment palette).
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                bottom: BorderSide(
                  color: cs.primary.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: TextStyle(color: cs.onSurface),
                        decoration: InputDecoration(
                          hintText:
                              'Search Surah (Hindi / English / 1-114)...',
                          hintStyle: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.45),
                              fontSize: 13),
                          prefixIcon:
                              Icon(Icons.search, color: cs.primary),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear,
                                      color: cs.onSurface
                                          .withValues(alpha: 0.5)),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor:
                              cs.onSurface.withValues(alpha: 0.07),
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
                          color: _isListening ? cs.error : cs.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isListening ? cs.error : cs.primary)
                                  .withValues(alpha: 0.35),
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
                        color: _isListening
                            ? cs.primary
                            : cs.onSurface.withValues(alpha: 0.65),
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
                          onSelected: (_) =>
                              setState(() => _filterIndex = i),
                          selectedColor: cs.primary,
                          backgroundColor:
                              cs.onSurface.withValues(alpha: 0.08),
                          labelStyle: TextStyle(
                            color: selected
                                ? cs.onPrimary
                                : cs.onSurface.withValues(alpha: 0.75),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          side: BorderSide(
                            color: selected
                                ? Colors.transparent
                                : cs.primary.withValues(alpha: 0.3),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 4),
                // Sort dropdown + result count
                Row(
                  children: [
                    Text('Sort:',
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.6),
                            fontSize: 12)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _sort,
                      dropdownColor: cs.surface,
                      style: TextStyle(color: cs.primary, fontSize: 13),
                      underline: const SizedBox(),
                      icon: Icon(Icons.arrow_drop_down, color: cs.primary),
                      items: _sortOptions
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
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.45),
                            fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),

          // Surah List
          Expanded(
            child: displayedSurahs.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 54,
                              color: cs.onSurface.withValues(alpha: 0.38)),
                          const SizedBox(height: 12),
                          Text(
                            'No Surah matched your search.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600,
                                fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Try Hindi (सूरह यासीन), English (Yaseen),\nArabic (يس) or a number (1-114)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color:
                                    cs.onSurface.withValues(alpha: 0.55),
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: displayedSurahs.length,
                    itemBuilder: (context, index) {
                      final surah = displayedSurahs[index];
                      final isCurrentlyPlaying =
                          audio.isPlaying && audio.currentSurah == surah.number;
                      final isBookmarked =
                          bookmarked.contains(surah.startPage);
                      return _buildSurahCard(
                        context,
                        surah,
                        isCurrentlyPlaying: isCurrentlyPlaying,
                        isBookmarked: isBookmarked,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
