import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/juz_data.dart';
import '../data/quran_data.dart';
import '../services/preferences_service.dart';
import '../utils/script_font.dart';

/// Khatm Planner: 30 days, one Juz per day (mirrors the website's
/// 30-day Khatam schedule). Tapping a day card toggles it completed;
/// "Read" opens the mushaf at the Juz start page.
class KhatmPlannerScreen extends StatelessWidget {
  final void Function(int page) onOpenPage;

  const KhatmPlannerScreen({required this.onOpenPage, super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final prefs = Provider.of<PreferencesService>(context);
    final done = prefs.khatmDays.toSet();
    final progress = done.length / 30.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Khatm Planner',
          style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold),
        ),
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
                        '${done.length} / 30 days',
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
                    backgroundColor:
                        cs.onSurface.withValues(alpha: 0.12),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(cs.primary),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'One Juz per day — tap a day to mark it done.',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
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
                childAspectRatio: 1.35,
              ),
              itemCount: 30,
              itemBuilder: (context, i) {
                final day = i + 1;
                final juz = juzList[i];
                final (startPage, endPage) = khatmDayPages(day);
                final isDone = done.contains(day);
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => prefs.toggleKhatmDay(day),
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
                            Icon(
                              isDone
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: isDone
                                  ? cs.primary
                                  : cs.onSurface.withValues(alpha: 0.4),
                              size: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
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
                        const Spacer(),
                        Row(
                          children: [
                            Text(
                              'p. $startPage–$endPage',
                              style: TextStyle(
                                color: cs.onSurface
                                    .withValues(alpha: 0.6),
                                fontSize: 11,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => onOpenPage(startPage),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Read',
                                  style: TextStyle(
                                    color: cs.onPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
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
