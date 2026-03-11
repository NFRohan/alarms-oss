import 'package:alarms_oss/src/features/alarms/domain/alarm_spec.dart';
import 'package:alarms_oss/src/features/alarms/domain/alarm_mission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes and deserializes alarm specs', () {
    final original = AlarmSpec(
      id: 'alarm-1',
      label: 'Morning',
      hour: 7,
      minute: 30,
      timezoneId: 'Asia/Dhaka',
      enabled: true,
      weekdays: const [
        AlarmWeekday.monday,
        AlarmWeekday.wednesday,
        AlarmWeekday.friday,
      ],
      ringtone: AlarmRingtone.systemNotification,
      snoozeDurationMinutes: 9,
      maxSnoozes: 3,
      mission: const MissionSpec.math(
        difficulty: MathMissionDifficulty.hard,
        problemCount: 4,
      ),
      nextTriggerAtUtc: DateTime.utc(2026, 3, 12, 1, 30),
    );

    final roundTrip = AlarmSpec.fromMap(original.toMap());

    expect(roundTrip.id, original.id);
    expect(roundTrip.label, original.label);
    expect(roundTrip.hour, original.hour);
    expect(roundTrip.minute, original.minute);
    expect(roundTrip.timezoneId, original.timezoneId);
    expect(roundTrip.enabled, isTrue);
    expect(roundTrip.weekdays, original.weekdays);
    expect(roundTrip.ringtone, original.ringtone);
    expect(roundTrip.mission.type, original.mission.type);
    expect(roundTrip.mission.mathDifficulty, original.mission.mathDifficulty);
    expect(
      roundTrip.mission.mathProblemCount,
      original.mission.mathProblemCount,
    );
    expect(roundTrip.nextTriggerAtUtc, original.nextTriggerAtUtc);
  });

  test('uses one-time summary when no weekdays are selected', () {
    final alarm = AlarmSpec.createDraft(timezoneId: 'UTC');

    expect(alarm.repeatSummary, 'One time');
  });

  test('serializes and deserializes steps mission config', () {
    final original = AlarmSpec(
      id: 'alarm-2',
      label: 'Walk',
      hour: 6,
      minute: 45,
      timezoneId: 'UTC',
      enabled: true,
      weekdays: const [],
      ringtone: AlarmRingtone.systemAlarm,
      snoozeDurationMinutes: 5,
      maxSnoozes: 1,
      mission: const MissionSpec.steps(goal: 50),
      nextTriggerAtUtc: null,
    );

    final roundTrip = AlarmSpec.fromMap(original.toMap());

    expect(roundTrip.mission.type, AlarmMissionType.steps);
    expect(roundTrip.mission.stepGoal, 50);
  });

  test('serializes and deserializes QR mission config', () {
    final original = AlarmSpec(
      id: 'alarm-3',
      label: 'Bathroom QR',
      hour: 8,
      minute: 15,
      timezoneId: 'UTC',
      enabled: true,
      weekdays: const [],
      ringtone: AlarmRingtone.systemAlarm,
      snoozeDurationMinutes: 9,
      maxSnoozes: 0,
      mission: const MissionSpec.qr(targetValue: 'sink-qr-target'),
      nextTriggerAtUtc: null,
    );

    final roundTrip = AlarmSpec.fromMap(original.toMap());

    expect(roundTrip.mission.type, AlarmMissionType.qr);
    expect(roundTrip.mission.qrTargetValue, 'sink-qr-target');
    expect(roundTrip.mission.hasQrTarget, isTrue);
  });
}
