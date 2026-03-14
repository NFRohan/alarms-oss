package dev.neoalarm.app.alarmengine

import org.json.JSONObject

data class ToneRecord(
    val id: String,
    val displayName: String,
    val sourceKind: String,
    val localFileName: String?,
    val sourceUri: String?,
    val mimeType: String,
    val sizeBytes: Long,
    val warning: String?,
    val createdAtEpochMillis: Long,
) {
    fun toChannelMap(isHealthy: Boolean): Map<String, Any?> {
        return mapOf(
            "id" to id,
            "displayName" to displayName,
            "sourceKind" to sourceKind,
            "mimeType" to mimeType,
            "sizeBytes" to sizeBytes,
            "isHealthy" to isHealthy,
            "warning" to warning,
        )
    }

    fun toJson(): JSONObject {
        return JSONObject().apply {
            put("id", id)
            put("displayName", displayName)
            put("sourceKind", sourceKind)
            put("localFileName", localFileName)
            put("sourceUri", sourceUri)
            put("mimeType", mimeType)
            put("sizeBytes", sizeBytes)
            put("warning", warning)
            put("createdAtEpochMillis", createdAtEpochMillis)
        }
    }

    companion object {
        const val SOURCE_IMPORTED_COPY = "imported_copy"
        const val SOURCE_EXTERNAL_REFERENCE = "external_reference"

        fun fromJson(json: JSONObject): ToneRecord {
            return ToneRecord(
                id = json.getString("id"),
                displayName = json.getString("displayName"),
                sourceKind = json.getString("sourceKind"),
                localFileName = json.optString("localFileName").takeUnless { it.isBlank() },
                sourceUri = json.optString("sourceUri").takeUnless { it.isBlank() },
                mimeType = json.optString("mimeType", "application/octet-stream"),
                sizeBytes = json.optLong("sizeBytes", 0L),
                warning = json.optString("warning").takeUnless { it.isBlank() },
                createdAtEpochMillis = json.optLong("createdAtEpochMillis", 0L),
            )
        }
    }
}
