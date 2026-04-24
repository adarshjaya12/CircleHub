import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/circular_scaffold.dart';
import '../widgets/page_indicator.dart';
import '../features/clock/clock_page.dart';
import '../features/weather/weather_page.dart';
import '../features/news/news_page.dart';
import '../features/gallery/gallery_page.dart';
import '../features/alarm/alarm_page.dart';
import '../features/calendar/calendar_page.dart';
import '../core/constants.dart';

/// Root page — wraps the [PageView] in a [CircularScaffold] and shows
/// the page-indicator dots overlaid inside the circle's safe zone.
class HubPage extends StatefulWidget {
  const HubPage({super.key});

  @override
  State<HubPage> createState() => _HubPageState();
}

class _HubPageState extends State<HubPage> {
  final _controller = PageController();
  int _current = 0;

  static const _pages = <Widget>[
    WeatherPage(),
    ClockPage(),
    CalendarPage(),
    NewsPage(),
    GalleryPage(),
    AlarmPage(),
  ];

  @override
  void initState() {
    super.initState();
    // Immersive kiosk mode — hides status bar and navigation bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final R = CircleHub.radius;

    return CircularScaffold(
      child: Stack(
        children: [
          // ── Page swipe area ───────────────────────────────────────────────
          PageView(
            controller: _controller,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (i) => setState(() => _current = i),
            children: _pages,
          ),

          // ── Page indicator (bottom safe zone) ─────────────────────────────
          Positioned(
            bottom: (R - CircleHub.safeRadius) + R * 0.06,
            left: 0,
            right: 0,
            child: PageIndicator(count: _pages.length, current: _current),
          ),
        ],
      ),
    );
  }
}
