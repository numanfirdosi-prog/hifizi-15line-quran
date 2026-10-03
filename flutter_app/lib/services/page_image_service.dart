import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Resilient loader for the 15-line mushaf page images.
///
/// Some networks block or stall `raw.githubusercontent.com` (the connection
/// hangs: no error, no progress, infinite loading). This service tries
/// multiple CDNs in order, with a per-URL timeout, so a hanging host is
/// skipped instead of freezing the reader. Successful downloads are cached
/// on disk so pages keep working offline afterwards.
class PageImageService {
  static const _repo = 'numanfirdosi-prog/hifizi-15line-quran';
  static const _timeout = Duration(seconds: 15);

  /// Page image URLs in fallback order (1-based [page]).
  static List<String> pageImageUrls(int page) => [
        'https://raw.githubusercontent.com/$_repo/main/assets/pages/$page.webp',
        'https://cdn.jsdelivr.net/gh/$_repo@main/assets/pages/$page.webp',
        'https://github.com/$_repo/raw/main/assets/pages/$page.webp',
      ];

  static Future<Directory> _cacheDir() async {
    final tmp = await getTemporaryDirectory();
    final dir = Directory('${tmp.path}/mushaf_pages');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Local cache file for [page], if it was downloaded before.
  static Future<File?> cachedFile(int page) async {
    final f = File('${(await _cacheDir()).path}/$page.webp');
    return await f.exists() ? f : null;
  }

  /// Loads the page image bytes: disk cache first, then each CDN URL with
  /// a timeout until one succeeds. [onProgress] reports (received, total).
  /// Throws the last error if every source fails.
  static Future<Uint8List> fetchPageImage(
    int page, {
    void Function(int received, int? total)? onProgress,
  }) async {
    final hit = await cachedFile(page);
    if (hit != null) {
      final bytes = await hit.readAsBytes();
      onProgress?.call(bytes.length, bytes.length);
      return bytes;
    }

    Object? lastError;
    for (final url in pageImageUrls(page)) {
      try {
        final bytes = await _download(url, onProgress: onProgress)
            .timeout(_timeout);
        // Basic sanity: a valid WebP starts with "RIFF".
        if (bytes.length > 12 &&
            bytes[0] == 0x52 &&
            bytes[1] == 0x49 &&
            bytes[2] == 0x46 &&
            bytes[3] == 0x46) {
          unawaited(_cacheDir().then(
              (d) => File('${d.path}/$page.webp').writeAsBytes(bytes)));
          return bytes;
        }
        lastError = const FormatException('Invalid image data');
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? const HttpException('Page download failed');
  }

  static Future<Uint8List> _download(
    String url, {
    void Function(int received, int? total)? onProgress,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = _timeout;
    try {
      final req = await client.getUrl(Uri.parse(url));
      final res = await req.close();
      if (res.statusCode != 200) {
        throw HttpException('HTTP ${res.statusCode} for $url');
      }
      final total = res.contentLength > 0 ? res.contentLength : null;
      final chunks = <int>[];
      var received = 0;
      await for (final chunk in res) {
        chunks.addAll(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      return Uint8List.fromList(chunks);
    } finally {
      client.close(force: true);
    }
  }
}
