import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/preferences_service.dart';
import 'home_navigation_screen.dart';

/// Short, skippable first-launch onboarding. Shown once after the splash.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardPage(
      icon: Icons.menu_book_outlined,
      title: 'Read the 15-Line Mushaf',
      body:
          'The complete Quran in the familiar 15-line Indo-Pak layout. '
          'Tap any ayah on the page — it highlights and its recitation begins, '
          'continuing ayah-by-ayah.',
    ),
    _OnboardPage(
      icon: Icons.cloud_off_outlined,
      title: 'Works Offline',
      body:
          'Quran pages, search, bookmarks and notes work without internet. '
          'Recitation audio can be cached for offline listening.',
    ),
    _OnboardPage(
      icon: Icons.headphones_outlined,
      title: 'Audio, Bookmarks & Backup',
      body:
          'Twelve qaris, ayah-by-ayah playback, prayer times with azan, '
          'bookmarks, notes and one-tap backup of everything.',
    ),
  ];

  Future<void> _finish() async {
    final prefs =
        Provider.of<PreferencesService>(context, listen: false);
    await prefs.setOnboardingDone(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeNavigationScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final last = _page == _pages.length - 1;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _pages[i],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: last
                      ? _finish
                      : () => _controller.nextPage(
                            duration:
                                const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(last ? 'Get Started' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 56, color: cs.primary),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.7),
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
