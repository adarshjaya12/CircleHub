import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import 'calendar_provider.dart';
import 'views/day_view.dart';
import 'views/week_view.dart';
import 'views/month_view.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  static const _kInitialPage = 500;
  late PageController _pageCtrl;
  int _currentPage = _kInitialPage;

  // +1 = zoom out (new view slides up), -1 = zoom in (new view slides down)
  int _zoomDir = 1;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(initialPage: _kInitialPage);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(calendarProvider);
    final notifier = ref.read(calendarProvider.notifier);

    return LayoutBuilder(builder: (_, box) {
      final R = box.maxWidth / 2;

      return Container(
        color: CircleHub.background,
        child: Stack(
          children: [

            // ── Vertical swipe → zoom in / out ─────────────────────────────
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragEnd: (details) {
                final dy = details.velocity.pixelsPerSecond.dy;
                if (dy > 250) {
                  // swipe down → zoom out (day → week → month)
                  setState(() => _zoomDir = 1);
                  notifier.zoomOut();
                  // Reset page controller for the new view mode
                  _resetPageCtrl();
                } else if (dy < -250) {
                  // swipe up → zoom in (month → week → day)
                  setState(() => _zoomDir = -1);
                  notifier.zoomIn();
                  _resetPageCtrl();
                }
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) {
                  final begin = Offset(0, _zoomDir > 0 ? 1.0 : -1.0);
                  return SlideTransition(
                    position: Tween(begin: begin, end: Offset.zero).animate(
                        CurvedAnimation(
                            parent: anim, curve: Curves.easeOutCubic)),
                    child: child,
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(state.viewMode),
                  // ── Horizontal swipe → navigate dates ──────────────────
                  child: NotificationListener<ScrollNotification>(
                    // Absorb horizontal scroll so the outer hub PageView
                    // doesn't intercept the calendar's date swipe
                    onNotification: (n) {
                      if (n.metrics.axis == Axis.horizontal) return true;
                      return false;
                    },
                    child: PageView.builder(
                      controller: _pageCtrl,
                      onPageChanged: (page) {
                        final delta = page - _currentPage;
                        _currentPage = page;
                        if (delta > 0) {
                          notifier.stepForward();
                        } else {
                          notifier.stepBack();
                        }
                      },
                      itemBuilder: (_, __) => switch (state.viewMode) {
                        CalendarViewMode.day => DayView(
                            state: state, R: R),
                        CalendarViewMode.week => WeekView(
                            state: state,
                            R: R,
                            onDayTap: (d) {
                              notifier.selectDay(d);
                              setState(() => _zoomDir = -1);
                              notifier.zoomIn();
                              _resetPageCtrl();
                            }),
                        CalendarViewMode.month => MonthView(
                            state: state,
                            R: R,
                            onDayTap: (d) {
                              notifier.selectDay(d);
                              setState(() => _zoomDir = -1);
                              notifier.zoomIn();
                              _resetPageCtrl();
                            }),
                      },
                    ),
                  ),
                ),
              ),
            ),

            // ── Add event FAB ───────────────────────────────────────────────
            Positioned(
              right: R * 0.22,
              top: R * 0.18,
              child: GestureDetector(
                onTap: () => _showAddSheet(context, notifier, state.selectedDay),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: CircleHub.accentBlue.withAlpha(30),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: CircleHub.accentBlue.withAlpha(120),
                        width: 1),
                  ),
                  child: const Icon(Icons.add,
                      color: CircleHub.accentBlue, size: 20),
                ),
              ),
            ),

          ],
        ),
      );
    });
  }

  void _resetPageCtrl() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final old = _pageCtrl;
      setState(() {
        _pageCtrl = PageController(initialPage: _kInitialPage);
        _currentPage = _kInitialPage;
      });
      old.dispose();
    });
  }

  void _showAddSheet(
      BuildContext context, CalendarNotifier notifier, DateTime day) {
    var title      = '';
    var startHour  = 9;
    var startMin   = 0;
    var endHour    = 10;
    var endMin     = 0;
    var colorIndex = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: CircleHub.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text('New Event',
                  style: const TextStyle(
                      color: CircleHub.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w300)),
              const SizedBox(height: 16),

              // Title
              TextField(
                autofocus: true,
                style: const TextStyle(color: CircleHub.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Event title',
                  hintStyle: const TextStyle(color: CircleHub.textDim),
                  filled: true,
                  fillColor: CircleHub.surfaceHigh,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: CircleHub.textDim),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: CircleHub.accentBlue),
                  ),
                ),
                onChanged: (v) => title = v,
              ),
              const SizedBox(height: 16),

              // Time pickers
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Start ',
                      style: TextStyle(
                          color: CircleHub.textSecondary,
                          fontSize: 13)),
                  _MiniSpinner(
                      value: startHour,
                      max: 23,
                      onChanged: (v) => setS(() => startHour = v)),
                  Text(':',
                      style: TextStyle(
                          color: CircleHub.textSecondary, fontSize: 20)),
                  _MiniSpinner(
                      value: startMin,
                      max: 59,
                      onChanged: (v) => setS(() => startMin = v)),
                  const SizedBox(width: 16),
                  Text('End ',
                      style: TextStyle(
                          color: CircleHub.textSecondary,
                          fontSize: 13)),
                  _MiniSpinner(
                      value: endHour,
                      max: 23,
                      onChanged: (v) => setS(() => endHour = v)),
                  Text(':',
                      style: TextStyle(
                          color: CircleHub.textSecondary, fontSize: 20)),
                  _MiniSpinner(
                      value: endMin,
                      max: 59,
                      onChanged: (v) => setS(() => endMin = v)),
                ],
              ),
              const SizedBox(height: 16),

              // Color selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(kEventColors.length, (i) {
                  return GestureDetector(
                    onTap: () => setS(() => colorIndex = i),
                    child: Container(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 5),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: kEventColors[i],
                        shape: BoxShape.circle,
                        border: colorIndex == i
                            ? Border.all(
                                color: CircleHub.textPrimary,
                                width: 2.5)
                            : null,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Save
              GestureDetector(
                onTap: () {
                  if (title.trim().isEmpty) return;
                  notifier.addEvent(CalendarEvent(
                    id: DateTime.now()
                        .millisecondsSinceEpoch
                        .toString(),
                    title: title.trim(),
                    start: DateTime(day.year, day.month, day.day,
                        startHour, startMin),
                    end: DateTime(day.year, day.month, day.day,
                        endHour, endMin),
                    colorIndex: colorIndex,
                  ));
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: CircleHub.accentBlue.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: CircleHub.accentBlue.withAlpha(100)),
                  ),
                  child: const Text('Add Event',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: CircleHub.accentBlue,
                          fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mini time spinner for the add-event sheet ─────────────────────────────────

class _MiniSpinner extends StatelessWidget {
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  const _MiniSpinner(
      {required this.value,
      required this.max,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => onChanged(value >= max ? 0 : value + 1),
          child: const Icon(Icons.keyboard_arrow_up,
              color: CircleHub.textDim, size: 18),
        ),
        Text(
          value.toString().padLeft(2, '0'),
          style: const TextStyle(
              color: CircleHub.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w200),
        ),
        GestureDetector(
          onTap: () => onChanged(value <= 0 ? max : value - 1),
          child: const Icon(Icons.keyboard_arrow_down,
              color: CircleHub.textDim, size: 18),
        ),
      ],
    );
  }
}
