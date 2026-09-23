import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class Qari {
  final String id;
  final String name;
  final String arabic;
  final String style;

  const Qari({
    required this.id,
    required this.name,
    required this.arabic,
    required this.style,
  });
}

const List<Qari> availableQaris = [
  Qari(id: 'ar.alafasy', name: 'Mishary Rashid Alafasy', arabic: 'مشاري راشد العفاسي', style: 'Murattal'),
  Qari(id: 'ar.abdulbasitmurattal', name: 'Abdul Basit Abdus Samad', arabic: 'عبد الباسط عبد الصمد', style: 'Murattal'),
  Qari(id: 'ar.husary', name: 'Mahmoud Khalil Al-Husary', arabic: 'محمود خليل الحصري', style: 'Murattal'),
  Qari(id: 'ar.minshawi', name: 'Mohamed Siddiq El-Minshawi', arabic: 'محمد صديق المنشاوي', style: 'Murattal'),
  Qari(id: 'ar.abdurrahmaansudais', name: 'Abdur-Rahman As-Sudais', arabic: 'عبد الرحمن السديس', style: 'Murattal'),
];

class AudioRecitationService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  Qari _selectedQari = availableQaris[0];
  bool _isPlaying = false;
  int _currentSurah = 1;
  int _currentAyah = 1;

  AudioPlayer get player => _player;
  Qari get selectedQari => _selectedQari;
  bool get isPlaying => _isPlaying;
  int get currentSurah => _currentSurah;
  int get currentAyah => _currentAyah;

  AudioRecitationService() {
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing && state.processingState != ProcessingState.completed;
      notifyListeners();
    });
  }

  void setSelectedQari(Qari qari) {
    _selectedQari = qari;
    notifyListeners();
  }

  Future<void> playSurah({required int surahNumber}) async {
    _currentSurah = surahNumber;
    _currentAyah = 1;

    // Format surah URL for CDN recitation (EveryAyah / Quran CDN)
    final sPad = surahNumber.toString().padLeft(3, '0');
    final audioUrl = 'https://server8.mp3quran.net/afs/$sPad.mp3';

    try {
      await _player.setUrl(audioUrl);
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

