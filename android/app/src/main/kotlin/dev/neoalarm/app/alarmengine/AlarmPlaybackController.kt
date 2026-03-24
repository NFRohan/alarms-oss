package dev.neoalarm.app.alarmengine

import android.content.ContentResolver
import android.content.Context
import android.media.AudioAttributes
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.media.audiofx.LoudnessEnhancer
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.UserManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import dev.neoalarm.app.R
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min

class AlarmPlaybackController(
    private val context: Context,
    private val alarmStore: AlarmStore,
    private val toneLibraryStore: ToneLibraryStore,
    private val toneLibraryManager: ToneLibraryManager,
    private val audioManager: AudioManager,
    private val userManager: UserManager,
) {
    private var mediaPlayer: MediaPlayer? = null
    private var loudnessEnhancer: LoudnessEnhancer? = null
    private val rampHandler = Handler(Looper.getMainLooper())
    private var rampRunnable: Runnable? = null
    private var restoredAlarmVolume: Int? = null

    fun start(session: AlarmRingSession?) {
        startPlayback(session)
        startVibration()
    }

    fun stop() {
        stopRamp()
        loudnessEnhancer?.release()
        loudnessEnhancer = null
        mediaPlayer?.apply {
            setOnPreparedListener(null)
            setOnErrorListener(null)
            stopSafely()
            reset()
            release()
        }
        mediaPlayer = null
        restoreAlarmVolumeIfNeeded()
        vibrator().cancel()
    }

    private fun startPlayback(session: AlarmRingSession?) {
        if (mediaPlayer?.isPlaying == true) {
            return
        }

        val activeAlarm = session?.alarmId?.let(alarmStore::get)
        val toneUri = resolveToneUri(activeAlarm)
        val shouldRamp = activeAlarm?.volumeRampEnabled == true
        val shouldEnableExtraLoud = activeAlarm?.extraLoudEnabled == true
        val targetVolume = 1f
        val startingVolume = if (shouldRamp) 0.12f else targetVolume

        if (shouldRamp) {
            maybeApplyAlarmVolumeFloor()
        } else {
            restoreAlarmVolumeIfNeeded()
        }

        mediaPlayer = MediaPlayer().apply {
            setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
            isLooping = true
            setVolume(startingVolume, startingVolume)
            maybeAttachLoudnessEnhancer(this, shouldEnableExtraLoud)
            setOnPreparedListener { player ->
                player.start()
                if (shouldRamp) {
                    startVolumeRamp(player, startingVolume, targetVolume)
                }
            }
            setOnErrorListener { _, _, _ ->
                stop()
                false
            }
            try {
                when {
                    toneUri == null -> setDataSourceToFallback(this)
                    toneUri.scheme == ContentResolver.SCHEME_ANDROID_RESOURCE ->
                        setDataSource(context, toneUri)

                    else -> setDataSource(context, toneUri)
                }
                prepareAsync()
            } catch (_: Exception) {
                try {
                    reset()
                    setVolume(startingVolume, startingVolume)
                    setDataSourceToFallback(this)
                    prepareAsync()
                } catch (_: Exception) {
                    release()
                    mediaPlayer = null
                    restoreAlarmVolumeIfNeeded()
                }
            }
        }
    }

    private fun startVibration() {
        val effect = VibrationEffect.createWaveform(longArrayOf(0, 700, 500), 0)
        vibrator().vibrate(effect)
    }

    private fun resolveToneUri(alarm: AlarmRecord?): Uri? {
        if (!isUserUnlocked()) {
            return fallbackToneUri()
        }

        if (alarm?.ringtoneId == "custom_tone") {
            val customTone = alarm.customToneId?.let(toneLibraryStore::get)
            val customToneUri = customTone?.takeIf(toneLibraryManager::isHealthy)
                ?.let(toneLibraryManager::resolveToneUri)
            return customToneUri ?: fallbackToneUri()
        }

        val ringtoneType = when (alarm?.ringtoneId) {
            "system_notification" -> RingtoneManager.TYPE_NOTIFICATION
            else -> RingtoneManager.TYPE_ALARM
        }

        return RingtoneManager.getActualDefaultRingtoneUri(context, ringtoneType)
            ?: RingtoneManager.getDefaultUri(ringtoneType)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: fallbackToneUri()
    }

    private fun fallbackToneUri(): Uri {
        return Uri.parse(
            "android.resource://${context.packageName}/${R.raw.direct_boot_alarm_fallback}",
        )
    }

    private fun maybeAttachLoudnessEnhancer(
        player: MediaPlayer,
        shouldEnable: Boolean,
    ) {
        loudnessEnhancer?.release()
        loudnessEnhancer = null

        if (!shouldEnable || !isSpeakerOutputActive()) {
            return
        }

        try {
            loudnessEnhancer = LoudnessEnhancer(player.audioSessionId).apply {
                setTargetGain(EXTRA_LOUD_TARGET_GAIN_MB)
                enabled = true
            }
        } catch (_: Exception) {
            loudnessEnhancer?.release()
            loudnessEnhancer = null
        }
    }

    private fun setDataSourceToFallback(player: MediaPlayer) {
        player.setDataSource(context, fallbackToneUri())
    }

    private fun startVolumeRamp(
        player: MediaPlayer,
        startingVolume: Float,
        targetVolume: Float,
    ) {
        stopRamp()
        val startAt = System.currentTimeMillis()
        val durationMillis = 25_000L
        val minVolume = startingVolume.coerceIn(0f, 1f)
        val maxVolume = targetVolume.coerceIn(minVolume, 1f)

        val runnable = object : Runnable {
            override fun run() {
                if (mediaPlayer !== player || !player.isPlaying) {
                    return
                }

                val elapsed = System.currentTimeMillis() - startAt
                val progress = min(1f, elapsed.toFloat() / durationMillis.toFloat())
                val currentVolume = minVolume + (maxVolume - minVolume) * progress
                player.setVolume(currentVolume, currentVolume)

                if (progress < 1f) {
                    rampHandler.postDelayed(this, 750L)
                }
            }
        }

        rampRunnable = runnable
        rampHandler.post(runnable)
    }

    private fun stopRamp() {
        rampRunnable?.let(rampHandler::removeCallbacks)
        rampRunnable = null
    }

    private fun maybeApplyAlarmVolumeFloor() {
        val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_ALARM)
        val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
        val minimumAudibleFloor = max(1, ceil(maxVolume * 0.35).toInt())

        if (currentVolume >= minimumAudibleFloor) {
            restoreAlarmVolumeIfNeeded()
            return
        }

        if (restoredAlarmVolume == null) {
            restoredAlarmVolume = currentVolume
        }

        audioManager.setStreamVolume(
            AudioManager.STREAM_ALARM,
            minimumAudibleFloor,
            0,
        )
    }

    private fun restoreAlarmVolumeIfNeeded() {
        val previousVolume = restoredAlarmVolume ?: return
        audioManager.setStreamVolume(
            AudioManager.STREAM_ALARM,
            previousVolume,
            0,
        )
        restoredAlarmVolume = null
    }

    private fun isUserUnlocked(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            userManager.isUserUnlocked
        } else {
            true
        }
    }

    private fun isSpeakerOutputActive(): Boolean {
        val outputs = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
        if (outputs.isEmpty()) {
            return true
        }

        if (outputs.any(::isPrivateListeningRoute)) {
            return false
        }

        return outputs.any(::isSpeakerRoute)
    }

    private fun isSpeakerRoute(device: AudioDeviceInfo): Boolean {
        return when (device.type) {
            AudioDeviceInfo.TYPE_BUILTIN_SPEAKER,
            AudioDeviceInfo.TYPE_BUILTIN_SPEAKER_SAFE,
            -> true

            else -> false
        }
    }

    private fun isPrivateListeningRoute(device: AudioDeviceInfo): Boolean {
        return when (device.type) {
            AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
            AudioDeviceInfo.TYPE_WIRED_HEADSET,
            AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
            AudioDeviceInfo.TYPE_BLUETOOTH_SCO,
            AudioDeviceInfo.TYPE_BLE_HEADSET,
            AudioDeviceInfo.TYPE_BLE_SPEAKER,
            AudioDeviceInfo.TYPE_HEARING_AID,
            AudioDeviceInfo.TYPE_USB_DEVICE,
            AudioDeviceInfo.TYPE_USB_HEADSET,
            AudioDeviceInfo.TYPE_LINE_ANALOG,
            AudioDeviceInfo.TYPE_LINE_DIGITAL,
            AudioDeviceInfo.TYPE_AUX_LINE,
            -> true

            else -> false
        }
    }

    private fun MediaPlayer.stopSafely() {
        try {
            if (isPlaying) {
                stop()
            }
        } catch (_: IllegalStateException) {
        }
    }

    private fun vibrator(): Vibrator {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            context.getSystemService(VibratorManager::class.java).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
    }

    companion object {
        private const val EXTRA_LOUD_TARGET_GAIN_MB = 200
    }
}
