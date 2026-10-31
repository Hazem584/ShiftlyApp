import WidgetKit
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
    if let widgetRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "ShiftlyTaskWidget") {
      TaskWidgetBridge.shared.register(widgetRegistrar.messenger())
      widgetRegistrar.addSceneDelegate(TaskWidgetBridge.shared)
    }
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

final class TaskWidgetBridge: NSObject, FlutterSceneLifeCycleDelegate {
  static let shared = TaskWidgetBridge()
  private var channel: FlutterMethodChannel?
  private var pending: [String: String]?
  private var ready = false

  func register(_ messenger: FlutterBinaryMessenger) {
    let bridge = FlutterMethodChannel(name: "shiftly/task_widget", binaryMessenger: messenger)
    channel = bridge
    bridge.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      let defaults = UserDefaults(suiteName: "group.com.example.shiftly")
      switch call.method {
      case "publish":
        guard let raw = call.arguments as? String, raw.utf8.count <= 16000,
              let bytes = raw.data(using: .utf8),
              let data = (try? JSONSerialization.jsonObject(with: bytes)) as? [String: Any],
              let tasks = data["tasks"] as? [[String: Any]], tasks.count <= 3,
              let owner = data["ownerId"] as? String, !owner.isEmpty else {
          result(FlutterError(code: "WIDGET_DATA", message: "Invalid task snapshot", details: nil)); return
        }
        defaults?.set(raw, forKey: "taskSnapshot")
        WidgetCenter.shared.reloadTimelines(ofKind: "ShiftlyTasksWidget")
        result(nil)
      case "clear":
        defaults?.removeObject(forKey: "taskSnapshot")
        WidgetCenter.shared.reloadTimelines(ofKind: "ShiftlyTasksWidget")
        result(nil)
      case "initialTap":
        self.ready = true
        result(self.pending)
        self.pending = nil
      case "pin":
        result(false) // iOS adds widgets through the Home Screen gallery.
      default: result(FlutterMethodNotImplemented)
      }
    }
  }


  func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
             options connectionOptions: UIScene.ConnectionOptions?) -> Bool {
    guard let contexts = connectionOptions?.urlContexts else { return false }
    return contexts.reduce(false) { accept($1.url) || $0 }
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    URLContexts.reduce(false) { accept($1.url) || $0 }
  }

  @discardableResult
  func accept(_ url: URL) -> Bool {
    guard url.scheme == "shiftly", url.host == "task-widget",
          let parts = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return false }
    let values = parts.queryItems ?? []
    let tap = ["ownerId": values.first(where: { $0.name == "ownerId" })?.value ?? "",
               "taskId": values.first(where: { $0.name == "taskId" })?.value ?? ""]
    if ready { channel?.invokeMethod("opened", arguments: tap) } else { pending = tap }
    return true
  }
}
