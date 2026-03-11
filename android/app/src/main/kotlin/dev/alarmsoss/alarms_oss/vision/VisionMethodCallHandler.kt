package dev.alarmsoss.alarms_oss.vision

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class VisionMethodCallHandler(
    private val sessionManager: VisionSessionManager,
) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "startQrRegistration" -> {
                    sessionManager.startQrRegistration()
                    result.success(null)
                }

                "startQrMission" -> {
                    val raw = call.arguments as? Map<*, *>
                        ?: throw IllegalArgumentException("QR mission payload missing.")
                    val targetValue = raw["targetValue"] as? String
                        ?: throw IllegalArgumentException("QR target value missing.")
                    sessionManager.startQrMission(targetValue)
                    result.success(null)
                }

                "stopVisionSession" -> {
                    sessionManager.stopSession()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        } catch (error: Exception) {
            result.error("vision_error", error.message, null)
        }
    }
}
