import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceDescription {
  const DeviceDescription({
    required this.name,
    required this.platform,
    required this.os,
    required this.version,
  });
  final String name;
  final String platform;
  final String os;
  final String version;
  Map<String, String> toJson() => {
    'deviceName': _limit(name, 120),
    'platform': platform,
    'osVersion': _limit(os, 120),
    'appVersion': _limit(version, 50),
  };
  static String _limit(String value, int size) =>
      value.length > size ? value.substring(0, size) : value;
  static Future<DeviceDescription> read() async {
    final platform = kIsWeb ? 'web' : defaultTargetPlatform.name;
    var name = platform;
    var os = platform;
    var version = '';
    try {
      final info = await PackageInfo.fromPlatform();
      version = '${info.version}+${info.buildNumber}';
      final plugin = DeviceInfoPlugin();
      if (kIsWeb) {
        final device = await plugin.webBrowserInfo;
        name = '${device.browserName.name} · ${device.platform ?? 'Web'}';
        os = device.platform ?? 'Web';
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            final device = await plugin.androidInfo;
            name = '${device.manufacturer} ${device.model}';
            os = 'Android ${device.version.release}';
          case TargetPlatform.iOS:
            final device = await plugin.iosInfo;
            name = '${device.model} (${device.utsname.machine})';
            os = '${device.systemName} ${device.systemVersion}';
          case TargetPlatform.macOS:
            final device = await plugin.macOsInfo;
            name = device.model;
            os = 'macOS ${device.osRelease}';
          case TargetPlatform.windows:
            final device = await plugin.windowsInfo;
            name = 'Windows PC';
            os = device.productName;
          case TargetPlatform.linux:
            final device = await plugin.linuxInfo;
            name = 'Linux PC';
            os = device.prettyName;
          case TargetPlatform.fuchsia:
            name = 'Fuchsia';
        }
      }
    } catch (_) {
      /* A device-info failure must never prevent sign-in. */
    }
    return DeviceDescription(
      name: name,
      platform: platform,
      os: os,
      version: version,
    );
  }
}
