import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Qari {
  final String id;
  final String name;
  final String arabic;
  final String style;
  final String country;
  final String baseUrl;

  const Qari({
    required this.id,
    required this.name,
    required this.arabic,
    required this.style,
    required this.country,
    required this.baseUrl,
  });

  /// Full mp3 URL for surah [n] on this qari's mp3quran server.
  String urlForSurah(int n) => '$baseUrl${n.toString().padLeft(3, '0')}.mp3';
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
  ),
  Qari(
    id: 'ar.abdulbasitmurattal',
    name: 'Abdul Basit Abdus Samad',
    arabic: 'عبد الباسط عبد الصمد',
    style: 'Murattal',
    country: 'Egypt',
    baseUrl: 'https://server7.mp3quran.net/basit/',
  ),
  Qari(
    id: 'ar.husary',
    name: 'Mahmoud Khalil Al-Husary',
    arabic: 'محمود خليل الحصري',
    style: 'Murattal',
    country: 'Egypt',
    baseUrl: 'https://server13.mp3quran.net/husr/',
  ),
  Qari(
    id: 'ar.minshawi',
    name: 'Mohamed Siddiq El-Minshawi',
    arabic: 'محمد صديق المنشاوي',
    style: 'Murattal',
    country: 'Egypt',
    baseUrl: 'https://server10.mp3quran.net/minsh/',
  ),
  Qari(
    id: 'ar.abdurrahmaansudais',
    name: 'Abdur-Rahman As-Sudais',
    arabic: 'عبد الرحمن السديس',
    style: 'Murattal',
    country: 'Makkah/Saudi Arabia',
    baseUrl: 'https://server11.mp3quran.net/sds/',
  ),
  // --- expanded studio list (API-extracted servers) ---
  Qari(
    id: 'ar.abdulbasitmujawwad',
    name: 'Abdul Basit Abdus Samad',
    arabic: 'عبد الباسط عبد الصمد',
    style: 'Mujawwad',
    country: 'Egypt',
    baseUrl: 'https://server7.mp3quran.net/basit/Almusshaf-Al-Mojawwad/',
  ),
  Qari(
    id: 'ar.husarymujawwad',
    name: 'Mahmoud Khalil Al-Husary',
    arabic: 'محمود خليل الحصري',
    style: 'Mujawwad',
    country: 'Egypt',
    baseUrl: 'https://server13.mp3quran.net/husr/Almusshaf-Al-Mojawwad/',
  ),
  Qari(
    id: 'ar.minshawimujawwad',
    name: 'Mohamed Siddiq El-Minshawi',
    arabic: 'محمد صديق المنشاوي',
    style: 'Mujawwad',
    country: 'Egypt',
    baseUrl: 'https://server10.mp3quran.net/minsh/Almusshaf-Al-Mojawwad/',
  ),
  Qari(
    id: 'ar.mahermuaiqly',
    name: 'Maher Al-Muaiqly',
    arabic: 'ماهر المعيقلي',
    style: 'Murattal',
    country: 'Makkah/Saudi Arabia',
    baseUrl: 'https://server12.mp3quran.net/maher/',
  ),
  Qari(
    id: 'ar.saoodshuraym',
    name: 'Saood Ash-Shuraym',
    arabic: 'سعود الشريم',
    style: 'Murattal',
    country: 'Makkah/Saudi Arabia',
    baseUrl: 'https://server7.mp3quran.net/shur/',
  ),
  Qari(
    id: 'ar.abubakrshatree',
    name: 'Abu Bakr Ash-Shatree',
    arabic: 'أبو بكر الشاطري',
    style: 'Murattal',
    country: 'Saudi Arabia',
    baseUrl: 'https://server11.mp3quran.net/shatri/',
  ),
  Qari(
    id: 'ar.alihudhaify',
    name: 'Ali Abdur-Rahman Al-Hudhaify',
    arabic: 'علي عبد الرحمن الحذيفي',
    style: 'Murattal',
    country: 'Madinah/Saudi Arabia',
    baseUrl: 'https://server9.mp3quran.net/hthfi/',
  ),
];

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

  AudioPlayer get player => _player;
  Qari get selectedQari => _selectedQari;
  bool get isPlaying => _isPlaying;
  int get currentSurah => _currentSurah;
  int get currentAyah => _currentAyah;

  AudioRecitationService() {
    _restoreSelectedQari();
    _player.playerStateStream.listen(_onPlayerState);
  }

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
      if (repeatMode == -1) {
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
    _currentSurah = surahNumber;
    _currentAyah = 1;
    _completedPlays = 0;

    final audioUrl = _selectedQari.urlForSurah(surahNumber);

    try {
      await _player.setLoopMode(repeatMode == -1 ? LoopMode.one : LoopMode.off);
      // M7: cache the audio file on disk while streaming, so a played Surah
      // keeps working offline afterwards.
      await _player.setAudioSource(
        LockCachingAudioSource(Uri.parse(audioUrl)),
      );
      await _player.play();
      notifyListeners();
    } catch (e) {
      debugPrint('[AudioRecitation] Error: $e');
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
    await _player.stop();
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
