import 'package:flutter/widgets.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_forms.dart';

String managerOperationLabel(BuildContext context, String resource) {
  final reversed = resource.endsWith('/reverse');
  final source = switch (resource.split('/').first) {
    'extra-effort' => reversed ? 'Reverse extra effort' : 'Grant extra effort',
    'adjustments' => reversed ? 'Reverse adjustment' : 'Adjust points',
    'policies' => 'Create policy version',
    'disputes' => 'Review dispute',
    _ => 'Saved operation',
  };
  return context.tr(source);
}

/// Localize field metadata, preserving the exact saved values for review.
String managerOperationDetails(
  BuildContext context,
  Map<String, Object?> payload, {
  String? resource,
}) {
  final fields = {
    for (final field in [
      ...ManagerForms.policy,
      ...ManagerForms.adjustment(),
      ...ManagerForms.effort(),
      ...ManagerForms.review,
    ])
      field.key: field,
  };
  return payload.entries
      .map((entry) {
        final field = fields[entry.key];
        final label =
            field?.label ??
            switch (entry.key) {
              'clientAwardId' ||
              'clientAdjustmentId' ||
              'clientReversalId' ||
              'clientPolicyId' => 'Saved request ID',
              'employeeMembershipId' => 'Employee membership',
              _ => entry.key,
            };
        final value = '${entry.value}';
        final isFreeTextReason =
            entry.key == 'reason' && resource?.endsWith('/reverse') == true;
        final display =
            !isFreeTextReason &&
                (field?.boolean == true || field?.choices != null)
            ? context.tr(value)
            : value;
        return '${context.tr(label)}: $display';
      })
      .join('\n\n');
}
