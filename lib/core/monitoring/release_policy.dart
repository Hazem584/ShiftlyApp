// Firebase is currently a tester-only channel. Production builds opt out.
const releaseChannel = String.fromEnvironment(
  'SHIFTLY_RELEASE_CHANNEL',
  defaultValue: 'firebase',
);

bool validReleaseUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      uri.scheme == 'https' &&
      uri.host == 'appdistribution.firebase.google.com' &&
      !uri.hasPort &&
      !uri.hasQuery &&
      !uri.hasFragment &&
      RegExp(r'^/testerapps/[A-Za-z0-9:._-]+/releases/[A-Za-z0-9_-]+/?$')
          .hasMatch(uri.path) &&
      uri.userInfo.isEmpty;
}

bool isApplicableRelease(
  Object? release, {
  required String platform,
  required int installedBuild,
}) =>
    release is Map &&
    release['build'] is int &&
    (release['build'] as int) > installedBuild &&
    (release['platform'] == null || release['platform'] == platform) &&
    (release['channel'] == null || release['channel'] == releaseChannel) &&
    release['required'] is bool &&
    release['version'] is String &&
    release['message'] is String &&
    release['url'] is String &&
    validReleaseUrl(release['url'] as String);

bool shouldCheckRelease(String platform) =>
    releaseChannel == 'firebase' &&
    (platform == 'android' || platform == 'ios');
