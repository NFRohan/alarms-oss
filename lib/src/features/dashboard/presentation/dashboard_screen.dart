import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neoalarm/src/core/theme/app_theme.dart';
import 'package:neoalarm/src/core/ui/neo_brutal_widgets.dart';
import 'package:neoalarm/src/features/alarms/application/alarm_list_controller.dart';
import 'package:neoalarm/src/features/alarms/domain/alarm_engine_status.dart';
import 'package:neoalarm/src/features/alarms/domain/alarm_spec.dart';
import 'package:neoalarm/src/features/alarms/presentation/alarm_editor_sheet.dart';
import 'package:neoalarm/src/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:neoalarm/src/features/onboarding/application/onboarding_controller.dart';
import 'package:neoalarm/src/features/settings/application/theme_mode_controller.dart';
import 'package:neoalarm/src/features/settings/presentation/settings_screen.dart';

enum _DashboardTab { alarms, settings }

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  _DashboardTab _selectedTab = _DashboardTab.alarms;
  Timer? _countdownTicker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _countdownTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(alarmEngineStatusProvider);
      if (_selectedTab == _DashboardTab.alarms) {
        ref.invalidate(alarmListControllerProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final alarms = ref.watch(alarmListControllerProvider);
    final engineStatus = ref.watch(alarmEngineStatusProvider);
    final themeMode = ref.watch(appThemeModeControllerProvider);
    final showAddAlarm = _selectedTab == _DashboardTab.alarms;

    return PopScope<Object?>(
      canPop: _selectedTab == _DashboardTab.alarms,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedTab == _DashboardTab.settings) {
          setState(() {
            _selectedTab = _DashboardTab.alarms;
          });
        }
      },
      child: Scaffold(
        backgroundColor: NeoColors.paper,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: showAddAlarm
            ? Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: NeoSquareIconButton(
                  icon: Icons.add,
                  backgroundColor: NeoColors.primary,
                  foregroundColor: NeoColors.accentInk,
                  size: 76,
                  onPressed: () {
                    _createAlarm(context, ref, engineStatus.asData?.value);
                  },
                ),
              )
            : null,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _selectedTab == _DashboardTab.alarms
              ? AlarmDashboardPage(
                  key: const ValueKey('alarms-tab'),
                  alarms: alarms,
                  engineStatus: engineStatus,
                  nextAlarmCountdownText: nextAlarmCountdownText(
                    alarms.asData?.value ?? const [],
                  ),
                  onRequestExactAlarmPermission: () {
                    _requestExactAlarmPermission(context);
                  },
                  onRequestNotificationPermission: () {
                    _requestNotificationPermission(context);
                  },
                  onOpenSettings: () {
                    setState(() {
                      _selectedTab = _DashboardTab.settings;
                    });
                  },
                  onEdit: (alarm) => _editAlarm(
                    context,
                    ref,
                    alarm,
                    engineStatus.asData?.value,
                  ),
                  onDelete: (alarm) => _deleteAlarm(context, ref, alarm),
                  onSkipNext: (alarm) => _skipNextOccurrence(context, ref, alarm),
                  onClearSkippedOccurrence: (alarm) =>
                      _clearSkippedOccurrence(context, ref, alarm),
                  onToggle: (alarm, enabled) =>
                      _setEnabled(context, ref, alarm, enabled),
                )
              : SettingsScreen(
                  key: const ValueKey('settings-tab'),
                  status: engineStatus,
                  themeMode: themeMode,
                  onBack: () {
                    setState(() {
                      _selectedTab = _DashboardTab.alarms;
                    });
                  },
                  onSetDarkModeEnabled: (enabled) => ref
                      .read(appThemeModeControllerProvider.notifier)
                      .setDarkModeEnabled(enabled),
                  onRequestExactAlarmAccess: () {
                    _requestExactAlarmPermission(context);
                  },
                  onRequestNotificationAccess: () {
                    _requestNotificationPermission(context);
                  },
                  onRequestBatteryOptimizationExemption: () {
                    _requestBatteryOptimizationExemption(context);
                  },
                  onRequestCameraPermission: () {
                    _requestCameraPermission(context);
                  },
                  onRequestActivityRecognitionPermission: () {
                    _requestActivityRecognitionPermission(context);
                  },
                  onRunOnboarding: () async {
                    await ref
                        .read(onboardingControllerProvider.notifier)
                        .resetOnboarding();
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _createAlarm(
    BuildContext context,
    WidgetRef ref,
    AlarmEngineStatus? engineStatus,
  ) async {
    final draft = AlarmSpec.createDraft(
      timezoneId: engineStatus?.timezoneId ?? 'UTC',
    );
    final edited = await AlarmEditorSheet.show(
      context,
      alarm: draft,
      engineStatus: engineStatus,
    );
    if (edited == null || !context.mounted) {
      return;
    }

    await _runRepositoryAction(
      context,
      () => ref.read(alarmListControllerProvider.notifier).saveAlarm(edited),
    );
  }

  Future<void> _editAlarm(
    BuildContext context,
    WidgetRef ref,
    AlarmSpec alarm,
    AlarmEngineStatus? engineStatus,
  ) async {
    final edited = await AlarmEditorSheet.show(
      context,
      alarm: alarm,
      engineStatus: engineStatus,
    );
    if (edited == null || !context.mounted) {
      return;
    }

    await _runRepositoryAction(
      context,
      () => ref.read(alarmListControllerProvider.notifier).saveAlarm(edited),
    );
  }

  Future<void> _deleteAlarm(
    BuildContext context,
    WidgetRef ref,
    AlarmSpec alarm,
  ) async {
    await _runRepositoryAction(
      context,
      () =>
          ref.read(alarmListControllerProvider.notifier).deleteAlarm(alarm.id),
    );
  }

  Future<void> _setEnabled(
    BuildContext context,
    WidgetRef ref,
    AlarmSpec alarm,
    bool enabled,
  ) async {
    await _runRepositoryAction(
      context,
      () => ref
          .read(alarmListControllerProvider.notifier)
          .setEnabled(id: alarm.id, enabled: enabled),
    );
  }

  Future<void> _skipNextOccurrence(
    BuildContext context,
    WidgetRef ref,
    AlarmSpec alarm,
  ) async {
    await _runRepositoryAction(
      context,
      () => ref
          .read(alarmListControllerProvider.notifier)
          .skipNextOccurrence(alarm.id),
    );
  }

  Future<void> _clearSkippedOccurrence(
    BuildContext context,
    WidgetRef ref,
    AlarmSpec alarm,
  ) async {
    await _runRepositoryAction(
      context,
      () => ref
          .read(alarmListControllerProvider.notifier)
          .clearSkippedOccurrence(alarm.id),
    );
  }

  Future<void> _runRepositoryAction(
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

  Future<void> _requestExactAlarmPermission(BuildContext context) async {
    await _runRepositoryAction(
      context,
      () => ref.read(alarmRepositoryProvider).requestExactAlarmPermission(),
    );
  }

  Future<void> _requestNotificationPermission(BuildContext context) async {
    await _runRepositoryAction(
      context,
      () => ref.read(alarmRepositoryProvider).requestNotificationPermission(),
    );
  }

  Future<void> _requestBatteryOptimizationExemption(
    BuildContext context,
  ) async {
    await _runRepositoryAction(
      context,
      () => ref
          .read(alarmRepositoryProvider)
          .requestBatteryOptimizationExemption(),
    );
  }

  Future<void> _requestCameraPermission(BuildContext context) async {
    await _runRepositoryAction(
      context,
      () => ref.read(alarmRepositoryProvider).requestCameraPermission(),
    );
  }

  Future<void> _requestActivityRecognitionPermission(
    BuildContext context,
  ) async {
    await _runRepositoryAction(
      context,
      () => ref
          .read(alarmRepositoryProvider)
          .requestActivityRecognitionPermission(),
    );
  }
}
