import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class FlutterInAppWebViewPage extends StatefulWidget {
  const FlutterInAppWebViewPage({super.key});

  @override
  State<FlutterInAppWebViewPage> createState() => _FlutterInAppWebViewPageState();
}

class _FlutterInAppWebViewPageState extends State<FlutterInAppWebViewPage> {
  InAppWebViewController? _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Flutter InAppWebView Page")),
      body: InAppWebView(
        // 載入本地 index.html（記得 pubspec.yaml 有宣告 assets/index.html）
        initialFile: 'assets/index.html',
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
        ),
        onWebViewCreated: (controller) {
          _controller = controller;

          // JS → Dart 溝通：註冊 handler "bridge"
          controller.addJavaScriptHandler(
            handlerName: 'bridge',
            callback: (args) {
              final action = args.isNotEmpty ? args.first['action'] : null;

              if (action == 'takePhoto') {
                // 模擬拍照，然後回呼 JS 的 onPhotoTaken(path)
                const fakePath = "/local/flutter/fake_photo.jpg";
                _controller?.evaluateJavascript(
                  source: "onPhotoTaken('$fakePath');",
                );
              } else if (action == 'closePage') {
                // 關閉頁面
                Navigator.of(context).maybePop();
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
