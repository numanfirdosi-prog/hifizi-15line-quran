import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/quran_data.dart';
import '../services/preferences_service.dart';
import '../services/audio_recitation_service.dart';

class MushafScreen extends StatefulWidget {
  final int initialPage;
  const MushafScreen({Key? key, this.initialPage = 2}) : super(key: key);

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  late PageController _pageController;
  late int _currentPage;
  final TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    _currentPage = widget.initialPage > 0 ? widget.initialPage : prefs.lastReadPage;
    // Pages in Mushaf are 1 to 611
    _pageController = PageController(initialPage: _currentPage - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    final pageNum = index + 1;
    setState(() {
      _currentPage = pageNum;
    });
    Provider.of<PreferencesService>(context, listen: false).setLastReadPage(pageNum);
  }

  void _showJumpToPageDialog() {
    final textController = TextEditingController(text: _currentPage.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F3A2C),
        title: const Text('ورقہ / صفحہ منتخب کریں', style: TextStyle(color: Colors.white, fontFamily: 'serif')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Page Number (1 to 611):',
              style: TextStyle(color: Color(0xFFE2E8F0)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1B4D3E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                hintText: 'Enter page 1-611',
                hintStyle: const TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final p = int.tryParse(textController.text.trim());
              if (p != null && p >= 1 && p <= totalPagesInMushaf) {
                Navigator.pop(ctx);
                _pageController.jumpToPage(p - 1);
              }
            },
            child: const Text('Go to Page'),
          ),
        ],
      ),
    );
  }

  String _getPageImageUrl(int page) {
    // 15-line high-resolution Quran page CDN
    final pStr = page.toString().padLeft(3, '0');
    return 'https://raw.githubusercontent.com/numanfirdosi-prog/hifzi-15line-quran/main/assets/pages/page_$pStr.webp';
  }

  @override
  Widget build(BuildContext context) {
    final prefs = Provider.of<PreferencesService>(context);
    final audio = Provider.of<AudioRecitationService>(context);
    final isBookmarked = prefs.bookmarks.contains(_currentPage);

    return Scaffold(
      backgroundColor: const Color(0xFF071F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3A2C),
        elevation: 2,
        title: Row(
          children: [
            Text(
              'صفحہ $_currentPage',
              style: const TextStyle(
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '/ $totalPagesInMushaf',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? const Color(0xFFD4AF37) : Colors.white70,
            ),
            onPressed: () => prefs.toggleBookmark(_currentPage),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: Colors.white70),
            tooltip: 'Jump to Page',
            onPressed: _showJumpToPageDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          // PageView with Reverse direction for Quranic Right-to-Left Reading
          PageView.builder(
            controller: _pageController,
            reverse: true, // RTL for Mushaf reading
            itemCount: totalPagesInMushaf,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final pageNum = index + 1;
              return InteractiveViewer(
                transformationController: _transformController,
                minScale: 1.0,
                maxScale: 3.5,
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF7EE),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      _getPageImageUrl(pageNum),
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F3A2C)),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Loading Page $pageNum...',
                                style: const TextStyle(color: Color(0xFF0F3A2C), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          color: const Color(0xFFFAF7EE),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.menu_book, size: 64, color: Color(0xFF0F3A2C)),
                                const SizedBox(height: 16),
                                Text(
                                  'صفحہ $pageNum',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F3A2C)),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '15-Line Offline Mushaf Page',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),

          // Bottom Quick Page Controller Slider
          Positioned(
            left: 16,
            right: 16,
            bottom: audio.isPlaying ? 80 : 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F3A2C).withOpacity(0.9),
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 8),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.white70),
                    onPressed: () {
                      if (_currentPage > 1) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFFD4AF37),
                        inactiveTrackColor: Colors.white24,
                        thumbColor: const Color(0xFFD4AF37),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: _currentPage.toDouble(),
                        min: 1.0,
                        max: totalPagesInMushaf.toDouble(),
                        onChanged: (val) {
                          _pageController.jumpToPage(val.toInt() - 1);
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
                    onPressed: () {
                      if (_currentPage < totalPagesInMushaf) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Audio Recitation Bar (when active)
          if (audio.isPlaying)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A291E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 10),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.graphic_eq, color: Color(0xFFD4AF37)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Surah ${audio.currentSurah}: ${allSurahs[audio.currentSurah - 1].nameEn}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            audio.selectedQari.name,
                            style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.pause_circle_filled, color: Color(0xFFD4AF37), size: 32),
                      onPressed: () => audio.pause(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                      onPressed: () => audio.stop(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

