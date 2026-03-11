import 'package:alarms_oss/src/features/alarms/domain/alarm_mission.dart';
import 'package:alarms_oss/src/features/alarms/domain/alarm_engine_status.dart';
import 'package:alarms_oss/src/features/alarms/domain/active_alarm_session.dart';
import 'package:alarms_oss/src/features/missions/presentation/math_mission_runner.dart';
import 'package:alarms_oss/src/features/missions/presentation/steps_mission_runner.dart';
import 'package:alarms_oss/src/platform/missions/mission_driver.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final missionRegistryProvider = Provider<MissionRegistry>((ref) {
  return const MissionRegistry([
    _DirectDismissMissionDriver(),
    MathMissionDriver(),
    StepsMissionDriver(),
    _UnsupportedMissionDriver(type: AlarmMissionType.qr),
  ]);
});

class MissionRegistry {
  const MissionRegistry(this._drivers);

  final List<MissionDriver> _drivers;

  List<AlarmMissionType> editorMissionTypes({AlarmEngineStatus? diagnostics}) {
    return _drivers
        .map((driver) => driver.type)
        .where(
          (type) => isConfigurableForEditor(type, diagnostics: diagnostics),
        )
        .toList(growable: false);
  }

  MissionDriver driverFor(AlarmMissionType type) {
    return _drivers.firstWhere((driver) => driver.type == type);
  }

  bool isConfigurableForEditor(
    AlarmMissionType type, {
    AlarmEngineStatus? diagnostics,
  }) {
    return switch (type) {
      AlarmMissionType.none => true,
      AlarmMissionType.math => true,
      AlarmMissionType.steps => diagnostics?.stepsMissionReady ?? false,
      AlarmMissionType.qr => false,
    };
  }
}

class _DirectDismissMissionDriver implements MissionDriver {
  const _DirectDismissMissionDriver();

  @override
  AlarmMissionType get type => AlarmMissionType.none;

  @override
  Widget buildRunner({
    required BuildContext context,
    required ActiveAlarmSession session,
    required MissionActionCallbacks actions,
  }) {
    return const SizedBox.shrink();
  }
}

class _UnsupportedMissionDriver implements MissionDriver {
  const _UnsupportedMissionDriver({required this.type});

  @override
  final AlarmMissionType type;

  @override
  Widget buildRunner({
    required BuildContext context,
    required ActiveAlarmSession session,
    required MissionActionCallbacks actions,
  }) {
    return const SizedBox.shrink();
  }
}
