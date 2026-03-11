package dev.neoalarm.app.alarmengine

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AlarmRescheduleReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action !in ALLOWED_ACTIONS) {
            return
        }

        runCatching {
            AlarmScheduler(context, AlarmStore(context)).rescheduleAll()
        }
    }

    companion object {
        private val ALLOWED_ACTIONS = setOf(
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
        )
    }
}

