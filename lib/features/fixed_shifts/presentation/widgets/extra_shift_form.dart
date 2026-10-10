import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/utils/workspace_timestamp_input.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/extra_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/active_template_selector.dart';

class ExtraShiftForm extends StatefulWidget {
  const ExtraShiftForm({
    required this.repository,
    required this.cubit,
    required this.workspaceId,
    required this.timezone,
    required this.actual,
    super.key,
  });
  final FixedShiftRepository repository;
  final ExtraShiftsCubit cubit;
  final String workspaceId, timezone;
  final bool actual;
  @override
  State<ExtraShiftForm> createState() => _ExtraShiftFormState();
}

class _ExtraShiftFormState extends State<ExtraShiftForm> {
  final explanation = TextEditingController(),
      actualIn = TextEditingController(),
      actualOut = TextEditingController();
  static const reasons = [
    'COVERED_EMPLOYEE',
    'ADDITIONAL_SHIFT',
    'APPROVED_OVERTIME',
    'EMERGENCY_SUPPORT',
    'HIGH_WORKLOAD_SUPPORT',
    'OTHER',
  ];
  String reason = 'ADDITIONAL_SHIFT';
  String? templateId, error;
  List<ShiftTemplate>? templates;
  late DateTime date;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    final today = WorkspaceTime.inWorkspace(
      DateTime.now().toUtc(),
      widget.timezone,
    );
    date = DateTime(today.year, today.month, today.day);
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final result = <ShiftTemplate>[];
      var page = 1;
      while (true) {
        final value = await widget.repository.listTemplates(
          widget.workspaceId,
          page: page,
        );
        if (!mounted) {
          return;
        }
        if (value.data.any((v) => v.workspaceId != widget.workspaceId)) {
          throw const FormatException('Invalid template scope');
        }
        result.addAll(value.data.where((v) => v.active));
        if (page >= value.pagination.totalPages) {
          break;
        }
        page++;
      }
      if (mounted) {
        setState(() {
          templates = result;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Unable to load active templates. Retry.');
      }
    }
  }

