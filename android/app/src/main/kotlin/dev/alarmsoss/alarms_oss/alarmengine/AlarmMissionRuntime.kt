package dev.alarmsoss.alarms_oss.alarmengine

import kotlin.random.Random
import org.json.JSONObject

enum class MathAnswerSubmissionResult(val id: String) {
    INCORRECT("incorrect"),
    ADVANCED("advanced"),
    COMPLETED("completed"),
}

data class MathChallengeState(
    val leftOperand: Int,
    val rightOperand: Int,
    val operatorSymbol: String,
    val correctAnswer: Int,
    val attemptCount: Int,
) {
    fun toChannelMap(): Map<String, Any> {
        return mapOf(
            "leftOperand" to leftOperand,
            "rightOperand" to rightOperand,
            "operatorSymbol" to operatorSymbol,
            "attemptCount" to attemptCount,
        )
    }

    fun toJson(): JSONObject {
        return JSONObject().apply {
            put("leftOperand", leftOperand)
            put("rightOperand", rightOperand)
            put("operatorSymbol", operatorSymbol)
            put("correctAnswer", correctAnswer)
            put("attemptCount", attemptCount)
        }
    }

    fun withAttemptIncremented(): MathChallengeState {
        return copy(attemptCount = attemptCount + 1)
    }

    companion object {
        fun fromJson(json: JSONObject): MathChallengeState {
            return MathChallengeState(
                leftOperand = json.getInt("leftOperand"),
                rightOperand = json.getInt("rightOperand"),
                operatorSymbol = json.getString("operatorSymbol"),
                correctAnswer = json.getInt("correctAnswer"),
                attemptCount = json.optInt("attemptCount", 0),
            )
        }

        fun generate(difficultyId: String): MathChallengeState {
            return when (difficultyId) {
                "easy" -> generateEasyChallenge()
                "hard" -> generateHardChallenge()
                else -> generateStandardChallenge()
            }
        }

        private fun generateEasyChallenge(): MathChallengeState {
            val addition = Random.nextBoolean()
            val left = Random.nextInt(2, 10)
            val right = Random.nextInt(1, 10)

            return if (addition) {
                MathChallengeState(
                    leftOperand = left,
                    rightOperand = right,
                    operatorSymbol = "+",
                    correctAnswer = left + right,
                    attemptCount = 0,
                )
            } else {
                val max = maxOf(left, right)
                val min = minOf(left, right)
                MathChallengeState(
                    leftOperand = max,
                    rightOperand = min,
                    operatorSymbol = "-",
                    correctAnswer = max - min,
                    attemptCount = 0,
                )
            }
        }

        private fun generateStandardChallenge(): MathChallengeState {
            return when (Random.nextInt(3)) {
                0 -> {
                    val left = Random.nextInt(10, 40)
                    val right = Random.nextInt(5, 25)
                    MathChallengeState(
                        leftOperand = left,
                        rightOperand = right,
                        operatorSymbol = "+",
                        correctAnswer = left + right,
                        attemptCount = 0,
                    )
                }

                1 -> {
                    val left = Random.nextInt(25, 60)
                    val right = Random.nextInt(5, 25)
                    MathChallengeState(
                        leftOperand = left,
                        rightOperand = right,
                        operatorSymbol = "-",
                        correctAnswer = left - right,
                        attemptCount = 0,
                    )
                }

                else -> {
                    val left = Random.nextInt(3, 10)
                    val right = Random.nextInt(3, 10)
                    MathChallengeState(
                        leftOperand = left,
                        rightOperand = right,
                        operatorSymbol = "x",
                        correctAnswer = left * right,
                        attemptCount = 0,
                    )
                }
            }
        }

        private fun generateHardChallenge(): MathChallengeState {
            return when (Random.nextInt(2)) {
                0 -> {
                    val left = Random.nextInt(8, 15)
                    val right = Random.nextInt(7, 13)
                    MathChallengeState(
                        leftOperand = left,
                        rightOperand = right,
                        operatorSymbol = "x",
                        correctAnswer = left * right,
                        attemptCount = 0,
                    )
                }

                else -> {
                    val left = Random.nextInt(40, 95)
                    val right = Random.nextInt(15, 50)
                    MathChallengeState(
                        leftOperand = left,
                        rightOperand = right,
                        operatorSymbol = "+",
                        correctAnswer = left + right,
                        attemptCount = 0,
                    )
                }
            }
        }
    }
}

