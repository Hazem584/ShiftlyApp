import 'package:flutter/material.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/models/shift.dart';
import 'package:shiftly/core/models/work_location.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_form_header.dart';

class WorkInformationSection extends StatelessWidget {
  const WorkInformationSection({
    super.key,
    required this.jobTitleController,
    required this.locations,
    required this.shifts,
    required this.selectedLocation,
    required this.selectedShift,
    required this.startDate,
    required this.status,
    required this.enabled,
    required this.onLocationChanged,
    required this.onShiftChanged,
    required this.onPickDate,
    required this.onStatusChanged,
  });

  final TextEditingController jobTitleController;
  final List<WorkLocation> locations;
  final List<Shift> shifts;
  final WorkLocation selectedLocation;
  final Shift selectedShift;
  final DateTime startDate;
  final EmploymentStatus status;
  final bool enabled;
  final ValueChanged<WorkLocation> onLocationChanged;
  final ValueChanged<Shift> onShiftChanged;
  final VoidCallback onPickDate;
  final ValueChanged<EmploymentStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: AppSpacing.l),
      const EmployeeFormSectionTitle(
        title: 'Work details',
        subtitle: 'Role, workplace, shift, and employment status',
      ),
      const SizedBox(height: 14),
      EmployeeFormControl(
        label: 'Job title',
        child: TextFormField(
          key: const Key('job-title-field'),
          controller: jobTitleController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(hintText: 'Enter job title'),
          validator: (value) =>
              (value?.trim().length ?? 0) < 2 ? 'Enter a job title' : null,
        ),
      ),
      const SizedBox(height: 13),
      EmployeeFormControl(
        label: 'Workplace / location',
        child: DropdownButtonFormField<WorkLocation>(
          isExpanded: true,
          initialValue: selectedLocation,
          decoration: const InputDecoration(),
          items: locations
              .map(
                (location) => DropdownMenuItem(
                  value: location,
                  child: Text(location.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: enabled
              ? (value) {
                  if (value != null) onLocationChanged(value);
                }
              : null,
        ),
      ),
      const SizedBox(height: 13),
      EmployeeFormControl(
        label: 'Assigned shift',
        child: DropdownButtonFormField<Shift>(
          isExpanded: true,
          initialValue: selectedShift,
          decoration: const InputDecoration(),
          items: shifts
              .map(
                (shift) => DropdownMenuItem(
                  value: shift,
                  child: Text(
                    '${shift.name} • ${shift.timeRange}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: enabled
              ? (value) {
                  if (value != null) onShiftChanged(value);
                }
              : null,
        ),
      ),
      const SizedBox(height: 13),
      EmployeeFormControl(
        label: 'Start date',
        child: InkWell(
          onTap: enabled ? onPickDate : null,
          borderRadius: BorderRadius.circular(AppRadii.m),
          child: InputDecorator(
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
            ),
            child: Text(_formatDate(startDate)),
          ),
        ),
      ),
      const SizedBox(height: 13),
      EmployeeFormControl(
        label: 'Employment status',
        child: DropdownButtonFormField<EmploymentStatus>(
          isExpanded: true,
          initialValue: status,
          decoration: const InputDecoration(),
          items: EmploymentStatus.values
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(_statusLabel(value)),
                ),
              )
              .toList(),
          onChanged: enabled
              ? (value) {
                  if (value != null) onStatusChanged(value);
                }
              : null,
        ),
      ),
    ],
  );

  String _formatDate(DateTime value) =>
      '${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}/${value.year}';

  String _statusLabel(EmploymentStatus value) => switch (value) {
    EmploymentStatus.active => 'Active',
    EmploymentStatus.suspended => 'Suspended',
    EmploymentStatus.onLeave => 'On leave',
    EmploymentStatus.unknown => 'Unknown',
  };
}
