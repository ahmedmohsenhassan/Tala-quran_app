package com.ahmed.tala_quran

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.ahmed.tala_quran/settings").setMethodCallHandler { call, result ->
            if (call.method == "openSettings") {
                val intentName = call.arguments as String
                try {
                    val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && intentName == "android.settings.REQUEST_SCHEDULE_EXACT_ALARM") {
                        Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                            data = Uri.fromParts("package", packageName, null)
                        }
                    } else {
                        // Fallback to app details
                        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.fromParts("package", packageName, null)
                        }
                    }
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
