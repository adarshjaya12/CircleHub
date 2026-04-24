import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import 'alarm_provider.dart';

class AlarmPage extends ConsumerWidget {
  const AlarmPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarms    = ref.watch(alarmProvider);
    final notifier  = ref.read(alarmProvider.notifier);
    final ringState = notifier.ringState;
    final R         = CircleHub.radius;

    return Container(
      color: CircleHub.background,
      child: Stack(
        children: [
          // ── Alarm list ──────────────────────────────────────────────────
          Column(
            children: [
              SizedBox(height: R * 0.18),

              Text(
                'ALARMS',
                style: TextStyle(
                  color: CircleHub.accentGreen,
                  fontSize: R * 0.042,
                  letterSpacing: 6,
                  fontWeight: FontWeight.w300,
                ),
              ),
              SizedBox(height: R * 0.06),

              // Alarm items
              Expanded(
                child: alarms.isEmpty
                    ? Center(
                        child: Text(
                          'No alarms set.\nTap + to add one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: CircleHub.textDim,
                            fontSize: R * 0.04,
                            height: 1.6,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: R * 0.20),
                        itemCount: alarms.length,
                        itemBuilder: (_, i) => _AlarmTile(
                          alarm: alarms[i],
                          onToggle: () => notifier.toggleAlarm(alarms[i].id),
                          onDelete: () => notifier.removeAlarm(alarms[i].id),
                        ),
                      ),
              ),

              SizedBox(height: R * 0.18),
            ],
          ),

          // ── Add alarm FAB (top-right of safe zone) ───────────────────────
          Positioned(
            right: R * 0.22,
            top: R * 0.20,
            child: GestureDetector(
              onTap: () => _showAddAlarmSheet(context, notifier),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: CircleHub.accentGreen.withAlpha(30),
                  shape: BoxShape.circle,
                  border: Border.all(color: CircleHub.accentGreen.withAlpha(120), width: 1),
                ),
                child: const Icon(Icons.add, color: CircleHub.accentGreen, size: 22),
              ),
            ),
          ),

          // ── Ringing overlay ──────────────────────────────────────────────
          if (ringState != AlarmState.idle)
            _RingingOverlay(
              snoozed: ringState == AlarmState.snoozed,
              onSnooze: notifier.snooze,
              onDismiss: notifier.dismiss,
            ),
        ],
      ),
    );
  }

  void _showAddAlarmSheet(BuildContext context, AlarmNotifier notifier) {
    var hour = 7;
    var minute = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: CircleHub.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('New Alarm',
                  style: TextStyle(
                      color: CircleHub.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w300)),
              const SizedBox(height: 20),

              // Time picker row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TimeSpinner(
                    value: hour,
                    max: 23,
                    onChanged: (v) => setState(() => hour = v),
                  ),
                  Text(' : ',
                      style: TextStyle(
                          color: CircleHub.textSecondary, fontSize: 36, fontWeight: FontWeight.w100)),
                  _TimeSpinner(
                    value: minute,
                    max: 59,
                    onChanged: (v) => setState(() => minute = v),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Confirm
              GestureDetector(
                onTap: () {
                  notifier.addAlarm(Alarm(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    hour: hour,
                    minute: minute,
                  ));
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: CircleHub.accentGreen.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CircleHub.accentGreen.withAlpha(100)),
                  ),
                  child: const Text('Set Alarm',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: CircleHub.accentGreen, fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Alarm tile ──────────────────────────────────────────────────────────────

class _AlarmTile extends StatelessWidget {
  final Alarm alarm;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _AlarmTile({
    required this.alarm,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(alarm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: CircleHub.alarmRinging),
      ),
      onDismissed: (_) => onDelete(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alarm.timeString,
                    style: TextStyle(
                      color: alarm.enabled ? CircleHub.textPrimary : CircleHub.textDim,
                      fontSize: 32,
                      fontWeight: FontWeight.w100,
                      letterSpacing: 2,
                    ),
                  ),
                  if (alarm.label.isNotEmpty)
                    Text(alarm.label,
                        style: const TextStyle(
                            color: CircleHub.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            Switch(
              value: alarm.enabled,
              onChanged: (_) => onToggle(),
              activeColor: CircleHub.alarmSet,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Simple vertical spinner ──────────────────────────────────────────────────

class _TimeSpinner extends StatelessWidget {
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  const _TimeSpinner({required this.value, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_up, color: CircleHub.textSecondary),
          onPressed: () => onChanged(value >= max ? 0 : value + 1),
        ),
        Text(
          value.toString().padLeft(2, '0'),
          style: const TextStyle(
              color: CircleHub.textPrimary, fontSize: 48, fontWeight: FontWeight.w100),
        ),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: CircleHub.textSecondary),
          onPressed: () => onChanged(value <= 0 ? max : value - 1),
        ),
      ],
    );
  }
}

// ── Ringing overlay ──────────────────────────────────────────────────────────

class _RingingOverlay extends StatefulWidget {
  final bool snoozed;
  final VoidCallback onSnooze;
  final VoidCallback onDismiss;

  const _RingingOverlay({
    required this.snoozed,
    required this.onSnooze,
    required this.onDismiss,
  });

  @override
  State<_RingingOverlay> createState() => _RingingOverlayState();
}

class _RingingOverlayState extends State<_RingingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final R = CircleHub.radius;
    final color = widget.snoozed ? CircleHub.alarmSnoozed : CircleHub.alarmRinging;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Container(
        color: color.withAlpha((30 + _pulse.value * 25).round()),
        child: child,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Bell icon pulsing
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Transform.scale(
              scale: 0.95 + _pulse.value * 0.1,
              child: Icon(
                widget.snoozed ? Icons.snooze : Icons.notifications_active,
                color: color,
                size: R * 0.22,
              ),
            ),
          ),
          SizedBox(height: R * 0.06),

          Text(
            widget.snoozed ? 'SNOOZED' : 'ALARM',
            style: TextStyle(
              color: color,
              fontSize: R * 0.06,
              fontWeight: FontWeight.w200,
              letterSpacing: 8,
            ),
          ),
          if (widget.snoozed)
            Text(
              '${CircleHub.snoozeDurationMinutes} minutes',
              style: TextStyle(color: color.withAlpha(180), fontSize: R * 0.04),
            ),

          SizedBox(height: R * 0.10),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!widget.snoozed)
                _ActionButton(
                  label: 'SNOOZE',
                  icon: Icons.snooze,
                  color: CircleHub.alarmSnoozed,
                  onTap: widget.onSnooze,
                ),
              SizedBox(width: R * 0.08),
              _ActionButton(
                label: 'DISMISS',
                icon: Icons.alarm_off,
                color: CircleHub.textSecondary,
                onTap: widget.onDismiss,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(100), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: color.withAlpha(200),
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
