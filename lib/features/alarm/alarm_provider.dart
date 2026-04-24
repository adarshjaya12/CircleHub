import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';

// ── Data model ─────────────────────────────────────────────────────────────

class Alarm {
  final String id;
  final int hour;
  final int minute;
  final String label;
  final bool enabled;
  final Set<int> days; // 1=Mon … 7=Sun, empty = one-shot

  const Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    this.label = '',
    this.enabled = true,
    this.days = const {},
  });

  Alarm copyWith({bool? enabled, Set<int>? days, String? label}) => Alarm(
        id: id,
        hour: hour,
        minute: minute,
        label: label ?? this.label,
        enabled: enabled ?? this.enabled,
        days: days ?? this.days,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'label': label,
        'enabled': enabled,
        'days': days.toList(),
      };

  factory Alarm.fromJson(Map<String, dynamic> j) => Alarm(
        id: j['id'] as String,
        hour: j['hour'] as int,
        minute: j['minute'] as int,
        label: j['label'] as String? ?? '',
        enabled: j['enabled'] as bool? ?? true,
        days: ((j['days'] as List?)?.cast<int>() ?? []).toSet(),
      );

  String get timeString =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

enum AlarmState { idle, ringing, snoozed }

// ── GPIO bridge ────────────────────────────────────────────────────────────

/// Manages the Python subprocess that pulses the solenoid bell.
class GpioBellService {
  Process? _proc;
  bool _available = false;

  Future<void> init() async {
    try {
      _proc = await Process.start('python3', ['/app/gpio/bell_controller.py'])
          .timeout(const Duration(seconds: 3));
      _available = true;
    } catch (_) {
      // Desktop / non-Pi environment — GPIO not available, alarm still fires UI
    }
  }

  void ring()    => _send('RING');
  void stop()    => _send('STOP');
  void dispose() { _send('QUIT'); _proc?.kill(); }

  void _send(String cmd) {
    if (_available) _proc?.stdin.writeln(cmd);
  }
}

// ── State notifier ─────────────────────────────────────────────────────────

class AlarmNotifier extends StateNotifier<List<Alarm>> {
  final GpioBellService _bell;
  AlarmState _ringState = AlarmState.idle;
  String? _ringingId;
  Timer? _checkTimer;
  Timer? _snoozeTimer;
  Timer? _autoKillTimer;

  AlarmState get ringState => _ringState;

  AlarmNotifier(this._bell) : super([]) {
    _load();
    _bell.init();
    // Check every 30 seconds for due alarms
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) => _checkAlarms());
    _checkAlarms();
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('alarms') ?? [];
    state = raw
        .map((s) => Alarm.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'alarms', state.map((a) => jsonEncode(a.toJson())).toList());
  }

  // ── Alarm management ──────────────────────────────────────────────────────

  void addAlarm(Alarm alarm) {
    state = [...state, alarm];
    _save();
  }

  void removeAlarm(String id) {
    state = state.where((a) => a.id != id).toList();
    _save();
  }

  void toggleAlarm(String id) {
    state = state
        .map((a) => a.id == id ? a.copyWith(enabled: !a.enabled) : a)
        .toList();
    _save();
  }

  // ── Ring control ──────────────────────────────────────────────────────────

  void _trigger(String alarmId) {
    _ringingId = alarmId;
    _ringState = AlarmState.ringing;
    _bell.ring();

    // Auto-dismiss after max ring time
    _autoKillTimer?.cancel();
    _autoKillTimer = Timer(
        Duration(minutes: CircleHub.maxRingMinutes), dismiss);
  }

  /// Stop bell for [snoozeDurationMinutes] then re-trigger.
  void snooze() {
    if (_ringState != AlarmState.ringing) return;
    _bell.stop();
    _ringState = AlarmState.snoozed;
    _snoozeTimer?.cancel();
    _snoozeTimer = Timer(
        Duration(minutes: CircleHub.snoozeDurationMinutes), () {
      if (_ringingId != null) _trigger(_ringingId!);
    });
  }

  /// Stop the bell and cancel all pending retriggers.
  void dismiss() {
    _bell.stop();
    _ringState = AlarmState.idle;
    _snoozeTimer?.cancel();
    _autoKillTimer?.cancel();
    _ringingId = null;

    // If the alarm is a one-shot, disable it
    if (_ringingId != null) {
      state = state.map((a) {
        if (a.id == _ringingId && a.days.isEmpty) {
          return a.copyWith(enabled: false);
        }
        return a;
      }).toList();
      _save();
    }
  }

  void _checkAlarms() {
    if (_ringState != AlarmState.idle) return;
    final now = DateTime.now();
    for (final alarm in state) {
      if (!alarm.enabled) continue;
      if (alarm.hour != now.hour || alarm.minute != now.minute) continue;
      if (alarm.days.isNotEmpty && !alarm.days.contains(now.weekday)) continue;
      _trigger(alarm.id);
      break;
    }
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _snoozeTimer?.cancel();
    _autoKillTimer?.cancel();
    _bell.dispose();
    super.dispose();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────

final gpioBellProvider = Provider((ref) => GpioBellService());

final alarmProvider = StateNotifierProvider<AlarmNotifier, List<Alarm>>((ref) {
  return AlarmNotifier(ref.read(gpioBellProvider));
});

final alarmRingStateProvider = Provider<AlarmState>((ref) {
  // Re-derive from notifier — triggers UI rebuild when ring state changes
  final notifier = ref.read(alarmProvider.notifier);
  return notifier.ringState;
});
