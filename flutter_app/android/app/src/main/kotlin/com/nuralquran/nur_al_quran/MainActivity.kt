package com.nuralquran.nur_al_quran

import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.nuralquran.nur_al_quran/lock_screen"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Shows (or hides) this activity over the lock screen.
                    // Used ONLY by the azan alarm screen; the manifest does NOT
                    // set showWhenLocked so normal app use never bypasses the
                    // lock screen.
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
        }
    }
}
