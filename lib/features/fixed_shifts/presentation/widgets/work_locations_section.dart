import 'package:flutter/material.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/work_location_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/dialogs/work_location_dialog.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/work_locations_card.dart';

class WorkLocationsSection extends StatefulWidget {
  const WorkLocationsSection({
    super.key,
    required this.scope,
    required this.repository,
    required this.isCurrent,
    this.onChanged,
  });
  final FeatureSessionScope scope;
  final WorkLocationRepository repository;
  final bool Function() isCurrent;
  final VoidCallback? onChanged;

  @override
  State<WorkLocationsSection> createState() => _WorkLocationsSectionState();
}

class _WorkLocationsSectionState extends State<WorkLocationsSection> {
  List<WorkspaceWorkLocation> _locations = [];
  String _mode = 'OFF';
  bool _loading = true, _busy = false;
  int _gen = 0;
  String? _error;

  bool _alive(int g) => mounted && g == _gen && widget.isCurrent();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final g = ++_gen;
    if (!widget.scope.isManager || !widget.isCurrent()) return;
    setState(() => (_loading = true, _error = null));
    try {
      final res = await Future.wait([
        widget.repository.getGeofenceMode(widget.scope.workspaceId),
        widget.repository.list(widget.scope.workspaceId),
      ]);
      if (!_alive(g)) return;
      setState(() {
        _mode = res[0] as String;
        _locations = res[1] as List<WorkspaceWorkLocation>;
        _loading = false;
      });
    } catch (e) {
      if (_alive(g)) {
        setState(
          () => (_loading = false, _error = ApiErrorParser.parse(e).message),
        );
      }
    }
  }

  Future<void> _runMutation(Future<void> Function() action) async {
    if (_busy) return;
    final g = _gen;
    setState(() => (_busy = true, _error = null));
    try {
      await action();
    } catch (e) {
      if (_alive(g)) setState(() => _error = ApiErrorParser.parse(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openEditor([WorkspaceWorkLocation? existing]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => WorkLocationDialog(
        repository: widget.repository,
        workspaceId: widget.scope.workspaceId,
        existing: existing,
      ),
    );
    if (saved == true && mounted) {
      widget.onChanged?.call();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) => buildWorkLocationsCard(
    context: context,
    mode: _mode,
    locations: _locations,
    loading: _loading,
    busy: _busy,
    error: _error,
    onModeChanged: (m) => _runMutation(() async {
      _mode = await widget.repository.updateGeofenceMode(
        widget.scope.workspaceId,
        m,
      );
    }),
    onAdd: _openEditor,
    onEdit: _openEditor,
    onArchive: (loc) => _runMutation(() async {
      await widget.repository.archive(widget.scope.workspaceId, loc.id);
      widget.onChanged?.call();
      await _load();
    }),
    onRefresh: _load,
  );
}
