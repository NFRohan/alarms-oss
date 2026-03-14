package dev.neoalarm.app.alarmengine

import android.content.Context
import org.json.JSONArray
import java.io.File

class ToneLibraryStore(context: Context) {
    private val storageContext = alarmEngineStorageContext(context)
    private val prefs = storageContext.getSharedPreferences(
        TONE_LIBRARY_PREFS_NAME,
        Context.MODE_PRIVATE,
    )
    private val tonesDirectory = File(storageContext.filesDir, "alarm_tones").apply {
        mkdirs()
    }

    fun list(): List<ToneRecord> {
        val raw = prefs.getString(KEY_TONES, "[]") ?: "[]"
        val array = JSONArray(raw)
        return buildList {
            for (index in 0 until array.length()) {
                add(ToneRecord.fromJson(array.getJSONObject(index)))
            }
        }.sortedBy(ToneRecord::displayName)
    }

    fun get(id: String): ToneRecord? = list().firstOrNull { it.id == id }

    fun upsert(record: ToneRecord) {
        replaceAll(list().filterNot { it.id == record.id } + record)
    }

    fun replaceAll(records: List<ToneRecord>) {
        val array = JSONArray().apply {
            records.forEach { put(it.toJson()) }
        }
        prefs.edit().putString(KEY_TONES, array.toString()).apply()
    }

    fun delete(id: String): ToneRecord? {
        val existing = get(id) ?: return null
        replaceAll(list().filterNot { it.id == id })
        existing.localFileName?.let { fileName ->
            File(tonesDirectory, fileName).delete()
        }
        return existing
    }

    fun resolveFile(fileName: String): File = File(tonesDirectory, fileName)

    companion object {
        private const val KEY_TONES = "tones"
    }
}
