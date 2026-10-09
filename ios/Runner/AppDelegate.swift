import Flutter
import UIKit
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "shiftly/chat_gallery",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "saveImage" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let arguments = call.arguments as? [String: Any],
            let bytes = arguments["bytes"] as? FlutterStandardTypedData,
            bytes.data.count > 0, bytes.data.count <= 5 * 1024 * 1024,
            let image = UIImage(data: bytes.data) else {
        result(FlutterError(code: "INVALID_IMAGE", message: "Invalid image", details: nil))
        return
      }
      let save: (PHAuthorizationStatus) -> Void = { status in
        guard status == .authorized else {
          DispatchQueue.main.async {
            result(FlutterError(code: "PHOTO_PERMISSION_DENIED", message: "Photo access was denied", details: nil))
          }
          return
        }
        PHPhotoLibrary.shared().performChanges({
          PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, _ in
          DispatchQueue.main.async {
            if success { result(true) }
            else { result(FlutterError(code: "PHOTO_SAVE_FAILED", message: "Could not save image", details: nil)) }
          }
        }
      }
      if #available(iOS 14, *) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly, handler: save)
      } else {
        PHPhotoLibrary.requestAuthorization(save)
      }
    }
  }
}
