package com.hifi.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.hifi.app/stream"
    private val scope = CoroutineScope(Dispatchers.Main)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getStreamUrl") {
                val videoId = call.argument<String>("videoId")
                if (videoId.isNullOrBlank()) {
                    result.error("INVALID_ARGUMENT", "videoId is required", null)
                    return@setMethodCallHandler
                }

                scope.launch {
                    val streamUrl = withContext(Dispatchers.IO) {
                        StreamExtractor.getAudioStreamUrl(videoId)
                    }

                    if (streamUrl != null) {
                        result.success(streamUrl)
                    } else {
                        result.error("EXTRACT_FAILED", "Failed to extract audio stream for $videoId", null)
                    }
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
