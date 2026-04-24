import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../calendar_provider.dart';

class MonthView extends StatelessWidget {
  final CalendarState state;
  final double R;
  final ValueChanged<DateTime> onDayTap;

  const MonthView({
    super.key,
    required this.state,
    required this.R,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected    = state.selectedDay;
    final firstDay    = DateTime(selected.year, selected.month, 1);
    final daysInMonth = DateTime(selected.year, selected.month + 1, 0).day;
    final startOffset = firstDay.weekday - 1; // Mon=0 … Sun=6
    final totalCells  = startOffset + daysInMonth;
    final rows        = (totalCells / 7).ceil();

    // Full usable width = 2R - 2*hPad; divide into 7 equal columns
    // hPad=0.14 keeps corner cells inside the circle at the header row height
    final hPad  = R * 0.14;
    final cellW = (2 * R - 2 * hPad) / 7;
    // Grid height: total content ~1.65R, leaving ~0.35R top+bottom balanced
    final gridH = R * 1.08;
    final cellH = gridH / rows;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: R * 0.36),

          // Month + year
          Text(
            DateFormat('MMMM yyyy').format(selected).toUpperCase(),
            style: TextStyle(
              color: CircleHub.textSecondary,
              fontSize: R * 0.058,
              letterSpacing: 3,
              fontWeight: FontWeight.w300,
            ),
          ),

          SizedBox(height: R * 0.06),

          // Weekday headers
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((l) => SizedBox(
                      width: cellW,
                      child: Text(
                        l,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: CircleHub.textDim,
                          fontSize: R * 0.044,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ))
                .toList(),
          ),

          SizedBox(height: R * 0.02),

          // Calendar grid
          SizedBox(
            height: gridH,
            child: Column(
              children: List.generate(rows, (row) {
                return SizedBox(
                  height: cellH,
                  child: Row(
                    children: List.generate(7, (col) {
                      final idx    = row * 7 + col;
                      final dayNum = idx - startOffset + 1;

                      if (dayNum < 1 || dayNum > daysInMonth) {
                        return SizedBox(width: cellW, height: cellH);
                      }

                      final day        = DateTime(selected.year, selected.month, dayNum);
                      final isSelected = _same(day, selected);
                      final isToday    = _isToday(day);
                      final dayEvents  = state.eventsForDay(day);

                      return GestureDetector(
                        onTap: () => onDayTap(day),
                        child: SizedBox(
                          width: cellW,
                          height: cellH,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: cellH * 0.56,
                                height: cellH * 0.56,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? CircleHub.accentBlue
                                      : isToday
                                          ? CircleHub.accent.withAlpha(40)
                                          : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$dayNum',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : isToday
                                            ? CircleHub.accent
                                            : CircleHub.textSecondary,
                                    fontSize: R * 0.050,
                                    fontWeight: isSelected
                                        ? FontWeight.w500
                                        : FontWeight.w300,
                                  ),
                                ),
                              ),
                              if (dayEvents.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: dayEvents
                                        .take(3)
                                        .map((e) => Container(
                                              width: 3.5,
                                              height: 3.5,
                                              margin: const EdgeInsets
                                                  .symmetric(horizontal: 1),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? Colors.white
                                                        .withAlpha(200)
                                                    : e.color,
                                                shape: BoxShape.circle,
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isToday(DateTime d) => _same(d, DateTime.now());
}
