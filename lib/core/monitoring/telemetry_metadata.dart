import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

Map<String, Object> telemetryMetadata(
  PackageInfo info,
  String sessionId,
  String lifecycle,
) => {
  'sessionId': sessionId,
  'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
  'version': info.version,
  'build': int.tryParse(info.buildNumber) ?? 0,
  'state': lifecycle,
};
