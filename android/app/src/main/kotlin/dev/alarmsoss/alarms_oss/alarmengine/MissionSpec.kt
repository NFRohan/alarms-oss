package dev.alarmsoss.alarms_oss.alarmengine

import org.json.JSONObject

data class MissionSpec(
    val type: String,
    val mathDifficultyId: String? = null,
    val mathProblemCount: Int? = null,
    val stepGoal: Int? = null,
) {
    fun toChannelMap(): Map<String, Any?> {
        return mapOf(
            "type" to type,
            "config" to when (type) {
                TYPE_MATH -> mapOf(
                    "difficulty" to (mathDifficultyId ?: DEFAULT_MATH_DIFFICULTY),
                    "problemCount" to normalizeMathProblemCount(mathProblemCount),
                )
                TYPE_STEPS -> mapOf(
                    "goal" to normalizeStepGoal(stepGoal),
                )
                else -> emptyMap<String, Any?>()
            },
        )
    }

    fun toJson(): JSONObject {
        return JSONObject().apply {
            put("type", type)
            put(
                "config",
                JSONObject().apply {
                    when (type) {
                        TYPE_MATH -> {
                            put("difficulty", mathDifficultyId ?: DEFAULT_MATH_DIFFICULTY)
                            put("problemCount", normalizeMathProblemCount(mathProblemCount))
                        }

                        TYPE_STEPS -> {
                            put("goal", normalizeStepGoal(stepGoal))
                        }
                    }
                },
            )
        }
    }

    companion object {
        const val TYPE_NONE = "none"
        const val TYPE_MATH = "math"
        const val TYPE_STEPS = "steps"
        const val TYPE_QR = "qr"
        const val DEFAULT_MATH_DIFFICULTY = "standard"
        const val DEFAULT_MATH_PROBLEM_COUNT = 1
        const val MIN_MATH_PROBLEM_COUNT = 1
        const val MAX_MATH_PROBLEM_COUNT = 5
        const val DEFAULT_STEP_GOAL = 30
        const val MIN_STEP_GOAL = 10
        const val MAX_STEP_GOAL = 100

        fun fromChannelMap(raw: Map<*, *>?, fallbackType: String? = null): MissionSpec {
            val type = (raw?.get("type") as? String) ?: fallbackType ?: TYPE_NONE
            val config = raw?.get("config") as? Map<*, *>

            return MissionSpec(
                type = type,
                mathDifficultyId = when (type) {
                    TYPE_MATH -> (config?.get("difficulty") as? String) ?: DEFAULT_MATH_DIFFICULTY
                    else -> null
                },
                mathProblemCount = when (type) {
                    TYPE_MATH -> normalizeMathProblemCount(
                        (config?.get("problemCount") as? Number)?.toInt(),
                    )
                    else -> null
                },
                stepGoal = when (type) {
                    TYPE_STEPS -> normalizeStepGoal((config?.get("goal") as? Number)?.toInt())
                    else -> null
                },
            )
        }

        fun fromJson(json: JSONObject?, fallbackType: String? = null): MissionSpec {
            val type = json?.optString("type")?.takeIf(String::isNotBlank) ?: fallbackType ?: TYPE_NONE
            val config = json?.optJSONObject("config")

            return MissionSpec(
                type = type,
                mathDifficultyId = when (type) {
                    TYPE_MATH -> config?.optString("difficulty", DEFAULT_MATH_DIFFICULTY)
                        ?: DEFAULT_MATH_DIFFICULTY
                    else -> null
                },
                mathProblemCount = when (type) {
                    TYPE_MATH -> normalizeMathProblemCount(
                        if (config?.has("problemCount") == true) {
                            config.optInt("problemCount", DEFAULT_MATH_PROBLEM_COUNT)
                        } else {
                            null
                        },
                    )
                    else -> null
                },
                stepGoal = when (type) {
                    TYPE_STEPS -> normalizeStepGoal(
                        if (config?.has("goal") == true) {
                            config.optInt("goal", DEFAULT_STEP_GOAL)
                        } else {
                            null
                        },
                    )
                    else -> null
                },
            )
        }

        fun normalizeMathProblemCount(value: Int?): Int {
            return (value ?: DEFAULT_MATH_PROBLEM_COUNT)
                .coerceIn(MIN_MATH_PROBLEM_COUNT, MAX_MATH_PROBLEM_COUNT)
        }

        fun normalizeStepGoal(value: Int?): Int {
            return (value ?: DEFAULT_STEP_GOAL)
                .coerceIn(MIN_STEP_GOAL, MAX_STEP_GOAL)
        }
    }
}
