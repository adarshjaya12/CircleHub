import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Color palette ─────────────────────────────────────────────────────────────

const List<Color> kEventColors = [
  Color(0xFF4A9EFF), // blue  (default)
  Color(0xFFF5A623), // amber
  Color(0xFF4ADE80), // green
  Color(0xFFE63946), // red
  Color(0xFFB47FFF), // purple
  Color(0xFF38BDF8), // teal
];

// ── View mode ─────────────────────────────────────────────────────────────────

enum CalendarViewMode { day, week, month }

// ── Event model ───────────────────────────────────────────────────────────────

class CalendarEvent {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final int colorIndex;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    this.colorIndex = 0,
  });

  Color get color => kEventColors[colorIndex.clamp(0, kEventColors.length - 1)];

  bool get isAllDay =>
      start.hour == 0 && start.minute == 0 &&
      end.hour == 23 && end.minute == 59;

  bool occursOn(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'colorIndex': colorIndex,
      };

  factory CalendarEvent.fromJson(Map<String, dynamic> j) => CalendarEvent(
        id: j['id'] as String,
        title: j['title'] as String,
        start: DateTime.parse(j['start'] as String),
        end: DateTime.parse(j['end'] as String),
        colorIndex: j['colorIndex'] as int? ?? 0,
      );
}

// ── State ─────────────────────────────────────────────────────────────────────

class CalendarState {
  final List<CalendarEvent> events;
  final DateTime selectedDay;
  final CalendarViewMode viewMode;

  const CalendarState({
    required this.events,
    required this.selectedDay,
    required this.viewMode,
  });

  CalendarState copyWith({
    List<CalendarEvent>? events,
    DateTime? selectedDay,
    CalendarViewMode? viewMode,
  }) =>
      CalendarState(
        events: events ?? this.events,
        selectedDay: selectedDay ?? this.selectedDay,
        viewMode: viewMode ?? this.viewMode,
      );

  List<CalendarEvent> eventsForDay(DateTime day) =>
      events.where((e) => e.occursOn(day)).toList()
        ..sort((a, b) => a.start.compareTo(b.start));

  bool hasEventsOn(DateTime day) => events.any((e) => e.occursOn(day));
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class CalendarNotifier extends StateNotifier<CalendarState> {
  CalendarNotifier()
      : super(CalendarState(
          events: [],
          selectedDay: _today(),
          viewMode: CalendarViewMode.day,
        )) {
    _load();
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // ── Navigation ──────────────────────────────────────────────────────────────

  void selectDay(DateTime day) =>
      state = state.copyWith(
          selectedDay: DateTime(day.year, day.month, day.day));

  void stepForward() {
    final d = state.selectedDay;
    state = state.copyWith(
      selectedDay: switch (state.viewMode) {
        CalendarViewMode.day   => d.add(const Duration(days: 1)),
        CalendarViewMode.week  => d.add(const Duration(days: 7)),
        CalendarViewMode.month => DateTime(d.year, d.month + 1, 1),
      },
    );
  }

  void stepBack() {
    final d = state.selectedDay;
    state = state.copyWith(
      selectedDay: switch (state.viewMode) {
        CalendarViewMode.day   => d.subtract(const Duration(days: 1)),
        CalendarViewMode.week  => d.subtract(const Duration(days: 7)),
        CalendarViewMode.month => DateTime(d.year, d.month - 1, 1),
      },
    );
  }

  void zoomOut() {
    if (state.viewMode == CalendarViewMode.month) return;
    state = state.copyWith(
      viewMode: state.viewMode == CalendarViewMode.day
          ? CalendarViewMode.week
          : CalendarViewMode.month,
    );
  }

  void zoomIn() {
    if (state.viewMode == CalendarViewMode.day) return;
    state = state.copyWith(
      viewMode: state.viewMode == CalendarViewMode.month
          ? CalendarViewMode.week
          : CalendarViewMode.day,
    );
  }

  // ── CRUD ────────────────────────────────────────────────────────────────────

  void addEvent(CalendarEvent event) {
    state = state.copyWith(events: [...state.events, event]);
    _save();
  }

  void removeEvent(String id) {
    state = state.copyWith(
        events: state.events.where((e) => e.id != id).toList());
    _save();
  }

  // ── Persistence ─────────────────────────────────────────────────────────────

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('calendar_events') ?? [];
    state = state.copyWith(
      events: raw
          .map((s) =>
              CalendarEvent.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'calendar_events',
        state.events.map((e) => jsonEncode(e.toJson())).toList());
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final calendarProvider =
    StateNotifierProvider<CalendarNotifier, CalendarState>(
        (ref) => CalendarNotifier());
