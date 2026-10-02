import 'package:flutter_test/flutter_test.dart';
import 'package:nur_al_quran/services/audio_recitation_service.dart';

void main() {
  test('all 12 qaris have everyayah.com ayah URLs in SSSVVV format', () {
    expect(availableQaris.length, 12);
    const expectedFolders = {
      'ar.alafasy': 'Alafasy_128kbps',
      'ar.abdulbasitmurattal': 'Abdul_Basit_Murattal_192kbps',
      'ar.abdulbasitmujawwad': 'Abdul_Basit_Mujawwad_128kbps',
      'ar.husary': 'Husary_128kbps',
      'ar.husarymujawwad': 'Husary_Mujawwad_64kbps',
      'ar.minshawi': 'Minshawy_Murattal_128kbps',
      'ar.minshawimujawwad': 'Minshawy_Mujawwad_192kbps',
      'ar.abdurrahmaansudais': 'Abdurrahmaan_As-Sudais_192kbps',
      'ar.mahermuaiqly': 'MaherAlMuaiqly128kbps',
      'ar.saoodshuraym': 'Saood_ash-Shuraym_128kbps',
      'ar.abubakrshatree': 'Abu_Bakr_Ash-Shaatree_128kbps',
      'ar.alihudhaify': 'Hudhaify_128kbps',
    };
    for (final q in availableQaris) {
      final folder = expectedFolders[q.id];
      expect(folder, isNotNull, reason: 'unexpected qari id ${q.id}');
      // e.g. surah 2, ayah 255 -> 002255.mp3
      expect(
        q.ayahUrl(2, 255),
        'https://everyayah.com/data/$folder/002255.mp3',
        reason: q.id,
      );
      // padding check: surah 1, ayah 1 -> 001001.mp3
      expect(q.ayahUrl(1, 1).endsWith('/001001.mp3'), isTrue, reason: q.id);
    }
  });

  test('nextAyahAfter advances within surah and wraps across surahs', () {
    expect(nextAyahAfter(2, 255), (2, 256));
    // Al-Fatihah has 7 ayahs -> wraps to 2:1
    expect(nextAyahAfter(1, 7), (2, 1));
    // Al-Baqarah has 286 ayahs -> wraps to 3:1
    expect(nextAyahAfter(2, 286), (3, 1));
  });

  test('nextAyahAfter returns null at end of Quran (114:6)', () {
    expect(nextAyahAfter(114, 6), isNull);
    expect(nextAyahAfter(114, 5), (114, 6));
  });

  test('prevAyahBefore goes back within surah and wraps', () {
    expect(prevAyahBefore(2, 255), (2, 254));
    // 2:1 -> back to 1:7 (Al-Fatihah has 7 ayahs)
    expect(prevAyahBefore(2, 1), (1, 7));
    // 1:1 -> null (start of Quran)
    expect(prevAyahBefore(1, 1), isNull);
  });
}
