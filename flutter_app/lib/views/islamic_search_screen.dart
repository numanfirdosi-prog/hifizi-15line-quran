import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../models/islamic_search_result.dart';
import '../services/islamic_search_service.dart';
import '../services/preferences_service.dart';
import '../services/voice_search_service.dart';
import '../utils/script_font.dart';
import '../widgets/premium_card.dart';

/// Al-Bahith Al-Islami (Islamic Knowledge Search Engine)
/// Comprehensive research engine for:
/// - Quran & Classical Tafseer
/// - Authentic Hadith Collections (Bukhari, Muslim, Tirmidhi, etc.)
/// - Fiqh Rulings & Classical Fatawa with exact book, volume, page citations
/// - Arabic & Urdu Classical Lexicons (Lisan al-Arab, Mufradat al-Quran)
class IslamicSearchScreen extends StatefulWidget {
  const IslamicSearchScreen({super.key});

  @override
  State<IslamicSearchScreen> createState() => _IslamicSearchScreenState();
}

class _IslamicSearchScreenState extends State<IslamicSearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final IslamicSearchService _searchService = IslamicSearchService();
  final VoiceSearchService _voiceService = VoiceSearchService();

  late TabController _tabController;
  IslamicSearchCategory _selectedCategory = IslamicSearchCategory.all;

  List<IslamicSearchResult> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _errorMessage = '';
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _voiceService.init();
  }

  @override
  void dispose() {
    _voiceService.stopListening();
    _voiceService.dispose();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _errorMessage = '';
      _results = [];
    });

    final prefs = Provider.of<PreferencesService>(context, listen: false);
    await prefs.addIslamicSearchHistory(clean);

    try {
      final res = await _searchService.search(
        query: clean,
        category: _selectedCategory,
        geminiApiKey: prefs.islamicSearchApiKey.isNotEmpty
            ? prefs.islamicSearchApiKey
            : null,
      );

      if (mounted) {
        setState(() {
          _results = res;
          _isLoading = false;
          if (res.isEmpty) {
            _errorMessage =
                'کوئی مستند نتیجہ نہیں ملا۔ برائے مہربانی سوال کا صیغہ، کتاب کا نام یا مادہ تبدیل کر کے تلاش کریں۔';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'تلاش کے دوران رابطہ منقطع ہوا۔ انٹرنیٹ کنکشن چیک کریں یا دوبارہ کوشش کریں۔';
        });
      }
    }
  }

  Future<void> _toggleVoiceSearch() async {
    if (_isListening) {
      await _voiceService.stopListening();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    setState(() => _isListening = true);
    final ok = await _voiceService.startListening(
      onResult: (spokenText, _) {
        if (mounted) {
          _searchController.text = spokenText;
          if (spokenText.trim().isNotEmpty) {
            _performSearch(spokenText);
          }
        }
      },
    );

    if (!ok && mounted) {
      setState(() => _isListening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('آواز سے تلاش کے لیے مائیکروفون کی اجازت درکار ہے۔'),
        ),
      );
    }
  }

  void _showApiKeyDialog() {
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    final textController =
        TextEditingController(text: prefs.islamicSearchApiKey);

    showDialog(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surface,
          title: Row(
            children: [
              Icon(Icons.vpn_key, color: cs.primary),
              const SizedBox(width: 8),
              const Text(
                'AI Search API Key (اختیاری)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'نور القرآن کا سرچ انجن قرآن، حدیث اور کلاسیکی فقہ و لغت کے لیے براہِ راست مستند ڈیٹا بغیر کسی کی (Key) کے مفت فراہم کرتا ہے۔',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  'اگر آپ لائیو ویب سرچ اور فتاویٰ کی جدید ترین سمری چاہتے ہیں، تو اپنی ذاتی گوگل جیمنائی (Gemini) API Key درج کر سکتے ہیں:',
                  style: TextStyle(fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    labelText: 'Gemini API Key',
                    hintText: 'AIzaSy...',
                    prefixIcon: Icon(Icons.key),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    launchUrl(
                      Uri.parse('https://aistudio.google.com/app/apikey'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text(
                    'مفت گوگل API Key حاصل کریں (Google AI Studio)',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (prefs.islamicSearchApiKey.isNotEmpty)
              TextButton(
                onPressed: () async {
                  await prefs.setIslamicSearchApiKey('');
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('کی حذف کریں'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('منسوخ'),
            ),
            FilledButton(
              onPressed: () async {
                await prefs.setIslamicSearchApiKey(textController.text);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('محفوظ کریں'),
            ),
          ],
        );
      },
    );
  }

  void _showCitationDetails(IslamicCitation c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final cs = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.verified, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'مستند شرعی حوالہ و مرجع',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _detailRow('کتاب کا نام:', c.bookName),
              if (c.author != null) _detailRow('مصنف / امام:', c.author!),
              if (c.chapter != null) _detailRow('باب / کتاب:', c.chapter!),
              if (c.volume != null) _detailRow('جلد نمبر:', c.volume!),
              if (c.pageOrNumber != null)
                _detailRow('صفحہ / حدیث نمبر:', c.pageOrNumber!),
              if (c.grading != null) _detailRow('صحت کا حکم:', c.grading!),
              if (c.schoolOfThought != null)
                _detailRow('مسلک / مذہب:', c.schoolOfThought!),
              const SizedBox(height: 16),
              if (c.sourceUrl != null && c.sourceUrl!.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      launchUrl(
                        Uri.parse(c.sourceUrl!),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('اصل مرجع انٹرنیٹ پر دیکھیں'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الباحث الإسلامي — تلاشِ علم',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            tooltip: 'AI Search Settings',
            icon: const Icon(Icons.settings),
            onPressed: _showApiKeyDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: cs.primary,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurface.withValues(alpha: 0.6),
          tabs: const [
            Tab(icon: Icon(Icons.search), text: 'تلاش و تحقیق'),
            Tab(icon: Icon(Icons.bookmark), text: 'محفوظ جوابات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(cs, isDark),
          _buildSavedTab(cs, isDark),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 1: Live Islamic Search Tab
  // ---------------------------------------------------------------------------
  Widget _buildSearchTab(ColorScheme cs, bool isDark) {
    return Column(
      children: [
        // Top Search Bar & Voice Input
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: cs.surface,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: _performSearch,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'مسئلہ، حدیث، آیت یا لفظ تلاش کریں...',
                  hintTextDirection: TextDirection.rtl,
                  prefixIcon: IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.redAccent : cs.primary,
                    ),
                    onPressed: _toggleVoiceSearch,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        ),
                      IconButton(
                        icon: Icon(Icons.search, color: cs.primary),
                        onPressed: () => _performSearch(_searchController.text),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Category filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: IslamicSearchCategory.values.map((cat) {
                    final selected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        selected: selected,
                        label: Text(
                          cat.titleUrdu,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.normal,
                            color: selected ? Nur.deepGreen : cs.onSurface,
                          ),
                        ),
                        backgroundColor: cs.surface,
                        selectedColor: cs.primary,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedCategory = cat);
                            if (_searchController.text.trim().isNotEmpty) {
                              _performSearch(_searchController.text);
                            }
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Search History / Quick Suggestions
        Consumer<PreferencesService>(
          builder: (context, prefs, _) {
            final history = prefs.islamicSearchHistory;
            if (history.isEmpty || _hasSearched) {
              return const SizedBox.shrink();
            }
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final item in history.take(6))
                    ActionChip(
                      avatar: const Icon(Icons.history, size: 14),
                      label: Text(item, style: const TextStyle(fontSize: 11)),
                      onPressed: () {
                        _searchController.text = item;
                        _performSearch(item);
                      },
                    ),
                ],
              ),
            );
          },
        ),

        // Content Area: Loading / Error / Results
        Expanded(
          child: _isLoading
              ? _buildShimmerLoading(cs)
              : _errorMessage.isNotEmpty && _results.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline,
                                size: 48, color: cs.primary.withValues(alpha: 0.6)),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.7),
                                  fontSize: 14,
                                  height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    )
                  : !_hasSearched
                      ? _buildEmptyGuide(cs)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final item = _results[index];
                            return _buildResultCard(item, cs, isDark);
                          },
                        ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 2: Saved / Bookmarked Answers
  // ---------------------------------------------------------------------------
  Widget _buildSavedTab(ColorScheme cs, bool isDark) {
    return Consumer<PreferencesService>(
      builder: (context, prefs, _) {
        final savedJsonList = prefs.savedIslamicAnswersJson;
        if (savedJsonList.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_border,
                      size: 56, color: cs.primary.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text(
                    'کوئی محفوظ جواب موجود نہیں۔',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'کسی بھی مسئلے، حدیث یا آیت کو سرچ کر کے محفوظ (Bookmark) کریں تاکہ بعد میں انٹرنیٹ کے بغیر بھی دیکھ سکیں۔',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.6),
                        height: 1.5),
                  ),
                ],
              ),
            ),
          );
        }

        final savedResults = savedJsonList.map((jsonStr) {
          try {
            return IslamicSearchResult.fromJson(
                jsonDecode(jsonStr) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        }).whereType<IslamicSearchResult>().toList();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: savedResults.length,
          itemBuilder: (context, index) {
            final item = savedResults[index];
            return _buildResultCard(item, cs, isDark, isSavedView: true);
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Result Card Widget
  // ---------------------------------------------------------------------------
  Widget _buildResultCard(IslamicSearchResult item, ColorScheme cs, bool isDark,
      {bool isSavedView = false}) {
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    final isSaved = prefs.savedIslamicAnswersJson.any((str) {
      try {
        final map = jsonDecode(str);
        return map['id'] == item.id;
      } catch (_) {
        return false;
      }
    });

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Nur.cardRadius),
        side: BorderSide(color: Nur.goldBorder(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Badges row: Category + Evidence Type
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    item.category.titleUrdu,
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.evidenceType == EvidenceType.quranNass
                        ? Nur.elevatedGreen.withValues(alpha: 0.2)
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.evidenceType.labelUrdu,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Question / Title
            Text(
              item.title,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),

            // Summary / Verdict
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Text(
                item.summary,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),

            // Arabic text section (if present)
            if (item.arabicText.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F362C) : const Color(0xFFF3F7F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Nur.goldBorder(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'اصل عربی متن:',
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.auto_stories, size: 16, color: Nur.gold),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.arabicText,
                      textDirection: TextDirection.rtl,
                      style: arabicStyle(
                        prefs.scriptStyle,
                        fontSize: 18,
                        height: 1.8,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Urdu Translation
            if (item.translation.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'ترجمہ: ${item.translation}',
                  textDirection: TextDirection.rtl,
                  style: urduStyle(
                    fontSize: 14,
                    color: cs.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],

            // Tafsir or Scholarly Commentary section (تفسیر و فقہی شرح)
            if (item.tafsirOrCommentary != null &&
                item.tafsirOrCommentary!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF132822)
                      : const Color(0xFFF0F7F4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          item.category == IslamicSearchCategory.quran
                              ? Icons.menu_book
                              : Icons.school,
                          size: 16,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.category == IslamicSearchCategory.quran
                              ? 'معتمد تفسیر (تفسیر ابن کثیر):'
                              : 'شرعی و فقہی شرح:',
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.tafsirOrCommentary!,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.9),
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Differences of opinion (Ikhtilaf-e-Aimma) if any
            if (item.differencesOfOpinion != null &&
                item.differencesOfOpinion!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.balance, size: 18, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'فقہی آراء: ${item.differencesOfOpinion!}',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.9),
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),

            // Citation Footer Row
            InkWell(
              onTap: () => _showCitationDetails(item.citation),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book, size: 16, color: Nur.gold),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.citation.formattedReferenceUrdu,
                        textDirection: TextDirection.rtl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cs.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_left, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons Bar: Copy, WhatsApp Share, Bookmark
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Copy
                    IconButton(
                      tooltip: 'کاپی کریں',
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: item.toShareableText()));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('مکمل جواب اور حوالہ کاپی ہو گیا')),
                        );
                      },
                    ),
                    // WhatsApp / System Share
                    IconButton(
                      tooltip: 'شیئر کریں',
                      icon: const Icon(Icons.share, size: 20),
                      onPressed: () {
                        Share.share(item.toShareableText());
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Bookmark / Save
                    IconButton(
                      tooltip: isSaved ? 'محفوظ سے ہٹائیں' : 'محفوظ کریں',
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: isSaved ? Nur.gold : null,
                      ),
                      onPressed: () async {
                        if (isSaved) {
                          await prefs.removeSavedIslamicAnswer(item.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('محفوظ جوابات سے ہٹا دیا گیا')),
                            );
                          }
                        } else {
                          await prefs
                              .saveIslamicAnswer(jsonEncode(item.toJson()));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('جواب محفوظ کر لیا گیا')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shimmer / Animated Loading View
  // ---------------------------------------------------------------------------
  Widget _buildShimmerLoading(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: cs.primary),
          const SizedBox(height: 16),
          Text(
            'مستند کتب و مصادر سے تلاش جاری ہے...',
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurface.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'قرآن، حدیث، فقہی فتاویٰ اور عربی لغت کی تصدیق کی جا رہی ہے',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty State & Guided Prompts
  // ---------------------------------------------------------------------------
  Widget _buildEmptyGuide(ColorScheme cs) {
    final sampleTopics = [
      'روزہ توڑنے کا شرعی کفارہ',
      'نماز میں سجدہ سہو کا طریقہ',
      'زکوٰۃ کا نصاب کتنا ہے',
      'صحیح البخاری حدیث 1',
      'لفظ تقویٰ کا لغوی و شرعی معنی',
      'نمازِ وتر کی رکعات اور قنوت',
      'قرآن 2:255 آیت الکرسی',
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.explore, size: 48, color: cs.primary),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'الباsecond اسلامی سرچ انجن میں خوش آمدید',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'یہاں آپ اسلام سے متعلق کوئی بھی مسئلہ، حدیث، آیت، فقہی حکم یا عربی و اردو لغت تلاش کر سکتے ہیں۔ ہر جواب کتاب کے نام، جلد، صفحہ اور حدیث نمبر کی قطعی دلیل کے ساتھ پیش کیا جائے گا۔',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurface.withValues(alpha: 0.7),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'عام دریافت کردہ اہم مسائل (نمونہ):',
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sampleTopics.map((topic) {
            return InkWell(
              onTap: () {
                _searchController.text = topic;
                _performSearch(topic);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Text(
                  topic,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

