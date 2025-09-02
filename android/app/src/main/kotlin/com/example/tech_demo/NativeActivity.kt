package com.example.tech_demo

import android.annotation.SuppressLint
import android.app.Activity
import android.os.Bundle
import android.view.ViewGroup
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import android.widget.Toast

/**
 * 原生 Android 頁面：
 * - 以 WebView 載入本地 index.html（android/app/src/main/assets/index.html）
 * - 透過 JavascriptInterface 提供 JS ↔ 原生互動
 *   - Android.takePhoto()：模擬拍照並回傳路徑
 *   - Android.closePage()：關閉當前頁面
 */
class NativeActivity : Activity() {

    private lateinit var webView: WebView

    @SuppressLint("SetJavaScriptEnabled") // 我們清楚知道開啟 JS 的風險，僅在受信任內容使用
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 父容器：用 FrameLayout 之後要疊加其他元件也方便
        val root = FrameLayout(this)

        // 建立 WebView 並設定
        webView = WebView(this).apply {
            // 1) 基本能力
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true                   // 支援 localStorage/sessionStorage
            settings.databaseEnabled = true
            settings.allowFileAccess = true

            // 2) 一般建議設定
            settings.cacheMode = WebSettings.LOAD_DEFAULT
            settings.useWideViewPort = true
            settings.loadWithOverviewMode = true

            // 3) 客製化 client
            webViewClient = WebViewClient()     // 基本瀏覽控制（避免跳系統瀏覽器）
            webChromeClient = WebChromeClient() // alert/confirm、console、進度等

            // 4) 綁定 JS Bridge：HTML 端以 window.Android.xxx 呼叫
            addJavascriptInterface(AndroidBridge(), "Android")

            // 5) 載入本地 HTML（assets/index.html）
            loadUrl("file:///android_asset/index.html")
        }

        // 把 WebView 塞進 root，往下偏移 56dp（一般 ActionBar 高度）
        val topBarHeight = (56 * resources.displayMetrics.density).toInt()

        root.addView(
            webView,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            ).apply {
                topMargin = topBarHeight
            }
        )

        setContentView(root)
    }

    /**
     * JS Bridge：讓 HTML 端能呼叫 Android 原生功能
     * - 注意：@JavascriptInterface 必須加，JS 才看得到
     */
    inner class AndroidBridge {

        /** HTML: Android.takePhoto() → 模擬拍照並回傳檔案路徑給 onPhotoTaken() */
        @JavascriptInterface
        fun takePhoto() {
            runOnUiThread {
                Toast.makeText(this@NativeActivity, "📸 開啟相機！（模擬）", Toast.LENGTH_SHORT).show()
                val fakePath = "/storage/emulated/0/DCIM/fake_photo.jpg"
                callJs("onPhotoTaken", "'$fakePath'")
            }
        }

        /** HTML: Android.closePage() → 關閉原生頁面 */
        @JavascriptInterface
        fun closePage() {
            runOnUiThread { finish() }
        }
    }

    /**
     * 輔助：呼叫頁面上的全域 JS 函式
     * @param func JS 全域函式名稱（例如 onPhotoTaken）
     * @param args 已處理好的參數字串（例如 "'/path/to.jpg'", 或 "1, 'ok'"）
     *
     * 範例：callJs("onPhotoTaken", "'/a/b.jpg'")
     * 最後執行：window.onPhotoTaken('/a/b.jpg')
     */
    private fun callJs(func: String, args: String) {
        val js = "window.$func && window.$func($args)"
        webView.evaluateJavascript(js, null)
    }

    /**
     * 返回鍵邏輯：先讓 WebView 往回上一頁，沒有歷史再關閉 Activity
     */
    override fun onBackPressed() {
        if (this::webView.isInitialized && webView.canGoBack()) {
            webView.goBack()
        } else {
            super.onBackPressed()
        }
    }

    /**
     * 生命週期清理，避免 WebView 造成記憶體洩漏
     */
    override fun onDestroy() {
        if (this::webView.isInitialized) {
            (webView.parent as? FrameLayout)?.removeView(webView)
            webView.stopLoading()
            webView.clearHistory()
            webView.destroy()
        }
        super.onDestroy()
    }
}
