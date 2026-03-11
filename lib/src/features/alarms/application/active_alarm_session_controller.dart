import 'package:neoalarm/src/features/alarms/application/alarm_list_controller.dart';
import 'package:neoalarm/src/features/alarms/data/alarm_repository.dart';
import 'package:neoalarm/src/features/alarms/domain/active_alarm_session.dart';
import 'package:neoalarm/src/features/alarms/domain/alarm_mission.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final activeAlarmSessionProvider = FutureProvider<ActiveAlarmSession?>(
  (ref) => ref.watch(alarmRepositoryProvider).getActiveAlarmSession(),
);

final activeAlarmSessionControllerProvider =
    Provider<ActiveAlarmSessionController>(
      (ref) => ActiveAlarmSessionController(ref),
    );

class ActiveAlarmSessionController {
  const ActiveAlarmSessionController(this._ref);

  final Ref _ref;

  AlarmRepository get _repository => _ref.read(alarmRepositoryProvider);

  Future<void> dismiss() async {
    await _repository.dismissActiveAlarmSession();
    _ref.invalidate(activeAlarmSessionProvider);
    _ref.invalidate(alarmListControllerProvider);
  }

  Future<void> snooze() async {
    await _repository.snoozeActiveAlarmSession();
    _ref.invalidate(activeAlarmSessionProvider);
    _ref.invalidate(alarmListControllerProvider);
  }

  Future<void> startMission() async {
    await _repository.startMission();
    _ref.invalidate(activeAlarmSessionProvider);
  }

  Future<void> registerMissionActivity() async {
    await _repository.registerMissionActivity();
    _ref.invalidate(activeAlarmSessionProvider);
  }

  Future<void> requestActivityRecognitionPermission() async {
    await _repository.requestActivityRecognitionPermission();
    _ref.invalidate(activeAlarmSessionProvider);
  }

  Future<void> requestCameraPermission() async {
    await _repository.requestCameraPermission();
    _ref.invalidate(activeAlarmSessionProvider);
  }

  Future<MathAnswerSubmissionResult> submitMathAnswer(String answer) async {
    final result = await _repository.submitMathAnswer(answer);
    _ref.invalidate(activeAlarmSessionProvider);
    _ref.invalidate(alarmListControllerProvider);
    return result;
  }

  void refresh() {
    _ref.invalidate(activeAlarmSessionProvider);
  }
}
