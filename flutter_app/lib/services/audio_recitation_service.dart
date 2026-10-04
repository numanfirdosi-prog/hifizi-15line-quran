import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/quran_data.dart';
import 'qari_audio_storage.dart';

class Qari {
  final String id;
  final String name;
  final String arabic;
  final String style;
  final String country;
  final String baseUrl;

  /// Base URL for per-ayah MP3s on everyayah.com
  /// (pattern: {ayahBaseUrl}{SSS}{VVV}.mp3, e.g. 002255.mp3).
  final String ayahBaseUrl;

  const Qari({
    required this.id,
    required this.name,
    required this.arabic,
    required this.style,
    required this.country,
    required this.baseUrl,
    required this.ayahBaseUrl,
  });

  /// Full mp3 URL for surah [n] on this qari's mp3quran server.
  String urlForSurah(int n) => '$baseUrl${n.toString().padLeft(3, '0')}.mp3';

  /// Full mp3 URL for ayah [v] of surah [s] on everyayah.com.
  String ayahUrl(int s, int v) =>
      '$ayahBaseUrl${s.toString().padLeft(3, '0')}${v.toString().padLeft(3, '0')}.mp3';
}

// Server URLs below were extracted from the mp3quran API
// (https://www.mp3quran.net/api/v3/reciters?language=eng) on 2026-10-02:
// each reciter's moshaf 'server' field for the matching Murattal/Mujawwad
// moshaf. The 5 original qaris keep their previous base URL.
const List<Qari> availableQaris = [
  Qari(
    id: 'ar.alafasy',
    name: 'Mishary Rashid Alafasy',
    arabic: 'مشاري راشد العفاسي',
    style: 'Murattal',
    country: 'Kuwait',
    baseUrl: 'https://server8.mp3quran.net/afs/',
    ayahBaseUrl: 'https://everyayah.com/data/Alafasy_128kbps/',
  ),
  Qari(
    id: 'ar.abdulbasitmurattal',
    name: 'Abdul Basit Abdus Samad',
    arabic: 'عبد الباسط عبد الصمد',
    style: 'Murattal',
    country: 'Egypt',
    baseUrl: 'https://server7.mp3quran.net/basit/',
    ayahBaseUrl: 'https://everyayah.com/data/Abdul_Basit_Murattal_192kbps/',
  ),
  Qari(
    id: 'ar.husary',
    name: 'Mahmoud Khalil Al-Husary',
    arabic: 'محمود خليل الحصري',
    style: 'Murattal',
    country: 'Egypt',
    baseUrl: 'https://server13.mp3quran.net/husr/',
    ayahBaseUrl: 'https://everyayah.com/data/Husary_128kbps/',
  ),
  Qari(
    id: 'ar.minshawi',
    name: 'Mohamed Siddiq El-Minshawi',
    arabic: 'محمد صديق المنشاوي',
    style: 'Murattal',
    country: 'Egypt',
    baseUrl: 'https://server10.mp3quran.net/minsh/',
    ayahBaseUrl: 'https://everyayah.com/data/Minshawy_Murattal_128kbps/',
  ),
  Qari(
    id: 'ar.abdurrahmaansudais',
    name: 'Abdur-Rahman As-Sudais',
    arabic: 'عبد الرحمن السديس',
    style: 'Murattal',
    country: 'Makkah/Saudi Arabia',
    baseUrl: 'https://server11.mp3quran.net/sds/',
    ayahBaseUrl: 'https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/',
  ),
  // --- expanded studio list (API-extracted servers) ---
  Qari(
    id: 'ar.abdulbasitmujawwad',
    name: 'Abdul Basit Abdus Samad',
    arabic: 'عبد الباسط عبد الصمد',
    style: 'Mujawwad',
    country: 'Egypt',
    baseUrl: 'https://server7.mp3quran.net/basit/Almusshaf-Al-Mojawwad/',
    ayahBaseUrl: 'https://everyayah.com/data/Abdul_Basit_Mujawwad_128kbps/',
  ),
  Qari(
    id: 'ar.husarymujawwad',
    name: 'Mahmoud Khalil Al-Husary',
    arabic: 'محمود خليل الحصري',
    style: 'Mujawwad',
    country: 'Egypt',
    baseUrl: 'https://server13.mp3quran.net/husr/Almusshaf-Al-Mojawwad/',
    ayahBaseUrl: 'https://everyayah.com/data/Husary_Mujawwad_64kbps/',
  ),
  Qari(
    id: 'ar.minshawimujawwad',
    name: 'Mohamed Siddiq El-Minshawi',
    arabic: 'محمد صديق المنشاوي',
    style: 'Mujawwad',
    country: 'Egypt',
    baseUrl: 'https://server10.mp3quran.net/minsh/Almusshaf-Al-Mojawwad/',
    ayahBaseUrl: 'https://everyayah.com/data/Minshawy_Mujawwad_192kbps/',
  ),
  Qari(
    id: 'ar.mahermuaiqly',
    name: 'Maher Al-Muaiqly',
    arabic: 'ماهر المعيقلي',
    style: 'Murattal',
    country: 'Makkah/Saudi Arabia',
    baseUrl: 'https://server12.mp3quran.net/maher/',
    ayahBaseUrl: 'https://everyayah.com/data/MaherAlMuaiqly128kbps/',
  ),
  Qari(
    id: 'ar.saoodshuraym',
    name: 'Saood Ash-Shuraym',
    arabic: 'سعود الشريم',
    style: 'Murattal',
    country: 'Makkah/Saudi Arabia',
    baseUrl: 'https://server7.mp3quran.net/shur/',
    ayahBaseUrl: 'https://everyayah.com/data/Saood_ash-Shuraym_128kbps/',
  ),
  Qari(
    id: 'ar.abubakrshatree',
    name: 'Abu Bakr Ash-Shatree',
    arabic: 'أبو بكر الشاطري',
    style: 'Murattal',
    country: 'Saudi Arabia',
    baseUrl: 'https://server11.mp3quran.net/shatri/',
    ayahBaseUrl: 'https://everyayah.com/data/Abu_Bakr_Ash-Shaatree_128kbps/',
  ),
  Qari(
    id: 'ar.alihudhaify',
    name: 'Ali Abdur-Rahman Al-Hudhaify',
    arabic: 'علي عبد الرحمن الحذيفي',
    style: 'Murattal',
    country: 'Madinah/Saudi Arabia',
    baseUrl: 'https://server9.mp3quran.net/hthfi/',
    ayahBaseUrl: 'https://everyayah.com/data/Hudhaify_128kbps/',
  ),
];

