import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    checkCameraPermission()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
   func checkCameraPermission() {
    AVCaptureDevice.requestAccess(for: .video) { granted in
      if granted {
        print("Permissão da câmera concedida")
      } else {
        print("Permissão da câmera negada")
      }
    }
  }
}
