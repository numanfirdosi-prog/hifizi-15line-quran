import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'audio_recitation_service.dart';

/// On-disk storage for downloaded qari audio packs (offline playback).
///
/// Layout inside the app documents directory:
///   qari_audio/{qariId}/surah_001.mp3 ... surah_114.mp3
///   qari_audio/{qariId}/ayah_001_001.mp3 ... ayah_114_006.mp3
///
/// Nothing here touches the network or SharedPreferences; it is a thin
/// wrapper over dart:io so the download service and the audio player can
/// share one layout.
class QariAudioStorage {
  /// Per-surah MP3s per qari (001..114).
  static const int totalSurahFiles = 114;

  /// Per-ayah MP3s per qari (sum of allSurahs[*].totalAyahs).
  static const int totalAyahFiles = 6236;

  /// Full pack size: 114 surahs + 6236 ayahs.
  static const int totalPackFiles = totalSurahFiles + totalAyahFiles; // 6350

  /// File name for surah [surah] (1..114): `surah_001.mp3`.
  static String surahFileName(int surah) =>
      'surah_${surah.toString().padLeft(3, '0')}.mp3';

  /// File name for ayah [ayah] of surah [surah]: `ayah_002_255.mp3`.
  static String ayahFileName(int surah, int ayah) =>
      'ayah_${surah.toString().padLeft(3, '0')}_'
      '${ayah.toString().padLeft(3, '0')}.mp3';

  /// Directory holding one qari's pack: {docs}/qari_audio/{qariId}/.
  /// Created when missing.
  static Future<Directory> qariDir(String qariId) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/qari_audio/$qariId');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Local file for surah [surah] of [qari], or null when not downloaded.
  static Future<File?> surahFile(Qari qari, int surah) async {
    final dir = await qariDir(qari.id);
    final file = File('${dir.path}/${surahFileName(surah)}');
    return await file.exists() ? file : null;
  }

  /// Local file for ayah [ayah] of surah [surah] of [qari],
  /// or null when not downloaded.
  static Future<File?> ayahFile(Qari qari, int surah, int ayah) async {
    final dir = await qariDir(qari.id);
    final file = File('${dir.path}/${ayahFileName(surah, ayah)}');
    return await file.exists() ? file : null;
  }

  /// (surahsDownloaded, ayahsDownloaded) for [qariId], counted by
  /// file-name prefix. Never throws.
  static Future<(int, int)> downloadedCounts(String qariId) async {
    try {
      final dir = await qariDir(qariId);
      var surahs = 0;
      var ayahs = 0;
      await for (final entry in dir.list()) {
        final name = entry.path.split('/').last;
        if (name.startsWith('surah_') && name.endsWith('.mp3')) {
          surahs++;
        } else if (name.startsWith('ayah_') && name.endsWith('.mp3')) {
          ayahs++;
        }
      }
      return (surahs, ayahs);
    } catch (_) {
      return (0, 0);
    }
  }

  /// True when the full pack (114 surahs + 6236 ayahs) is on disk.
  /// Never throws.
  static Future<bool> isPackComplete(String qariId) async {
    final (surahs, ayahs) = await downloadedCounts(qariId);
    return surahs >= totalSurahFiles && ayahs >= totalAyahFiles;
  }

  /// Total bytes of [qariId]'s downloaded pack. Never throws.
  static Future<int> totalBytes(String qariId) async {
    try {
      final dir = await qariDir(qariId);
      var bytes = 0;
      await for (final entry in dir.list()) {
        if (entry is File) bytes += await entry.length();
      }
      return bytes;
    } catch (_) {
      return 0;
    }
  }

  /// Deletes [qariId]'s whole pack directory. Never throws.
  static Future<void> deleteQari(String qariId) async {
    try {
      final dir = await qariDir(qariId);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }
}
