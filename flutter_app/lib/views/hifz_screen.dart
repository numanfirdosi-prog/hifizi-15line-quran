import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/juz_data.dart';
import '../data/quran_data.dart';
import '../main.dart';
import '../models/hifz_model.dart';
import '../models/surah.dart';
import '../services/hifz_service.dart';
import '../utils/script_font.dart';
import '../widgets/premium_card.dart';

class HifzScreen extends StatefulWidget {
  final void Function(int page) onOpenPage;

  const HifzScreen({required this.onOpenPage, super.key});

  @override
  State<HifzScreen> createState() => _HifzScreenState();
}

class _HifzScreenState extends State<HifzScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _mistakeFilter = 'all'; // 'all', 'active', 'resolved'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text(
          'Hifz Manager (حفظ مینیجر)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: cs.surface,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: cs.primary,
          indicatorWeight: 3,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurface.withValues(alpha: 0.6),
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(
              icon: Icon(Icons.school_outlined, size: 20),
              text: 'Sabaq & Sabqi',
            ),
            Tab(
              icon: Icon(Icons.autorenew_rounded, size: 20),
              text: 'Manzil Daur',
            ),
            Tab(
              icon: Icon(Icons.bookmark_border_rounded, size: 20),
              text: 'Mistakes Log',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyHifzTab(cs, isDark),
          _buildManzilDaurTab(cs, isDark),
          _buildMistakesTab(cs, isDark),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: SABAQ & SABQI (Daily Hifz & Revision)
  // =========================================================================
  Widget _buildDailyHifzTab(ColorScheme cs, bool isDark) {
    return Consumer<HifzService>(
      builder: (context, hifz, _) {
        final totalMemorized = hifz.totalMemorizedPages;
        final progressFrac = (totalMemorized / 611.0).clamp(0.0, 1.0);
        final percent = (progressFrac * 100).toStringAsFixed(1);

        return ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: Nur.screenMargin, vertical: Nur.s16),
          children: [
            // Overall Progress Card
            NurCard(
              padding: const EdgeInsets.all(Nur.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.workspace_premium_rounded,
                              color: cs.primary, size: 24),
                          const SizedBox(width: Nur.s8),
                          Text(
                            'Overall Hifz Progress (کل حفظ)',
                            style: TextStyle(
                              color: cs.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$percent%',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Nur.s12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progressFrac,
                      minHeight: 8,
                      backgroundColor: cs.primary.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                    ),
                  ),
                  const SizedBox(height: Nur.s8),
                  Text(
                    '$totalMemorized of 611 pages memorized',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.65),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Nur.s16),

            // 1. TODAY'S SABAQ (سبق - نیا سبق)
            NurCard(
              padding: const EdgeInsets.all(Nur.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.menu_book_rounded,
                                color: cs.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's Sabaq (آج کا سبق)",
                                style: TextStyle(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "Target: ${hifz.dailySabaqPages} Page(s) daily",
                                style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_outlined,
                            size: 20, color: cs.primary),
                        tooltip: 'Edit Target',
                        onPressed: () => _showEditSabaqDialog(context, hifz),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Target Page: ${hifz.sabaqPage}',
                              style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getSurahForPage(hifz.sabaqPage),
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.75),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(Nur.buttonRadius),
                          ),
                        ),
                        onPressed: () {
                          widget.onOpenPage(hifz.sabaqPage);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.auto_stories, size: 16),
                        label: const Text('Read Page'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    borderRadius: BorderRadius.circular(Nur.buttonRadius),
                    onTap: () => hifz.toggleTodaySabaq(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Nur.s12, vertical: 10),
                      decoration: BoxDecoration(
                        color: hifz.isTodaySabaqDone
                            ? Colors.green.withValues(alpha: 0.15)
                            : cs.surface,
                        borderRadius: BorderRadius.circular(Nur.buttonRadius),
                        border: Border.all(
                          color: hifz.isTodaySabaqDone
                              ? Colors.green
                              : cs.onSurface.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hifz.isTodaySabaqDone
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: hifz.isTodaySabaqDone
                                ? Colors.green
                                : cs.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              hifz.isTodaySabaqDone
                                  ? 'Sabaq Completed Today! (سبق مکمل ہو گیا)'
                                  : 'Tap to Mark as Completed (مکمل کریں)',
                              style: TextStyle(
                                color: hifz.isTodaySabaqDone
                                    ? Colors.green
                                    : cs.onSurface,
                                fontWeight: hifz.isTodaySabaqDone
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Nur.s16),

            // 2. TODAY'S SABQI / AAMOKHTAH (سبقی - آموختہ)
            NurCard(
              padding: const EdgeInsets.all(Nur.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.history_edu_rounded,
                                color: Colors.amber, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's Sabqi (سبقی / آموختہ)",
                                style: TextStyle(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "Recent revision portion",
                                style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_outlined,
                            size: 20, color: cs.primary),
                        tooltip: 'Edit Range',
                        onPressed: () => _showEditSabqiDialog(context, hifz),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pages: ${hifz.sabqiStartPage} – ${hifz.sabqiEndPage}',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${hifz.sabqiEndPage - hifz.sabqiStartPage + 1} page(s) revision',
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.75),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(Nur.buttonRadius),
                          ),
                        ),
                        onPressed: () {
                          widget.onOpenPage(hifz.sabqiStartPage);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.auto_stories, size: 16),
                        label: const Text('Read Sabqi'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    borderRadius: BorderRadius.circular(Nur.buttonRadius),
                    onTap: () => hifz.toggleTodaySabqi(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Nur.s12, vertical: 10),
                      decoration: BoxDecoration(
                        color: hifz.isTodaySabqiDone
                            ? Colors.green.withValues(alpha: 0.15)
                            : cs.surface,
                        borderRadius: BorderRadius.circular(Nur.buttonRadius),
                        border: Border.all(
                          color: hifz.isTodaySabqiDone
                              ? Colors.green
                              : cs.onSurface.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hifz.isTodaySabqiDone
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: hifz.isTodaySabqiDone
                                ? Colors.green
                                : cs.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              hifz.isTodaySabqiDone
                                  ? 'Sabqi Revised Today! (سبقی دہرائی مکمل)'
                                  : 'Tap to Mark as Revised (دہرائی مکمل کریں)',
                              style: TextStyle(
                                color: hifz.isTodaySabqiDone
                                    ? Colors.green
                                    : cs.onSurface,
                                fontWeight: hifz.isTodaySabqiDone
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================================
  // TAB 2: MANZIL DAUR (Long-term Revision Rotation)
  // =========================================================================
  Widget _buildManzilDaurTab(ColorScheme cs, bool isDark) {
    return Consumer<HifzService>(
      builder: (context, hifz, _) {
        final currentJuzNum = hifz.manzilCurrentJuz;
        final juzObj = (currentJuzNum >= 1 && currentJuzNum <= juzList.length)
            ? juzList[currentJuzNum - 1]
            : null;
        final startPage = juzObj?.startPage ?? 1;

        return ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: Nur.screenMargin, vertical: Nur.s16),
          children: [
            // Current Manzil Focus Card
            NurCard(
              padding: const EdgeInsets.all(Nur.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.sync_rounded,
                                color: cs.primary, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's Manzil Daur (آج کا دور)",
                                style: TextStyle(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "Daily rotation: ${hifz.manzilDailyTarget} Juz daily",
                                style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                            foregroundColor: cs.onSurface.withValues(alpha: 0.6)),
                        onPressed: () => _confirmResetManzil(context, hifz),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Reset', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Juz $currentJuzNum: ${juzObj?.nameTr ?? ''}',
                              style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'پارہ $currentJuzNum — ${juzObj?.nameAr ?? ''}',
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.8),
                                fontSize: 14,
                                fontFamily: arabicFontFamily('amiri'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(Nur.buttonRadius),
                          ),
                        ),
                        onPressed: () {
                          widget.onOpenPage(startPage);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.auto_stories, size: 16),
                        label: const Text('Read Juz'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    borderRadius: BorderRadius.circular(Nur.buttonRadius),
                    onTap: () => hifz.toggleTodayManzil(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Nur.s12, vertical: 10),
                      decoration: BoxDecoration(
                        color: hifz.isTodayManzilDone
                            ? Colors.green.withValues(alpha: 0.15)
                            : cs.surface,
                        borderRadius: BorderRadius.circular(Nur.buttonRadius),
                        border: Border.all(
                          color: hifz.isTodayManzilDone
                              ? Colors.green
                              : cs.onSurface.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hifz.isTodayManzilDone
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: hifz.isTodayManzilDone
                                ? Colors.green
                                : cs.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              hifz.isTodayManzilDone
                                  ? "Today's Daur Completed! (دور مکمل ہوا)"
                                  : "Mark Juz as Revised & Next (دور مکمل کریں)",
                              style: TextStyle(
                                color: hifz.isTodayManzilDone
                                    ? Colors.green
                                    : cs.onSurface,
                                fontWeight: hifz.isTodayManzilDone
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Nur.s20),

            // 30-Juz Rotation Cycle Grid
            Text(
              '30 Juz Revision Progress (اس دور کا جائزہ)',
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: 30,
              itemBuilder: (context, idx) {
                final juzNumber = idx + 1;
                final isDone = hifz.manzilCompletedJuz.contains(juzNumber);
                final isCurrent = hifz.manzilCurrentJuz == juzNumber;

                return InkWell(
                  borderRadius: BorderRadius.circular(Nur.buttonRadius),
                  onTap: () {
                    hifz.setManzilConfig(currentJuz: juzNumber);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDone
                          ? cs.primary
                          : isCurrent
                              ? cs.primary.withValues(alpha: 0.2)
                              : cs.surface,
                      borderRadius: BorderRadius.circular(Nur.buttonRadius),
                      border: Border.all(
                        color: isCurrent
                            ? cs.primary
                            : isDone
                                ? cs.primary
                                : cs.onSurface.withValues(alpha: 0.15),
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$juzNumber',
                            style: TextStyle(
                              color: isDone
                                  ? cs.onPrimary
                                  : isCurrent
                                      ? cs.primary
                                      : cs.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (isDone)
                            Icon(Icons.check, size: 12, color: cs.onPrimary),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // =========================================================================
  // TAB 3: MISTAKES TRACKER (غلطی اور اٹکان لاگ)
  // =========================================================================
  Widget _buildMistakesTab(ColorScheme cs, bool isDark) {
    return Consumer<HifzService>(
      builder: (context, hifz, _) {
        var list = hifz.mistakes;
        if (_mistakeFilter == 'active') {
          list = list.where((m) => !m.isResolved).toList();
        } else if (_mistakeFilter == 'resolved') {
          list = list.where((m) => m.isResolved).toList();
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            onPressed: () => _showAddMistakeDialog(context, hifz),
            icon: const Icon(Icons.add),
            label: const Text('Log Mistake (اٹکان درج کریں)'),
          ),
          body: Column(
            children: [
              // Filter Chips Row
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: Nur.screenMargin, vertical: 10),
                child: Row(
                  children: [
                    _filterChip(
                        'All (${hifz.mistakes.length})', 'all', cs),
                    const SizedBox(width: Nur.s8),
                    _filterChip(
                        'Unresolved (${hifz.activeMistakesCount})', 'active', cs),
                    const SizedBox(width: Nur.s8),
                    _filterChip('Pukhta (پختہ)', 'resolved', cs),
                  ],
                ),
              ),

              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(Nur.s24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline_rounded,
                                  size: 64,
                                  color: cs.primary.withValues(alpha: 0.4)),
                              const SizedBox(height: 14),
                              Text(
                                _mistakeFilter == 'active'
                                    ? 'No active mistakes! Mashallah!'
                                    : 'No mistakes logged yet.',
                                style: TextStyle(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Log any Ayah where you faced hesitation (shuba) or a mistake so you can revise it.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(
                            left: Nur.screenMargin,
                            right: Nur.screenMargin,
                            top: Nur.s8,
                            bottom: 80),
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          final m = list[idx];
                          return NurCard(
                            padding: const EdgeInsets.all(Nur.s12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    m.isResolved
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked,
                                    color: m.isResolved
                                        ? Colors.green
                                        : cs.onSurface.withValues(alpha: 0.4),
                                    size: 26,
                                  ),
                                  tooltip: m.isResolved
                                      ? 'Mark Unresolved'
                                      : 'Mark Pukhta (Resolved)',
                                  onPressed: () =>
                                      hifz.toggleMistakeResolved(m.id),
                                ),
                                const SizedBox(width: Nur.s8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Surah ${_getSurahName(m.surah)} (${m.surah}:${m.ayah})',
                                            style: TextStyle(
                                              color: cs.onSurface,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: m.count > 1
                                                  ? Colors.red
                                                      .withValues(alpha: 0.15)
                                                  : cs.primary
                                                      .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${m.count}x repeated',
                                              style: TextStyle(
                                                color: m.count > 1
                                                    ? Colors.red
                                                    : cs.primary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: cs.onSurface
                                                  .withValues(alpha: 0.08),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              m.mistakeType,
                                              style: TextStyle(
                                                color: cs.onSurface
                                                    .withValues(alpha: 0.7),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: Nur.s8),
                                          Text(
                                            'Page ${m.page}',
                                            style: TextStyle(
                                              color: cs.primary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (m.notes != null &&
                                          m.notes!.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          m.notes!,
                                          style: TextStyle(
                                            color: cs.onSurface
                                                .withValues(alpha: 0.7),
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.auto_stories,
                                          size: 20),
                                      tooltip: 'Open Page',
                                      color: cs.primary,
                                      onPressed: () {
                                        widget.onOpenPage(m.page);
                                        Navigator.pop(context);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 20),
                                      color: cs.onSurface.withValues(alpha: 0.4),
                                      tooltip: 'Delete',
                                      onPressed: () => hifz.deleteMistake(m.id),
                                    ),
                                  ],
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
      },
    );
  }

  Widget _filterChip(String label, String value, ColorScheme cs) {
    final isSelected = _mistakeFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _mistakeFilter = value);
      },
      selectedColor: cs.primary,
      labelStyle: TextStyle(
        color: isSelected ? cs.onPrimary : cs.onSurface,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  // Dialogs
  void _showEditSabaqDialog(BuildContext context, HifzService hifz) {
    final pageCtrl = TextEditingController(text: hifz.sabaqPage.toString());
    final targetCtrl =
        TextEditingController(text: hifz.dailySabaqPages.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Sabaq Target'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pageCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Page (1 - 611)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Daily Pages to Memorize',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final p = int.tryParse(pageCtrl.text.trim()) ?? hifz.sabaqPage;
              final t =
                  int.tryParse(targetCtrl.text.trim()) ?? hifz.dailySabaqPages;
              hifz.setSabaqTarget(page: p, dailyPages: t);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditSabqiDialog(BuildContext context, HifzService hifz) {
    final startCtrl =
        TextEditingController(text: hifz.sabqiStartPage.toString());
    final endCtrl = TextEditingController(text: hifz.sabqiEndPage.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Sabqi Revision Range'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: startCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'From Page',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: endCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'To Page',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final s =
                  int.tryParse(startCtrl.text.trim()) ?? hifz.sabqiStartPage;
              final e = int.tryParse(endCtrl.text.trim()) ?? hifz.sabqiEndPage;
              hifz.setSabqiRange(startPage: s, endPage: e);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmResetManzil(BuildContext context, HifzService hifz) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Manzil Cycle?'),
        content: const Text(
          'This will restart the 30-Juz revision cycle from Juz 1.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              hifz.resetManzilCycle();
              Navigator.pop(ctx);
            },
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddMistakeDialog(BuildContext context, HifzService hifz) {
    final surahCtrl = TextEditingController(text: '1');
    final ayahCtrl = TextEditingController(text: '1');
    final pageCtrl = TextEditingController(text: '1');
    final notesCtrl = TextEditingController();
    String selectedType = "I'rab / Harkat";

    final types = [
      "I'rab / Harkat (زبر زیر پیش)",
      "Shuba / Mutashabihat (شبہ / متشابہات)",
      "Kalima / Words (کلمہ چھوٹنا)",
      "Aayat Order (آیت آگے پیچھے)",
      "Waqf / Stop (وقف کی غلطی)",
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Log Mistake (اٹکان درج کریں)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: surahCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Surah (1-114)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: ayahCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Ayah #',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: pageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Page',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Mistake Type',
                    border: OutlineInputBorder(),
                  ),
                  items: types
                      .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Reminders (اختیاری نوٹ)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final s = int.tryParse(surahCtrl.text.trim()) ?? 1;
                final a = int.tryParse(ayahCtrl.text.trim()) ?? 1;
                final p = int.tryParse(pageCtrl.text.trim()) ?? 1;
                hifz.addMistake(
                  surah: s,
                  ayah: a,
                  page: p,
                  mistakeType: selectedType,
                  notes: notesCtrl.text.trim(),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  String _getSurahForPage(int page) {
    Surah current = allSurahs.first;
    for (final s in allSurahs) {
      if (s.startPage <= page) {
        current = s;
      } else {
        break;
      }
    }
    return 'Surah ${current.nameEn} (${current.nameAr})';
  }

  String _getSurahName(int surahNum) {
    if (surahNum >= 1 && surahNum <= 114) {
      final s = allSurahs[surahNum - 1];
      return s.nameEn;
    }
    return 'Surah $surahNum';
  }
}
