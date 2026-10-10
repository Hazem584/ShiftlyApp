import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/manager_performance/domain/entities/manager_points_record.dart';
import 'package:shiftly/features/manager_performance/presentation/cubit/manager_performance_cubit.dart';
import 'package:shiftly/features/manager_performance/presentation/cubit/manager_performance_state.dart';
import 'package:shiftly/features/manager_performance/presentation/cubit/manager_resource_state.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_action_dialog.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_audit_dialog.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_calendar.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_form_field.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_forms.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_recovery_banner.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_resource_list.dart';
import 'package:shiftly/features/points/domain/entities/points_models.dart';
import 'package:shiftly/features/points/presentation/widgets/points_achievements.dart';
import 'package:shiftly/features/points/presentation/widgets/points_wallet.dart';

class EmployeePerformanceScreen extends StatefulWidget {
  const EmployeePerformanceScreen({required this.membershipId, super.key});
  final String membershipId;
  @override
  State<EmployeePerformanceScreen> createState() =>
      _EmployeePerformanceScreenState();
}

class _EmployeePerformanceScreenState extends State<EmployeePerformanceScreen> {
  String _section = 'calendar';
  DateTime _month = DateTime.now();
  String? _type;
  ManagerPerformanceCubit get _cubit => context.read<ManagerPerformanceCubit>();
  ManagerResourceState _resource(
    ManagerPerformanceState state,
    String resource,
  ) =>
      state.resources[ManagerPerformanceCubit.key(
        resource,
        widget.membershipId,
      )] ??
      const ManagerResourceState();
  Map<String, Object?> get _query => _section == 'calendar'
      ? {'year': _month.year, 'month': _month.month}
      : {if (_section == 'history' && _type != null) 'pointType': _type};
  void _load() {
    _cubit.load('', target: widget.membershipId, object: true);
    _cubit.load(_section, target: widget.membershipId, query: _query);
  }

  @override
  void initState() {
    super.initState();
    _resetMonth();
    _load();
  }

  void _resetMonth() {
    final date = DateTime.parse(
      WorkspaceTime.dateKey(
        DateTime.now(),
        _cubit.state.scope?.timezone ?? 'Etc/UTC',
      ),
    );
    _month = DateTime(date.year, date.month);
  }

