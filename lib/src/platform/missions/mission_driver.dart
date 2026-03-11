import 'package:neoalarm/src/features/alarms/domain/active_alarm_session.dart';
import 'package:neoalarm/src/features/alarms/domain/alarm_mission.dart';
import 'package:flutter/widgets.dart';

class MissionActionCallbacks {
  const MissionActionCallbacks({
    required this.registerActivity,
    required this.refreshSession,
    required this.requestCameraPermission,
    required this.requestActivityRecognitionPermission,
    required this.submitMathAnswer,
  });

  final Future<void> Function() registerActivity;
  final VoidCallback refreshSession;
  final Future<void> Function() requestCameraPermission;
  final Future<void> Function() requestActivityRecognitionPermission;

  final Future<MathAnswerSubmissionResult> Function(String answer)
  submitMathAnswer;
}

abstract class MissionDriver {
  AlarmMissionType get type;

  Widget buildRunner({
    required BuildContext context,
    required ActiveAlarmSession session,
    required MissionActionCallbacks actions,
  });
}
