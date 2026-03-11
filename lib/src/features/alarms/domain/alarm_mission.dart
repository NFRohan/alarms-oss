const minMathMissionProblemCount = 1;
const maxMathMissionProblemCount = 5;

int _normalizeMathMissionProblemCount(int? value) {
  final resolved = value ?? minMathMissionProblemCount;
  return resolved
      .clamp(minMathMissionProblemCount, maxMathMissionProblemCount)
      .toInt();
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
  }) : assert(
         type != AlarmMissionType.math ||
             (mathProblemCount >= minMathMissionProblemCount &&
                 mathProblemCount <= maxMathMissionProblemCount),
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

  const MissionSpec.steps() : this(type: AlarmMissionType.steps);

  const MissionSpec.qr() : this(type: AlarmMissionType.qr);

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
      AlarmMissionType.steps => const MissionSpec.steps(),
      AlarmMissionType.qr => const MissionSpec.qr(),
    };
  }

  final AlarmMissionType type;
  final MathMissionDifficulty mathDifficulty;
  final int mathProblemCount;

  bool get isDirectDismiss => type == AlarmMissionType.none;

  String get summary {
    return switch (type) {
      AlarmMissionType.none => type.label,
      AlarmMissionType.math =>
        '${type.label} - ${mathDifficulty.label} - $mathProblemCount ${mathProblemCount == 1 ? 'problem' : 'problems'}',
      AlarmMissionType.steps => type.label,
      AlarmMissionType.qr => type.label,
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
        _ => <String, Object?>{},
      },
    };
  }

  MissionSpec copyWith({
    AlarmMissionType? type,
    MathMissionDifficulty? mathDifficulty,
    int? mathProblemCount,
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
      AlarmMissionType.steps => const MissionSpec.steps(),
      AlarmMissionType.qr => const MissionSpec.qr(),
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

class ActiveMissionSnapshot {
  const ActiveMissionSnapshot({
    required this.spec,
    required this.status,
    required this.solvedProblemCount,
    required this.targetProblemCount,
    this.mathChallenge,
  });

  factory ActiveMissionSnapshot.fromMap(Map<Object?, Object?>? raw) {
    final missionRaw = raw ?? const <Object?, Object?>{};
    final config = missionRaw['config'] as Map<Object?, Object?>?;
    final challengeRaw = missionRaw['mathChallenge'] as Map<Object?, Object?>?;
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
    );
  }

  final MissionSpec spec;
  final ActiveMissionStatus status;
  final int solvedProblemCount;
  final int targetProblemCount;
  final MathChallengeSnapshot? mathChallenge;

  bool get isCompleted => status == ActiveMissionStatus.completed;

  bool get hasMultipleProblems => targetProblemCount > 1;

  int get currentProblemNumber => (solvedProblemCount + 1)
      .clamp(minMathMissionProblemCount, targetProblemCount)
      .toInt();
}
