import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/quran_data.dart';
import 'audio_recitation_service.dart';
import 'qari_audio_storage.dart';

/// Download state of one qari's full audio pack.
enum QariPackState { idle, downloading, paused, complete, error }

/// Immutable per-qari progress snapshot.
class QariPackProgress {
  final QariPackState state;

  /// Files finished (downloaded + skipped-as-existing).
  final int done;

  /// Always [QariAudioStorage.totalPackFiles] (6350).
  final int total;
  final int errorCount;
  final String? errorMessage;

  const QariPackProgress({
    this.state = QariPackState.idle,
    this.done = 0,
    this.total = QariAudioStorage.totalPackFiles,
    this.errorCount = 0,
    this.errorMessage,
  });

  /// 0..1 fraction of the pack finished.
  double get fraction =>
      total <= 0 ? 0.0 : (done / total).clamp(0.0, 1.0);

  QariPackProgress copyWith({
    QariPackState? state,
    int? done,
    int? total,
    int? errorCount,
    String? errorMessage,
  }) {
    return QariPackProgress(
      state: state ?? this.state,
      done: done ?? this.done,
      total: total ?? this.total,
      errorCount: errorCount ?? this.errorCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class _DownloadJob {
  final String url;
  final String path;
  const _DownloadJob(this.url, this.path);
}

/// Downloads full qari audio packs (114 surah MP3s + 6236 ayah MP3s) for
/// offline playback, one qari at a time. A single failed file is recorded
/// and skipped — it never aborts the whole pack. Nothing is persisted to
/// SharedPreferences; completeness is derived by scanning the pack
/// directory (see [refreshCompleteCache]).
class QariDownloadService extends ChangeNotifier {
  final Map<String, QariPackProgress> _progress = {};
  final Map<String, Qari> _qaris = {};

  /// qariIds known to hold a complete pack on disk (lazy disk-scan cache).
  final Set<String> _completeCache = {};

  String? _activeId;
  final Set<String> _starting = {};
  HttpClient? _httpClient;
  bool _cancelRequested = false;

  /// Max time to establish a TCP connection for one file. Without this a
  /// stalled network froze the queue at "Downloading…" forever.
  static const _connectTimeout = Duration(seconds: 25);

  /// Max quiet time while waiting for a server's response headers. A
  /// server that connects but never answers raises [TimeoutException],
  /// handled below like any other failed file.
  static const _headerTimeout = Duration(seconds: 60);

  /// Max time for one file's body to finish streaming (generous, so very
  /// slow networks can still complete a large surah MP3); a mid-download
  /// stall raises [TimeoutException] instead of hanging the queue.
  static const _bodyTimeout = Duration(minutes: 10);

  /// Monotonic run id: every [startDownload] call takes the next value, so
  /// a newer call supersedes any older run still stuck in [_buildQueue] or
  /// [_runQueue]. Without this, starting qari B while qari A was still
  /// building its queue (or mid-file) could leave two queue loops running
  /// at once, racing over [_cancelRequested], [_activeId] and [_httpClient].
  int _runSeq = 0;

  /// Current progress snapshot for [qariId] (idle when never touched).
  QariPackProgress progressOf(String qariId) =>
      _progress[qariId] ?? const QariPackProgress();

  /// Synchronous "known complete" check: live state or the lazy disk-scan
  /// cache. Call [refreshCompleteCache] to (re)scan from disk.
  bool isKnownComplete(String qariId) {
    final p = _progress[qariId];
    if (p != null && p.state == QariPackState.complete) return true;
    return _completeCache.contains(qariId);
  }

  /// (Re)scans every qari's pack directory and updates the complete cache.
  /// Call lazily when a download UI builds. Never throws.
  Future<void> refreshCompleteCache() async {
    try {
      for (final q in availableQaris) {
        if (await QariAudioStorage.isPackComplete(q.id)) {
          _completeCache.add(q.id);
        } else {
          _completeCache.remove(q.id);
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  /// Downloaded file counts for [qariId]: (surahs, ayahs). Never throws.
  Future<(int, int)> countsOf(String qariId) =>
      QariAudioStorage.downloadedCounts(qariId);

  /// Downloaded bytes for [qariId]. Never throws.
  Future<int> bytesOf(String qariId) => QariAudioStorage.totalBytes(qariId);

  void _set(String qariId, QariPackProgress p) {
    _progress[qariId] = p;
    notifyListeners();
  }

  /// Starts (or resumes) downloading [qari]'s full pack. Files already on
  /// disk are skipped, so resume never re-downloads. Only one qari
  /// downloads at a time — another active download is auto-paused.
  /// Never throws.
  Future<void> startDownload(Qari qari) async {
    if (_activeId == qari.id || _starting.contains(qari.id)) return;
    _starting.add(qari.id);
    // This run supersedes any older one still in flight (see [_runSeq]).
    final mySeq = ++_runSeq;
    bool isSuperseded() => mySeq != _runSeq;
    try {
      if (_activeId != null && _activeId != qari.id) {
        await pauseDownload(_activeId!);
      }
      if (isSuperseded()) return;
      _qaris[qari.id] = qari;

      final jobs = await _buildQueue(qari);
      if (isSuperseded()) return;
      final alreadyDone = QariAudioStorage.totalPackFiles - jobs.length;
      if (jobs.isEmpty) {
        // Everything is already on disk.
        _completeCache.add(qari.id);
        _set(
            qari.id,
            const QariPackProgress(
              state: QariPackState.complete,
              done: QariAudioStorage.totalPackFiles,
            ));
        return;
      }

      _cancelRequested = false;
      _activeId = qari.id;
      _set(qari.id,
          QariPackProgress(state: QariPackState.downloading, done: alreadyDone));
      await _runQueue(qari.id, jobs, mySeq);

      final current = progressOf(qari.id);
      if (_cancelRequested) {
        _set(qari.id, current.copyWith(state: QariPackState.paused));
      } else {
        final complete = await QariAudioStorage.isPackComplete(qari.id);
        if (complete) {
          _completeCache.add(qari.id);
          _set(
              qari.id,
              current.copyWith(
                state: QariPackState.complete,
                done: QariAudioStorage.totalPackFiles,
              ));
        } else if (current.errorCount > 0) {
          _set(
              qari.id,
              current.copyWith(
                state: QariPackState.error,
                errorMessage:
                    '${current.errorCount} file(s) failed — Resume to retry.',
              ));
        } else {
          _set(qari.id, current.copyWith(state: QariPackState.paused));
        }
      }
    } catch (e) {
      final current = progressOf(qari.id);
      _set(qari.id,
          current.copyWith(state: QariPackState.error, errorMessage: '$e'));
    } finally {
      _starting.remove(qari.id);
      // Only a non-superseded run may clear the shared handles; a newer
      // run has already taken them over.
      if (!isSuperseded()) {
        if (_activeId == qari.id) _activeId = null;
        _httpClient = null;
      }
    }
  }

  /// Pauses the active download for [qariId], keeping downloaded files.
  /// Never throws.
  Future<void> pauseDownload(String qariId) async {
    try {
      if (_activeId == qariId) {
        _cancelRequested = true;
        // Abort the in-flight request so the queue loop notices promptly.
        _httpClient?.close(force: true);
        _httpClient = null;
      } else {
        final p = progressOf(qariId);
        if (p.state == QariPackState.downloading) {
          _set(qariId, p.copyWith(state: QariPackState.paused));
        }
      }
    } catch (_) {}
  }

  /// Cancels the active download for [qariId] (keeps downloaded files,
  /// same as pause). Never throws.
  Future<void> cancelDownload(String qariId) => pauseDownload(qariId);

  /// Deletes [qariId]'s pack from disk and resets its state. Ignored while
  /// that qari is downloading. Never throws.
  Future<void> deleteDownload(String qariId) async {
    try {
      if (_activeId == qariId) return;
      await QariAudioStorage.deleteQari(qariId);
      _completeCache.remove(qariId);
      _progress.remove(qariId);
      _qaris.remove(qariId);
      notifyListeners();
    } catch (_) {}
  }

  /// Builds the (url, targetPath) queue, skipping files already on disk.
  /// A zero-byte file is a leftover of a force-killed download and is
  /// queued for re-download, not skipped.
  Future<List<_DownloadJob>> _buildQueue(Qari qari) async {
    final dir = await QariAudioStorage.qariDir(qari.id);
    final jobs = <_DownloadJob>[];
    for (var s = 1; s <= 114; s++) {
      final path = '${dir.path}/${QariAudioStorage.surahFileName(s)}';
      if (await _needsDownload(path)) {
        jobs.add(_DownloadJob(qari.urlForSurah(s), path));
      }
    }
    for (var s = 1; s <= 114; s++) {
      final totalAyahs = allSurahs[s - 1].totalAyahs;
      for (var v = 1; v <= totalAyahs; v++) {
        final path = '${dir.path}/${QariAudioStorage.ayahFileName(s, v)}';
        if (await _needsDownload(path)) {
          jobs.add(_DownloadJob(qari.ayahUrl(s, v), path));
        }
      }
    }
    return jobs;
  }

  /// True when [path] is missing or holds only a zero-byte leftover of a
  /// killed download — both must be (re)downloaded.
  static Future<bool> _needsDownload(String path) async {
    final file = File(path);
    return !await file.exists() || await file.length() == 0;
  }

  /// Downloads [jobs] sequentially, streaming each response straight to
  /// disk. A failed or cancelled file's partial output is deleted so a
  /// later resume re-downloads it cleanly. Failed files are counted and
  /// skipped — they never abort the pack. Stalled connections raise
  /// [TimeoutException] via the timeouts below and are handled like any
  /// other failed file. Stops promptly when [_cancelRequested] is set or
  /// when [runSeq] no longer matches [_runSeq] (a newer [startDownload]
  /// superseded this run).
  Future<void> _runQueue(String qariId, List<_DownloadJob> jobs, int runSeq) async {
    final client = HttpClient()..connectionTimeout = _connectTimeout;
    _httpClient = client;
    try {
      for (final job in jobs) {
        if (_cancelRequested || runSeq != _runSeq) break;
        final file = File(job.path);
        try {
          // Bounded: connectionTimeout guards the TCP connect above; these
          // guard a stalled server (headers never arrive) and a stalled
          // body stream (bytes stop mid-file).
          final request =
              await client.getUrl(Uri.parse(job.url)).timeout(_headerTimeout);
          final response = await request.close().timeout(_headerTimeout);
          if (response.statusCode != 200) {
            throw HttpException('HTTP ${response.statusCode} for ${job.url}');
          }
          await response.pipe(file.openWrite()).timeout(_bodyTimeout);
          final p = progressOf(qariId);
          _set(qariId, p.copyWith(done: p.done + 1));
        } catch (e) {
          // Always drop partial output so resume starts this file fresh.
          try {
            if (await file.exists()) await file.delete();
          } catch (_) {}
          if (_cancelRequested || runSeq != _runSeq) break;
          final p = progressOf(qariId);
          _set(qariId, p.copyWith(errorCount: p.errorCount + 1));
          debugPrint('[QariDownload] failed ${job.url}: $e');
        }
      }
    } finally {
      client.close(force: true);
      if (identical(_httpClient, client)) _httpClient = null;
    }
  }
}
