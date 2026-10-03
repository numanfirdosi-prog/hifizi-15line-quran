import 'package:flutter_test/flutter_test.dart';
import 'package:nur_al_quran/services/page_image_service.dart';

void main() {
  group('PageImageService.pageImageUrls', () {
    test('returns 3 fallback URLs for a page', () {
      final urls = PageImageService.pageImageUrls(1);
      expect(urls.length, 3);
    });

    test('first URL is raw.githubusercontent.com', () {
      final urls = PageImageService.pageImageUrls(1);
      expect(urls[0],
          'https://raw.githubusercontent.com/numanfirdosi-prog/hifizi-15line-quran/main/assets/pages/1.webp');
    });

    test('second URL is the jsDelivr CDN fallback', () {
      final urls = PageImageService.pageImageUrls(1);
      expect(urls[1],
          'https://cdn.jsdelivr.net/gh/numanfirdosi-prog/hifizi-15line-quran@main/assets/pages/1.webp');
    });

    test('third URL is the github.com raw fallback', () {
      final urls = PageImageService.pageImageUrls(1);
      expect(urls[2],
          'https://github.com/numanfirdosi-prog/hifizi-15line-quran/raw/main/assets/pages/1.webp');
    });

    test('page number is interpolated in every URL', () {
      final urls = PageImageService.pageImageUrls(604);
      for (final u in urls) {
        expect(u.contains('604.webp'), isTrue);
      }
      // No two fallbacks share the same host (true redundancy).
      final hosts = urls.map((u) => Uri.parse(u).host).toSet();
      expect(hosts.length, 3);
    });

    test('all URLs use https', () {
      for (final u in PageImageService.pageImageUrls(10)) {
        expect(Uri.parse(u).scheme, 'https');
      }
    });
  });
}
