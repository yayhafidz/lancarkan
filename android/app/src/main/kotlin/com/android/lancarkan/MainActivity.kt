package com.android.lancarkan

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.android.lancarkan/nav_location"
    private var methodChannel: MethodChannel? = null

    private val navStoppedReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == BackgroundLocationService.ACTION_NAV_STOPPED) {
                methodChannel?.invokeMethod("onNavigationStopped", null)
            }
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startMock" -> {
                    val lat = call.argument<Double>("lat") ?: 0.0
                    val lng = call.argument<Double>("lng") ?: 0.0
                    val alt = call.argument<Double>("alt") ?: 0.0
                    val bearing = call.argument<Double>("bearing")?.toFloat() ?: 0.0f
                    val speed = call.argument<Double>("speed")?.toFloat() ?: 0.0f
                    val accuracy = call.argument<Double>("accuracy")?.toFloat() ?: 1.0f

                    val intent = Intent(this, BackgroundLocationService::class.java).apply {
                        putExtra("lat", lat)
                        putExtra("lng", lng)
                        putExtra("alt", alt)
                        putExtra("bearing", bearing)
                        putExtra("speed", speed)
                        putExtra("accuracy", accuracy)
                    }

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(true)
                }
                "updateMock" -> {
                    val lat = call.argument<Double>("lat") ?: 0.0
                    val lng = call.argument<Double>("lng") ?: 0.0
                    val alt = call.argument<Double>("alt") ?: 0.0
                    val bearing = call.argument<Double>("bearing")?.toFloat() ?: 0.0f
                    val speed = call.argument<Double>("speed")?.toFloat() ?: 0.0f
                    val accuracy = call.argument<Double>("accuracy")?.toFloat() ?: 1.0f

                    val intent = Intent(BackgroundLocationService.ACTION_UPDATE_LOCATION).apply {
                        putExtra("lat", lat)
                        putExtra("lng", lng)
                        putExtra("alt", alt)
                        putExtra("bearing", bearing)
                        putExtra("speed", speed)
                        putExtra("accuracy", accuracy)
                    }
                    sendBroadcast(intent)
                    result.success(true)
                }
                "stopMock" -> {
                    val intent = Intent(this, BackgroundLocationService::class.java).apply {
                        action = BackgroundLocationService.ACTION_STOP
                    }
                    startService(intent)
                    result.success(true)
                }
                "moveToBackground" -> {
                    moveTaskToBack(true)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        val filter = IntentFilter(BackgroundLocationService.ACTION_NAV_STOPPED)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(navStoppedReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(navStoppedReceiver, filter)
        }
    }

    override fun onDestroy() {
        try {
            unregisterReceiver(navStoppedReceiver)
        } catch (_: IllegalArgumentException) {
            // Receiver was not registered
        }
        super.onDestroy()
    }
}
