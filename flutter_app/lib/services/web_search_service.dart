import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// A single web search result from an Islamic website.
class WebSearchResult {
  final String title;
  final String url;
  final String snippet;
  final String source; // Domain name, e.g. "sunnah.com"

  const WebSearchResult({
    required this.title,
    required this.url,
    required this.snippet,
    required this.source,
  });

  @override
  String toString() => 'WebSearchResult(source: $source, title: $title)';
}

/// Web search service for the Al-Bahith Al-Islami search engine.
///
/// Searches the open web (via DuckDuckGo HTML, no API key required) and
/// prioritises trusted Islamic websites so users get answers from
/// Quran.com, Sunnah.com, IslamQA, Dawat-e-Islami, etc. inside the app.
///
/// All methods return an empty list on failure and never throw.
class WebSearchService {
  static final WebSearchService _instance = WebSearchService._internal();
  factory WebSearchService() => _instance;
  WebSearchService._internal();

  final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8)
    ..badCertificateCallback = ((_, __, ___) => true);

  /// Trusted Islamic domains, in priority order (lower index = higher trust).
  static const List<String> trustedDomains = [
    // Siratul Jinan ayah-by-ayah Tafsir (Urdu)
    'urdumehfil.net',
    // Dawat-e-Islami / Sunni classical sources
    'dawateislami.net',
    'alahazrat.net',
    // Quran & Hadith canonical sources
    'quran.com',
    'sunnah.com',
    'islamqa.info',
    'islamweb.net',
    'islamqa.org',
    // Fiqh / Fatwa portals
    'darulifta-deoband.com',
    'darulifta.org',
    'askimam.org',
    'muftionline.co.za',
    'jaalhaq.com',
    // Islamic encyclopedia & libraries
    'al-islam.org',
    'kitabosunnat.com',
    'islamicfinder.org',
    'searchtruth.com',
    'hadithcollection.com',
    'aboutislam.net',
  ];

  /// Searches the web for [query] and returns up to [maxResults] results,
  /// with trusted Islamic sites ranked first.
  ///
  /// Uses the DuckDuckGo HTML endpoint (free, no API key). Returns an
  /// empty list on any network/parse failure — never throws.
  Future<List<WebSearchResult>> searchWeb(
    String query, {
    int maxResults = 5,
  }) async {
    final clean = query.trim();
    if (clean.isEmpty || maxResults <= 0) return const [];

    try {
      final uri = Uri.parse(
        'https://html.duckduckgo.com/html/?q=${Uri.encodeComponent(clean)}',
      );
      final req = await _httpClient.getUrl(uri).timeout(
            const Duration(seconds: 8),
          );
      req.headers.set(
        'User-Agent',
        'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36',
      );
      req.headers.set('Accept-Language', 'en-US,en;q=0.9,ur;q=0.8,ar;q=0.7');
      final res = await req.close().timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return const [];

      final body = await res.transform(utf8.decoder).join();
      final results = _parseDuckDuckGoResults(body);
      results.sort(
        (a, b) => _domainPriority(a.source).compareTo(_domainPriority(b.source)),
      );
      return results.take(maxResults).toList();
    } catch (e) {
      debugPrint('[WebSearchService] searchWeb failed: $e');
      return const [];
    }
  }

  /// Searches specifically for Tafsir Siratul Jinan content matching [query]
  /// (ayah reference, topic, or keywords) on urdumehfil.net, which publishes
  /// Siratul Jinan ayah-by-ayah with Kanz-ul-Iman translation.
  Future<List<WebSearchResult>> searchSiratulJinan(
    String query, {
    int maxResults = 5,
  }) async {
    final clean = query.trim();
    if (clean.isEmpty) return const [];
    return searchWeb(
      'site:urdumehfil.net "تفسیر صراط الجنان" $clean',
      maxResults: maxResults,
    );
  }

  /// Priority rank for a domain: trusted domains first (by list order),
  /// everything else last.
  int _domainPriority(String domain) {
    final lower = domain.toLowerCase();
    for (var i = 0; i < trustedDomains.length; i++) {
      final trusted = trustedDomains[i];
      if (lower == trusted || lower.endsWith('.$trusted')) return i;
    }
    return trustedDomains.length + 1;
  }

  /// Parses DuckDuckGo HTML results into [WebSearchResult]s.
  ///
  /// DDG HTML marks result links with `class="result__a"` (href is a
  /// `//duckduckgo.com/l/?uddg=<urlencoded-destination>` redirect) and
  /// snippets with `class="result__snippet"`.
  List<WebSearchResult> _parseDuckDuckGoResults(String html) {
    final results = <WebSearchResult>[];

    final linkMatches = RegExp(
      r'class="result__a"[^>]*href="([^"]+)"[^>]*>([\s\S]*?)</a>',
    ).allMatches(html).toList();
    final snippetMatches = RegExp(
      r'class="result__snippet"[^>]*>([\s\S]*?)</a>',
    ).allMatches(html).toList();

    for (var i = 0; i < linkMatches.length; i++) {
      final rawHref = linkMatches[i].group(1) ?? '';
      final rawTitle = linkMatches[i].group(2) ?? '';
      final rawSnippet =
          i < snippetMatches.length ? snippetMatches[i].group(1) ?? '' : '';

      final url = _resolveDuckDuckGoHref(rawHref);
      if (url.isEmpty) continue;

      final title = _cleanHtml(rawTitle);
      if (title.isEmpty) continue;

      final uri = Uri.tryParse(url);
      final source = uri?.host.replaceFirst(RegExp(r'^www\.'), '') ?? '';
      if (source.isEmpty) continue;

      results.add(
        WebSearchResult(
          title: title,
          url: url,
          snippet: _cleanHtml(rawSnippet),
          source: source,
        ),
      );
    }

    return results;
  }

  /// Resolves a DuckDuckGo redirect href to the real destination URL.
  String _resolveDuckDuckGoHref(String href) {
    var h = href.trim();
    if (h.isEmpty) return '';
    // DDG wraps destinations as //duckduckgo.com/l/?uddg=<encoded>&rut=...
    final uddgMatch = RegExp(r'[?&]uddg=([^&]+)').firstMatch(h);
    if (uddgMatch != null) {
      final encoded = uddgMatch.group(1) ?? '';
      try {
        return Uri.decodeComponent(encoded);
      } catch (_) {
        return encoded;
      }
    }
    if (h.startsWith('//')) h = 'https:$h';
    if (h.contains('duckduckgo.com')) return ''; // internal DDG link
    if (h.startsWith('http://') || h.startsWith('https://')) return h;
    return '';
  }

  /// Strips HTML tags and decodes common HTML entities.
  String _cleanHtml(String raw) {
    var text = raw.replaceAll(RegExp(r'<[^>]*>'), '');
    text = _decodeHtmlEntities(text);
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _decodeHtmlEntities(String s) {
    var out = s
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#x27;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ');
    // Numeric entities: &#123; and &#x7B;
    out = out.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (m) => String.fromCharCode(int.tryParse(m.group(1) ?? '') ?? 0),
    );
    out = out.replaceAllMapped(
      RegExp(r'&#x([0-9a-fA-F]+);'),
      (m) =>
          String.fromCharCode(int.tryParse(m.group(1) ?? '', radix: 16) ?? 0),
    );
    return out;
  }
}

