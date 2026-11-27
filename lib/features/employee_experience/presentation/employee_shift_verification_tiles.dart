import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/models/workspace_work_location.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_tile.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/eligible_shift_occurrence.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/template_eligibility.dart';

List<Widget> buildEmployeeShiftVerificationTiles(
  BuildContext context, {
  required EligibleShiftOccurrence entry,
  required TemplateEligibility? eligibility,
}) {
  final geoMode = eligibility?.geofenceMode ?? 'OFF';
  final selfieMode = eligibility?.selfieMode ?? 'OFF';
  final locations =
      eligibility?.workLocations ?? const <WorkspaceWorkLocation>[];
  final pinnedId = entry.template.workLocationId;
  final pinned = pinnedId == null
      ? null
      : locations.where((l) => l.id == pinnedId).firstOrNull;
  final locationLabel = pinned != null
      ? '${pinned.name} (${pinned.radiusMeters}m)'
      : entry.template.workLocationName != null
      ? entry.template.workLocationName!
      : locations.isNotEmpty
      ? locations.map((l) => '${l.name} (${l.radiusMeters}m)').join(' · ')
      : context.tr('Workplace on-site location');
  final showLocation =
      geoMode != 'OFF' ||
      pinnedId != null ||
      entry.template.workLocationName != null ||
      locations.isNotEmpty;

  return [
    if (showLocation) ...[
      const SizedBox(height: 14),
      EmployeeTile(
        icon: Icons.location_on_outlined,
        title: context.tr(
          geoMode == 'ENFORCE'
              ? 'On-site location required'
              : 'Workplace location check',
        ),
        subtitle:
            '$locationLabel\n${context.tr('You must be on-site at the workplace location to clock in.')}',
      ),
    ],
    if (selfieMode != 'OFF') ...[
      const SizedBox(height: 14),
      EmployeeTile(
        icon: Icons.camera_front_outlined,
        title: context.tr(
          selfieMode == 'REQUIRED'
              ? 'Front-camera selfie required'
              : 'Front-camera selfie verification',
        ),
        subtitle: context.tr(
          'Front camera only · Look directly at the camera without sunglasses, mask, or face covering.',
        ),
      ),
    ],
  ];
}
