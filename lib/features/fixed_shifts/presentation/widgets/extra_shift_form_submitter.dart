import 'package:flutter/material.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/extra_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/extra_shift_confirm_dialog.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/extra_shift_payload_builder.dart';

Future<void> recoverExtraShiftOperation({
  required BuildContext context,
  required ExtraShiftsCubit cubit,
  required bool Function() isMounted,
  required void Function(bool busy, String? error) updateState,
}) async {
  if (cubit.isClosed) return;
  updateState(true, null);
  final saved = await cubit.recover();
  if (!context.mounted || !isMounted()) return;
  if (saved) return Navigator.pop(context, true);
  updateState(
    false,
    cubit.state.failure?.message ?? 'Recovery is still unresolved.',
  );
}

Future<void> submitExtraShiftForm({
  required BuildContext context,
  required ExtraShiftsCubit cubit,
  required List<ShiftTemplate> templates,
  required String templateId,
  required DateTime date,
  required String reason,
  required String explanationText,
  required bool actual,
  required String actualInText,
  required String actualOutText,
  required String timezone,
  required bool Function() isMounted,
  required void Function(bool busy, String? error) updateState,
}) async {
  final text = explanationText.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (text.length < 3 || text.length > 1000) {
    return updateState(false, 'Enter an explanation of 3–1000 characters.');
  }
  final Map<String, Object?> payload;
  try {
    payload = buildExtraShiftPayload(
      templateId: templateId,
      date: date,
      reason: reason,
      explanationText: text,
      actual: actual,
      actualInText: actualInText,
      actualOutText: actualOutText,
      timezone: timezone,
    );
  } on FormatException catch (e) {
    return updateState(false, e.message);
  }
  final confirmed = await showExtraShiftConfirmDialog(
    context: context,
    templates: templates,
    templateId: templateId,
    payload: payload,
    timezone: timezone,
    reason: reason,
    text: text,
    actual: actual,
  );
  if (!isMounted() || confirmed != true || cubit.isClosed) return;
  updateState(true, null);
  final success = await cubit.create(payload, actual: actual);
  if (!context.mounted || !isMounted()) return;
  if (success) return Navigator.pop(context, true);
  updateState(
    false,
    cubit.state.failure?.message ??
        'Recover the saved operation in Extra Shifts before submitting again.',
  );
}
