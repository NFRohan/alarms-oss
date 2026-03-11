import 'package:alarms_oss/src/app/app.dart';
import 'package:alarms_oss/src/features/alarms/application/alarm_list_controller.dart';
import 'package:alarms_oss/src/features/alarms/data/alarm_repository.dart';
import 'package:alarms_oss/src/features/alarms/domain/active_alarm_session.dart';
import 'package:alarms_oss/src/features/alarms/domain/alarm_engine_status.dart';
import 'package:alarms_oss/src/features/alarms/domain/alarm_mission.dart';
import 'package:alarms_oss/src/features/alarms/domain/alarm_spec.dart';
import 'package:alarms_oss/src/features/app_startup/domain/app_startup_context.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('renders dashboard shell', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alarmRepositoryProvider.overrideWithValue(_FakeAlarmRepository()),
        ],
        child: const AlarmApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ALRM'), findsOneWidget);
    expect(find.text('READY TO RING'), findsOneWidget);
  });

  testWidgets('renders direct-boot-safe shell before unlock', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alarmRepositoryProvider.overrideWithValue(
            _FakeAlarmRepository(
              startupContext: const AppStartupContext(userUnlocked: false),
            ),
          ),
        ],
        child: const AlarmApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DIRECT BOOT MODE'), findsOneWidget);
    expect(find.textContaining('Unlock the device'), findsOneWidget);
  });
}

class _FakeAlarmRepository implements AlarmRepository {
  _FakeAlarmRepository({
    this.startupContext = const AppStartupContext(userUnlocked: true),
  });

  final AppStartupContext startupContext;

  @override
  Future<void> deleteAlarm(String id) async {}

  @override
  Future<void> dismissActiveAlarmSession() async {}

  @override
  Future<void> snoozeActiveAlarmSession() async {}

  @override
  Future<void> startMission() async {}

  @override
  Future<void> registerMissionActivity() async {}

  @override
  Future<MathAnswerSubmissionResult> submitMathAnswer(String answer) async {
    return MathAnswerSubmissionResult.incorrect;
  }

  @override
  Future<AlarmEngineStatus> getStatus() async {
    return const AlarmEngineStatus(
      canScheduleExactAlarms: true,
      notificationsEnabled: true,
      batteryOptimizationIgnored: false,
      hasCamera: true,
      cameraPermissionGranted: false,
      hasStepSensor: true,
      activityRecognitionGranted: false,
      timezoneId: 'UTC',
    );
  }

  @override
  Future<AppStartupContext> getStartupContext() async {
    return startupContext;
  }

  @override
  Future<ActiveAlarmSession?> getActiveAlarmSession() async {
    return null;
  }

  @override
  Future<void> requestActivityRecognitionPermission() async {}

  @override
  Future<void> requestBatteryOptimizationExemption() async {}

  @override
  Future<void> requestCameraPermission() async {}

  @override
  Future<void> requestExactAlarmPermission() async {}

  @override
  Future<void> requestNotificationPermission() async {}

  @override
  Future<List<AlarmSpec>> listAlarms() async {
    return const [];
  }

  @override
  Future<void> rescheduleAll() async {}

  @override
  Future<AlarmSpec> setAlarmEnabled({
    required String id,
    required bool enabled,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AlarmSpec> upsertAlarm(AlarmSpec alarm) async {
    return alarm;
  }
}
