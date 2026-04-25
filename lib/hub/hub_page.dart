import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/circular_scaffold.dart';
import '../features/clock/clock_page.dart';
import '../features/weather/weather_page.dart';
import '../features/news/news_page.dart';
import '../features/gallery/gallery_page.dart';
import '../features/alarm/alarm_page.dart';
import '../features/calendar/calendar_page.dart';
/// Root page — wraps the [PageView] in a [CircularScaffold].
class HubPage extends StatefulWidget {
  const HubPage({super.key});

  @override
  State<HubPage> createState() => _HubPageState();
}

class _HubPageState extends State<HubPage> {
  final _controller = PageController();

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
    return CircularScaffold(
      child: Stack(
        children: [
          // ── Page swipe area ───────────────────────────────────────────────
          PageView(
            controller: _controller,
            physics: const BouncingScrollPhysics(),
            children: _pages,
          ),

        ],
      ),
    );
  }
}
