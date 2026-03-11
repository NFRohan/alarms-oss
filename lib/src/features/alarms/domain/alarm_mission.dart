const minMathMissionProblemCount = 1;
const maxMathMissionProblemCount = 5;
const defaultStepMissionGoal = 30;
const minStepMissionGoal = 10;
const maxStepMissionGoal = 100;
const minQrTargetLength = 1;

int _normalizeMathMissionProblemCount(int? value) {
  final resolved = value ?? minMathMissionProblemCount;
  return resolved
      .clamp(minMathMissionProblemCount, maxMathMissionProblemCount)
      .toInt();
}

int _normalizeStepMissionGoal(int? value) {
  final resolved = value ?? defaultStepMissionGoal;
  return resolved.clamp(minStepMissionGoal, maxStepMissionGoal).toInt();
}

String? _normalizeQrTargetValue(String? value) {
  final resolved = value?.trim();
  if (resolved == null || resolved.isEmpty) {
    return null;
  }
  return resolved.length >= minQrTargetLength ? resolved : null;
}

enum AlarmMissionType {
  none('none', 'Direct dismiss', 'Dismiss button is immediately available.'),
  math('math', 'Math mission', 'Solve a math challenge to dismiss.'),
  steps(
    'steps',
    'Steps mission',
    'Requires a step sensor and activity recognition.',
  ),
  qr('qr', 'QR mission', 'Requires a camera and camera permission.');

  const AlarmMissionType(this.id, this.label, this.description);

  final String id;
  final String label;
  final String description;

  static AlarmMissionType fromId(String? value) {
    return AlarmMissionType.values.firstWhere(
      (missionType) => missionType.id == value,
      orElse: () => AlarmMissionType.none,
    );
  }
}

enum MathMissionDifficulty {
  easy('easy', 'Easy'),
  standard('standard', 'Standard'),
  hard('hard', 'Hard');

  const MathMissionDifficulty(this.id, this.label);

  final String id;
  final String label;

  static MathMissionDifficulty fromId(String? value) {
    return MathMissionDifficulty.values.firstWhere(
      (difficulty) => difficulty.id == value,
      orElse: () => MathMissionDifficulty.standard,
    );
  }
}

class MissionSpec {
  const MissionSpec({
    required this.type,
    this.mathDifficulty = MathMissionDifficulty.standard,
    this.mathProblemCount = minMathMissionProblemCount,
    this.stepGoal = defaultStepMissionGoal,
    this.qrTargetValue,
  }) : assert(
         type != AlarmMissionType.math ||
             (mathProblemCount >= minMathMissionProblemCount &&
                 mathProblemCount <= maxMathMissionProblemCount),
       ),
       assert(
         type != AlarmMissionType.steps ||
             (stepGoal >= minStepMissionGoal && stepGoal <= maxStepMissionGoal),
       ),
       assert(
         type != AlarmMissionType.qr ||
             qrTargetValue == null ||
             qrTargetValue.length >= minQrTargetLength,
       );

  const MissionSpec.none() : this(type: AlarmMissionType.none);

  const MissionSpec.math({
    MathMissionDifficulty difficulty = MathMissionDifficulty.standard,
    int problemCount = minMathMissionProblemCount,
  }) : this(
         type: AlarmMissionType.math,
         mathDifficulty: difficulty,
         mathProblemCount: problemCount,
       );

  const MissionSpec.steps({int goal = defaultStepMissionGoal})
    : this(type: AlarmMissionType.steps, stepGoal: goal);

  const MissionSpec.qr({String? targetValue})
    : this(type: AlarmMissionType.qr, qrTargetValue: targetValue);

  factory MissionSpec.fromMap(
    Map<Object?, Object?>? raw, {
    String? fallbackType,
  }) {
    final type = AlarmMissionType.fromId(
      (raw?['type'] ?? fallbackType) as String?,
    );
    final config = raw?['config'] as Map<Object?, Object?>?;

    return switch (type) {
      AlarmMissionType.none => const MissionSpec.none(),
      AlarmMissionType.math => MissionSpec.math(
        difficulty: MathMissionDifficulty.fromId(
          config?['difficulty'] as String?,
        ),
        problemCount: _normalizeMathMissionProblemCount(
          (config?['problemCount'] as num?)?.toInt(),
        ),
      ),
      AlarmMissionType.steps => MissionSpec.steps(
        goal: _normalizeStepMissionGoal((config?['goal'] as num?)?.toInt()),
      ),
      AlarmMissionType.qr => MissionSpec.qr(
        targetValue: _normalizeQrTargetValue(config?['targetValue'] as String?),
      ),
    };
  }

  final AlarmMissionType type;
  final MathMissionDifficulty mathDifficulty;
  final int mathProblemCount;
  final int stepGoal;
  final String? qrTargetValue;

  bool get isDirectDismiss => type == AlarmMissionType.none;

  bool get hasQrTarget =>
      (qrTargetValue?.trim().isNotEmpty ?? false) &&
      type == AlarmMissionType.qr;

