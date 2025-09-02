import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
  let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
      let channel = FlutterMethodChannel(name: "demo/native",
                                         binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { [weak controller] (call, result) in
        switch call.method {
        case "openIOS":
          let vc = NativeViewController()
          vc.modalPresentationStyle = .formSheet
          controller?.present(vc, animated: true, completion: nil)
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
