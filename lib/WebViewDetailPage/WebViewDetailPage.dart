// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'FlutterInAppWebViewPage.dart';
const _channel = MethodChannel('demo/native');

class WebViewDetailPage extends StatelessWidget {
  const WebViewDetailPage({super.key});

  Future<void> _openAndroid() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _safeInvoke('openAndroid');
    }
  }

  Future<void> _openIOS() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _safeInvoke('openIOS');
    }
  }

  Future<void> _safeInvoke(String method) async {
    try {
      await _channel.invokeMethod(method);
    } on PlatformException catch (e) {
      debugPrint('PlatformException: $e');
    }
  }

  void _openFlutter(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FlutterInAppWebViewPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('三按鈕入口')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _openAndroid,
              child: const Text('開啟 Android 原生頁面'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _openIOS,
              child: const Text('開啟 iOS 原生頁面'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _openFlutter(context),
              child: const Text('開啟 Flutter 頁面'),
            ),
          ],
        ),
      ),
    );
  }
}