  String get summary {
    return switch (type) {
      AlarmMissionType.none => type.label,
      AlarmMissionType.math =>
        '${type.label} - ${mathDifficulty.label} - $mathProblemCount ${mathProblemCount == 1 ? 'problem' : 'problems'}',
      AlarmMissionType.steps => '${type.label} - $stepGoal steps',
      AlarmMissionType.qr =>
        hasQrTarget
            ? '${type.label} - target saved'
            : '${type.label} - target missing',
    };
  }

  Map<String, Object?> toMap() {
    return {
      'type': type.id,
      'config': switch (type) {
        AlarmMissionType.math => {
          'difficulty': mathDifficulty.id,
          'problemCount': mathProblemCount,
        },
        AlarmMissionType.steps => {'goal': stepGoal},
        AlarmMissionType.qr => {
          'targetValue': _normalizeQrTargetValue(qrTargetValue),
        },
        _ => <String, Object?>{},
      },
    };
  }

  MissionSpec copyWith({
    AlarmMissionType? type,
    MathMissionDifficulty? mathDifficulty,
    int? mathProblemCount,
    int? stepGoal,
    String? qrTargetValue,
  }) {
    final resolvedType = type ?? this.type;
    return switch (resolvedType) {
      AlarmMissionType.none => const MissionSpec.none(),
      AlarmMissionType.math => MissionSpec.math(
        difficulty: mathDifficulty ?? this.mathDifficulty,
        problemCount: _normalizeMathMissionProblemCount(
          mathProblemCount ?? this.mathProblemCount,
        ),
      ),
      AlarmMissionType.steps => MissionSpec.steps(
        goal: _normalizeStepMissionGoal(stepGoal ?? this.stepGoal),
      ),
      AlarmMissionType.qr => MissionSpec.qr(
        targetValue:
            _normalizeQrTargetValue(qrTargetValue) ??
            _normalizeQrTargetValue(this.qrTargetValue),
      ),
    };
  }
}

enum ActiveAlarmSessionState {
  ringing('ringing'),
  missionActive('mission_active'),
  snoozed('snoozed');

  const ActiveAlarmSessionState(this.id);

  final String id;

  static ActiveAlarmSessionState fromId(String? value) {
    return ActiveAlarmSessionState.values.firstWhere(
      (state) => state.id == value,
      orElse: () => ActiveAlarmSessionState.ringing,
    );
  }
}

enum ActiveMissionStatus {
  pending('pending'),
  completed('completed');

  const ActiveMissionStatus(this.id);

  final String id;

  static ActiveMissionStatus fromId(String? value) {
    return ActiveMissionStatus.values.firstWhere(
      (status) => status.id == value,
      orElse: () => ActiveMissionStatus.pending,
    );
  }
}

enum MathAnswerSubmissionResult {
  incorrect('incorrect'),
  advanced('advanced'),
  completed('completed');

  const MathAnswerSubmissionResult(this.id);

  final String id;

  static MathAnswerSubmissionResult fromId(String? value) {
    return MathAnswerSubmissionResult.values.firstWhere(
      (result) => result.id == value,
      orElse: () => MathAnswerSubmissionResult.incorrect,
    );
  }
}

enum StepMissionTrackingState {
  awaitingSteps('awaiting_steps'),
  tracking('tracking'),
  missingPermission('missing_permission'),
  unsupportedSensor('unsupported_sensor');

  const StepMissionTrackingState(this.id);

  final String id;

  static StepMissionTrackingState fromId(String? value) {
    return StepMissionTrackingState.values.firstWhere(
      (state) => state.id == value,
      orElse: () => StepMissionTrackingState.awaitingSteps,
    );
  }
}

enum QrMissionTrackingState {
  awaitingScan('awaiting_scan'),
  tracking('tracking'),
  targetMissing('target_missing'),
  missingPermission('missing_permission'),
  unsupportedCamera('unsupported_camera');

  const QrMissionTrackingState(this.id);

  final String id;

  static QrMissionTrackingState fromId(String? value) {
    return QrMissionTrackingState.values.firstWhere(
      (state) => state.id == value,
      orElse: () => QrMissionTrackingState.awaitingScan,
    );
  }
}

class MathChallengeSnapshot {
  const MathChallengeSnapshot({
    required this.leftOperand,
    required this.rightOperand,
    required this.operatorSymbol,
    required this.attemptCount,
  });

  factory MathChallengeSnapshot.fromMap(Map<Object?, Object?> raw) {
    return MathChallengeSnapshot(
      leftOperand: (raw['leftOperand']! as num).toInt(),
      rightOperand: (raw['rightOperand']! as num).toInt(),
      operatorSymbol: raw['operatorSymbol']! as String,
      attemptCount: (raw['attemptCount']! as num).toInt(),
    );
  }

  final int leftOperand;
  final int rightOperand;
  final String operatorSymbol;
  final int attemptCount;

  String get prompt => '$leftOperand $operatorSymbol $rightOperand';
}

class StepProgressSnapshot {
  const StepProgressSnapshot({
    required this.completedSteps,
    required this.targetSteps,
    required this.trackingState,
  });

