import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/manager_performance/presentation/cubit/manager_performance_cubit.dart';
import 'package:shiftly/features/manager_performance/presentation/cubit/manager_performance_state.dart';
import 'package:shiftly/features/manager_performance/presentation/cubit/manager_resource_state.dart';
import 'package:shiftly/features/manager_performance/presentation/screens/manager_dispute_screen.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_action_dialog.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_forms.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_recovery_banner.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_resource_list.dart';

class ManagerPerformanceScreen extends StatefulWidget {
  const ManagerPerformanceScreen({super.key});
  @override
  State<ManagerPerformanceScreen> createState() =>
      _ManagerPerformanceScreenState();
}

class _ManagerPerformanceScreenState extends State<ManagerPerformanceScreen> {
  String _section = 'summary';
  String? _status;
  String _search = '';
  Object? _scope;
  Map<String, Object?> get _query => {
    if (_section == 'summary' && _search.isNotEmpty) 'search': _search,
    if (_section == 'disputes' && _status != null) 'status': _status,
  };
  void _load() {
    final cubit = context.read<ManagerPerformanceCubit>();
    cubit.load(_section, query: _query);
    if (_section == 'policies') {
      cubit.load('policies/current', object: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = context.read<ManagerPerformanceCubit>().state.scope;
    if (_scope != scope) {
      _scope = scope;
      _load();
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<ManagerPerformanceCubit, ManagerPerformanceState>(
    listenWhen: (before, after) => before.scope != after.scope,
    listener: (context, state) {
      _search = '';
      _status = null;
      _scope = state.scope;
      _load();
    },
    builder: (context, state) {
      final cubit = context.read<ManagerPerformanceCubit>();
      final resource =
          state.resources[ManagerPerformanceCubit.key(_section, null)] ??
          const ManagerResourceState();
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('Performance'))),
        body: state.scope == null
            ? Center(
                child: Text(context.tr('Active manager workspace required.')),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  await cubit.load(_section, query: _query);
                  if (_section == 'policies') {
                    await cubit.load('policies/current', object: true);
                  }
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    ManagerRecoveryBanner(cubit: cubit, state: state),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final section in const {
                          'summary': 'Overview / employees',
                          'policies': 'Points Policies',
                          'disputes': 'Disputes',
                          'warnings': 'Warnings',
                        }.entries)
                          ChoiceChip(
                            label: Text(context.tr(section.value)),
                            selected: _section == section.key,
                            onSelected: (_) {
                              setState(() => _section = section.key);
                              _load();
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_section == 'summary')
                      TextFormField(
                        key: ValueKey(state.scope),
                        initialValue: _search,
                        maxLength: 100,
                        decoration: InputDecoration(
                          labelText: context.tr('Employee name'),
                          suffixIcon: const Icon(Icons.search),
                        ),
                        onFieldSubmitted: (value) {
                          setState(() => _search = value.trim());
                          _load();
                        },
                      ),
                    if (_section == 'disputes')
                      Wrap(
                        spacing: 6,
                        children: [
                          for (final status in const [
                            null,
                            'PENDING',
                            'APPROVED',
                            'REJECTED',
                            'CANCELLED',
                          ])
                            FilterChip(
                              label: Text(context.tr(status ?? 'All')),
                              selected: _status == status,
                              onSelected: (_) {
                                setState(() => _status = status);
                                _load();
                              },
                            ),
                        ],
                      ),
                    if (_section == 'policies') ...[
                      Text(context.tr('Current policy')),
                      if (state
                              .resources['workspace:policies/current']
                              ?.loading ==
                          true)
                        const LinearProgressIndicator(),
                      if (state.resources['workspace:policies/current']?.error
                          case final error?)
                        Text(context.tr(error)),
                      if (state.resources['workspace:policies/current']?.object
                          case final current?)
                        Text(
                          context.tr(
                            'Effective {value1} · Points enabled: {value2}',
                            {
                              'value1': (current['effectiveFrom']).toString(),
                              'value2': context.tr('${current['isEnabled']}'),
                            },
                          ),
                        ),
                      FilledButton.icon(
                        onPressed:
                            !state.canMutate ||
                                resource.loading ||
                                resource.error != null ||
                                state
                                        .resources['workspace:policies/current']
                                        ?.object ==
                                    null
                            ? null
                            : () async {
                                final scope = state.scope!;
                                final dates =
                                    resource.records
                                        .map(
                                          (record) =>
                                              record.text('effectiveFrom'),
                                        )
                                        .toList()
                                      ..sort();
                                final payload =
                                    await showDialog<Map<String, Object?>>(
                                      context: context,
                                      builder: (_) => ManagerActionDialog(
                                        title: context.tr(
                                          'Create policy version',
                                        ),
                                        fields: ManagerForms.policy,
                                        cubit: cubit,
                                        scope: scope,
                                        afterDate: dates.isEmpty
                                            ? null
                                            : dates.last,
                                        initial: {
                                          ...?state
                                              .resources['workspace:policies/current']
                                              ?.object,
                                          'effectiveFrom': '',
                                        },
                                      ),
                                    );
                                if (payload != null &&
                                    cubit.state.scope == scope &&
                                    context.mounted) {
                                  await cubit.submit('policies', payload);
                                }
                              },
                        icon: const Icon(Icons.add),
                        label: Text(context.tr('New future-effective version')),
                      ),
                      Text(context.tr('Version history')),
                    ],
                    ManagerResourceList(
                      resource: _section,
                      state: resource,
                      timezone: state.scope!.timezone,
                      reload: _load,
                      more: () =>
                          cubit.load(_section, more: true, query: _query),
                      onRecord: _section == 'disputes'
                          ? (record) => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => BlocProvider.value(
                                  value: cubit,
                                  child: ManagerDisputeScreen(id: record.id),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
      );
    },
  );
}
