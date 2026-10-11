import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/quran_data.dart';
import '../data/verse_index.dart';
import '../services/preferences_service.dart';
import '../services/voice_search_service.dart';
import '../utils/script_font.dart';
import 'ayah_player_sheet.dart';

/// Full-text search across the Quran (Arabic + English + Urdu). Filter runs
/// only on submit (or voice input), never on every keystroke.
///
/// States: initial hint (no query) / loading data / searching / results
/// (paginated) / no results / error + retry. The last query is preserved
/// across navigation via SharedPreferences.
class SearchQuranScreen extends StatefulWidget {
  final void Function(int page) onOpenPage;
  const SearchQuranScreen({required this.onOpenPage, super.key});

  @override
  State<SearchQuranScreen> createState() => _SearchQuranScreenState();
}

class _SearchQuranScreenState extends State<SearchQuranScreen> {
  static const int _pageSize = 50;
  static const String _kLastQueryKey = 'nur_last_search_query';

  final TextEditingController _controller = TextEditingController();
  final VoiceSearchService _voice = VoiceSearchService();
  Timer? _voicePoll;

  Future<List<dynamic>> _loadFuture = Future.wait(
      [loadQuranText(), loadVersePageIndex(), loadUrduKanzulIman()]);
  List<QuranTextEntry> _results = [];
  Map<String, String> _urdu = {};
  bool _searched = false;
  bool _searching = false;
  String? _searchError;
  int _visibleCount = _pageSize;
  bool _listening = false;

  /// Precomputed normalized corpora (built once per data load) so each
  /// search is a fast substring scan instead of re-normalizing 6,236
  /// verses on every keystroke-submit.
  List<String>? _normArCache;
  List<String>? _normEnCache;
  List<String>? _normUrCache;

