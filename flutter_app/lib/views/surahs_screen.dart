import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/quran_data.dart';
import '../models/surah.dart';
import '../services/voice_search_service.dart';
import '../services/audio_recitation_service.dart';
import '../services/preferences_service.dart';

class SurahsScreen extends StatefulWidget {
  final Function(int page) onOpenPage;
  const SurahsScreen({Key? key, required this.onOpenPage}) : super(key: key);

  @override
  State<SurahsScreen> createState() => _SurahsScreenState();
}

class _SurahsScreenState extends State<SurahsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final VoiceSearchService _voiceService = VoiceSearchService();
  List<Surah> _displayedSurahs = allSurahs;
  bool _isListening = false;
  String _voiceFeedback = '';

  @override
  void initState() {
    super.initState();
    _voiceService.init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _displayedSurahs = allSurahs;
        _voiceFeedback = '';
      });
      return;
    }

    final results = _voiceService.searchSurahs(query);
    setState(() {
      _displayedSurahs = results;
    });
  }

  Future<void> _toggleVoiceSearch() async {
    if (_isListening) {
      await _voiceService.stopListening();
      setState(() {
        _isListening = false;
      });
      return;
    }

    setState(() {
      _isListening = true;
      _voiceFeedback = 'Listening in Hindi / English / Urdu...';
    });

    await _voiceService.startListening(
      localeId: 'hi_IN',
      onResult: (spokenText, matchedSurahs) {
        setState(() {
          _searchController.text = spokenText;
          _displayedSurahs = matchedSurahs.isNotEmpty ? matchedSurahs : allSurahs;
          _voiceFeedback = 'Heard: "$spokenText"';
          _isListening = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioRecitationService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF071F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3A2C),
        title: const Text(
          'فہرست سورتیں (114 Surahs)',
          style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 18),
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
                          hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.white54),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFF144234),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                          color: _isListening ? Colors.redAccent : const Color(0xFFD4AF37),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _isListening ? Colors.redAccent.withOpacity(0.5) : const Color(0xFFD4AF37).withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: Colors.black87,
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
                        color: _isListening ? Colors.amberAccent : Colors.white70,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Surah List
          Expanded(
            child: _displayedSurahs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.search_off, size: 54, color: Colors.white38),
                        SizedBox(height: 12),
                        Text(
                          'No Surah matched your search.\nTry Hindi (सूरह यासीन) or English (Yaseen)',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white60),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _displayedSurahs.length,
                    separatorBuilder: (ctx, i) => const Divider(color: Colors.white12, height: 1),
                    itemBuilder: (context, index) {
                      final surah = _displayedSurahs[index];
                      final isCurrentlyPlaying = audio.isPlaying && audio.currentSurah == surah.number;

                      return Container(
                        color: isCurrentlyPlaying ? const Color(0xFF144234) : Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            // Surah Number Badge
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                                color: const Color(0xFF0F3A2C),
                              ),
                              child: Center(
                                child: Text(
                                  surah.number.toString(),
                                  style: const TextStyle(
                                    color: Color(0xFFD4AF37),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Surah Details (English & Hindi)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        surah.nameEn,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white10,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          surah.nameHi,
                                          style: const TextStyle(
                                            color: Color(0xFFD4AF37),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${surah.meaning} • ${surah.totalAyahs} Ayahs • Page ${surah.startPage}',
                                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),

                            // Arabic Name
                            Text(
                              surah.nameAr,
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 18,
                                fontFamily: 'serif',
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Read Button (opens Mushaf)
                            IconButton(
                              icon: const Icon(Icons.menu_book, color: Color(0xFFD4AF37), size: 22),
                              tooltip: 'Read in 15-line Mushaf',
                              onPressed: () => widget.onOpenPage(surah.startPage),
                            ),

                            // Audio Recite Button
                            IconButton(
                              icon: Icon(
                                isCurrentlyPlaying ? Icons.pause_circle_filled : Icons.play_circle_outline,
                                color: const Color(0xFFD4AF37),
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
