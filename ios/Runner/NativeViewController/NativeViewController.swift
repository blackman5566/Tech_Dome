//
//  NativeViewController.swift
//  Runner
//
//  Created by 許佳豪 on 2025/9/2.
//

import UIKit
import WebKit

/// MARK: - WKScriptMessageHandler 擴充
extension NativeViewController {
    /// 接收來自 JS 的呼叫
    ///
    /// - parameter userContentController: 註冊的 WKUserContentController
    /// - parameter message: JS 傳進來的資料 (透過 window.webkit.messageHandlers.<name>.postMessage)
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // 只處理 JS 呼叫 "camera" 通道的訊息
        if message.name == "camera" {
            // 嘗試轉型成 [String: Any]，方便讀取 action
            guard let dict = message.body as? [String: Any],
                  let action = dict["action"] as? String else { return }

            switch action {
            case "takePhoto":
                // 模擬回傳資料給 JS
                // JS 側必須實作 window.onPhotoTaken(path)，這裡會觸發它
                let js = "window.onPhotoTaken('success:12345.jpg')"
                webView.evaluateJavaScript(js, completionHandler: nil)

            case "closePage":
                // JS 呼叫關閉頁面 → 直接 dismiss ViewController
                self.dismiss(animated: true)

            default:
                // 預留給未來擴充的 action
                break
            }
        }
    }
}


/// MARK: - NativeViewController
///
/// 使用 WKWebView 載入本地 HTML，並透過 WKScriptMessageHandler
/// 與前端的 JavaScript 互動 (Hybrid App Demo)
class NativeViewController: UIViewController, WKScriptMessageHandler {

    /// WebView 實體
    var webView: WKWebView!

    /// 初始化並設定 WKWebView
    func setupWKWebView() {
        // 建立用來與 JS 溝通的控制器
        let contentController = WKUserContentController()

        // 註冊一個 JS handler，名稱是 "camera"
        // → JS 側要呼叫 window.webkit.messageHandlers.camera.postMessage(...)
        contentController.add(self, name: "camera")

        // WebView 設定，掛上剛剛的 contentController
        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        // 建立 WebView，frame 填滿整個 ViewController
        webView = WKWebView(frame: view.bounds, configuration: config)
        view.addSubview(webView)

        // 載入本地 HTML 檔 (index.html 必須放在 Xcode 專案 Bundle 裡)
        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            // allowingReadAccessTo: 允許讀取 html 所在目錄內的資源 (圖片、CSS、JS 等)
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }
    
    /// UIViewController 生命週期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWKWebView()
    }
}
