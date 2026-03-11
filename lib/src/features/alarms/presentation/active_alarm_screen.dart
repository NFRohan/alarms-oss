import 'dart:async';

import 'package:neoalarm/src/core/theme/app_theme.dart';
import 'package:neoalarm/src/core/ui/neo_brutal_widgets.dart';
import 'package:neoalarm/src/features/alarms/application/active_alarm_session_controller.dart';
import 'package:neoalarm/src/features/alarms/domain/active_alarm_session.dart';
import 'package:neoalarm/src/features/alarms/domain/alarm_mission.dart';
import 'package:neoalarm/src/features/missions/application/mission_registry.dart';
import 'package:neoalarm/src/platform/missions/mission_driver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActiveAlarmScreen extends ConsumerStatefulWidget {
  const ActiveAlarmScreen({required this.session, super.key});

  final ActiveAlarmSession session;

  @override
  ConsumerState<ActiveAlarmScreen> createState() => _ActiveAlarmScreenState();
}

class _ActiveAlarmScreenState extends ConsumerState<ActiveAlarmScreen> {
  static const _missionQuietWindow = Duration(seconds: 30);
  static const _missionRefreshDelay = Duration(seconds: 31);
  static const _missionPingThrottle = Duration(seconds: 2);
  static const _missionCountdownTick = Duration(milliseconds: 250);

  Timer? _countdownTimer;
  Timer? _missionRefreshTimer;
  DateTime? _lastMissionPingAt;

  ActiveAlarmSession get _session => widget.session;

  @override
  void initState() {
    super.initState();
    _syncMissionTimers();
  }

