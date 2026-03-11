package dev.neoalarm.app.alarmengine

import android.content.Context

internal const val ALARM_ENGINE_PREFS_NAME = "alarm_engine_store"

internal fun alarmEngineStorageContext(context: Context): Context {
    val appContext = context.applicationContext
    val storageContext = appContext.createDeviceProtectedStorageContext()

    runCatching {
        storageContext.moveSharedPreferencesFrom(appContext, ALARM_ENGINE_PREFS_NAME)
    }

    return storageContext
}