// ---------------------------------------------------------------------------
// Tafsir Siratul Jinan (صراط الجنان فی تفسیر القرآن)
// ---------------------------------------------------------------------------
//
// Author: Mufti Muhammad Qasim Attari (Qadri), published by
// Maktaba-tul-Madina, Karachi (10 volumes, 2013–2017).
//
// There is NO public API that serves Siratul Jinan by ayah. The best online
// access points are:
//  1. urdumehfil.net — publishes Siratul Jinan ayah-by-ayah together with
//     the Arabic text and Kanz-ul-Iman translation. Page URLs carry a
//     publish date (e.g. /2026/10/07/surah-al-araf-ayat-no-056/), so a
//     per-ayah URL cannot be constructed deterministically; a
//     site-restricted search is the reliable way to reach the right page.
//  2. dawateislami.net book library — hosts the full volumes as PDF
//     (e.g. "Sirat ul Jinan-Jild-1", Para 1–3).
//  3. Dawat-e-Islami's "Sirat ul Jinan Quran & Tafsir" app
//     (com.dawateislami.AlQuran.Translation) — full Tafsir, app-only.
//
// The helpers below therefore return search URLs that land the user on the
// correct Siratul Jinan page for a given ayah / query.

/// Dawat-e-Islami book library page for Siratul Jinan, Volume 1
/// (Para 1–3). Further volumes are listed under the "Sirat ul Jinan"
/// category in the same library.
const String siratulJinanBookLibraryUrl =
    'https://www.dawateislami.net/bookslibrary/hi/sirat-ul-jinan-jild-1';

