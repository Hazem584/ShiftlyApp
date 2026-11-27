import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/monitoring/release_policy.dart';
import 'package:shiftly/core/monitoring/release_update_launcher.dart';
import 'package:shiftly/core/monitoring/release_update_request.dart';
import 'package:shiftly/core/monitoring/release_update_state.dart';

class ReleaseUpdateController extends Cubit<ReleaseUpdateState> {
  ReleaseUpdateController(this._client, this._openRelease)
    : super(initialReleaseUpdateState);

  final Dio _client;
  final Future<bool> Function(Uri)? _openRelease;
  final Set<int> _deferred = {};
  Map<String, dynamic>? _release;
  bool _checking = false;
  bool _initial = true;
  bool _launching = false, _launchFailed = false, _attemptedUpdate = false;

  void _publish() => emit((
    visibleRelease: _deferred.contains(_release?['build']) ? null : _release,
    initial: _initial,
    launching: _launching,
    launchFailed: _launchFailed,
    attemptedUpdate: _attemptedUpdate,
  ));

  void finishStartup() {
    _initial = false;
    _publish();
  }

  void defer(int build) {
    _deferred.add(build);
    _publish();
  }

  Future<void> check({
    required String platform,
    required int installedBuild,
  }) async {
    if (_checking || !shouldCheckRelease(platform)) return;
    _checking = true;
    try {
      final body = await fetchReleaseResponse(
        _client,
        platform,
        installedBuild,
      );
      if (isClosed || body == null) return;
      final release = body['release'];
      if (isApplicableRelease(
        release,
        platform: platform,
        installedBuild: installedBuild,
      )) {
        final next = Map<String, dynamic>.from(release as Map);
        if (_release?['build'] != next['build'] ||
            _release?['url'] != next['url']) {
          _attemptedUpdate = false;
          _launchFailed = false;
        }
        _release = next;
      } else {
        _release = null;
      }
      _publish();
    } catch (_) {
      // A failed refresh leaves the last verified gate visible.
    } finally {
      _checking = false;
    }
  }

  Future<void> launch() async {
    if (_launching || _release == null) return;
    _launching = true;
    _attemptedUpdate = true;
    _launchFailed = false;
    _publish();
    try {
      final uri = Uri.parse(_release!['url'] as String);
      final opened = await openReleaseWithTimeout(uri, _openRelease);
      if (!isClosed) _launchFailed = !opened;
    } catch (_) {
      if (!isClosed) _launchFailed = true;
    } finally {
      if (!isClosed) {
        _launching = false;
        _publish();
      }
    }
  }

  @override
  Future<void> close() {
    _client.close(force: true);
    return super.close();
  }
}
