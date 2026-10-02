import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../data/quran_data.dart';

/// Deep-link format: `quranapp://page/<n>` (n = 1..611).
/// Pure parser — unit tested.
int? parseDeepLinkPage(Uri uri) {
  if (uri.scheme != 'quranapp') return null;
  if (uri.host != 'page') return null;
  if (uri.pathSegments.isEmpty) return null;
  final page = int.tryParse(uri.pathSegments.first);
  if (page == null || page < 1 || page > totalPagesInMushaf) return null;
  return page;
}

/// Listens for incoming `quranapp://` links (cold start + warm) and
/// publishes valid page targets. HomeNavigationScreen observes
/// [pendingPage] and jumps the reader there.
class DeepLinkService {
  /// Set to a page number when a valid deep link arrives.
  static final ValueNotifier<int?> pendingPage = ValueNotifier<int?>(null);

  /// Called when a quranapp:// link arrived but failed validation.
  static void Function()? onInvalidLink;

  static bool _started = false;

  static Future<void> init() async {
    if (_started) return;
    _started = true;
    final appLinks = AppLinks();
    try {
      final initial = await appLinks.getInitialLink();
      if (initial != null) _handle(initial);
    } catch (_) {
      // Link handling unavailable — deep links simply won't work.
    }
    try {
      appLinks.uriLinkStream.listen(_handle, onError: (_) {});
    } catch (_) {}
  }

  static void _handle(Uri uri) {
    final page = parseDeepLinkPage(uri);
    if (page != null) {
      pendingPage.value = page;
    } else if (uri.scheme == 'quranapp') {
      onInvalidLink?.call();
    }
  }
}
