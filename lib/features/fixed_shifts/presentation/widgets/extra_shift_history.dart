import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/extra_authorization.dart';

import '../cubit/extra_shifts_cubit.dart';
import '../cubit/extra_shifts_state.dart';
import 'extra_authorization_card.dart';

List<Widget> extraShiftHistory(
  BuildContext context,
  ExtraShiftsCubit cubit,
  ExtraShiftsState state, {
  required bool canEdit,
  required ValueChanged<ExtraAuthorization> onRevoke,
}) {
  final pagination = state.page?.pagination;
  return [
    if (state.canonical != null)
      ExpansionTile(
        title: Text(context.tr('Last saved canonical result')),
        children: [ExtraAuthorizationCard(value: state.canonical!)],
      ),
    if (state.page?.data.isEmpty == true)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(context.tr('No extra authorizations recorded.')),
      ),
    for (final value in state.page?.data ?? <ExtraAuthorization>[])
      ExtraAuthorizationCard(
        value: value,
        onRevoke:
            canEdit &&
                !state.busy &&
                !state.loading &&
                !state.recoveryBlocked &&
                value.canRevoke
            ? () => onRevoke(value)
            : null,
      ),
    if (pagination != null && pagination.totalPages > 1)
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          TextButton(
            onPressed: state.loading || state.busy || pagination.page <= 1
                ? null
                : () => cubit.load(page: pagination.page - 1),
            child: Text(context.tr('Previous')),
          ),
          Text(
            context.tr('Page {value1} of {value2}', {
              'value1': (pagination.page).toString(),
              'value2': (pagination.totalPages).toString(),
            }),
          ),
          TextButton(
            onPressed:
                state.loading ||
                    state.busy ||
                    pagination.page >= pagination.totalPages
                ? null
                : () => cubit.load(page: pagination.page + 1),
            child: Text(context.tr('Next')),
          ),
        ],
      ),
  ];
}
