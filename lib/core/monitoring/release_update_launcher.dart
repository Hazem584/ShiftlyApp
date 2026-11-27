import 'package:url_launcher/url_launcher.dart';

Future<bool> openReleaseWithTimeout(
  Uri uri,
  Future<bool> Function(Uri)? openRelease,
) =>
    (openRelease?.call(uri) ??
            launchUrl(uri, mode: LaunchMode.externalApplication))
        .timeout(const Duration(seconds: 15));
