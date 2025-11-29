package com.smarttasbih.app

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.time.ZoneId
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "smarttasbih/timezone"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getLocalTimezone" -> {
                    try {
                        val tzId = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            ZoneId.systemDefault().id
                        } else {
                            TimeZone.getDefault().id
                        }
                        result.success(tzId)
                    } catch (e: Exception) {
                        result.error("TZ_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
