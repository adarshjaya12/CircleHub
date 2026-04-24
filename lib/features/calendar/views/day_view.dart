import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../calendar_provider.dart';

class DayView extends StatelessWidget {
  final CalendarState state;
  final double R;
  const DayView({super.key, required this.state, required this.R});

  @override
  Widget build(BuildContext context) {
    final day    = state.selectedDay;
    final events = state.eventsForDay(day);
    final isToday = _isToday(day);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: R * 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: R * 0.30),

          // Weekday name — centered
          Text(
            DateFormat('EEEE').format(day).toUpperCase(),
            style: TextStyle(
              color: isToday ? CircleHub.accentBlue : CircleHub.textSecondary,
              fontSize: R * 0.052,
              letterSpacing: 4,
              fontWeight: FontWeight.w300,
            ),
          ),
          SizedBox(height: R * 0.01),

          // Day number — centered, smaller so it doesn't clip
          Text(
            DateFormat('d').format(day),
            style: TextStyle(
              color: CircleHub.textPrimary,
              fontSize: R * 0.24,
              fontWeight: FontWeight.w100,
              height: 1.0,
            ),
          ),

          // Month + year — centered
          Text(
            DateFormat('MMMM yyyy').format(day).toUpperCase(),
            style: TextStyle(
              color: CircleHub.textDim,
              fontSize: R * 0.048,
              letterSpacing: 2,
              fontWeight: FontWeight.w300,
            ),
          ),

          SizedBox(height: R * 0.06),
          Container(height: 0.5, color: CircleHub.surfaceHigh),
          SizedBox(height: R * 0.06),

          // Events
          Expanded(
            child: events.isEmpty
                ? Center(
                    child: Text(
                      'No events',
                      style: TextStyle(
                          color: CircleHub.textDim, fontSize: R * 0.055),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: events.length,
                    separatorBuilder: (_, __) => SizedBox(height: R * 0.04),
                    itemBuilder: (_, i) =>
                        _EventRow(event: events[i], R: R),
                  ),
          ),

          SizedBox(height: R * 0.30),
        ],
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

class _EventRow extends StatelessWidget {
  final CalendarEvent event;
  final double R;
  const _EventRow({required this.event, required this.R});

  @override
  Widget build(BuildContext context) {
    final timeStr = event.isAllDay
        ? 'All day'
        : '${_fmt(event.start)} – ${_fmt(event.end)}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3,
          height: R * 0.12,
          decoration: BoxDecoration(
            color: event.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: R * 0.05),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: TextStyle(
                  color: CircleHub.textPrimary,
                  fontSize: R * 0.075,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: R * 0.01),
              Text(
                timeStr,
                style: TextStyle(
                    color: CircleHub.textDim, fontSize: R * 0.052),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