/// Returns a URL that opens the Siratul Jinan Tafsir page for the given
/// [surah] (1–114) and [ayah], via a site-restricted search on
/// urdumehfil.net (the site that publishes Siratul Jinan ayah-by-ayah).
String siratulJinanUrl(int surah, int ayah) {
  final slug = _surahSlug(surah);
  final ayahStr = ayah.toString().padLeft(3, '0');
  final q = 'site:urdumehfil.net "تفسیر صراط الجنان" $slug "ayat no $ayahStr"';
  return 'https://html.duckduckgo.com/html/?q=${Uri.encodeComponent(q)}';
}

/// Returns a URL that searches Siratul Jinan content for a free-text
/// [query] (topic, keyword, or ayah reference) on urdumehfil.net.
String siratulJinanSearchUrl(String query) {
  final clean = query.trim();
  final q = 'site:urdumehfil.net "تفسیر صراط الجنان" $clean';
  return 'https://html.duckduckgo.com/html/?q=${Uri.encodeComponent(q)}';
}

/// URL slug for a surah, e.g. 7 -> "surah-al-araf", matching the
/// urdumehfil.net page-title pattern "Surah Al-A'raf Ayat No 056".
String _surahSlug(int surah) {
  if (surah < 1 || surah > 114) return 'surah';
  final name = _surahNames[surah - 1];
  final slug = name
      .toLowerCase()
      .replaceAll("'", '')
      .replaceAll(' ', '-');
  return 'surah-$slug';
}

/// Transliterated Surah names used for Siratul Jinan page slugs.
const List<String> _surahNames = [
  "Al-Fatiha", "Al-Baqarah", "Aal-e-Imran", "An-Nisa", "Al-Maidah",
  "Al-Anam", "Al-Araf", "Al-Anfal", "At-Tawbah", "Yunus",
  "Hud", "Yusuf", "Ar-Rad", "Ibrahim", "Al-Hijr",
  "An-Nahl", "Al-Isra", "Al-Kahf", "Maryam", "Taha",
  "Al-Anbiya", "Al-Hajj", "Al-Muminun", "An-Nur", "Al-Furqan",
  "Ash-Shuara", "An-Naml", "Al-Qasas", "Al-Ankabut", "Ar-Rum",
  "Luqman", "As-Sajdah", "Al-Ahzab", "Saba", "Fatir",
  "Ya-Sin", "As-Saffat", "Sad", "Az-Zumar", "Ghafir",
  "Fussilat", "Ash-Shura", "Az-Zukhruf", "Ad-Dukhan", "Al-Jathiyah",
  "Al-Ahqaf", "Muhammad", "Al-Fath", "Al-Hujurat", "Qaf",
  "Adh-Dhariyat", "At-Tur", "An-Najm", "Al-Qamar", "Ar-Rahman",
  "Al-Waqiah", "Al-Hadid", "Al-Mujadila", "Al-Hashr", "Al-Mumtahanah",
  "As-Saff", "Al-Jumuah", "Al-Munafiqun", "At-Taghabun", "At-Talaq",
  "At-Tahrim", "Al-Mulk", "Al-Qalam", "Al-Haqqah", "Al-Maarij",
  "Nuh", "Al-Jinn", "Al-Muzzammil", "Al-Muddaththir", "Al-Qiyamah",
  "Al-Insan", "Al-Mursalat", "An-Naba", "An-Naziat", "Abasa",
  "At-Takwir", "Al-Infitar", "Al-Mutaffifin", "Al-Inshiqaq", "Al-Buruj",
  "At-Tariq", "Al-Ala", "Al-Ghashiyah", "Al-Fajr", "Al-Balad",
  "Ash-Shams", "Al-Layl", "Ad-Duha", "Ash-Sharh", "At-Tin",
  "Al-Alaq", "Al-Qadr", "Al-Bayyinah", "Az-Zalzalah", "Al-Adiyat",
  "Al-Qariah", "At-Takathur", "Al-Asr", "Al-Humazah", "Al-Fil",
  "Quraysh", "Al-Maun", "Al-Kawthar", "Al-Kafirun", "An-Nasr",
  "Al-Masad", "Al-Ikhlas", "Al-Falaq", "An-Nas",
];
