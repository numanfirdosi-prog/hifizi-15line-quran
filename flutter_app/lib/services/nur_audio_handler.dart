import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../data/quran_data.dart';
import 'audio_recitation_service.dart';

/// Bridges audio_service (background playback, lock-screen controls, media
/// notification) with the existing [AudioRecitationService], which keeps
/// owning the just_audio player and all playback logic. This handler only
/// mirrors state into [mediaItem]/[playbackState] and forwards transport
/// controls to the service. If audio_service fails to start, in-app audio
/// keeps working untouched.
class NurAudioHandler extends BaseAudioHandler {
  final AudioRecitationService _service;

  NurAudioHandler(this._service) {
    _service.addListener(_sync);
    _sync();
  }

  void _sync() {
    final s = _service;
    final isAyah = s.ayahMode;
    final surahName = allSurahs[(s.currentSurah - 1).clamp(0, 113)].nameEn;
    mediaItem.add(MediaItem(
      id: isAyah
          ? 'ayah:${s.currentSurah}:${s.currentAyah}'
          : 'surah:${s.currentSurah}',
      album: 'Nur Al-Quran',
      title: isAyah
          ? '$surahName ${s.currentSurah}:${s.currentAyah}'
          : 'Surah $surahName',
      artist: s.selectedQari.name,
    ));

    final playerState = s.player.playerState;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (s.isPlaying) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[playerState.processingState]!,
        playing: s.isPlaying,
        updatePosition: s.player.position,
        bufferedPosition: s.player.bufferedPosition,
        speed: s.player.speed,
      ),
    );
  }

  @override
  Future<void> play() => _service.resume();

  @override
  Future<void> pause() => _service.pause();

  @override
  Future<void> stop() async {
    await _service.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) =>
      _service.player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_service.ayahMode) {
      await _service.playNextAyah();
    } else {
      final next = (_service.currentSurah + 1).clamp(1, 114);
      await _service.playSurah(surahNumber: next);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_service.ayahMode) {
      await _service.playPrevAyah();
    } else {
      final prev = (_service.currentSurah - 1).clamp(1, 114);
      await _service.playSurah(surahNumber: prev);
    }
  }
}

/// Starts the audio_service background bridge. Guarded: any failure leaves
/// normal in-app audio fully working.
Future<void> initBackgroundAudio(AudioRecitationService service) async {
  try {
    await AudioService.init(
      builder: () => NurAudioHandler(service),
      config: const AudioServiceConfig(
        androidNotificationChannelId:
            'com.nuralquran.nur_al_quran.audio',
        androidNotificationChannelName: 'Quran Recitation',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  } catch (e) {
    // Background audio unavailable on this device — in-app audio unaffected.
    debugPrint('[Audio] background service unavailable: $e');
  }
}