  @override
  void didUpdateWidget(covariant ActiveAlarmScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_session.sessionId != oldWidget.session.sessionId ||
        _session.state != oldWidget.session.state ||
        _session.missionTimeoutAtUtc != oldWidget.session.missionTimeoutAtUtc) {
      if (!_session.isMissionActive) {
        _lastMissionPingAt = null;
      }
      _syncMissionTimers();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _missionRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final formattedTime = localizations.formatTimeOfDay(
      TimeOfDay(hour: _session.hour, minute: _session.minute),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    final missionRegistry = ref.watch(missionRegistryProvider);
    final missionDriver = missionRegistry.driverFor(_session.mission.spec.type);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: NeoColors.primary,
        body: Stack(
          children: [
            Positioned(
              top: 90,
              left: -24,
              child: Text(
                'Z',
                style: theme.textTheme.displayLarge?.copyWith(
                  color: NeoColors.ink.withValues(alpha: 0.08),
                  fontSize: 160,
                ),
              ),
            ),
            Positioned(
              right: -16,
              bottom: 110,
              child: Transform.rotate(
                angle: 0.18,
                child: Container(
                  width: 170,
                  height: 170,
                  color: NeoColors.ink.withValues(alpha: 0.05),
                  alignment: Alignment.center,
                  child: Text(
                    'Z',
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: NeoColors.ink.withValues(alpha: 0.09),
                      fontSize: 120,
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Column(
                  children: [
                    Row(
                      children: [
                        NeoPanel(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          borderWidth: 2,
                          shadowOffset: const Offset(3, 3),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.alarm, size: 18),
                              const SizedBox(width: 8),
                              Text(_headerLabel),
                            ],
                          ),
                        ),
                        const Spacer(),
                        NeoPanel(
                          padding: const EdgeInsets.all(9),
                          borderWidth: 2,
                          shadowOffset: const Offset(3, 3),
                          child: Text(
                            '${_session.snoozeCount}/${_session.maxSnoozes}',
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    formattedTime,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.displayLarge
                                        ?.copyWith(
                                          fontSize:
                                              MediaQuery.sizeOf(context).width >
                                                  420
                                              ? 110
                                              : 74,
                                        ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _session.alarmLabel.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.headlineLarge,
                                  ),
                                  const SizedBox(height: 28),
                                  if (_session.showsMissionQuietTimer) ...[
                                    _MissionQuietTimer(
                                      remaining: _remainingMissionQuietTime,
                                      total: _missionQuietWindow,
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  if (_session.awaitingMissionStart)
                                    _MissionEntryPanel(
                                      onStartMission: () {
                                        _runAction(context, () async {
                                          await ref
                                              .read(
                                                activeAlarmSessionControllerProvider,
                                              )
                                              .startMission();
                                          _syncMissionTimers();
                                        });
                                      },
                                    )
                                  else if (_session.requiresMission)
                                    missionDriver.buildRunner(
                                      context: context,
                                      session: _session,
                                      actions: MissionActionCallbacks(
                                        registerActivity:
                                            _registerMissionActivity,
                                        refreshSession: () {
                                          ref
                                              .read(
                                                activeAlarmSessionControllerProvider,
                                              )
                                              .refresh();
                                        },
                                        requestCameraPermission: () => ref
                                            .read(
                                              activeAlarmSessionControllerProvider,
                                            )
                                            .requestCameraPermission(),
                                        requestActivityRecognitionPermission: () => ref
                                            .read(
                                              activeAlarmSessionControllerProvider,
                                            )
                                            .requestActivityRecognitionPermission(),
                                        submitMathAnswer: (answer) async {
                                          try {
                                            return await ref
                                                .read(
                                                  activeAlarmSessionControllerProvider,
                                                )
                                                .submitMathAnswer(answer);
                                          } on PlatformException catch (error) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    error.message ?? error.code,
                                                  ),
                                                ),
                                              );
                                            }
                                            return MathAnswerSubmissionResult
                                                .incorrect;
                                          }
                                        },
                                      ),
                                    )
                                  else
                                    NeoActionButton(
                                      label: 'Dismiss',
                                      expand: true,
                                      backgroundColor: NeoColors.panel,
                                      onPressed: () => _runAction(
                                        context,
                                        () => ref
                                            .read(
                                              activeAlarmSessionControllerProvider,
                                            )
                                            .dismiss(),
                                      ),
                                    ),
                                  if (_showSnoozeButton) ...[
                                    const SizedBox(height: 16),
                                    NeoActionButton(
                                      label: _session.canSnooze
                                          ? 'Snooze ${_session.snoozeDurationMinutes} min'
                                          : 'Snooze limit reached',
                                      expand: true,
                                      backgroundColor: NeoColors.warm,
                                      onPressed: _session.canSnooze
                                          ? () => _runAction(
                                              context,
                                              () => ref
                                                  .read(
                                                    activeAlarmSessionControllerProvider,
                                                  )
                                                  .snooze(),
                                            )
                                          : null,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _headerLabel {
    if (_session.isMissionActive) {
      return 'MISSION ACTIVE';
    }
    if (_session.requiresMission) {
      return 'MISSION REQUIRED';
    }
    return 'ACTIVE ALARM';
  }

  bool get _showSnoozeButton {
    return !_session.requiresMission || _session.awaitingMissionStart;
  }

  Duration get _remainingMissionQuietTime {
    final missionTimeoutAt = _session.missionTimeoutAtLocal;
    if (missionTimeoutAt == null) {
      return Duration.zero;
    }

    final remaining = missionTimeoutAt.difference(DateTime.now());
    if (remaining.isNegative) {
      return Duration.zero;
    }
    return remaining;
  }

  void _syncMissionTimers() {
    _countdownTimer?.cancel();
    _missionRefreshTimer?.cancel();
    if (_session.isMissionActive) {
      _countdownTimer = Timer.periodic(_missionCountdownTick, (_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      });
      _missionRefreshTimer = Timer(_missionRefreshDelay, () {
        if (!mounted) {
          return;
        }
        ref.read(activeAlarmSessionControllerProvider).refresh();
      });
    }
  }

  Future<void> _registerMissionActivity() async {
    if (!_session.isMissionActive) {
      return;
    }

    _syncMissionTimers();

    final now = DateTime.now();
    if (_lastMissionPingAt != null &&
        now.difference(_lastMissionPingAt!) < _missionPingThrottle) {
      return;
    }
    _lastMissionPingAt = now;

    try {
      await ref
          .read(activeAlarmSessionControllerProvider)
          .registerMissionActivity();
    } on PlatformException {
      if (mounted) {
        ref.read(activeAlarmSessionControllerProvider).refresh();
      }
    }
  }

  Future<void> _runAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on PlatformException catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message ?? error.code)));
    }
  }
}

class _MissionQuietTimer extends StatelessWidget {
  const _MissionQuietTimer({required this.remaining, required this.total});

  final Duration remaining;
  final Duration total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remainingSeconds =
        remaining.inSeconds + (remaining.inMilliseconds % 1000 == 0 ? 0 : 1);
    final totalMillis = total.inMilliseconds;
    final remainingFraction = totalMillis == 0
        ? 0.0
        : (remaining.inMilliseconds / totalMillis).clamp(0.0, 1.0);

    return NeoPanel(
      color: NeoColors.warm,
      padding: const EdgeInsets.all(14),
      borderWidth: 2,
      shadowOffset: const Offset(3, 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('QUIET TIMER', style: theme.textTheme.labelLarge),
              const Spacer(),
              Text('$remainingSeconds s', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: remainingFraction,
              backgroundColor: NeoColors.panel,
              valueColor: const AlwaysStoppedAnimation<Color>(
                NeoColors.success,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep interacting or the alarm rings again when this expires.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MissionEntryPanel extends StatelessWidget {
  const _MissionEntryPanel({required this.onStartMission});

  final VoidCallback onStartMission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NeoPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Start mission', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 10),
          Text(
            'Silence the alarm and begin the mission. Idle for 30 seconds and it rings again.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          NeoActionButton(
            label: 'Start mission',
            expand: true,
            backgroundColor: NeoColors.cyan,
            onPressed: onStartMission,
          ),
        ],
      ),
    );
  }
}
