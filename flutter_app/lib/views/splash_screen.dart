import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/quran_data.dart';
import '../data/verse_index.dart';
import '../services/auto_backup_service.dart';
import '../services/azan_alarm_service.dart';
import '../services/preferences_service.dart';
import 'home_navigation_screen.dart';
import 'onboarding_screen.dart';

/// Pure validation of the bundled Quran dataset. Returns a list of
/// human-readable problems (empty = all good). Kept pure for testing.
List<String> validateQuranData({
  required int surahCount,
  required int pageCount,
  required int ayahCount,
}) {
  final problems = <String>[];
  if (surahCount != 114) {
    problems.add('Surah metadata incomplete ($surahCount/114).');
  }
  if (pageCount != 611) {
    problems.add('Mushaf page data incomplete ($pageCount/611).');
  }
  if (ayahCount != 6236) {
    problems.add('Quran text incomplete ($ayahCount/6236 ayahs).');
  }
  return problems;
}

/// Elegant Islamic splash: original crescent emblem, app name, and real
/// startup initialization (data validation, alarm service). On failure it
/// shows a human-readable error with Retry and an offline fallback note.
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  bool _failed = false;
  String _error = '';
  String _status = 'Preparing…';

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _initialize();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() {
      _failed = false;
      _error = '';
      _status = 'Checking Quran data…';
    });
    try {
      // 1. Validate bundled Quran dataset integrity.
      final textEntries = await loadQuranText();
      final problems = validateQuranData(
        surahCount: allSurahs.length,
        pageCount: totalPagesInMushaf,
        ayahCount: textEntries.length,
      );
      if (problems.isNotEmpty) {
        throw StateError(problems.join(' '));
      }

      // 2. Alarm/notification service (guarded — never blocks startup).
      setState(() => _status = 'Setting up services…');
      try {
        await AzanAlarmService().init();
      } catch (e) {
        debugPrint('[Splash] azan init failed: $e');
      }

      // 3. Re-arm the weekly auto-backup alarm if the user enabled it.
      try {
        final prefs =
            Provider.of<PreferencesService>(context, listen: false);
        if (prefs.autoBackup) {
          await AutoBackupService.scheduleWeekly();
        }
      } catch (e) {
        debugPrint('[Splash] auto-backup re-arm failed: $e');
      }

      if (!mounted) return;
      final prefs =
          Provider.of<PreferencesService>(context, listen: false);
      final Widget next = prefs.onboardingDone
          ? const HomeNavigationScreen()
          : const OnboardingScreen();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => next),
      );
      // If the app was cold-started from the azan full-screen intent, open
      // the alarm UI now that the navigator is ready.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await AzanAlarmService().checkLaunchedFromAlarm();
        AzanAlarmService.drainPendingAlarm();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _error = e.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _anim.drive(
                    Tween(begin: 0.65, end: 1.0),
                  ),
                  child: const _NurEmblem(size: 112),
                ),
                const SizedBox(height: 24),
                Text(
                  'نور القرآن',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nur Al-Quran',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.85),
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '15-Line Hifzi Mushaf',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 40),
                if (_failed) ...[
                  Icon(Icons.error_outline,
                      color: cs.error, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    _error.isEmpty
                        ? 'Something went wrong during startup.'
                        : _error,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: cs.onSurface, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your saved data is safe. Offline reading may still work.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          cs.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _initialize,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      color: cs.primary,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _status,
                    style: TextStyle(
                      color:
                          cs.onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Original Nur Al-Quran emblem: gold crescent cradling a star on an
/// emerald rounded medallion. Drawn with CustomPainter (no copied artwork).
class _NurEmblem extends StatelessWidget {
  final double size;
  const _NurEmblem({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _EmblemPainter(),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final bg = Paint()
      ..color = const Color(0xFF1B4D3E)
      ..style = PaintingStyle.fill;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, w),
      Radius.circular(w * 0.28),
    );
    canvas.drawRRect(rrect, bg);

    // Gold crescent.
    final gold = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.fill;
    final c = Offset(w * 0.5, w * 0.52);
    canvas.drawCircle(c, w * 0.30, gold);
    final cut = Paint()
      ..color = const Color(0xFF1B4D3E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(w * 0.60, w * 0.44), w * 0.25, cut);

    // Small eight-point star beside the crescent.
    final starC = Offset(w * 0.68, w * 0.62);
    final starPath = Path();
    for (int i = 0; i < 16; i++) {
      final r = i.isEven ? w * 0.075 : w * 0.032;
      final a = i * math.pi / 8 - math.pi / 2;
      final pt = Offset(
        starC.dx + r * math.cos(a),
        starC.dy + r * math.sin(a),
      );
      if (i == 0) {
        starPath.moveTo(pt.dx, pt.dy);
      } else {
        starPath.lineTo(pt.dx, pt.dy);
      }
    }
    starPath.close();
    canvas.drawPath(starPath, gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
