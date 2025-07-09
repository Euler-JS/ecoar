import Flutter
import UIKit
import GoogleMaps
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyCc_QAuSZWSS63Ep3wDqd1MNC1SFIeeTK4")
    GeneratedPluginRegistrant.register(with: self)

    // Dica: só chame essa função quando for necessário
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
