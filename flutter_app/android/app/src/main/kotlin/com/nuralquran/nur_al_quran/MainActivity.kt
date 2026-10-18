package com.nuralquran.nur_al_quran

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.view.KeyEvent
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.nuralquran.nur_al_quran/lock_screen"
    }

    private var isAzanActive = false
    private var screenOffReceiverRegistered = false

    private val screenOffReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == Intent.ACTION_SCREEN_OFF) {
                // User pressed the phone's lock/power switch button -> stop the azan alarm!
                stopAzanAlarm()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        registerScreenOffReceiver()
        if (isAzanIntent(intent)) {
            isAzanActive = true
            setShowWhenLockedCompat(true)
        } else {
            setShowWhenLockedCompat(false)
        }
    }

    override fun onDestroy() {
        unregisterScreenOffReceiver()
        super.onDestroy()
    }

    private fun registerScreenOffReceiver() {
        if (!screenOffReceiverRegistered) {
            try {
                val filter = IntentFilter(Intent.ACTION_SCREEN_OFF)
                registerReceiver(screenOffReceiver, filter)
                screenOffReceiverRegistered = true
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun unregisterScreenOffReceiver() {
        if (screenOffReceiverRegistered) {
            try {
                unregisterReceiver(screenOffReceiver)
                screenOffReceiverRegistered = false
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (isAzanActive && event.action == KeyEvent.ACTION_DOWN) {
            when (event.keyCode) {
                KeyEvent.KEYCODE_POWER,
                KeyEvent.KEYCODE_VOLUME_UP,
                KeyEvent.KEYCODE_VOLUME_DOWN,
                KeyEvent.KEYCODE_MUTE -> {
                    stopAzanAlarm()
                    return true
                }
            }
        }
        return super.dispatchKeyEvent(event)
    }

    private fun stopAzanAlarm() {
        try {
            isAzanActive = false
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            prefs.edit().putBoolean("flutter.nur_azan_stop", true).apply()
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
            for (id in 101..105) {
                nm.cancel(id)
            }
            for (id in 1001..1005) {
                nm.cancel(id)
            }
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, CHANNEL).invokeMethod("azanSilenced", null)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (isAzanIntent(intent)) {
            isAzanActive = true
            setShowWhenLockedCompat(true)
        }
    }

    override fun onResume() {
        super.onResume()
    }

    private fun isAzanIntent(intent: Intent?): Boolean {
        if (intent == null) return false
        val payload = intent.getStringExtra("payload")
        if (payload != null && payload.startsWith("azan_alarm")) return true
        val extras = intent.extras ?: return false
        for (key in extras.keySet()) {
            val value = extras.get(key)
            if (value is String && value.contains("azan_alarm")) {
                return true
            }
        }
        val id = extras.getInt("notification_id", extras.getInt("notificationId", -1))
        if (id in 1001..1005) {
            return true
        }
        return false
    }

    private fun wakeScreenIfLocked() {
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            if (!powerManager.isInteractive) {
                @Suppress("DEPRECATION")
                val wakeLock = powerManager.newWakeLock(
                    PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                            PowerManager.ACQUIRE_CAUSES_WAKEUP or
                            PowerManager.ON_AFTER_RELEASE,
                    "com.nuralquran.nur_al_quran:AzanScreenWakeLock"
                )
                wakeLock.acquire(10000) // 10 seconds
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setShowWhenLocked" -> {
                        val show = call.argument<Boolean>("show") ?: false
                        setShowWhenLockedCompat(show)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun setShowWhenLockedCompat(show: Boolean) {
        runOnUiThread {
            if (show) {
                wakeScreenIfLocked()
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                setShowWhenLocked(show)
                setTurnScreenOn(show)
            } else {
                @Suppress("DEPRECATION")
                if (show) {
                    window.addFlags(
                        WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                    )
                } else {
                    window.clearFlags(
                        WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                    )
                }
            }
            if (show) {
                window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            } else {
                window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            }
        }
    }
}
