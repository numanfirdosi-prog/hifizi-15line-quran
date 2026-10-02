import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/quran_data.dart';
import '../data/verse_index.dart';
import '../services/preferences_service.dart';
import '../utils/script_font.dart';

/// Full-text search across the Quran (Arabic + English). Filter runs only on
/// submit, never on every keystroke.
class SearchQuranScreen extends StatefulWidget {
  final void Function(int page) onOpenPage;
  const SearchQuranScreen({required this.onOpenPage, super.key});

  @override
  State<SearchQuranScreen> createState() => _SearchQuranScreenState();
}

class _SearchQuranScreenState extends State<SearchQuranScreen> {
  final TextEditingController _controller = TextEditingController();
  late final Future<List<dynamic>> _loadFuture;
  List<QuranTextEntry> _results = [];
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    _loadFuture = Future.wait([loadQuranText(), loadVersePageIndex()]);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    final data = await _loadFuture;
    final entries = data[0] as List<QuranTextEntry>;
    final normQ = normalizeArabic(q);
    final lowerQ = q.toLowerCase();
    final results = <QuranTextEntry>[];
    for (final e in entries) {
      if (results.length >= 200) break;
      if (normalizeArabic(e.ar).contains(normQ) ||
          e.en.toLowerCase().contains(lowerQ)) {
        results.add(e);
      }
    }
    if (!mounted) return;
    setState(() {
      _results = results;
      _searched = true;
    });
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _results = [];
      _searched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
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
                      hintText: 'Search any keyword in Arabic or English',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear',
                        onPressed: _clearSearch,
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
          if (_searched)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _results.length >= 200
                    ? '200+ results (top 200 shown)'
                    : '${_results.length} results',
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Center(
                    child: Text(
                      'Failed to load Quran data',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  );
                }
                if (!_searched) return _initialHint(context);
                if (_results.isEmpty) return _emptyState(context);
                final verseIndex = snapshot.data![1] as Map<String, int>;
                return Consumer<PreferencesService>(
                  builder: (context, prefs, _) => ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
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
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            if (page != null) {
                              widget.onOpenPage(page);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Page not found for this verse'),
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  e.ar,
                                  textDirection: TextDirection.rtl,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: arabicStyle(
                                    prefs.scriptStyle,
                                    fontSize: 20,
                                    color: cs.onSurface,
                                    scale: prefs.ayahScale,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  e.en,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$surahName ${e.v} • Page ${page ?? '?'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: cs.primary,
                                  ),
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
              'Enter an Arabic or English keyword and press Search',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
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
            Icon(Icons.search_off, size: 64, color: cs.onSurfaceVariant),
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
              'Try Arabic or English keywords',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
