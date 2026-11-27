import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/work_location_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';

class TemplateWorkLocationPicker extends StatefulWidget {
  const TemplateWorkLocationPicker({
    super.key,
    required this.selectedId,
    required this.enabled,
    required this.onChanged,
  });
  final String? selectedId;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  State<TemplateWorkLocationPicker> createState() =>
      _TemplateWorkLocationPickerState();
}

class _TemplateWorkLocationPickerState
    extends State<TemplateWorkLocationPicker> {
  List<WorkspaceWorkLocation> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!getIt.isRegistered<WorkLocationRepository>()) return;
    final scope = context.read<ManagerTemplatesCubit>().scope;
    if (scope == null) return;
    try {
      final list = await getIt<WorkLocationRepository>().list(
        scope.workspaceId,
      );
      if (mounted) setState(() => _items = list);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    final validId = _items.any((e) => e.id == widget.selectedId)
        ? widget.selectedId
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String?>(
        initialValue: validId,
        decoration: InputDecoration(
          labelText: context.tr('Required work location (optional)'),
        ),
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text(context.tr('Any workspace location')),
          ),
          for (final loc in _items)
            DropdownMenuItem<String?>(
              value: loc.id,
              child: Text('${loc.name} (${loc.radiusMeters}m)'),
            ),
        ],
        onChanged: widget.enabled ? widget.onChanged : null,
      ),
    );
  }
}
