import 'package:alarms_oss/src/features/alarms/application/alarm_list_controller.dart';
import 'package:alarms_oss/src/features/alarms/domain/alarm_engine_status.dart';
import 'package:alarms_oss/src/features/alarms/domain/alarm_spec.dart';
import 'package:alarms_oss/src/features/alarms/presentation/alarm_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(alarmEngineStatusProvider);
      ref.invalidate(alarmListControllerProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alarms = ref.watch(alarmListControllerProvider);
    final engineStatus = ref.watch(alarmEngineStatusProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _createAlarm(context, ref, engineStatus.asData?.value);
        },
        label: const Text('Add alarm'),
        icon: const Icon(Icons.add_alarm),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF4EDE1), Color(0xFFE8DDCF), Color(0xFFD8CAB5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Text(
                'alarms-oss',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The alarm engine is live. Sprint 4 turns the dashboard into the control surface for device readiness and alarm policy.',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF56483A),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 28),
              _HeroStatusCard(engineStatus: engineStatus.asData?.value),
              const SizedBox(height: 16),
              _EngineStatusBanner(
                status: engineStatus,
                onRequestAccess: () {
                  _requestExactAlarmPermission(context);
                },
              ),
              _NotificationStatusBanner(
                status: engineStatus,
                onRequestAccess: () {
                  _requestNotificationPermission(context);
                },
              ),
              const SizedBox(height: 20),
              _DeviceDiagnosticsSection(
                status: engineStatus,
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
              ),
              const SizedBox(height: 20),
              Text(
                'Scheduled alarms',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _AlarmListSection(
                alarms: alarms,
                onEdit: (alarm) =>
                    _editAlarm(context, ref, alarm, engineStatus.asData?.value),
                onDelete: (alarm) => _deleteAlarm(context, ref, alarm),
                onToggle: (alarm, enabled) =>
                    _setEnabled(context, ref, alarm, enabled),
              ),
            ],
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

class _HeroStatusCard extends StatelessWidget {
  const _HeroStatusCard({required this.engineStatus});

  final AlarmEngineStatus? engineStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: const Color(0xFF1C160F),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0x33FFFFFF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Sprint 4 diagnostics pass',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Alarm delivery is now paired with device diagnostics and a fuller editor model.',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              engineStatus == null
                  ? 'Loading device scheduling state...'
                  : 'Device timezone: ${engineStatus!.timezoneId}\n'
                        'Exact alarms: ${engineStatus!.canScheduleExactAlarms ? 'ready' : 'permission required'}\n'
                        'Notifications: ${engineStatus!.notificationsEnabled ? 'ready' : 'permission required'}\n'
                        'Battery optimization: ${engineStatus!.batteryOptimizationIgnored ? 'ignored' : 'active'}\n'
                        'Camera: ${engineStatus!.cameraReady
                            ? 'ready'
                            : engineStatus!.hasCamera
                            ? 'permission required'
                            : 'unsupported'}\n'
                        'Steps: ${engineStatus!.stepsMissionReady
                            ? 'ready'
                            : engineStatus!.hasStepSensor
                            ? 'permission required'
                            : 'unsupported'}',
              style: const TextStyle(color: Color(0xFFE8DDCF), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _EngineStatusBanner extends StatelessWidget {
  const _EngineStatusBanner({required this.status, this.onRequestAccess});

  final AsyncValue<AlarmEngineStatus> status;
  final VoidCallback? onRequestAccess;

  @override
  Widget build(BuildContext context) {
    return status.when(
      data: (status) {
        if (status.canScheduleExactAlarms) {
          return const SizedBox.shrink();
        }

        return _InfoBanner(
          title: 'Exact alarm access is not available',
          detail:
              'Enabled alarms need exact-alarm capability. On Android 13+ the app should use the alarm-clock permission automatically; on Android 12L and lower, open the settings handoff below.',
          accent: Color(0xFFC85C3D),
          actionLabel: onRequestAccess == null ? null : 'Open access settings',
          onAction: onRequestAccess,
        );
      },
      loading: () => const _InfoBanner(
        title: 'Checking alarm engine state',
        detail: 'Loading exact-alarm capability and device timezone.',
        accent: Color(0xFF2B6A6C),
      ),
      error: (_, stackTrace) => const _InfoBanner(
        title: 'Alarm engine status could not be loaded',
        detail: 'The native bridge is unavailable or returned an error.',
        accent: Color(0xFFC85C3D),
      ),
    );
  }
}

class _NotificationStatusBanner extends StatelessWidget {
  const _NotificationStatusBanner({required this.status, this.onRequestAccess});

  final AsyncValue<AlarmEngineStatus> status;
  final VoidCallback? onRequestAccess;

  @override
  Widget build(BuildContext context) {
    return status.when(
      data: (status) {
        if (status.notificationsEnabled) {
          return const SizedBox.shrink();
        }

        return _InfoBanner(
          title: 'Notifications are disabled',
          detail:
              'The exact alarm can still ring, but Android will suppress notification affordances until notification access is granted.',
          accent: const Color(0xFFC85C3D),
          actionLabel: onRequestAccess == null ? null : 'Enable notifications',
          onAction: onRequestAccess,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

class _DeviceDiagnosticsSection extends StatelessWidget {
  const _DeviceDiagnosticsSection({
    required this.status,
    required this.onRequestExactAlarmAccess,
    required this.onRequestNotificationAccess,
    required this.onRequestBatteryOptimizationExemption,
    required this.onRequestCameraPermission,
    required this.onRequestActivityRecognitionPermission,
  });

  final AsyncValue<AlarmEngineStatus> status;
  final VoidCallback onRequestExactAlarmAccess;
  final VoidCallback onRequestNotificationAccess;
  final VoidCallback onRequestBatteryOptimizationExemption;
  final VoidCallback onRequestCameraPermission;
  final VoidCallback onRequestActivityRecognitionPermission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: const Color(0xFFFFFBF4),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: status.when(
          data: (status) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device diagnostics',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'These checks are the current ground truth for alarm delivery and future mission availability on this device.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF56483A),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                _DiagnosticTile(
                  title: 'Exact alarms',
                  statusLabel: status.canScheduleExactAlarms
                      ? 'Ready'
                      : 'Needs access',
                  detail: status.canScheduleExactAlarms
                      ? 'Exact scheduling is available.'
                      : 'Enabled alarms cannot be scheduled until exact-alarm access is available.',
                  accent: status.canScheduleExactAlarms
                      ? const Color(0xFF2B6A6C)
                      : const Color(0xFFC85C3D),
                  actionLabel: status.canScheduleExactAlarms
                      ? null
                      : 'Open settings',
                  onAction: status.canScheduleExactAlarms
                      ? null
                      : onRequestExactAlarmAccess,
                ),
                const SizedBox(height: 12),
                _DiagnosticTile(
                  title: 'Notifications',
                  statusLabel: status.notificationsEnabled
                      ? 'Ready'
                      : 'Needs access',
                  detail: status.notificationsEnabled
                      ? 'The ring service can surface high-priority notifications.'
                      : 'Foreground alarm UI still works, but notification affordances are suppressed until permission is granted.',
                  accent: status.notificationsEnabled
                      ? const Color(0xFF2B6A6C)
                      : const Color(0xFFC85C3D),
                  actionLabel: status.notificationsEnabled
                      ? null
                      : 'Enable notifications',
                  onAction: status.notificationsEnabled
                      ? null
                      : onRequestNotificationAccess,
                ),
                const SizedBox(height: 12),
                _DiagnosticTile(
                  title: 'Battery optimization',
                  statusLabel: status.batteryOptimizationIgnored
                      ? 'Ignored'
                      : 'Still active',
                  detail: status.batteryOptimizationIgnored
                      ? 'The app is already exempt from battery optimizations.'
                      : 'Exact alarms still fire, but some OEMs are more aggressive unless the app is exempt.',
                  accent: status.batteryOptimizationIgnored
                      ? const Color(0xFF2B6A6C)
                      : const Color(0xFFC85C3D),
                  actionLabel: status.batteryOptimizationIgnored
                      ? null
                      : 'Request exemption',
                  onAction: status.batteryOptimizationIgnored
                      ? null
                      : onRequestBatteryOptimizationExemption,
                ),
                const SizedBox(height: 12),
                _DiagnosticTile(
                  title: 'Camera mission readiness',
                  statusLabel: !status.hasCamera
                      ? 'Unsupported'
                      : status.cameraPermissionGranted
                      ? 'Ready'
                      : 'Permission required',
                  detail: !status.hasCamera
                      ? 'This device does not expose a usable camera to the app.'
                      : status.cameraPermissionGranted
                      ? 'Camera prerequisites are satisfied for the future QR mission.'
                      : 'Grant camera permission now so the QR mission path is ready when the native vision pipeline lands.',
                  accent: status.cameraReady
                      ? const Color(0xFF2B6A6C)
                      : const Color(0xFFC85C3D),
                  actionLabel:
                      (!status.hasCamera || status.cameraPermissionGranted)
                      ? null
                      : 'Grant camera',
                  onAction:
                      (!status.hasCamera || status.cameraPermissionGranted)
                      ? null
                      : onRequestCameraPermission,
                ),
                const SizedBox(height: 12),
                _DiagnosticTile(
                  title: 'Steps mission readiness',
                  statusLabel: !status.hasStepSensor
                      ? 'Unsupported'
                      : status.activityRecognitionGranted
                      ? 'Ready'
                      : 'Permission required',
                  detail: !status.hasStepSensor
                      ? 'This device does not expose a hardware step counter.'
                      : status.activityRecognitionGranted
                      ? 'Sensor prerequisites are satisfied for the future steps mission.'
                      : 'Grant activity recognition so the steps mission can be enabled when the mission runtime lands.',
                  accent: status.stepsMissionReady
                      ? const Color(0xFF2B6A6C)
                      : const Color(0xFFC85C3D),
                  actionLabel:
                      (!status.hasStepSensor ||
                          status.activityRecognitionGranted)
                      ? null
                      : 'Grant activity access',
                  onAction:
                      (!status.hasStepSensor ||
                          status.activityRecognitionGranted)
                      ? null
                      : onRequestActivityRecognitionPermission,
                ),
              ],
            );
          },
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Device diagnostics',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Loading device readiness checks...'),
            ],
          ),
          error: (error, stackTrace) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Device diagnostics',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text('$error'),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlarmListSection extends StatelessWidget {
  const _AlarmListSection({
    required this.alarms,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final AsyncValue<List<AlarmSpec>> alarms;
  final Future<void> Function(AlarmSpec alarm) onEdit;
  final Future<void> Function(AlarmSpec alarm) onDelete;
  final Future<void> Function(AlarmSpec alarm, bool enabled) onToggle;

  @override
  Widget build(BuildContext context) {
    return alarms.when(
      data: (alarms) {
        if (alarms.isEmpty) {
          return const _InfoBanner(
            title: 'No alarms yet',
            detail:
                'Create a one-time or repeating alarm to exercise the native store, exact scheduler, and Sprint 4 configuration flow.',
            accent: Color(0xFF2B6A6C),
          );
        }

        return Column(
          children: [
            for (final alarm in alarms) ...[
              _AlarmCard(
                alarm: alarm,
                onEdit: () => onEdit(alarm),
                onDelete: () => onDelete(alarm),
                onToggle: (enabled) => onToggle(alarm, enabled),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
      loading: () => const _InfoBanner(
        title: 'Loading alarms',
        detail: 'Fetching persisted alarms from the native Android store.',
        accent: Color(0xFF2B6A6C),
      ),
      error: (error, _) => _InfoBanner(
        title: 'Alarm loading failed',
        detail: '$error',
        accent: const Color(0xFFC85C3D),
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  const _AlarmCard({
    required this.alarm,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final AlarmSpec alarm;
  final Future<void> Function() onEdit;
  final Future<void> Function() onDelete;
  final Future<void> Function(bool enabled) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final nextTrigger = alarm.nextTriggerAtLocal;

    return Card(
      color: const Color(0xFFFFFBF4),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.formatTimeOfDay(
                          TimeOfDay(hour: alarm.hour, minute: alarm.minute),
                          alwaysUse24HourFormat:
                              MediaQuery.alwaysUse24HourFormatOf(context),
                        ),
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        alarm.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alarm.repeatSummary,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF56483A),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: alarm.enabled,
                  onChanged: (enabled) {
                    onToggle(enabled);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Next trigger',
              value: nextTrigger == null
                  ? 'Not scheduled'
                  : '${_weekdayLabel(nextTrigger.weekday)}, ${nextTrigger.month}/${nextTrigger.day} ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(nextTrigger), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}',
            ),
            const SizedBox(height: 8),
            _InfoRow(label: 'Timezone', value: alarm.timezoneId),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Snooze policy',
              value:
                  '${alarm.snoozeDurationMinutes} min | ${alarm.maxSnoozes} max',
            ),
            const SizedBox(height: 8),
            _InfoRow(label: 'Ringtone', value: alarm.ringtoneSummary),
            const SizedBox(height: 8),
            _InfoRow(label: 'Dismissal', value: alarm.missionSummary),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    onEdit();
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    onDelete();
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticTile extends StatelessWidget {
  const _DiagnosticTile({
    required this.title,
    required this.statusLabel,
    required this.detail,
    required this.accent,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String statusLabel;
  final String detail;
  final Color accent;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF5EEE2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              detail,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF56483A),
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.title,
    required this.detail,
    required this.accent,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String detail;
  final Color accent;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: const Color(0xFFFFFBF4),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
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
                      height: 1.45,
                    ),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF56483A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

String _weekdayLabel(int weekday) {
  return switch (weekday) {
    DateTime.monday => 'Mon',
    DateTime.tuesday => 'Tue',
    DateTime.wednesday => 'Wed',
    DateTime.thursday => 'Thu',
    DateTime.friday => 'Fri',
    DateTime.saturday => 'Sat',
    DateTime.sunday => 'Sun',
    _ => '',
  };
}
