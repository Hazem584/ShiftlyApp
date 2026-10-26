import Flutter
import UIKit
import Photos
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let iconChannel = FlutterMethodChannel(name: "shiftly/app_icons", binaryMessenger: engineBridge.applicationRegistrar.messenger())
    iconChannel.setMethodCallHandler { call, result in
      DispatchQueue.main.async {
        let app = UIApplication.shared
        let definitions = (Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any])?["CFBundleAlternateIcons"] as? [String: Any] ?? [:]
        var available: [String: String] = ["default": "default"]
        for name in definitions.keys where name.hasPrefix("Shiftly_icon_") {
          let key = String(name.dropFirst("Shiftly_".count))
          let digest = String(key.dropFirst(5))
          if digest.range(of: "^[a-f0-9]{64}$", options: .regularExpression) != nil { available[key] = digest }
        }
        switch call.method {
        case "capabilities":
          let current = app.alternateIconName.map { String($0.dropFirst("Shiftly_".count)) } ?? "default"
          result(["icons": available, "current": current, "supported": app.supportsAlternateIcons])
        case "select":
          guard let args = call.arguments as? [String: Any], let key = args["key"] as? String, available[key] != nil else {
            result(FlutterError(code: "ICON_NOT_BUNDLED", message: "Icon is not in this build", details: nil)); return
          }
          guard app.applicationState == .active, app.supportsAlternateIcons else {
            result(FlutterError(code: "ICON_UNAVAILABLE", message: "Retry when the app is active", details: nil)); return
          }
          let requested = key == "default" ? nil : "Shiftly_" + key
          if app.alternateIconName == requested { result(true); return }
          app.setAlternateIconName(requested) { error in
            DispatchQueue.main.async { if error != nil { result(FlutterError(code: "ICON_CHANGE_FAILED", message: "Could not change app icon", details: nil)) } else { result(true) } }
          }
        default: result(FlutterMethodNotImplemented)
        }
      }
    }
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
