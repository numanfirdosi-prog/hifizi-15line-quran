import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/juz_data.dart';
import '../services/preferences_service.dart';
import '../utils/script_font.dart';

/// Khatm Planner: 30 days, one Juz per day (mirrors the website's
/// 30-day Khatam schedule).
///
/// Two clearly separated states per day:
///  - Manual completion (the checkbox): YOU mark a day done. This is the
///    only thing that counts toward the 30-day progress. Mistakes can be
///    corrected by unchecking, or via the Undo snackbar.
///  - Auto page progress (the bar): counts mushaf pages of the day's Juz
///    that were opened in the reader. Opening a page never marks the day
///    complete — a Juz is never claimed as "read" from page opens alone.
///
/// Day↔Juz↔page mappings come from the verified [juzList] / [khatmDayPages]
/// data; completion state persists in [PreferencesService] across restarts.
class KhatmPlannerScreen extends StatefulWidget {
  final void Function(int page) onOpenPage;

  const KhatmPlannerScreen({required this.onOpenPage, super.key});

  @override
  State<KhatmPlannerScreen> createState() => _KhatmPlannerScreenState();
}

class _KhatmPlannerScreenState extends State<KhatmPlannerScreen> {
  /// Toggle a day's manual completion. Marking complete offers an Undo
  /// snackbar so a mistaken tap is easy to correct.
  Future<void> _toggleDay(PreferencesService prefs, int day) async {
    final wasDone = prefs.khatmDays.contains(day);
    await prefs.toggleKhatmDay(day);
    if (!mounted) return;
    if (!wasDone) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Day $day marked complete'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => prefs.toggleKhatmDay(day),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Clears ALL manually-marked days after confirmation. Auto page-open
  /// counts (readPages) are untouched — only the completion state resets.
  Future<void> _resetPlan(PreferencesService prefs) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Khatm plan?'),
        content: const Text(
          'This unmarks all 30 days. Your opened-page history stays '
          'as it is.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      for (final day in [...prefs.khatmDays]) {
        await prefs.toggleKhatmDay(day);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final prefs = Provider.of<PreferencesService>(context);
    final done = prefs.khatmDays.toSet();
    final progress = done.length / 30.0;
    final remaining = 30 - done.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Khatm Planner',
          style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_outlined),
            tooltip: 'Reset plan (unmark all days)',
            onPressed: () => _resetPlan(prefs),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${done.length} / 30 days marked complete',
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: cs.onSurface.withValues(alpha: 0.12),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(cs.primary),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  remaining == 0
                      ? 'MashaAllah — all 30 days marked complete!'
                      : '$remaining day${remaining == 1 ? '' : 's'} remaining.',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tick the box when YOU finish a Juz. The bar under each '
                  'day counts pages you opened (auto) — it never marks a '
                  'day complete by itself.',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.02,
              ),
              itemCount: 30,
              itemBuilder: (context, i) {
                final day = i + 1;
                final juz = juzList[i];
                final (startPage, endPage) = khatmDayPages(day);
                final isDone = done.contains(day);
                final totalPages = endPage - startPage + 1;
                var openedCount = 0;
                for (var p = startPage; p <= endPage; p++) {
                  if (prefs.readPages.contains(p)) openedCount++;
                }
                final openedPct =
                    totalPages > 0 ? openedCount / totalPages : 0.0;
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _toggleDay(prefs, day),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDone
                          ? cs.primary.withValues(alpha: 0.18)
                          : cs.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDone
                            ? cs.primary
                            : cs.primary.withValues(alpha: 0.25),
                        width: isDone ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Day $day',
                              style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            // Explicit completion checkbox (the manual
                            // state): tap to mark / unmark.
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: Checkbox(
                                value: isDone,
                                activeColor: cs.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                onChanged: (_) => _toggleDay(prefs, day),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Juz ${juz.number} • ${juz.nameTr}',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          juz.nameAr,
                          style: arabicStyle(
                            prefs.scriptStyle,
                            fontSize: 16,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Auto progress: pages opened (from real reading
                        // data) — informational only.
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: openedPct,
                                  minHeight: 5,
                                  backgroundColor: cs.onSurface
                                      .withValues(alpha: 0.12),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      cs.primary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${(openedPct * 100).round()}%',
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.6),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$openedCount/$totalPages pages opened (auto)',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'p. $startPage–$endPage',
                                style: TextStyle(
                                  color: cs.onSurface
                                      .withValues(alpha: 0.6),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            FilledButton(
                              onPressed: () => widget.onOpenPage(startPage),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                minimumSize: const Size(72, 34),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: const Text('Read'),
                            ),
                          ],
                        ),
                      ],
                    ),
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