/// Pure helper: the (surah, ayah) following ([s], [v]), or null at the end
/// of the Quran (after 114:6).
(int, int)? nextAyahAfter(int s, int v) {
  final total = allSurahs[s - 1].totalAyahs;
  var ns = s;
  var nv = v + 1;
  if (nv > total) {
    ns += 1;
    nv = 1;
  }
  if (ns > 114) return null;
  return (ns, nv);
}

/// Pure helper: the (surah, ayah) preceding ([s], [v]), or null at 1:1.
(int, int)? prevAyahBefore(int s, int v) {
  var ns = s;
  var nv = v - 1;
  if (nv < 1) {
    ns -= 1;
    if (ns < 1) return null;
    nv = allSurahs[ns - 1].totalAyahs;
  }
  return (ns, nv);
}

class AudioRecitationService extends ChangeNotifier {
  static const String _selectedQariIdKey = 'selectedQariId';

  final AudioPlayer _player = AudioPlayer();
  Qari _selectedQari = availableQaris[0];
  bool _isPlaying = false;
  int _currentSurah = 1;
  int _currentAyah = 1;

  /// 0 = off, 1/3/5 = that many total plays, -1 = infinite.
  int repeatMode = 0;
  int _completedPlays = 0;

  /// Ayah-by-ayah mode: plays one ayah MP3 after another, advancing through
  /// the Mushaf until the user stops. Ignores [repeatMode].
  bool _ayahMode = false;
  bool get ayahMode => _ayahMode;