  @override
  void dispose() {
    explanation.dispose();
    actualIn.dispose();
    actualOut.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.actual
          ? context.tr('Record extra attendance')
          : context.tr('Authorize an extra shift'),
    ),
    scrollable: true,
    content: SizedBox(
      width: 480,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr(
              'Times and operational dates in {value1}. Overnight shifts use their start date.',
              {'value1': (widget.timezone).toString()},
            ),
          ),
          const SizedBox(height: 12),
          if (templates == null)
            TextButton(
              onPressed: busy ? null : _loadTemplates,
              child: Text(context.tr('Load / retry templates')),
            )
          else if (templates!.isEmpty)
            Text(
              context.tr(
                'No active templates. Create one before assigning extras.',
              ),
            )
          else
            ActiveTemplateSelector(
              templates: templates!,
              value: templateId,
              onChanged: busy ? null : (v) => setState(() => templateId = v),
            ),
          OutlinedButton(
            onPressed: busy ? null : _pickDate,
            child: Text(
              context.tr('Operational date {value1}', {
                'value1': (WorkspaceTime.localDateKey(
                  year: date.year,
                  month: date.month,
                  day: date.day,
                )).toString(),
              }),
            ),
          ),
          DropdownButtonFormField<String>(
            initialValue: reason,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: context.tr('Structured reason'),
            ),
            items: [
              for (final value in reasons)
                DropdownMenuItem(
                  value: value,
                  child: Text(
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? context.tr(value)
                        : value.replaceAll('_', ' '),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: busy ? null : (v) => setState(() => reason = v!),
          ),
          TextField(
            controller: explanation,
            enabled: !busy,
            maxLength: 1000,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: context.tr('Explanation (3–1000 characters)'),
            ),
          ),
          if (widget.actual) ...[
            Text(
              context.tr(
                'Enter local dates/times with the offset applicable at each instant. During a repeated DST hour, choose the intended offset explicitly. Missing DST times are invalid.',
              ),
            ),
            TextField(
              controller: actualIn,
              enabled: !busy,
              decoration: InputDecoration(
                labelText: context.tr('Actual clock-in with offset'),
                hintText: '2026-10-09T08:00:00+03:00',
              ),
            ),
            TextField(
              controller: actualOut,
              enabled: !busy,
              decoration: InputDecoration(
                labelText: context.tr('Actual clock-out with offset'),
                hintText: '2026-10-09T16:00:00+03:00',
              ),
            ),
            Text(
              context.tr(
                'Recording EXTRA attendance does not award BLUE. Use Employee Performance → Extra effort approval separately and link the attendance.',
              ),
            ),
          ],
          if (widget.cubit.state.intent != null)
            FilledButton.tonal(
              onPressed: busy ? null : _recover,
              child: Text(context.tr('Recover saved extra operation')),
            ),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: Text(context.tr('Cancel')),
      ),
      FilledButton(
        onPressed:
            busy || templateId == null || widget.cubit.state.recoveryBlocked
            ? null
            : _submit,
        child: Text(
          busy ? context.tr('Saving…') : context.tr('Review and save'),
        ),
      ),
    ],
  );
  Future<void> _recover() async {
    if (widget.cubit.isClosed) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    final saved = await widget.cubit.recover();
    if (!mounted) {
      return;
    }
    if (saved) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        busy = false;
        error =
            widget.cubit.state.failure?.message ??
            'Recovery is still unresolved.';
      });
    }
  }

  Future<void> _pickDate() async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime(date.year + 5, 12, 31),
    );
    if (mounted && chosen != null) {
      setState(() => date = chosen);
    }
  }

  Future<void> _submit() async {
    final text = explanation.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.length < 3 || text.length > 1000) {
      setState(() => error = 'Enter an explanation of 3–1000 characters.');
      return;
    }
    final payload = <String, Object?>{
      'shiftTemplateId': templateId,
      'operationalDate': WorkspaceTime.localDateKey(
        year: date.year,
        month: date.month,
        day: date.day,
      ),
      'reason': reason,
      'explanation': text,
    };
    try {
      if (widget.actual) {
        final start = WorkspaceTimestampInput.parse(
              actualIn.text,
              widget.timezone,
            ),
            end = WorkspaceTimestampInput.parse(
              actualOut.text,
              widget.timezone,
            );
        WorkspaceTimestampInput.validateRange(
          start,
          end,
          DateTime.now().toUtc(),
        );
        payload['actualClockInAt'] = start.toIso8601String();
        payload['actualClockOutAt'] = end.toIso8601String();
      }
    } on FormatException catch (e) {
      setState(() => error = e.message);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.tr('Confirm extra shift')),
        scrollable: true,
        content: Text(
          context.tr(
            '{value1}\n{value2} · {value3}\n{value4}\n{value5}{value6}',
            {
              'value1': (templates!.firstWhere((t) => t.id == templateId).name)
                  .toString(),
              'value2': (payload['operationalDate']).toString(),
              'value3': (widget.timezone).toString(),
              'value4': context.tr(reason),
              'value5': (text).toString(),
              'value6':
                  (widget.actual
                          ? context.tr(
                              '\nClock-in: {start}\nClock-out: {end}\nNo automatic BLUE award.',
                              {
                                'start': WorkspaceTime.dateTime(
                                  DateTime.parse(
                                    payload['actualClockInAt'] as String,
                                  ),
                                  widget.timezone,
                                  locale: Localizations.localeOf(context)
                                      .toString(),
                                ),
                                'end': WorkspaceTime.dateTime(
                                  DateTime.parse(
                                    payload['actualClockOutAt'] as String,
                                  ),
                                  widget.timezone,
                                  locale: Localizations.localeOf(context)
                                      .toString(),
                                ),
                              },
                            )
                          : '')
                      .toString(),
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(context.tr('Back')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(context.tr('Confirm')),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || widget.cubit.isClosed) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    final success = await widget.cubit.create(payload, actual: widget.actual);
    if (!mounted) {
      return;
    }
    if (success) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        busy = false;
        error = widget.cubit.state.failure?.message ?? 'Recover the saved operation in Extra Shifts before submitting again.';
      });
    }
  }
}
