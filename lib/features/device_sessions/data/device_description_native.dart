import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

Future<(String, String)> readNativeDeviceDescription(
  DeviceInfoPlugin p,
  String fallback,
) async => switch (defaultTargetPlatform) {
  TargetPlatform.android => () async {
    final d = await p.androidInfo;
    return ('${d.manufacturer} ${d.model}', 'Android ${d.version.release}');
  }(),
  TargetPlatform.iOS => () async {
    final d = await p.iosInfo;
    return (
      '${d.model} (${d.utsname.machine})',
      '${d.systemName} ${d.systemVersion}',
    );
  }(),
  TargetPlatform.macOS => () async {
    final d = await p.macOsInfo;
    return (d.model, 'macOS ${d.osRelease}');
  }(),
  TargetPlatform.windows => () async {
    final d = await p.windowsInfo;
    return ('Windows PC', d.productName);
  }(),
  TargetPlatform.linux => () async {
    final d = await p.linuxInfo;
    return ('Linux PC', d.prettyName);
  }(),
  TargetPlatform.fuchsia => ('Fuchsia', fallback),
};
