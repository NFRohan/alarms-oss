package dev.alarmsoss.alarms_oss

import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import dev.alarmsoss.alarms_oss.alarmengine.AlarmEngineMethodCallHandler
import dev.alarmsoss.alarms_oss.alarmengine.AlarmRingingService
import dev.alarmsoss.alarms_oss.alarmengine.RingSessionStore
import dev.alarmsoss.alarms_oss.vision.VisionMethodCallHandler
import dev.alarmsoss.alarms_oss.vision.VisionPreviewPlatformViewFactory
import dev.alarmsoss.alarms_oss.vision.VisionSessionManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var visionSessionManager: VisionSessionManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        syncAlarmWindowState()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        syncAlarmWindowState()
    }

    override fun onResume() {
        super.onResume()
        syncAlarmWindowState()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        visionSessionManager = VisionSessionManager(
            context = applicationContext,
            lifecycleOwner = this,
        )

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "dev.alarmsoss.alarm_engine",
        ).setMethodCallHandler(
            AlarmEngineMethodCallHandler(
                context = applicationContext,
                activity = this,
            ),
        )

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "dev.alarmsoss.vision",
        ).setMethodCallHandler(VisionMethodCallHandler(visionSessionManager))

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "dev.alarmsoss.vision/events",
        ).setStreamHandler(visionSessionManager)

        flutterEngine.platformViewsController.registry.registerViewFactory(
            "dev.alarmsoss.vision/preview",
            VisionPreviewPlatformViewFactory(visionSessionManager),
        )
    }

    private fun syncAlarmWindowState() {
        val activeSession = RingSessionStore(applicationContext).get()
        val requestedAlarmUi = activeSession?.isActive == true

        setShowWhenLocked(requestedAlarmUi)
        setTurnScreenOn(requestedAlarmUi)

        if (requestedAlarmUi) {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }
}
