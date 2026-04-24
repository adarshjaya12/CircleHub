import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../calendar_provider.dart';

class WeekView extends StatelessWidget {
  final CalendarState state;
  final double R;
  final ValueChanged<DateTime> onDayTap;

  const WeekView({
    super.key,
    required this.state,
    required this.R,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = state.selectedDay;
    final days     = _weekDays(selected);
    final events   = state.eventsForDay(selected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: R * 0.28),

        // Month label — very narrow zone here, use tight horizontal padding
        Padding(
          padding: EdgeInsets.symmetric(horizontal: R * 0.32),
          child: Text(
            DateFormat('MMMM yyyy').format(selected).toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CircleHub.textDim,
              fontSize: R * 0.048,
              letterSpacing: 3,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),

        SizedBox(height: R * 0.14),

        // 7-day strip — pushed toward vertical center where circle is wider.
        // hPad = R*0.16 gives available width ≈ 1.68R, safe at this y-offset.
        Padding(
          padding: EdgeInsets.symmetric(horizontal: R * 0.16),
          child: Row(
            children: days.map((day) => Expanded(
              child: _DayCell(
                day: day,
                isSelected: _same(day, selected),
                isToday: _isToday(day),
                events: state.eventsForDay(day),
                R: R,
                onTap: () => onDayTap(day),
              ),
            )).toList(),
          ),
        ),

        SizedBox(height: R * 0.07),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: R * 0.20),
          child: Container(height: 0.5, color: CircleHub.surfaceHigh),
        ),

        SizedBox(height: R * 0.07),

        // Events list
        Expanded(
          child: events.isEmpty
              ? Center(
                  child: Text(
                    'No events',
                    style: TextStyle(
                        color: CircleHub.textDim, fontSize: R * 0.055),
                  ),
                )
              : Padding(
                  padding: EdgeInsets.symmetric(horizontal: R * 0.22),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: events.length,
                    separatorBuilder: (_, __) => SizedBox(height: R * 0.04),
                    itemBuilder: (_, i) =>
                        _WeekEventRow(event: events[i], R: R),
                  ),
                ),
        ),

        SizedBox(height: R * 0.30),
      ],
    );
  }

  List<DateTime> _weekDays(DateTime d) {
    final start = d.subtract(Duration(days: d.weekday - 1)); // Monday
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isToday(DateTime d) => _same(d, DateTime.now());
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final List<CalendarEvent> events;
  final double R;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.events,
    required this.R,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pillColor = isSelected
        ? CircleHub.accentBlue
        : isToday
            ? CircleHub.accent.withAlpha(40)
            : Colors.transparent;
    final numColor = isSelected
        ? Colors.white
        : isToday
            ? CircleHub.accent
            : CircleHub.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          // Single weekday letter
          Text(
            DateFormat('E').format(day)[0],
            style: TextStyle(
                color: CircleHub.textDim,
                fontSize: R * 0.044,
                fontWeight: FontWeight.w300),
          ),
          SizedBox(height: R * 0.012),

          // Day number inside circle
          Container(
            width: R * 0.13,
            height: R * 0.13,
            decoration: BoxDecoration(color: pillColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: numColor,
                fontSize: R * 0.068,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w300,
              ),
            ),
          ),
          SizedBox(height: R * 0.010),

          // Event dots (up to 3)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: events
                .take(3)
                .map((e) => Container(
                      width: 3.5,
                      height: 3.5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withAlpha(180)
                            : e.color,
                        shape: BoxShape.circle,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _WeekEventRow extends StatelessWidget {
  final CalendarEvent event;
  final double R;
  const _WeekEventRow({required this.event, required this.R});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration:
              BoxDecoration(color: event.color, shape: BoxShape.circle),
        ),
        SizedBox(width: R * 0.04),
        Expanded(
          child: Text(
            event.title,
            style: TextStyle(
                color: CircleHub.textPrimary,
                fontSize: R * 0.068,
                fontWeight: FontWeight.w300),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!event.isAllDay)
          Text(
            _fmt(event.start),
            style:
                TextStyle(color: CircleHub.textDim, fontSize: R * 0.050),
          ),
      ],
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
