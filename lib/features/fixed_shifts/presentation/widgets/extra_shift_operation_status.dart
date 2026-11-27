import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/core/widgets/failure_notice.dart';

import '../cubit/extra_shifts_cubit.dart';
import '../cubit/extra_shifts_state.dart';

List<Widget> extraShiftOperationStatus(
  BuildContext context,
  ExtraShiftsCubit cubit,
  ExtraShiftsState state,
  int page,
) => [
  if (state.loading) const AppContentLoading(rows: 1),
  if (state.failure != null)
    FailureNotice(
      failure: state.failure!,
      refreshing: state.loading,
      onRefresh: state.busy ? null : () => cubit.load(page: page),
    ),
  if (state.intent != null) ...[
    Text(
      context.tr(
        'Saved {value1} for employee membership {value2} on {value3}. Resolve this operation before creating another extra.',
        {
          'value1':
              (state.intent!.actual ? 'actual attendance' : 'authorization')
                  .toString(),
          'value2': (state.intent!.membershipId).toString(),
          'value3': (state.intent!.payload['operationalDate']).toString(),
        },
      ),
    ),
    FilledButton.tonal(
      onPressed: state.busy ? null : cubit.recover,
      child: Text(context.tr('Recover saved extra operation')),
    ),
  ],
];