  /// Ayah-range repeat: when set, [_advanceAyah] loops within
  /// [_repeatRangeSurah]:[_repeatRangeStart]..[_repeatRangeEnd].
  int? _repeatRangeSurah;
  int? _repeatRangeStart;
  int? _repeatRangeEnd;
  bool get hasAyahRepeatRange => _repeatRangeSurah != null;
  int? get repeatRangeStart => _repeatRangeStart;
  int? get repeatRangeEnd => _repeatRangeEnd;

  /// Human-readable label for the active ayah repeat range, e.g.
  /// "Surah 2: 255–260". Null when no range is set.
  String? get repeatRangeLabel {
    final s = _repeatRangeSurah;
    final a = _repeatRangeStart;
    final b = _repeatRangeEnd;
    if (s == null || a == null || b == null) return null;
    return 'Surah $s: $a–$b (loop)';
  }

  /// Pure validation for an ayah repeat range (single surah).
  static bool isValidAyahRange(int surah, int start, int end) {
    if (surah < 1 || surah > 114) return false;
    if (start < 1 || end < start) return false;
    return end <= allSurahs[surah - 1].totalAyahs;
  }

  AudioPlayer get player => _player;
  Qari get selectedQari => _selectedQari;
  bool get isPlaying => _isPlaying;
  int get currentSurah => _currentSurah;
  int get currentAyah => _currentAyah;

  AudioRecitationService() {
    _restoreSelectedQari();
    _initAudioSession();
    _player.playerStateStream.listen(_onPlayerState);
    // Website-style highlight fill: 0..1 progress of the current ayah.
    _player.positionStream.listen((pos) {
      if (!_ayahMode || _progressClosed) return;
      final d = _player.duration;
      final p = (d == null || d.inMilliseconds <= 0)
          ? 0.0
          : (pos.inMilliseconds / d.inMilliseconds).clamp(0.0, 1.0);
      _ayahProgressController.add(p);
    });
  }

