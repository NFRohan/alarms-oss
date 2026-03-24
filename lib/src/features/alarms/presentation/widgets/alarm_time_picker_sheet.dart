import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:neoalarm/src/core/theme/app_theme.dart';
import 'package:neoalarm/src/core/ui/neo_brutal_widgets.dart';
import 'package:neoalarm/src/features/alarms/domain/alarm_countdown_formatter.dart';

class AlarmTimePickerSheet extends StatefulWidget {
  const AlarmTimePickerSheet({
    required this.initialTime,
    required this.countdownText,
    super.key,
  });

  final TimeOfDay initialTime;
  final String countdownText;

  static Future<TimeOfDay?> show(
    BuildContext context, {
    required TimeOfDay initialTime,
    required String countdownText,
  }) {
    return showModalBottomSheet<TimeOfDay>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.68),
      builder: (context) => AlarmTimePickerSheet(
        initialTime: initialTime,
        countdownText: countdownText,
      ),
    );
  }

  @override
  State<AlarmTimePickerSheet> createState() => _AlarmTimePickerSheetState();
}

class _AlarmTimePickerSheetState extends State<AlarmTimePickerSheet> {
  late int _selectedHour;
  late int _selectedMinute;
  late DayPeriod _selectedPeriod;
  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;
  late final FixedExtentScrollController _periodController;
  Timer? _countdownTicker;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hourOfPeriod == 0
        ? 12
        : widget.initialTime.hourOfPeriod;
    _selectedMinute = widget.initialTime.minute;
    _selectedPeriod = widget.initialTime.period;
    _hourController = FixedExtentScrollController(initialItem: _selectedHour - 1);
    _minuteController = FixedExtentScrollController(initialItem: _selectedMinute);
    _periodController = FixedExtentScrollController(
      initialItem: _selectedPeriod == DayPeriod.am ? 0 : 1,
    );
    _countdownTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    _hourController.dispose();
    _minuteController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);
    final selectedTime = _selectedTime;
    final countdownText = formatAlarmCountdown(
      computeNextAlarmPreview(
        hour: selectedTime.hour,
        minute: selectedTime.minute,
        weekdays: const [],
      ),
    );

    return FractionallySizedBox(
      heightFactor: 0.7,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          10,
          16,
          10,
          10 + mediaQuery.viewPadding.bottom,
        ),
        child: DecoratedBox(
          decoration: neoPanelDecoration(
            color: NeoColors.paper,
            borderWidth: 3,
            shadowOffset: const Offset(5, 5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                decoration: BoxDecoration(
                  color: NeoColors.cyan,
                  border: Border(
                    bottom: BorderSide(color: NeoColors.ink, width: 3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PICK TIME',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: NeoColors.accentInk,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            localizations.formatTimeOfDay(
                              selectedTime,
                              alwaysUse24HourFormat: false,
                            ),
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: NeoColors.accentInk,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            countdownText,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: NeoColors.accentInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                    NeoSquareIconButton(
                      icon: Icons.close,
                      backgroundColor: NeoColors.panel,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  child: NeoPanel(
                    color: NeoColors.panel,
                    padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: _TimeWheel(
                            controller: _hourController,
                            childCount: 12,
                            onSelectedItemChanged: (index) {
                              setState(() {
                                _selectedHour = index + 1;
                              });
                            },
                            itemBuilder: (context, index) =>
                                _TimeWheelValue(label: '${index + 1}'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            ':',
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: NeoColors.ink,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _TimeWheel(
                            controller: _minuteController,
                            childCount: 60,
                            onSelectedItemChanged: (index) {
                              setState(() {
                                _selectedMinute = index;
                              });
                            },
                            itemBuilder: (context, index) => _TimeWheelValue(
                              label: index.toString().padLeft(2, '0'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 112,
                          child: _TimeWheel(
                            controller: _periodController,
                            childCount: 2,
                            onSelectedItemChanged: (index) {
                              setState(() {
                                _selectedPeriod = index == 0
                                    ? DayPeriod.am
                                    : DayPeriod.pm;
                              });
                            },
                            itemBuilder: (context, index) => _TimeWheelValue(
                              label: index == 0 ? 'AM' : 'PM',
                              compact: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: NeoActionButton(
                        label: 'Cancel',
                        backgroundColor: NeoColors.panel,
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NeoActionButton(
                        label: 'Apply',
                        backgroundColor: NeoColors.primary,
                        onPressed: () {
                          Navigator.of(context).pop(selectedTime);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TimeOfDay get _selectedTime {
    final normalizedHour = _selectedHour % 12;
    final resolvedHour = _selectedPeriod == DayPeriod.am
        ? normalizedHour
        : normalizedHour + 12;
    return TimeOfDay(hour: resolvedHour, minute: _selectedMinute);
  }
}

class _TimeWheel extends StatelessWidget {
  const _TimeWheel({
    required this.controller,
    required this.childCount,
    required this.itemBuilder,
    required this.onSelectedItemChanged,
  });

  final FixedExtentScrollController controller;
  final int childCount;
  final NullableIndexedWidgetBuilder itemBuilder;
  final ValueChanged<int> onSelectedItemChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CupertinoTheme(
          data: CupertinoThemeData(
            brightness: Theme.of(context).brightness,
            primaryColor: NeoColors.ink,
          ),
          child: CupertinoPicker.builder(
            scrollController: controller,
            itemExtent: 58,
            diameterRatio: 1.18,
            squeeze: 1.18,
            selectionOverlay: const SizedBox.shrink(),
            onSelectedItemChanged: onSelectedItemChanged,
            childCount: childCount,
            itemBuilder: itemBuilder,
          ),
        ),
        IgnorePointer(
          child: Container(
            height: 70,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: NeoColors.primary.withValues(alpha: 0.24),
              border: Border(
                top: BorderSide(color: NeoColors.ink, width: 3),
                bottom: BorderSide(color: NeoColors.ink, width: 3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeWheelValue extends StatelessWidget {
  const _TimeWheelValue({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Text(
        label,
        style: (compact
                ? theme.textTheme.headlineLarge
                : theme.textTheme.displayMedium)
            ?.copyWith(
              color: NeoColors.ink,
              fontStyle: FontStyle.italic,
              fontSize: compact ? 30 : 40,
            ),
      ),
    );
  }
}