data class AlarmMissionRuntime(
    val spec: MissionSpec,
    val status: String,
    val solvedProblemCount: Int,
    val targetProblemCount: Int,
    val mathChallenge: MathChallengeState?,
) {
    fun toChannelMap(): Map<String, Any?> {
        return buildMap {
            putAll(spec.toChannelMap())
            put("status", status)
            put("solvedProblemCount", solvedProblemCount)
            put("targetProblemCount", targetProblemCount)
            put("mathChallenge", mathChallenge?.toChannelMap())
        }
    }

    fun toJson(): JSONObject {
        return spec.toJson().apply {
            put("status", status)
            put("solvedProblemCount", solvedProblemCount)
            put("targetProblemCount", targetProblemCount)
            put("mathChallenge", mathChallenge?.toJson())
        }
    }

    val isDismissAllowed: Boolean
        get() = spec.type == MissionSpec.TYPE_NONE || status == STATUS_COMPLETED

    fun submitMathAnswer(answerRaw: String): Pair<AlarmMissionRuntime, MathAnswerSubmissionResult> {
        if (spec.type != MissionSpec.TYPE_MATH) {
            return copy(status = STATUS_COMPLETED) to MathAnswerSubmissionResult.COMPLETED
        }

        val challenge = mathChallenge ?: return this to MathAnswerSubmissionResult.INCORRECT
        val answer = answerRaw.trim().toIntOrNull()
        if (answer == null || answer != challenge.correctAnswer) {
            return copy(mathChallenge = challenge.withAttemptIncremented()) to
                MathAnswerSubmissionResult.INCORRECT
        }

        val nextSolvedProblemCount = (solvedProblemCount + 1).coerceAtMost(targetProblemCount)
        if (nextSolvedProblemCount >= targetProblemCount) {
            return copy(
                status = STATUS_COMPLETED,
                solvedProblemCount = targetProblemCount,
                mathChallenge = null,
            ) to MathAnswerSubmissionResult.COMPLETED
        }

        return copy(
            solvedProblemCount = nextSolvedProblemCount,
            mathChallenge = MathChallengeState.generate(
                spec.mathDifficultyId ?: MissionSpec.DEFAULT_MATH_DIFFICULTY,
            ),
        ) to MathAnswerSubmissionResult.ADVANCED
    }

    companion object {
        const val STATUS_PENDING = "pending"
        const val STATUS_COMPLETED = "completed"

        fun create(spec: MissionSpec): AlarmMissionRuntime {
            return when (spec.type) {
                MissionSpec.TYPE_NONE -> AlarmMissionRuntime(
                    spec = spec,
                    status = STATUS_COMPLETED,
                    solvedProblemCount = 0,
                    targetProblemCount = 0,
                    mathChallenge = null,
                )

                MissionSpec.TYPE_MATH -> {
                    val targetProblemCount =
                        MissionSpec.normalizeMathProblemCount(spec.mathProblemCount)
                    AlarmMissionRuntime(
                        spec = spec,
                        status = STATUS_PENDING,
                        solvedProblemCount = 0,
                        targetProblemCount = targetProblemCount,
                        mathChallenge = MathChallengeState.generate(
                            spec.mathDifficultyId ?: MissionSpec.DEFAULT_MATH_DIFFICULTY,
                        ),
                    )
                }

                else -> AlarmMissionRuntime(
                    spec = spec,
                    status = STATUS_PENDING,
                    solvedProblemCount = 0,
                    targetProblemCount = 0,
                    mathChallenge = null,
                )
            }
        }

        fun fromJson(json: JSONObject): AlarmMissionRuntime {
            val spec = MissionSpec.fromJson(json)
            val challengeJson = json.optJSONObject("mathChallenge")
            val targetProblemCount = when (spec.type) {
                MissionSpec.TYPE_MATH -> MissionSpec.normalizeMathProblemCount(
                    if (json.has("targetProblemCount")) {
                        json.optInt(
                            "targetProblemCount",
                            MissionSpec.normalizeMathProblemCount(spec.mathProblemCount),
                        )
                    } else {
                        spec.mathProblemCount
                    },
                )
                else -> 0
            }

            return AlarmMissionRuntime(
                spec = spec,
                status = json.optString("status", STATUS_PENDING),
                solvedProblemCount = json.optInt("solvedProblemCount", 0),
                targetProblemCount = targetProblemCount,
                mathChallenge = challengeJson?.let(MathChallengeState::fromJson),
            )
        }
    }
}
