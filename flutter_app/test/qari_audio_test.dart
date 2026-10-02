import 'package:flutter_test/flutter_test.dart';
import 'package:nur_al_quran/data/quran_data.dart';
import 'package:nur_al_quran/services/audio_recitation_service.dart';
import 'package:nur_al_quran/services/qari_audio_storage.dart';
import 'package:nur_al_quran/services/qari_download_service.dart';

void main() {
  group('QariAudioStorage file names', () {
    test('surahFileName pads to 3 digits', () {
      expect(QariAudioStorage.surahFileName(1), 'surah_001.mp3');
      expect(QariAudioStorage.surahFileName(5), 'surah_005.mp3');
      expect(QariAudioStorage.surahFileName(114), 'surah_114.mp3');
    });

    test('ayahFileName pads surah and ayah to 3 digits', () {
      expect(QariAudioStorage.ayahFileName(1, 1), 'ayah_001_001.mp3');
      expect(QariAudioStorage.ayahFileName(2, 255), 'ayah_002_255.mp3');
      expect(QariAudioStorage.ayahFileName(114, 6), 'ayah_114_006.mp3');
    });

    test('surah and ayah file names never collide', () {
      final names = <String>{
        for (var s = 1; s <= 114; s++) QariAudioStorage.surahFileName(s),
        for (var s = 1; s <= 114; s++)
          for (var v = 1; v <= allSurahs[s - 1].totalAyahs; v++)
            QariAudioStorage.ayahFileName(s, v),
      };
      expect(names.length, QariAudioStorage.totalPackFiles);
    });
  });

  group('pack file counts', () {
    test('total pack files = 114 surahs + 6236 ayahs = 6350', () {
      expect(QariAudioStorage.totalSurahFiles, 114);
      expect(QariAudioStorage.totalAyahFiles, 6236);
      expect(QariAudioStorage.totalPackFiles, 6350);
      expect(QariAudioStorage.totalPackFiles,
          QariAudioStorage.totalSurahFiles + QariAudioStorage.totalAyahFiles);
    });

    test('ayah file count matches the real quran_data ayah total', () {
      final total = allSurahs.fold<int>(0, (sum, s) => sum + s.totalAyahs);
      expect(total, 6236);
      expect(total, QariAudioStorage.totalAyahFiles);
    });

    test('all 12 qaris have unique ids for per-qari directories', () {
      expect(availableQaris.length, 12);
      final ids = availableQaris.map((q) => q.id).toSet();
      expect(ids.length, 12);
    });
  });

  group('audio URL building (offline pack mirrors these URLs)', () {
    test('first and last surah URLs', () {
      final q = availableQaris.first;
      expect(q.urlForSurah(1), '${q.baseUrl}001.mp3');
      expect(q.urlForSurah(114), '${q.baseUrl}114.mp3');
    });

    test('ayah URLs for 2:255 and 114:6', () {
      final q = availableQaris.first; // Alafasy
      expect(q.ayahUrl(2, 255),
          'https://everyayah.com/data/Alafasy_128kbps/002255.mp3');
      expect(q.ayahUrl(114, 6).endsWith('114006.mp3'), isTrue);
      expect(q.ayahUrl(1, 1).endsWith('001001.mp3'), isTrue);
    });

    test('every qari builds 114 surah + 6236 ayah URLs', () {
      for (final q in availableQaris) {
        final surahUrls = [
          for (var s = 1; s <= 114; s++) q.urlForSurah(s)
        ];
        expect(surahUrls.toSet().length, 114, reason: q.id);
        var ayahCount = 0;
        for (var s = 1; s <= 114; s++) {
          for (var v = 1; v <= allSurahs[s - 1].totalAyahs; v++) {
            q.ayahUrl(s, v);
            ayahCount++;
          }
        }
        expect(ayahCount, 6236, reason: q.id);
      }
    });
  });

  group('QariPackProgress math', () {
    test('default progress is idle with zero fraction', () {
      const p = QariPackProgress();
      expect(p.state, QariPackState.idle);
      expect(p.done, 0);
      expect(p.total, QariAudioStorage.totalPackFiles);
      expect(p.fraction, 0.0);
      expect(p.errorCount, 0);
    });

    test('fraction is done/total', () {
      const p = QariPackProgress(
          state: QariPackState.downloading, done: 3175, total: 6350);
      expect(p.fraction, 0.5);
    });

    test('fraction clamps to 0..1', () {
      expect(
          const QariPackProgress(done: 6350, total: 6350).fraction, 1.0);
      expect(
          const QariPackProgress(done: 99999, total: 6350).fraction, 1.0);
      expect(const QariPackProgress(done: 0, total: 0).fraction, 0.0);
    });

    test('copyWith changes only the given fields', () {
      const p = QariPackProgress();
      final paused = p.copyWith(state: QariPackState.paused, done: 100);
      expect(paused.state, QariPackState.paused);
      expect(paused.done, 100);
      expect(paused.total, QariAudioStorage.totalPackFiles);
      expect(paused.errorCount, 0);
      final err = paused.copyWith(
          state: QariPackState.error,
          errorCount: 3,
          errorMessage: '3 file(s) failed');
      expect(err.state, QariPackState.error);
      expect(err.errorCount, 3);
      expect(err.errorMessage, contains('3 file(s) failed'));
      expect(err.done, 100);
    });
  });

  group('resume skip-existing logic (simulated, no disk)', () {
    // Mirrors _buildQueue: the full name list minus already-present names.
    List<String> queueFor(Set<String> existing) {
      final all = <String>[
        for (var s = 1; s <= 114; s++) QariAudioStorage.surahFileName(s),
        for (var s = 1; s <= 114; s++)
          for (var v = 1; v <= allSurahs[s - 1].totalAyahs; v++)
            QariAudioStorage.ayahFileName(s, v),
      ];
      return all.where((n) => !existing.contains(n)).toList();
    }

    test('fresh start queues all 6350 files', () {
      expect(queueFor(<String>{}).length, 6350);
    });

    test('partial pack queues only the missing files', () {
      final existing = <String>{
        for (var s = 1; s <= 10; s++) QariAudioStorage.surahFileName(s),
        for (var v = 1; v <= 7; v++) QariAudioStorage.ayahFileName(1, v),
      };
      expect(queueFor(existing).length, 6350 - existing.length);
    });

    test('fully downloaded pack queues nothing', () {
      final existing = queueFor(<String>{}).toSet();
      expect(queueFor(existing), isEmpty);
    });
  });

  group('ayah navigation helpers unchanged', () {
    test('nextAyahAfter at end of Quran returns null', () {
      expect(nextAyahAfter(114, 6), isNull);
    });

    test('nextAyahAfter crosses surah boundaries', () {
      expect(nextAyahAfter(1, 7), (2, 1)); // Al-Fatihah has 7 ayahs
      expect(nextAyahAfter(2, 286), (3, 1)); // Al-Baqarah has 286 ayahs
      expect(nextAyahAfter(2, 255), (2, 256));
    });

    test('prevAyahBefore at start of Quran returns null', () {
      expect(prevAyahBefore(1, 1), isNull);
    });

    test('isValidAyahRange still validates', () {
      expect(AudioRecitationService.isValidAyahRange(2, 255, 286), isTrue);
      expect(AudioRecitationService.isValidAyahRange(2, 255, 287), isFalse);
      expect(AudioRecitationService.isValidAyahRange(115, 1, 2), isFalse);
    });
  });
}