  @override
  void initState() {
    super.initState();
    // Preserve the query when returning: restore the last search after
    // the data loads and re-run it.
    _loadFuture.then((_) async {
      if (!mounted) return;
      try {
        final sp = await SharedPreferences.getInstance();
        final q = sp.getString(_kLastQueryKey) ?? '';
        if (q.isNotEmpty && mounted && _controller.text.isEmpty) {
          _controller.text = q;
          await _runSearch();
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _voicePoll?.cancel();
    _voice.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _ensureCaches(List<QuranTextEntry> entries) {
    if (_normArCache != null) return;
    _normArCache =
        entries.map((e) => normalizeArabic(e.ar)).toList(growable: false);
    _normEnCache =
        entries.map((e) => e.en.toLowerCase()).toList(growable: false);
    _normUrCache = entries
        .map((e) => normalizeUrdu(_urdu['${e.s}:${e.v}'] ?? ''))
        .toList(growable: false);
  }

  Future<void> _runSearch() async {
    final q = _controller.text.trim();
    if (q.isEmpty || _searching) return;
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      // Diacritics-only queries (e.g. just harakat, no letters) normalize
      // to an empty string, and `contains('')` matches every verse — ~200
      // bogus results. Require at least one actual letter; otherwise show
      // the normal "no results" UI.
      final stripped = normalizeArabic(q).replaceAll(RegExp(r'\s+'), '');
      if (!RegExp('[؀-ۿa-zA-Z]').hasMatch(stripped)) {
        if (!mounted) return;
        setState(() {
          _results = [];
          _searched = true;
          _searching = false;
          _visibleCount = _pageSize;
        });
        return;
      }
      final data = await _loadFuture;
      final entries = data[0] as List<QuranTextEntry>;
      _urdu = data[2] as Map<String, String>;
      _ensureCaches(entries);
      final normQ = normalizeArabic(q);
      final lowerQ = q.toLowerCase();
      // Urdu: match the query against the bundled Kanzul Iman translation,
      // normalized for diacritic-insensitive search (ے/ی, ھ/ہ unified).
      // Only runs when the query is typed in Perso-Arabic script, so
      // English queries never false-positive on Urdu text.
      final urduScript = RegExp('[؀-ۿ]').hasMatch(q);
      final normUrduQ = normalizeUrdu(q);
      // Dedupe by verse key: the strict + lenient passes must never emit
      // the same verse twice.
      final seen = <String>{};
      final results = <QuranTextEntry>[];
      for (var i = 0; i < entries.length; i++) {
        final e = entries[i];
        final key = '${e.s}:${e.v}';
        if (seen.contains(key)) continue;
        if (_normArCache![i].contains(normQ) ||
            _normEnCache![i].contains(lowerQ) ||
            (urduScript &&
                normUrduQ.isNotEmpty &&
                _normUrCache![i].contains(normUrduQ))) {
          seen.add(key);
          results.add(e);
        }
      }
      // Fallback: if strict Arabic search found nothing, try the lenient
      // form (alef stripped) so Uthmani spellings match simplified queries
      // (e.g. فَسْأَلُوا vs فَاسْأَلُوا).
      if (results.isEmpty && normQ.contains(RegExp('[؀-ۿ]'))) {
        final laxQ = normalizeArabicLenient(q);
        for (var i = 0; i < entries.length; i++) {
          final e = entries[i];
          final key = '${e.s}:${e.v}';
          if (seen.contains(key)) continue;
          if (normalizeArabicLenient(e.ar).contains(laxQ)) {
            seen.add(key);
            results.add(e);
          }
        }
      }
      await _persistQuery(q);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searched = true;
        _searching = false;
        _visibleCount = _pageSize;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _searched = true;
        _searchError = 'Search failed — $e';
      });
    }
  }

  Future<void> _persistQuery(String q) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kLastQueryKey, q);
    } catch (_) {}
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _results = [];
      _searched = false;
      _searchError = null;
      _visibleCount = _pageSize;
    });
    _persistQuery('');
  }

  /// Voice input: fills the search field with the recognized words and
  /// runs the search when the recognizer stops.
  Future<void> _startVoice() async {
    setState(() => _listening = true);
    final ok = await _voice.startListening(
      onResult: (words, _) {
        if (!mounted) return;
        _controller.text = words;
        _controller.selection =
            TextSelection.fromPosition(TextPosition(offset: words.length));
      },
    );
    if (!ok) {
      _voicePoll?.cancel();
      if (!mounted) return;
      setState(() => _listening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Voice search is not available on this device')),
      );
      return;
    }
    // The recognizer auto-stops on pause/timeout; poll until it does,
    // then search the final recognized words.
    _voicePoll?.cancel();
    _voicePoll = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (!mounted) return;
      if (!_voice.isListening) {
        _voicePoll?.cancel();
        if (_listening) {
          setState(() => _listening = false);
          _runSearch();
        }
      }
    });
  }

  Future<void> _stopVoice() async {
    _voicePoll?.cancel();
    await _voice.stopListening();
    if (!mounted) return;
    setState(() => _listening = false);
    _runSearch();
  }

  void _retryDataLoad() {
    setState(() {
      _normArCache = null;
      _normEnCache = null;
      _normUrCache = null;
      _loadFuture = Future.wait(
          [loadQuranText(), loadVersePageIndex(), loadUrduKanzulIman()]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final total = _results.length;
    final visible = _visibleCount.clamp(0, total);
    final hasMore = visible < total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Quran'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _runSearch(),
                    decoration: InputDecoration(
                      hintText:
                          'Search any keyword in Arabic, English or Urdu',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _listening ? Icons.mic : Icons.mic_none,
                              color: _listening ? cs.error : null,
                            ),
                            tooltip: _listening
                                ? 'Stop voice input'
                                : 'Voice search',
                            onPressed:
                                _listening ? _stopVoice : _startVoice,
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear',
                            onPressed: _clearSearch,
                          ),
                        ],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  onPressed: _runSearch,
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
          if (_listening)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.error,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Listening… speak now',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          if (_searching)
            LinearProgressIndicator(
              color: cs.primary,
              backgroundColor: cs.primary.withValues(alpha: 0.15),
              semanticsLabel: 'Searching…',
            ),
          if (_searched && _searchError == null && !_searching)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                total == 0
                    ? '0 results'
                    : hasMore
                        ? 'Showing $visible of $total results'
                        : '$total result${total == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _loadFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48,
                              color: cs.onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load Quran data',
                            style: TextStyle(
                                color: cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: cs.onPrimary,
                            ),
                            onPressed: _retryDataLoad,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (!_searched) return _initialHint(context);
                if (_searchError != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48,
                              color: cs.onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text(
                            _searchError!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry search'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: cs.onPrimary,
                            ),
                            onPressed: _runSearch,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (_results.isEmpty) return _emptyState(context);
                final verseIndex =
                    snapshot.data![1] as Map<String, int>;
                return Consumer<PreferencesService>(
                  builder: (context, prefs, _) =>
                      ListView.builder(
                    padding:
                        const EdgeInsets.only(bottom: 16),
                    itemCount: visible + (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= visible) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 48, vertical: 12),
                          child: OutlinedButton.icon(
                            icon:
                                const Icon(Icons.expand_more),
                            label: Text(
                              'Load more (${total - visible} remaining)',
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: cs.primary,
                              side: BorderSide(
                                  color: cs.primary.withValues(
                                      alpha: 0.6)),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => setState(() =>
                                _visibleCount =
                                    visible + _pageSize),
                          ),
                        );
                      }
                      final e = _results[index];
                      final page = verseIndex['${e.s}:${e.v}'];
                      final surahName = allSurahs[e.s - 1].nameEn;
                      return Card(
                        color: cs.surface,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(16),
                          onTap: () {
                            // Tapping a result opens the ayah player:
                            // highlights the ayah and plays its audio
                            // ayah-by-ayah until stopped.
                            showAyahPlayer(
                                context, surah: e.s, ayah: e.v);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  e.ar,
                                  textDirection:
                                      TextDirection.rtl,
                                  maxLines: 3,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: arabicStyle(
                                    prefs.scriptStyle,
                                    fontSize: 20,
                                    color: cs.onSurface,
                                    scale: prefs.ayahScale,
                                  ),
                                ),
                                if ((_urdu['${e.s}:${e.v}'] ?? '')
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    _urdu['${e.s}:${e.v}']!,
                                    textDirection:
                                        TextDirection.rtl,
                                    maxLines: 4,
                                    overflow:
                                        TextOverflow.ellipsis,
                                    style: urduStyle(
                                      fontSize: 16,
                                      color: cs.onSurface
                                          .withValues(alpha: 0.9),
                                      scale: prefs.ayahScale,
                                    ),
                                  ),
                                  Text(
                                    'ترجمہ: کنزالایمان (احمد رضا خان)',
                                    textDirection:
                                        TextDirection.rtl,
                                    style: urduStyle(
                                      fontSize: 12,
                                      color: cs.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  e.en,
                                  maxLines: 3,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '$surahName • Ayah ${e.v} • Page ${page ?? '?'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.w600,
                                          color: cs.primary,
                                        ),
                                        overflow:
                                            TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Listen',
                                      icon: const Icon(
                                        Icons
                                            .play_circle_outlined,
                                        size: 24,
                                      ),
                                      color: cs.primary,
                                      onPressed: () =>
                                          showAyahPlayer(context,
                                              surah: e.s,
                                              ayah: e.v),
                                    ),
                                    if (page != null)
                                      IconButton(
                                        tooltip:
                                            'Open in Mushaf — page $page',
                                        icon: Icon(
                                          Icons
                                              .menu_book_outlined,
                                          color: cs.primary,
                                          size: 22,
                                        ),
                                        onPressed: () => widget
                                            .onOpenPage(page),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialHint(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Search the Holy Quran',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter an Arabic, English or Urdu keyword and press Search — '
              'or tap the mic for voice input',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'No verses found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try Arabic, English or Urdu keywords',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
