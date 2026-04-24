import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

final newsServiceProvider = Provider((ref) => NewsService());

class NewsItem {
  final String title;
  final String source;
  final String pubDate;
  final String link;

  const NewsItem({
    required this.title,
    required this.source,
    required this.pubDate,
    required this.link,
  });
}

/// Parses public RSS feeds — no API key required.
class NewsService {
  static const _feeds = [
    ('BBC Top Stories',  'http://feeds.bbci.co.uk/news/rss.xml'),
    ('Reuters',          'https://feeds.reuters.com/reuters/topNews'),
    ('HackerNews',       'https://hnrss.org/frontpage?count=10'),
  ];

  Future<List<NewsItem>> fetchHeadlines() async {
    final items = <NewsItem>[];

    for (final (source, url) in _feeds) {
      try {
        final res = await http.get(Uri.parse(url))
            .timeout(const Duration(seconds: 8));
        if (res.statusCode != 200) continue;

        final doc = XmlDocument.parse(res.body);
        for (final item in doc.findAllElements('item').take(5)) {
          final title = item.getElement('title')?.innerText.trim() ?? '';
          final link  = item.getElement('link')?.innerText.trim() ?? '';
          final date  = item.getElement('pubDate')?.innerText.trim() ?? '';
          if (title.isNotEmpty) {
            items.add(NewsItem(title: title, source: source, pubDate: date, link: link));
          }
        }
      } catch (_) {
        // One feed failure doesn't break the others
      }
    }

    return items;
  }
}

final newsProvider = FutureProvider.autoDispose<List<NewsItem>>((ref) async {
  final link = ref.keepAlive();
  Future.delayed(const Duration(minutes: 15), link.close);
  return ref.read(newsServiceProvider).fetchHeadlines();
});
