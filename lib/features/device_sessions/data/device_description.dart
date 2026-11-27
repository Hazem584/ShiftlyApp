import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shiftly/features/device_sessions/data/device_description_native.dart';

class DeviceDescription {
  const DeviceDescription({
    required this.name,
    required this.platform,
    required this.os,
    required this.version,
  });
  final String name, platform, os, version;

  Map<String, String> toJson() => {
    'deviceName': _limit(name, 120),
    'platform': platform,
    'osVersion': _limit(os, 120),
    'appVersion': _limit(version, 50),
  };

  static String _limit(String v, int n) => v.length > n ? v.substring(0, n) : v;

  static Future<DeviceDescription> read() async {
    final platform = kIsWeb ? 'web' : defaultTargetPlatform.name;
    var name = platform, os = platform, version = '';
    try {
      final info = await PackageInfo.fromPlatform();
      version = '${info.version}+${info.buildNumber}';
      final p = DeviceInfoPlugin();
      if (kIsWeb) {
        final d = await p.webBrowserInfo;
        name = '${d.browserName.name} · ${d.platform ?? 'Web'}';
        os = d.platform ?? 'Web';
      } else {
        (name, os) = await readNativeDeviceDescription(p, platform);
      }
    } catch (_) {}
    return DeviceDescription(
      name: name,
      platform: platform,
      os: os,
      version: version,
    );
  }
}
