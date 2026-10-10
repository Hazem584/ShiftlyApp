import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/active_template_selector.dart';

class AssignmentForm extends StatefulWidget {
  const AssignmentForm({
    required this.repository,
    required this.cubit,
    required this.workspaceId,
    required this.timezone,
    super.key,
  });
  final FixedShiftRepository repository;
  final WorkPatternCubit cubit;
  final String workspaceId, timezone;
  @override
  State<AssignmentForm> createState() => _AssignmentFormState();
}

class _AssignmentFormState extends State<AssignmentForm> {
  final days = <int>{};
  late DateTime date, today;
  List<ShiftTemplate>? templates;
  String? templateId, error;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    final local = WorkspaceTime.inWorkspace(
      DateTime.now().toUtc(),
      widget.timezone,
    );
    today = DateTime(local.year, local.month, local.day);
    date = today;
    _load();
  }

  Future<void> _load() async {
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
      setState(() {
        templates = result;
        error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Unable to load active templates. Retry.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr('Assign a fixed shift')),
    scrollable: true,
    content: SizedBox(
      width: 480,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr(
              'Effective dates use {value1}. Saved assignment schedules remain unchanged when a template is edited.',
              {'value1': (widget.timezone).toString()},
            ),
          ),
          const SizedBox(height: 12),
          if (templates == null)
            TextButton(
              onPressed: busy ? null : _load,
              child: Text(context.tr('Load / retry templates')),
            )
          else if (templates!.isEmpty)
            Text(context.tr('No active templates. Create one first.'))
          else
            ActiveTemplateSelector(
              templates: templates!,
              value: templateId,
              onChanged: busy ? null : (v) => setState(() => templateId = v),
            ),
          const SizedBox(height: 12),
          Text(context.tr('Expected weekdays')),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var day = 0; day < 7; day++)
                FilterChip(
                  key: Key('weekday-$day'),
                  label: Text(
                    [
                      context.tr('Sun'),
                      context.tr('Mon'),
                      context.tr('Tue'),
                      context.tr('Wed'),
                      context.tr('Thu'),
                      context.tr('Fri'),
                      context.tr('Sat'),
                    ][day],
                  ),
                  selected: days.contains(day),
                  onSelected: busy
                      ? null
                      : (selected) => setState(() {
                          selected ? days.add(day) : days.remove(day);
                        }),
                ),
            ],
          ),
          OutlinedButton(
            onPressed: busy ? null : _pickDate,
            child: Text(
              context.tr('Effective {value1}', {
                'value1': (WorkspaceTime.localDateKey(
                  year: date.year,
                  month: date.month,
                  day: date.day,
                )).toString(),
              }),
            ),
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
        onPressed: busy || days.isEmpty || templateId == null ? null : _submit,
        child: Text(
          busy ? context.tr('Saving…') : context.tr('Review replacement'),
        ),
      ),
    ],
  );
  Future<void> _pickDate() async {
    final local = WorkspaceTime.inWorkspace(
      DateTime.now().toUtc(),
      widget.timezone,
    );
    today = DateTime(local.year, local.month, local.day);
    final chosen = await showDatePicker(
      context: context,
      initialDate: date.isBefore(today) ? today : date,
      firstDate: today,
      lastDate: DateTime(today.year + 5, 12, 31),
    );
    if (mounted && chosen != null) {
      setState(() => date = chosen);
    }
  }

  Future<void> _submit() async {
    final key = WorkspaceTime.localDateKey(
      year: date.year,
      month: date.month,
      day: date.day,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.tr('Replace the baseline assignment?')),
        content: Text(
          context.tr(
            '{value1}\nEffective {value2} · {value3}\nThe previous version ends the day before. Captured history is protected; the server may reject this replacement.',
            {
              'value1': (templates!.firstWhere((v) => v.id == templateId).name)
                  .toString(),
              'value2': (key).toString(),
              'value3': (widget.timezone).toString(),
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(context.tr('Back')),
          ),
          FilledButton(
            key: const Key('confirm-work-pattern'),
            onPressed: () => Navigator.pop(c, true),
            child: Text(context.tr('Create version')),
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
    final result = await widget.cubit.replace(
      shiftTemplateId: templateId!,
      weekdays: days,
      effectiveFrom: key,
    );
    if (!mounted) {
      return;
    }
    if (result == FixedShiftMutationResult.success) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        busy = false;
        error =
            widget.cubit.state.failure?.message ??
            'Unable to save assignment. Your selections are retained.';
      });
    }
  }
}