  factory StepProgressSnapshot.fromMap(Map<Object?, Object?> raw) {
    return StepProgressSnapshot(
      completedSteps: (raw['completedSteps'] as num?)?.toInt() ?? 0,
      targetSteps: _normalizeStepMissionGoal(
        (raw['targetSteps'] as num?)?.toInt(),
      ),
      trackingState: StepMissionTrackingState.fromId(
        raw['trackingState'] as String?,
      ),
    );
  }

  final int completedSteps;
  final int targetSteps;
  final StepMissionTrackingState trackingState;

  int get remainingSteps =>
      (targetSteps - completedSteps).clamp(0, targetSteps).toInt();

  bool get isAwaitingSteps =>
      trackingState == StepMissionTrackingState.awaitingSteps;

  bool get isTracking => trackingState == StepMissionTrackingState.tracking;

  bool get isPermissionBlocked =>
      trackingState == StepMissionTrackingState.missingPermission;

  bool get isUnsupported =>
      trackingState == StepMissionTrackingState.unsupportedSensor;

  double get progressFraction {
    if (targetSteps <= 0) {
      return 0;
    }
    return completedSteps / targetSteps;
  }
}

class QrProgressSnapshot {
  const QrProgressSnapshot({
    required this.trackingState,
    required this.targetConfigured,
  });

  factory QrProgressSnapshot.fromMap(Map<Object?, Object?> raw) {
    return QrProgressSnapshot(
      trackingState: QrMissionTrackingState.fromId(
        raw['trackingState'] as String?,
      ),
      targetConfigured: raw['targetConfigured'] as bool? ?? false,
    );
  }

  final QrMissionTrackingState trackingState;
  final bool targetConfigured;

  bool get isAwaitingScan =>
      trackingState == QrMissionTrackingState.awaitingScan;

  bool get isTracking => trackingState == QrMissionTrackingState.tracking;

  bool get isTargetMissing =>
      trackingState == QrMissionTrackingState.targetMissing;

  bool get isPermissionBlocked =>
      trackingState == QrMissionTrackingState.missingPermission;

  bool get isUnsupported =>
      trackingState == QrMissionTrackingState.unsupportedCamera;
}

class ActiveMissionSnapshot {
  const ActiveMissionSnapshot({
    required this.spec,
    required this.status,
    required this.solvedProblemCount,
    required this.targetProblemCount,
    this.mathChallenge,
    this.stepProgress,
    this.qrProgress,
  });

  factory ActiveMissionSnapshot.fromMap(Map<Object?, Object?>? raw) {
    final missionRaw = raw ?? const <Object?, Object?>{};
    final config = missionRaw['config'] as Map<Object?, Object?>?;
    final challengeRaw = missionRaw['mathChallenge'] as Map<Object?, Object?>?;
    final stepProgressRaw =
        missionRaw['stepProgress'] as Map<Object?, Object?>?;
    final qrProgressRaw = missionRaw['qrProgress'] as Map<Object?, Object?>?;
    final spec = MissionSpec.fromMap(missionRaw);

    return ActiveMissionSnapshot(
      spec: spec,
      status: ActiveMissionStatus.fromId(missionRaw['status'] as String?),
      solvedProblemCount:
          (missionRaw['solvedProblemCount'] as num?)?.toInt() ?? 0,
      targetProblemCount:
          (missionRaw['targetProblemCount'] as num?)?.toInt() ??
          (spec.type == AlarmMissionType.math
              ? _normalizeMathMissionProblemCount(
                  (config?['problemCount'] as num?)?.toInt(),
                )
              : 0),
      mathChallenge: challengeRaw == null
          ? null
          : MathChallengeSnapshot.fromMap(challengeRaw),
      stepProgress: spec.type == AlarmMissionType.steps
          ? StepProgressSnapshot.fromMap(
              stepProgressRaw ??
                  <Object?, Object?>{
                    'completedSteps': 0,
                    'targetSteps': spec.stepGoal,
                    'trackingState': StepMissionTrackingState.awaitingSteps.id,
                  },
            )
          : null,
      qrProgress: spec.type == AlarmMissionType.qr
          ? QrProgressSnapshot.fromMap(
              qrProgressRaw ??
                  <Object?, Object?>{
                    'trackingState': spec.hasQrTarget
                        ? QrMissionTrackingState.awaitingScan.id
                        : QrMissionTrackingState.targetMissing.id,
                    'targetConfigured': spec.hasQrTarget,
                  },
            )
          : null,
    );
  }

  final MissionSpec spec;
  final ActiveMissionStatus status;
  final int solvedProblemCount;
  final int targetProblemCount;
  final MathChallengeSnapshot? mathChallenge;
  final StepProgressSnapshot? stepProgress;
  final QrProgressSnapshot? qrProgress;

  bool get isCompleted => status == ActiveMissionStatus.completed;

  bool get hasMultipleProblems => targetProblemCount > 1;

  bool get isQrMissionReady => qrProgress?.targetConfigured ?? false;

  int get currentProblemNumber {
    if (targetProblemCount <= 0) {
      return 0;
    }

    return (solvedProblemCount + 1)
        .clamp(minMathMissionProblemCount, targetProblemCount)
        .toInt();
  }
}
