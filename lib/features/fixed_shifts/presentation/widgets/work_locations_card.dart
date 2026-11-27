import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/work_location_repository.dart';

Widget buildWorkLocationsCard({
  required BuildContext context,
  required String mode,
  required List<WorkspaceWorkLocation> locations,
  required bool loading,
  required bool busy,
  required String? error,
  required ValueChanged<String> onModeChanged,
  required VoidCallback onAdd,
  required ValueChanged<WorkspaceWorkLocation> onEdit,
  required ValueChanged<WorkspaceWorkLocation> onArchive,
  required VoidCallback onRefresh,
}) {
  final disabled = loading || busy;
  return SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr('Workplace locations & Geofence'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              onPressed: disabled ? null : onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        Text(
          context.tr(
            'Verify that employees clock in from an approved branch radius.',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final item in const [
              ('OFF', 'Off'),
              ('WARN', 'Warn only'),
              ('ENFORCE', 'Enforce on clock-in'),
            ])
              ChoiceChip(
                key: Key('geofence-mode-${item.$1}'),
                label: Text(context.tr(item.$2)),
                selected: mode == item.$1,
                onSelected: disabled ? null : (_) => onModeChanged(item.$1),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            key: const Key('add-work-location'),
            onPressed: disabled ? null : onAdd,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: Text(context.tr('Add work location')),
          ),
        ),
        if (error != null)
          Text(
            context.tr(error),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (loading) const AppContentLoading(rows: 1),
        if (!loading && locations.isEmpty)
          Text(context.tr('No work locations added yet.')),
        for (final loc in locations)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.place_outlined),
            title: Text(loc.name),
            subtitle: Text(
              '${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)} · ${loc.radiusMeters}m',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: disabled ? null : () => onEdit(loc),
                ),
                IconButton(
                  icon: const Icon(Icons.archive_outlined),
                  onPressed: disabled ? null : () => onArchive(loc),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
