import Flutter
import UIKit
import AVFoundation
import ARKit  // ← Adicional (opcional)

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    checkCameraPermission()
    checkARAvailability()  // ← Opcional
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  func checkCameraPermission() {
    AVCaptureDevice.requestAccess(for: .video) { granted in
      if granted {
        print("✅ Permissão da câmera concedida")
      } else {
        print("❌ Permissão da câmera negada")
      }
    }
  }
  
  // ← OPCIONAL - ar_flutter_plugin já faz isso
  func checkARAvailability() {
    if ARWorldTrackingConfiguration.isSupported {
      print("✅ ARKit suportado neste dispositivo")
    } else {
      print("❌ ARKit NÃO suportado neste dispositivo")
    }
  }
}