import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import 'news_service.dart';

class NewsPage extends ConsumerWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final R = CircleHub.radius;

    return Container(
      color: CircleHub.background,
      child: ref.watch(newsProvider).when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: CircleHub.accentBlue, strokeWidth: 2),
        ),
        error: (_, __) => Center(
          child: Text('News unavailable',
              style: TextStyle(color: CircleHub.textSecondary, fontSize: R * 0.04)),
        ),
        data: (items) => _NewsList(items: items),
      ),
    );
  }
}

class _NewsList extends StatelessWidget {
  final List<NewsItem> items;
  const _NewsList({required this.items});

  @override
  Widget build(BuildContext context) {
    final R = CircleHub.radius;
    // Horizontal padding shrinks list into the circular safe zone
    final hPad = R * 0.24;

    return Column(
      children: [
        SizedBox(height: R * 0.18),

        // Page title
        Text(
          'HEADLINES',
          style: TextStyle(
            color: CircleHub.accentBlue,
            fontSize: R * 0.042,
            letterSpacing: 6,
            fontWeight: FontWeight.w300,
          ),
        ),
        SizedBox(height: R * 0.05),

        // Scrollable list
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 0),
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(
              color: CircleHub.textDim.withAlpha(60),
              height: 1,
            ),
            itemBuilder: (_, i) {
              final item = items[i];
              return Padding(
                padding: EdgeInsets.symmetric(vertical: R * 0.025),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.source.toUpperCase(),
                      style: TextStyle(
                        color: CircleHub.accentBlue.withAlpha(180),
                        fontSize: R * 0.028,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: CircleHub.textPrimary,
                        fontSize: R * 0.038,
                        fontWeight: FontWeight.w300,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        SizedBox(height: R * 0.18),
      ],
    );
  }
}