  /// Configures the platform audio session: pauses on interruptions
  /// (phone calls) and headset unplug, resuming afterwards only if audio
  /// was playing before. Never throws — failures leave audio working.
  bool _playInterrupted = false;

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          if (_isPlaying) {
            _playInterrupted = true;
            pause();
          }
        } else {
          if (_playInterrupted) {
            _playInterrupted = false;
            resume();
          }
        }
      });
      session.becomingNoisyEventStream.listen((_) {
        if (_isPlaying) pause();
      });
    } catch (e) {
      debugPrint('[AudioRecitation] audio session unavailable: $e');
    }
  }

  final _ayahProgressController = StreamController<double>.broadcast();
  bool _progressClosed = false;

  /// 0..1 playback progress of the currently playing ayah (ayah mode).
  /// Drives the website-style right-to-left highlight fill.
  Stream<double> get ayahProgressStream => _ayahProgressController.stream;

  Future<void> _restoreSelectedQari() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_selectedQariIdKey);
      if (id == null) return;
      for (final q in availableQaris) {
        if (q.id == id) {
          _selectedQari = q;
          notifyListeners();
          break;
        }
      }
    } catch (e) {
      debugPrint('[AudioRecitation] restore qari failed: $e');
    }
  }

  Future<void> _onPlayerState(PlayerState state) async {
    _isPlaying =
        state.playing && state.processingState != ProcessingState.completed;
    if (state.processingState == ProcessingState.completed) {
      if (_ayahMode) {
        await _advanceAyah();
      } else if (repeatMode == -1) {
        // Infinite repeat.
        await _player.setLoopMode(LoopMode.one);
        await _player.seek(Duration.zero);
        await _player.play();
      } else if (repeatMode > 0) {
        _completedPlays++;
        if (_completedPlays < repeatMode) {
          await _player.seek(Duration.zero);
          await _player.play();
        } else {
          await _player.stop();
        }
      }
    }
    notifyListeners();
  }

  /// Advances to the next ayah (wrapping across surahs). When an ayah
  /// repeat range is set, loops back to its start after its end instead.
  /// Stops ayah mode at the end of the Quran (114:6). A single bad audio
  /// file (404/corrupt) is skipped instead of killing the whole recitation.
  Future<void> _advanceAyah() async {
    if (_repeatRangeSurah != null &&
        _currentSurah == _repeatRangeSurah &&
        _currentAyah >= (_repeatRangeEnd ?? 0)) {
      await playAyah(
          surah: _repeatRangeSurah!,
          ayah: _repeatRangeStart ?? 1,
          keepRepeatRange: true);
      return;
    }
    var next = _nextAyah();
    if (next == null) {
      _ayahMode = false;
      await _player.stop();
      notifyListeners();
      return;
    }
    // Skip over unloadable ayahs (max 5 in a row so a dead network doesn't
    // spin forever); stop only when the Quran ends or all retries fail.
    // keepRepeatRange: true — this is internal auto-advance, not a new
    // user request, so an active repeat range must survive.
    var failures = 0;
    while (!(await playAyah(
        surah: next.$1, ayah: next.$2, keepRepeatRange: true))) {
      failures++;
      if (failures >= 5) {
        _ayahMode = false;
        try {
          await _player.stop();
        } catch (_) {}
        notifyListeners();
        return;
      }
      next = nextAyahAfter(next.$1, next.$2);
      if (next == null) {
        _ayahMode = false;
        try {
          await _player.stop();
        } catch (_) {}
        notifyListeners();
        return;
      }
    }
  }

  /// Returns (surah, ayah) of the ayah after the current one, or null at
  /// the end of the Quran.
  (int, int)? _nextAyah() => nextAyahAfter(_currentSurah, _currentAyah);

  /// Skips to the next ayah (stays in ayah mode).
  Future<void> playNextAyah() async {
    final next = _nextAyah();
    if (next == null) {
      await stop();
      return;
    }
    await playAyah(surah: next.$1, ayah: next.$2);
  }

  /// Skips to the previous ayah (stays in ayah mode).
  Future<void> playPrevAyah() async {
    final prev = prevAyahBefore(_currentSurah, _currentAyah);
    if (prev == null) return;
    await playAyah(surah: prev.$1, ayah: prev.$2);
  }

  /// Starts repeating ayahs [startAyah]..[endAyah] of [surah] in a loop,
  /// beginning playback at [startAyah]. Returns false when the range is
  /// invalid (validated by [isValidAyahRange]).
  Future<bool> setAyahRepeatRange({
    required int surah,
    required int startAyah,
    required int endAyah,
  }) async {
    if (!isValidAyahRange(surah, startAyah, endAyah)) return false;
    _repeatRangeSurah = surah;
    _repeatRangeStart = startAyah;
    _repeatRangeEnd = endAyah;
    notifyListeners();
    return playAyah(surah: surah, ayah: startAyah, keepRepeatRange: true);
  }

  /// Clears any active ayah repeat range (playback continues normally).
  void clearAyahRepeatRange() {
    _repeatRangeSurah = null;
    _repeatRangeStart = null;
    _repeatRangeEnd = null;
    notifyListeners();
  }

  void setSelectedQari(Qari qari) {
    _selectedQari = qari;
    notifyListeners();
  }

  /// Async qari selection that persists across restarts.
  Future<void> setQari(Qari qari) async {
    _selectedQari = qari;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedQariIdKey, qari.id);
    } catch (e) {
      debugPrint('[AudioRecitation] persist qari failed: $e');
    }
  }

  void setRepeatMode(int mode) {
    repeatMode = mode;
    notifyListeners();
  }

  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  Future<void> playSurah({required int surahNumber}) async {
    _ayahMode = false;
    // A whole-surah playback is a fresh session: drop any ayah repeat
    // range left over from earlier, or _advanceAyah would later loop back
    // into the stale range when an ayah of that surah is played.
    _repeatRangeSurah = null;
    _repeatRangeStart = null;
    _repeatRangeEnd = null;
    _currentSurah = surahNumber;
    _currentAyah = 1;
    _completedPlays = 0;

    final audioUrl = _selectedQari.urlForSurah(surahNumber);

    try {
      await _player.setLoopMode(repeatMode == -1 ? LoopMode.one : LoopMode.off);
      // Offline first: play the downloaded pack file when present, so a
      // fully downloaded qari works without internet. Falls back to the
      // previous streaming behaviour otherwise.
      final localFile = await QariAudioStorage.surahFile(_selectedQari, surahNumber);
      await _player.setAudioSource(
        localFile != null
            ? AudioSource.uri(Uri.file(localFile.path))
            // M7: cache the audio file on disk while streaming, so a played
            // Surah keeps working offline afterwards.
            : LockCachingAudioSource(Uri.parse(audioUrl)),
      );
      await _player.play();
      notifyListeners();
    } catch (e) {
      debugPrint('[AudioRecitation] Error: $e');
    }
  }

  /// Plays a single ayah MP3 (everyayah.com) and enters ayah-by-ayah mode:
  /// when the ayah finishes, the next ayah starts automatically until the
  /// user stops. The current ayah is highlighted in the ayah player sheet.
  /// Plays a single ayah's audio and auto-advances ayah-by-ayah.
  /// Returns true on success, false when the audio could not be loaded
  /// (e.g. no internet). When [keepRepeatRange] is false (user-initiated
  /// playback), any stale ayah-repeat range is cleared so it can't hijack
  /// later sessions.
  Future<bool> playAyah(
      {required int surah, required int ayah, bool keepRepeatRange = false}) async {
    _ayahMode = true;
    _currentSurah = surah;
    _currentAyah = ayah;
    _completedPlays = 0;
    if (!keepRepeatRange) {
      _repeatRangeSurah = null;
      _repeatRangeStart = null;
      _repeatRangeEnd = null;
    }

    final audioUrl = _selectedQari.ayahUrl(surah, ayah);

    try {
      await _player.setLoopMode(LoopMode.off);
      // Offline first: play the downloaded pack file when present.
      final localFile = await QariAudioStorage.ayahFile(_selectedQari, surah, ayah);
      await _player.setAudioSource(
        localFile != null
            ? AudioSource.uri(Uri.file(localFile.path))
            // Cache the ayah audio on disk while streaming, like surah audio.
            : LockCachingAudioSource(Uri.parse(audioUrl)),
      );
      await _player.play();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[AudioRecitation] playAyah error: $e');
      _ayahMode = false;
      // The failed setAudioSource may have left stale "playing" state —
      // reset so the bottom bar doesn't show playing over silence.
      try {
        await _player.stop();
      } catch (_) {}
      notifyListeners();
      return false;
    }
  }

  Future<void> pause() async {
    await _player.pause();
    notifyListeners();
  }

  Future<void> resume() async {
    await _player.play();
    notifyListeners();
  }

  Future<void> stop() async {
    _ayahMode = false;
    _repeatRangeSurah = null;
    _repeatRangeStart = null;
    _repeatRangeEnd = null;
    await _player.stop();
    notifyListeners();
  }

  @override
  void dispose() {
    _progressClosed = true;
    _ayahProgressController.close();
    _player.dispose();
    super.dispose();
  }
}