  @override
  void didUpdateWidget(covariant EmployeePerformanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.membershipId != widget.membershipId) {
      _type = null;
      _resetMonth();
      _load();
    }
  }

  Future<void> _action(
    String title,
    String resource,
    List<ManagerFormField> fields,
    String uuidField,
  ) async {
    final scope = _cubit.state.scope;
    if (scope == null || !_cubit.state.canMutate) {
      return;
    }
    final target = widget.membershipId;
    final payload = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (_) => ManagerActionDialog(
        title: title,
        fields: fields,
        cubit: _cubit,
        scope: scope,
      ),
    );
    if (payload != null &&
        mounted &&
        widget.membershipId == target &&
        _cubit.state.scope == scope) {
      await _cubit.submit(
        resource,
        payload,
        target: target,
        uuidField: uuidField,
      );
    }
  }

  Future<void> _record(ManagerPointsRecord record) async {
    final scope = _cubit.state.scope;
    final target = widget.membershipId;
    final section = _section;
    if (scope == null) {
      return;
    }
    if (section == 'adjustments') {
      await _cubit.load(
        'adjustments/${record.id}',
        target: target,
        object: true,
      );
      if (!mounted ||
          _cubit.state.scope != scope ||
          target != widget.membershipId) {
        return;
      }
      final detail = _resource(_cubit.state, 'adjustments/${record.id}').object;
      if (detail == null) {
        return;
      }
      record = ManagerPointsRecord(detail);
    }
    if (!mounted ||
        _cubit.state.scope != scope ||
        target != widget.membershipId) {
      return;
    }
    final reverse = await showDialog<bool>(
      context: context,
      builder: (_) =>
          ManagerAuditDialog(record: record, cubit: _cubit, scope: scope),
    );
    if (reverse != true ||
        !mounted ||
        _cubit.state.scope != scope ||
        target != widget.membershipId) {
      return;
    }
    await _action(
      section == 'adjustments' ? 'Reverse adjustment' : 'Reverse extra effort',
      '$section/${record.id}/reverse',
      section == 'adjustments'
          ? ManagerForms.adjustment(reverse: true)
          : ManagerForms.effort(reverse: true),
      'clientReversalId',
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<ManagerPerformanceCubit, ManagerPerformanceState>(
    listenWhen: (before, after) => before.scope != after.scope,
    listener: (context, state) {
      _type = null;
      _resetMonth();
      _load();
    },
    builder: (context, state) {
      final walletResource = _resource(state, '');
      final json = walletResource.object;
      final wallet = json == null ? null : PointsWallet.fromJson(json);
      final resource = _resource(state, _section);
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('Employee Performance'))),
        body: state.scope == null
            ? Center(
                child: Text(context.tr('Active manager workspace required.')),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  await _cubit.load(
                    '',
                    target: widget.membershipId,
                    object: true,
                  );
                  await _cubit.load(
                    _section,
                    target: widget.membershipId,
                    query: _query,
                  );
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    ManagerRecoveryBanner(cubit: _cubit, state: state),
                    Text(
                      context.tr('Membership: {value1}', {
                        'value1': (widget.membershipId).toString(),
                      }),
                    ),
                    if (walletResource.loading) const LinearProgressIndicator(),
                    if (walletResource.error != null)
                      Text(context.tr(walletResource.error!)),
                    if (wallet != null) ...[
                      PointsWalletView(wallet: wallet),
                      Text(
                        context.tr(
                          'BLACK total: {value1} · This month: {value2}',
                          {
                            'value1': (wallet.black.total).toString(),
                            'value2': (wallet.black.currentMonth).toString(),
                          },
                        ),
                      ),
                      Text(
                        context.tr(
                          'ORANGE total: {value1} · This month: {value2}',
                          {
                            'value1': (wallet.orange.total).toString(),
                            'value2': (wallet.orange.currentMonth).toString(),
                          },
                        ),
                      ),
                      Text(
                        context.tr(
                          'BLUE total: {value1} · This month: {value2}',
                          {
                            'value1': (wallet.blue.total).toString(),
                            'value2': (wallet.blue.currentMonth).toString(),
                          },
                        ),
                      ),
                      Text(
                        context.tr(
                          'GREEN earned: {value1} · Bonuses: {value2} · Adjusted: {value3}',
                          {
                            'value1': (wallet.green.earned).toString(),
                            'value2': (wallet.green.bonuses).toString(),
                            'value3': (wallet.green.adjusted).toString(),
                          },
                        ),
                      ),
                      Text(
                        context.tr(
                          'GREEN spent on compensation: {value1} · RED compensated: {value2}',
                          {
                            'value1': (wallet.green.redeemed).toString(),
                            'value2': (wallet.red.compensated).toString(),
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: state.canMutate && wallet != null
                              ? () => _action(
                                  'Adjust points',
                                  'adjustments',
                                  ManagerForms.adjustment(),
                                  'clientAdjustmentId',
                                )
                              : null,
                          icon: const Icon(Icons.tune),
                          label: Text(context.tr('Adjust points')),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: state.canMutate && wallet != null
                              ? () => _action(
                                  'Grant extra effort',
                                  'extra-effort',
                                  ManagerForms.effort(),
                                  'clientAwardId',
                                )
                              : null,
                          icon: const Icon(Icons.volunteer_activism),
                          label: Text(context.tr('Grant BLUE')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final section in const {
                          'calendar': 'Calendar',
                          'history': 'Ledger history',
                          'achievements': 'Achievements',
                          'warnings': 'Warnings',
                          'extra-effort': 'Extra effort',
                          'adjustments': 'Adjustments',
                        }.entries)
                          ChoiceChip(
                            label: Text(context.tr(section.value)),
                            selected: _section == section.key,
                            onSelected: (_) {
                              setState(() => _section = section.key);
                              _cubit.load(
                                _section,
                                target: widget.membershipId,
                                query: _query,
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_section == 'history')
                      Wrap(
                        spacing: 6,
                        children: [
                          for (final type in const [
                            null,
                            'GREEN',
                            'BLACK',
                            'RED',
                            'ORANGE',
                            'BLUE',
                          ])
                            FilterChip(
                              label: Text(context.tr(type ?? 'All')),
                              selected: _type == type,
                              onSelected: (_) {
                                setState(() => _type = type);
                                _cubit.load(
                                  _section,
                                  target: widget.membershipId,
                                  query: _query,
                                );
                              },
                            ),
                        ],
                      ),
                    if (_section == 'calendar')
                      ManagerCalendar(
                        cubit: _cubit,
                        scope: state.scope,
                        month: _month,
                        state: resource,
                        timezone: state.scope!.timezone,
                        changeMonth: (month) {
                          setState(() => _month = month);
                          _cubit.load(
                            'calendar',
                            target: widget.membershipId,
                            query: _query,
                          );
                        },
                      )
                    else if (_section == 'achievements') ...[
                      if (resource.loading) const LinearProgressIndicator(),
                      if (resource.error != null)
                        Text(context.tr(resource.error!)),
                      PointsAchievements(
                        emptyText: "This employee's active GOLD badges will appear here.",
                        items: resource.records
                            .map(
                              (record) => Achievement.fromJson(record.fields),
                            )
                            .toList(),
                        timezone: state.scope!.timezone,
                      ),
                    ] else
                      ManagerResourceList(
                        resource: _section,
                        state: resource,
                        timezone: state.scope!.timezone,
                        reload: () => _cubit.load(
                          _section,
                          target: widget.membershipId,
                          query: _query,
                        ),
                        more: () => _cubit.load(
                          _section,
                          target: widget.membershipId,
                          more: true,
                          query: _query,
                        ),
                        onRecord:
                            {
                                  'adjustments',
                                  'extra-effort',
                                }.contains(_section) &&
                                state.canMutate
                            ? _record
                            : null,
                      ),
                  ],
                ),
              ),
      );
    },
  );
}
