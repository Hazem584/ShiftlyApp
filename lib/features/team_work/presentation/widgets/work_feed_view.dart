import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/features/team_work/presentation/cubit/work_feed_cubit.dart';

class WorkFeedView<T> extends StatelessWidget {
  const WorkFeedView({
    super.key,
    required this.cubit,
    required this.itemBuilder,
    this.header,
  });
  final WorkFeedCubit<T> cubit;
  final Widget Function(BuildContext, T, bool) itemBuilder;
  final Widget? header;
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<WorkFeedCubit<T>, WorkFeedState<T>>(
        bloc: cubit,
        builder: (context, state) => RefreshIndicator(
          onRefresh: cubit.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              ?header,
              if (state.notice != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(context.tr(state.notice!)),
                ),
              if (state.loading) const AppContentLoading(rows: 1),
              if (state.error != null)
                MaterialBanner(
                  content: Text(context.tr(state.error!)),
                  actions: [
                    TextButton(
                      onPressed: cubit.load,
                      child: Text(context.tr('Retry')),
                    ),
                  ],
                ),
              if (!state.loading && state.items.isEmpty && state.error == null)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    context.tr('Nothing to follow up here.'),
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final item in state.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: itemBuilder(context, item, state.busyId != null),
                ),
              if (state.hasMore)
                TextButton(
                  onPressed: state.loadingMore
                      ? null
                      : () => cubit.load(more: true),
                  child: Text(context.tr('Load more')),
                ),
            ],
          ),
        ),
      );
}
