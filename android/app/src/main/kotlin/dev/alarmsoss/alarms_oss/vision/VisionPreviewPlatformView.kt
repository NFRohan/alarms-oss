package dev.alarmsoss.alarms_oss.vision

import android.content.Context
import android.view.View
import androidx.camera.view.PreviewView
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.common.StandardMessageCodec

class VisionPreviewPlatformViewFactory(
    private val sessionManager: VisionSessionManager,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return VisionPreviewPlatformView(context, sessionManager)
    }
}

private class VisionPreviewPlatformView(
    context: Context,
    private val sessionManager: VisionSessionManager,
) : PlatformView {
    private val previewView = PreviewView(context).apply {
        implementationMode = PreviewView.ImplementationMode.COMPATIBLE
        scaleType = PreviewView.ScaleType.FILL_CENTER
    }

    init {
        sessionManager.attachPreviewView(previewView)
    }

    override fun getView(): View = previewView

    override fun dispose() {
        sessionManager.detachPreviewView(previewView)
    }
}
