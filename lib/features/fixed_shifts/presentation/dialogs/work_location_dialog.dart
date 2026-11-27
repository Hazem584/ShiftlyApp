import 'package:flutter/material.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/location/location_reader.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/work_location_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/dialogs/work_location_dialog_view.dart';

class WorkLocationDialog extends StatefulWidget {
  const WorkLocationDialog({
    super.key,
    required this.repository,
    required this.workspaceId,
    this.existing,
  });
  final WorkLocationRepository repository;
  final String workspaceId;
  final WorkspaceWorkLocation? existing;

  @override
  State<WorkLocationDialog> createState() => _WorkLocationDialogState();
}

class _WorkLocationDialogState extends State<WorkLocationDialog> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _lat = TextEditingController(
    text: widget.existing?.latitude.toStringAsFixed(6),
  );
  late final _lng = TextEditingController(
    text: widget.existing?.longitude.toStringAsFixed(6),
  );
  late int _radius = widget.existing?.radiusMeters ?? 100;
  bool _busy = false, _locating = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _lat, _lng]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _useCurrent() async {
    setState(() => (_locating = true, _error = null));
    try {
      final pt = await readDeviceAttendanceLocation(requiredForPunch: true);
      if (!mounted || pt == null) return;
      setState(() {
        _lat.text = pt.latitude.toStringAsFixed(6);
        _lng.text = pt.longitude.toStringAsFixed(6);
        _locating = false;
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => (_locating = false, _error = ApiErrorParser.parse(e).message),
        );
      }
    }
  }

  Future<void> _save() async {
    final title = _name.text.trim();
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());
    if (title.isEmpty ||
        lat == null ||
        lng == null ||
        lat.abs() > 90 ||
        lng.abs() > 180) {
      return setState(() => _error = 'Enter a valid name and GPS coordinates.');
    }
    setState(() => (_busy = true, _error = null));
    try {
      if (widget.existing == null) {
        await widget.repository.create(
          widget.workspaceId,
          name: title,
          latitude: lat,
          longitude: lng,
          radiusMeters: _radius,
        );
      } else {
        await widget.repository.update(
          widget.workspaceId,
          widget.existing!.id,
          name: title,
          latitude: lat,
          longitude: lng,
          radiusMeters: _radius,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(
          () => (_busy = false, _error = ApiErrorParser.parse(e).message),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => buildWorkLocationDialogView(
    context: context,
    existing: widget.existing,
    name: _name,
    lat: _lat,
    lng: _lng,
    radius: _radius,
    busy: _busy,
    locating: _locating,
    error: _error,
    onRadiusChanged: (v) => setState(() => _radius = v),
    onUseCurrentLocation: _useCurrent,
    onSave: _save,
  );
}
