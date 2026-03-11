package dev.neoalarm.app.alarmengine

import android.content.Context
import org.json.JSONObject

class RingSessionStore(context: Context) {
    private val prefs =
        alarmEngineStorageContext(context)
            .getSharedPreferences(ALARM_ENGINE_PREFS_NAME, Context.MODE_PRIVATE)

    fun get(): AlarmRingSession? {
        val raw = prefs.getString(KEY_ACTIVE_SESSION, null) ?: return null
        return runCatching { AlarmRingSession.fromJson(JSONObject(raw)) }.getOrNull()
    }

    fun put(session: AlarmRingSession) {
        prefs.edit().putString(KEY_ACTIVE_SESSION, session.toJson().toString()).apply()
    }

    fun clear() {
        prefs.edit().remove(KEY_ACTIVE_SESSION).apply()
    }

    companion object {
        private const val KEY_ACTIVE_SESSION = "active_ring_session"
    }
}

