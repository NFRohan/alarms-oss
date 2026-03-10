import 'package:alarms_oss/src/features/alarms/domain/alarm_engine_status.dart';
import 'package:alarms_oss/src/features/alarms/domain/alarm_spec.dart';
import 'package:flutter/material.dart';

class AlarmEditorSheet extends StatefulWidget {
  const AlarmEditorSheet({required this.alarm, this.engineStatus, super.key});

  final AlarmSpec alarm;
  final AlarmEngineStatus? engineStatus;

  static Future<AlarmSpec?> show(
    BuildContext context, {
    required AlarmSpec alarm,
    AlarmEngineStatus? engineStatus,
  }) {
    return showModalBottomSheet<AlarmSpec>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          AlarmEditorSheet(alarm: alarm, engineStatus: engineStatus),
    );
  }

  @override
  State<AlarmEditorSheet> createState() => _AlarmEditorSheetState();
}

class _AlarmEditorSheetState extends State<AlarmEditorSheet> {
  late final TextEditingController _labelController;
  late TimeOfDay _time;
  late bool _enabled;
  late Set<AlarmWeekday> _selectedWeekdays;
  late AlarmRingtone _ringtone;
  late int _snoozeDurationMinutes;
  late int _maxSnoozes;
  late AlarmMissionType _missionType;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.alarm.label);
    _time = TimeOfDay(hour: widget.alarm.hour, minute: widget.alarm.minute);
    _enabled = widget.alarm.enabled;
    _selectedWeekdays = widget.alarm.weekdays.toSet();
    _ringtone = widget.alarm.ringtone;
    _snoozeDurationMinutes = widget.alarm.snoozeDurationMinutes;
    _maxSnoozes = widget.alarm.maxSnoozes;
    _missionType =
        _missionOptionFor(widget.alarm.missionType, widget.engineStatus).enabled
        ? widget.alarm.missionType
        : AlarmMissionType.none;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final diagnostics = widget.engineStatus;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + mediaQuery.viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alarm details',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sprint 4 turns the editor into a real configuration surface with device-aware diagnostics.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF56483A),
                height: 1.4,
              ),
            ),
            if (diagnostics != null && !diagnostics.canScheduleExactAlarms) ...[
              const SizedBox(height: 16),
              const _EditorWarning(
                title: 'Exact alarms are not ready',
                detail:
                    'You can still save the alarm, but enabling it will fail until exact-alarm access is available.',
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.tonal(
              onPressed: _pickTime,
              child: Text('Time: ${_time.format(context)}'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Label',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Repeat days',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AlarmWeekday.values
                  .map((weekday) {
                    return FilterChip(
                      label: Text(weekday.shortLabel),
                      selected: _selectedWeekdays.contains(weekday),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedWeekdays.add(weekday);
                          } else {
                            _selectedWeekdays.remove(weekday);
                          }
                        });
                      },
                    );
                  })
                  .toList(growable: false),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AlarmRingtone>(
              initialValue: _ringtone,
              decoration: const InputDecoration(
                labelText: 'Ringtone policy',
                border: OutlineInputBorder(),
              ),
              items: AlarmRingtone.values
                  .map(
                    (ringtone) => DropdownMenuItem<AlarmRingtone>(
                      value: ringtone,
                      child: Text(ringtone.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _ringtone = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              _ringtone.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF56483A),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _snoozeDurationMinutes,
                    decoration: const InputDecoration(
                      labelText: 'Snooze',
                      border: OutlineInputBorder(),
                    ),
                    items: const [5, 9, 10, 15, 20]
                        .map(
                          (minutes) => DropdownMenuItem<int>(
                            value: minutes,
                            child: Text('$minutes min'),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _snoozeDurationMinutes = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _maxSnoozes,
                    decoration: const InputDecoration(
                      labelText: 'Max snoozes',
                      border: OutlineInputBorder(),
                    ),
                    items: const [0, 1, 2, 3, 4, 5]
                        .map(
                          (count) => DropdownMenuItem<int>(
                            value: count,
                            child: Text('$count'),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _maxSnoozes = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Dismissal mode',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...AlarmMissionType.values.map((missionType) {
              final option = _missionOptionFor(missionType, diagnostics);
              return _MissionChoiceTile(
                title: option.title,
                detail: option.detail,
                selected: _missionType == missionType,
                enabled: option.enabled,
                onTap: option.enabled
                    ? () {
                        setState(() {
                          _missionType = missionType;
                        });
                      }
                    : null,
              );
            }),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              value: _enabled,
              contentPadding: EdgeInsets.zero,
              title: const Text('Enabled'),
              subtitle: const Text(
                'Disabled alarms stay persisted but unscheduled.',
              ),
              onChanged: (value) {
                setState(() {
                  _enabled = value;
                });
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Save alarm'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);

    if (selected == null) {
      return;
    }

    setState(() {
      _time = selected;
    });
  }

  void _save() {
    final normalizedWeekdays = _selectedWeekdays.toList()
      ..sort((left, right) => left.isoValue.compareTo(right.isoValue));

    Navigator.of(context).pop(
      widget.alarm.copyWith(
        label: _labelController.text.trim().isEmpty
            ? 'Alarm'
            : _labelController.text.trim(),
        hour: _time.hour,
        minute: _time.minute,
        enabled: _enabled,
        weekdays: normalizedWeekdays,
        ringtone: _ringtone,
        snoozeDurationMinutes: _snoozeDurationMinutes,
        maxSnoozes: _maxSnoozes,
        missionType: _missionType,
        clearNextTriggerAtUtc: true,
      ),
    );
  }

  _MissionOption _missionOptionFor(
    AlarmMissionType missionType,
    AlarmEngineStatus? diagnostics,
  ) {
    return switch (missionType) {
      AlarmMissionType.none => const _MissionOption(
        title: 'Direct dismiss',
        detail: 'The alarm can be dismissed from the active alarm screen.',
        enabled: true,
      ),
      AlarmMissionType.math => const _MissionOption(
        title: 'Math mission',
        detail:
            'Visible now so the configuration model is stable. The actual mission lands in Sprint 5.',
        enabled: false,
      ),
      AlarmMissionType.steps => _MissionOption(
        title: 'Steps mission',
        detail: !((diagnostics?.hasStepSensor) ?? false)
            ? 'This device does not expose a hardware step counter.'
            : !((diagnostics?.activityRecognitionGranted) ?? false)
            ? 'Grant activity recognition from diagnostics before this mission can be enabled later.'
            : 'Sensor prerequisites look good. Mission runtime lands in Sprint 6.',
        enabled: false,
      ),
      AlarmMissionType.qr => _MissionOption(
        title: 'QR mission',
        detail: !((diagnostics?.hasCamera) ?? false)
            ? 'This device does not report camera availability.'
            : !((diagnostics?.cameraPermissionGranted) ?? false)
            ? 'Grant camera permission from diagnostics before this mission can be enabled later.'
            : 'Camera prerequisites look good. Native vision runtime lands in Sprint 7.',
        enabled: false,
      ),
    };
  }
}

class _MissionOption {
  const _MissionOption({
    required this.title,
    required this.detail,
    required this.enabled,
  });

  final String title;
  final String detail;
  final bool enabled;
}

class _MissionChoiceTile extends StatelessWidget {
  const _MissionChoiceTile({
    required this.title,
    required this.detail,
    required this.selected,
    required this.enabled,
    this.onTap,
  });

  final String title;
  final String detail;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = selected ? const Color(0xFF2B6A6C) : const Color(0xFFB7A89A);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFFFFBF4) : const Color(0xFFF3ECE2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? accent : const Color(0xFFD6C7B6),
              width: selected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: selected ? accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: accent, width: 2),
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: enabled ? null : const Color(0xFF7A6C5E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        detail,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: enabled
                              ? const Color(0xFF56483A)
                              : const Color(0xFF7A6C5E),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorWarning extends StatelessWidget {
  const _EditorWarning({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2EE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF56483A),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
