import 'package:flutter/material.dart';
import '../data/quran_data.dart';
import '../models/surah.dart';
import '../utils/script_font.dart';
import 'tafsir_surah_screen.dart';

/// Tafsir Home: list of all 114 Surahs. Tapping a surah opens its
/// Ayah List (Arabic + Urdu tarjuma). Tapping an ayah in the list
/// opens its detail page (ayah + tarjuma + Ibn Kathir tafsir).
class TafsirHomeScreen extends StatelessWidget {
  const TafsirHomeScreen({super.key});

  void _openSurah(BuildContext context, int surah) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TafsirSurahScreen(surah: surah),
      ),
    );
  }

  Widget _buildSurahCard(BuildContext context, Surah surah) {
    final cs = Theme.of(context).colorScheme;
    final badge = surah.number.toString().padLeft(2, '0');
    return Card(
      color: cs.surface,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: cs.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openSurah(context, surah.number),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Gold-ringed number medallion
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primary.withValues(alpha: 0.12),
                  border: Border.all(color: cs.primary, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.nameAr,
                      textDirection: TextDirection.rtl,
                      style: arabicStyle(
                        'sans',
                        fontSize: 20,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Surah $badge • ${surah.nameEn}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${surah.totalAyahs} Ayahs • ${surah.revelation}',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.primary),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tafsir',
          style: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Golden subtitle banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_stories, color: cs.primary, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'تفسیر ابن کثیر — ہر آیت کے ساتھ ترجمہ اور تفسیر',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: allSurahs.length,
              itemBuilder: (context, index) =>
                  _buildSurahCard(context, allSurahs[index]),
            ),
          ),
        ],
      ),
    );
  }
}
