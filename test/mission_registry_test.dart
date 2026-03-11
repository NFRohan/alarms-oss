import 'package:neoalarm/src/features/alarms/domain/alarm_engine_status.dart';
import 'package:neoalarm/src/features/alarms/domain/active_alarm_session.dart';
import 'package:neoalarm/src/features/alarms/domain/alarm_mission.dart';
import 'package:neoalarm/src/features/missions/application/mission_registry.dart';
import 'package:neoalarm/src/platform/missions/mission_driver.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const registry = MissionRegistry([
    _TestMissionDriver(AlarmMissionType.none),
    _TestMissionDriver(AlarmMissionType.math),
    _TestMissionDriver(AlarmMissionType.steps),
    _TestMissionDriver(AlarmMissionType.qr),
  ]);

  test('hides steps from the editor when activity recognition is denied', () {
    const diagnostics = AlarmEngineStatus(
      canScheduleExactAlarms: true,
      notificationsEnabled: true,
      batteryOptimizationIgnored: true,
      hasCamera: true,
      cameraPermissionGranted: true,
      hasStepSensor: true,
      activityRecognitionGranted: false,
      timezoneId: 'UTC',
    );

    expect(
      registry.editorMissionTypes(diagnostics: diagnostics),
      equals([
        AlarmMissionType.none,
        AlarmMissionType.math,
        AlarmMissionType.qr,
      ]),
    );
  });

  test(
    'shows steps in the editor only when the detector and permission are ready',
    () {
      const diagnostics = AlarmEngineStatus(
        canScheduleExactAlarms: true,
        notificationsEnabled: true,
        batteryOptimizationIgnored: true,
        hasCamera: true,
        cameraPermissionGranted: true,
        hasStepSensor: true,
        activityRecognitionGranted: true,
        timezoneId: 'UTC',
      );

      expect(
        registry.editorMissionTypes(diagnostics: diagnostics),
        equals([
          AlarmMissionType.none,
          AlarmMissionType.math,
          AlarmMissionType.steps,
          AlarmMissionType.qr,
        ]),
      );
    },
  );

  test('hides QR from the editor when camera permission is denied', () {
    const diagnostics = AlarmEngineStatus(
      canScheduleExactAlarms: true,
      notificationsEnabled: true,
      batteryOptimizationIgnored: true,
      hasCamera: true,
      cameraPermissionGranted: false,
      hasStepSensor: true,
      activityRecognitionGranted: true,
      timezoneId: 'UTC',
    );

    expect(
      registry.editorMissionTypes(diagnostics: diagnostics),
      equals([
        AlarmMissionType.none,
        AlarmMissionType.math,
        AlarmMissionType.steps,
      ]),
    );
  });
}

class _TestMissionDriver implements MissionDriver {
  const _TestMissionDriver(this.type);

  @override
  final AlarmMissionType type;

  @override
  Widget buildRunner({
    required BuildContext context,
    required ActiveAlarmSession session,
    required MissionActionCallbacks actions,
  }) {
    throw UnimplementedError();
  }
}
