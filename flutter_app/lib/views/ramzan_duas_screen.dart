import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/duas_data.dart';
import '../data/juz_data.dart';
import '../data/static_content.dart';
import '../services/preferences_service.dart';
import '../utils/script_font.dart';

/// Ramzan reflections and duas.
class RamzanDuasScreen extends StatefulWidget {
  final void Function(int page) onOpenPage;
  const RamzanDuasScreen({required this.onOpenPage, super.key});

  @override
  State<RamzanDuasScreen> createState() => _RamzanDuasScreenState();
}

class _RamzanDuasScreenState extends State<RamzanDuasScreen> {
  static const _categories = ['All 8', 'Sehri & Iftar', 'Ashra', 'Special'];

  String _category = 'All 8';
  int _reflectionOffset = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _category == 'All 8'
        ? duas
        : duas.where((d) => d.category == _category).toList();
    final reflections = ramadanReflections;
    final reflection = reflections[
        (DateTime.now().day - 1 + _reflectionOffset) % reflections.length];
    final juz = ((DateTime.now().day - 1) % 30) + 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Ramzan & Duas')),
      body: Consumer<PreferencesService>(
        builder: (context, prefs, _) => ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // Today's Reminder card.
            Card(
              color: theme.colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Reminder",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(reflection, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: () => setState(() => _reflectionOffset++),
                          child: const Text('Next Reflection'),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: reflection),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Reflection copied'),
                                ),
                              );
                            }
                          },
                          child: const Text('Copy Reflection'),
                        ),
                        TextButton(
                          onPressed: () =>
                              widget.onOpenPage(juzList[juz - 1].startPage),
                          child: Text("Read Today's Juz ($juz)"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Category chips.
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final c in _categories)
                  ChoiceChip(
                    label: Text(c),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            for (final dua in filtered) _duaCard(context, prefs, dua),
          ],
        ),
      ),
    );
  }

  Widget _duaCard(BuildContext context, PreferencesService prefs, Dua dua) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                dua.tag,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dua.title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              dua.arabic,
              textDirection: TextDirection.rtl,
              style: arabicStyle(
                prefs.scriptStyle,
                scale: prefs.ayahScale,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dua.transliteration,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
            if (dua.translationUrdu.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  dua.translationUrdu,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Noto Nastaliq Urdu',
                    fontSize: 14.5,
                    height: 1.85,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              dua.translation,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy Dua'),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(
                      text:
                          '${dua.arabic}\n\n${dua.translationUrdu}\n\n${dua.translation}',
                    ),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dua copied')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
