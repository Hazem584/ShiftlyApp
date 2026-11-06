import WidgetKit
import Flutter
import UIKit
import Photos
import UserNotifications
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    let action = UNNotificationAction(identifier: "shiftly_task_snooze_10",
      title: Locale.preferredLanguages.first?.hasPrefix("ar") == true ? "ذكّرني بعد 10 دقائق" : "Remind me in 10 minutes", options: [])
    UNUserNotificationCenter.current().setNotificationCategories([
      UNNotificationCategory(identifier: "shiftly_task_reminder", actions: [action], intentIdentifiers: [], options: [])
    ])
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func userNotificationCenter(_ center: UNUserNotificationCenter,
      didReceive response: UNNotificationResponse,
      withCompletionHandler completionHandler: @escaping () -> Void) {
    if response.actionIdentifier == "shiftly_task_snooze_10" {
      TaskNotificationSnooze.schedule(response, completion: completionHandler)
      return
    }
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    if let widgetRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "ShiftlyTaskWidget") {
      TaskWidgetBridge.shared.register(widgetRegistrar.messenger())
      widgetRegistrar.addSceneDelegate(TaskWidgetBridge.shared)
    }
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
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

// iOS calls this action in the background, including for visible APNs task alerts.
// No Flutter UI, authentication request, or network call is needed to snooze.
private enum TaskNotificationSnooze {
  static func schedule(_ response: UNNotificationResponse, completion: @escaping () -> Void) {
    let content = response.notification.request.content
    let info = content.userInfo
    var payload: [String: Any]
    if let raw = info["payload"] as? String, let bytes = raw.data(using: .utf8),
       let decoded = try? JSONSerialization.jsonObject(with: bytes) as? [String: Any] {
      payload = decoded
    } else {
      guard info["taskActionsVersion"] as? String == "1",
        let owner = info["recipientProfileId"] as? String,
        let task = info["taskId"] as? String else { completion(); return }
      payload = ["kind":"personal-task", "ownerId":owner, "taskId":task]
      if let revision = info["taskRevision"] as? String, let number = Int(revision) { payload["revision"] = number }
    }
    guard payload["kind"] as? String == "personal-task",
      let owner = payload["ownerId"] as? String, !owner.isEmpty,
      let task = payload["taskId"] as? String, !task.isEmpty else { completion(); return }
    let defaults = UserDefaults.standard
    guard defaults.string(forKey:"flutter.tasks.notification.owner") == owner,
      !defaults.bool(forKey:"flutter.tasks.notification.cancelled.\(owner).\(task)") else { completion(); return }
    let revisionKey = "flutter.tasks.notification.revision.\(owner).\(task)"
    if let saved = defaults.object(forKey: revisionKey) as? Int, let revision = payload["revision"] as? Int, saved != revision { completion(); return }
    var hash: UInt32 = 0x811c9dc5
    for byte in "\(owner):\(task)".utf8 { hash = (hash ^ UInt32(byte)) &* 0x01000193 }
    let id = 1400000000 + Int(hash % 100000000)
    payload["snoozed"] = true; payload["reminderKind"] = "SNOOZE"
    payload["title"] = content.title; payload["body"] = content.body
    guard let json = try? JSONSerialization.data(withJSONObject: payload),
      let raw = String(data: json, encoding: .utf8),
      let next = content.mutableCopy() as? UNMutableNotificationContent else { completion(); return }
    next.categoryIdentifier = "shiftly_task_reminder"
    next.userInfo = ["notificationId":id,"presentAlert":true,"presentSound":true,"presentBadge":false,"payload":raw]
    let request = UNNotificationRequest(identifier:String(id),content:next,
      trigger:UNTimeIntervalNotificationTrigger(timeInterval:600,repeats:false))
    UNUserNotificationCenter.current().add(request) { _ in
      if defaults.string(forKey:"flutter.tasks.notification.owner") != owner {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers:[String(id)])
      }
      completion()
    }
  }
}
