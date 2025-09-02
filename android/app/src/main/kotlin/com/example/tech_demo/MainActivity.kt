package com.example.tech_demo

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Flutter 的入口 Activity
/// - 繼承 FlutterActivity，讓 Flutter Engine 跑在 Android 原生上
class MainActivity : FlutterActivity() {

    // Flutter 與 Android 溝通的 Channel 名稱
    // - Dart 端要用 MethodChannel("demo/native") 呼叫這裡的方法
    private val CHANNEL = "demo/native"

    /// Flutter Engine 初始化時會呼叫這裡
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 建立 MethodChannel，綁定到 Flutter 的 binaryMessenger
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                // 根據 Dart 端傳進來的 method 名稱分流處理
                when (call.method) {
                    // Flutter 呼叫：MethodChannel.invokeMethod("openAndroid")
                    "openAndroid" -> {
                        // 啟動 NativeActivity（我們自訂的原生頁）
                        startActivity(Intent(this, NativeActivity::class.java))
                        // 回傳成功給 Flutter 端（null 表示沒特別回傳資料）
                        result.success(null)
                    }
                    // 其他未定義的 method，回傳 notImplemented
                    else -> result.notImplemented()
                }
            }
    }
}
