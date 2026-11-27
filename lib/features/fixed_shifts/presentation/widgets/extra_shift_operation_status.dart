import 'package:flutter/material.dart';
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
];
