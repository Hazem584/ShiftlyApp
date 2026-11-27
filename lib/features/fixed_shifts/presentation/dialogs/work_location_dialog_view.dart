import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/work_location_repository.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_dialog.dart';

Widget buildWorkLocationDialogView({
  required BuildContext context,
  required WorkspaceWorkLocation? existing,
  required TextEditingController name,
  required TextEditingController lat,
  required TextEditingController lng,
  required int radius,
  required bool busy,
  required bool locating,
  required String? error,
  required ValueChanged<int> onRadiusChanged,
  required VoidCallback onUseCurrentLocation,
  required VoidCallback onSave,
}) => ManagerDialog(
  title: Text(
    context.tr(existing == null ? 'Add work location' : 'Edit work location'),
  ),
  content: SizedBox(
    width: 440,
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: name,
            enabled: !busy,
            decoration: InputDecoration(
              labelText: context.tr('Location name'),
              hintText: context.tr('e.g. Main Branch'),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: busy || locating ? null : onUseCurrentLocation,
            icon: const Icon(Icons.my_location_outlined),
            label: Text(context.tr('Use my current GPS location')),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _coordField(context, lat, 'Latitude', busy)),
              const SizedBox(width: 10),
              Expanded(child: _coordField(context, lng, 'Longitude', busy)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('Allowed radius: {value1} meters', {
              'value1': radius.toString(),
            }),
          ),
          Slider(
            value: radius.clamp(25, 500).toDouble(),
            min: 25,
            max: 500,
            divisions: 19,
            onChanged: busy ? null : (v) => onRadiusChanged(v.round()),
          ),
          if (error != null)
            Text(
              context.tr(error),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
  ),
  actions: [
    TextButton(
      onPressed: busy ? null : () => Navigator.pop(context, false),
      child: Text(context.tr('Cancel')),
    ),
    FilledButton(
      key: const Key('save-work-location'),
      onPressed: busy ? null : onSave,
      child: Text(context.tr('Save location')),
    ),
  ],
);

Widget _coordField(
  BuildContext context,
  TextEditingController controller,
  String label,
  bool busy,
) => TextField(
  controller: controller,
  enabled: !busy,
  keyboardType: const TextInputType.numberWithOptions(
    decimal: true,
    signed: true,
  ),
  decoration: InputDecoration(labelText: context.tr(label)),
);
