import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/manager_performance/presentation/cubit/manager_performance_cubit.dart';
import 'package:shiftly/features/manager_performance/presentation/cubit/manager_performance_state.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_confirmation_dialog.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_form_field.dart';

class ManagerActionDialog extends StatefulWidget {
  const ManagerActionDialog({
    required this.title,
    required this.fields,
    required this.cubit,
    required this.scope,
    this.initial = const {},
    this.afterDate,
    super.key,
  });
  final String title;
  final List<ManagerFormField> fields;
  final ManagerPerformanceCubit cubit;
  final FeatureSessionScope scope;
  final Map<String, Object?> initial;
  final String? afterDate;
  @override
  State<ManagerActionDialog> createState() => _ManagerActionDialogState();
}

class _ManagerActionDialogState extends State<ManagerActionDialog> {
  final _form = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, Object?> _values = {};
  StreamSubscription<ManagerPerformanceState>? _subscription;
  bool _confirming = false;
  @override
  void initState() {
    super.initState();
    for (final field in widget.fields) {
      final value =
          widget.initial[field.key] ?? field.initial ?? field.choices?.first;
      if (field.boolean || field.choices != null) {
        _values[field.key] = value;
      } else {
        _controllers[field.key] = TextEditingController(
          text: value?.toString() ?? '',
        );
      }
    }
    _subscription = widget.cubit.stream.listen((state) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _allowed =>
      widget.cubit.state.scope == widget.scope && widget.cubit.state.canMutate;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr(widget.title)),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_allowed)
                Text(
                  context.tr(
                    'Manager access changed or another operation needs recovery.',
                  ),
                ),
              if (_allowed)
                for (final (index, field) in widget.fields.indexed) ...[
                  if (field.label.contains(' · ') &&
                      (index == 0 ||
                          widget.fields[index - 1].label.split(' · ').first !=
                              field.label.split(' · ').first))
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          context.tr(field.label.split(' · ').first),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _field(field),
                  ),
                ],
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _confirming ? null : () => Navigator.pop(context),
        child: Text(context.tr('Cancel')),
      ),
      FilledButton(
        onPressed: !_allowed || _confirming ? null : _confirm,
        child: Text(context.tr('Review change')),
      ),
    ],
  );
  Widget _field(ManagerFormField field) {
    if (field.boolean) {
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(context.tr(field.label)),
        value: _values[field.key] == true,
        onChanged: !_allowed
            ? null
            : (value) => setState(() => _values[field.key] = value),
      );
    }
    if (field.choices != null) {
      return DropdownButtonFormField<String>(
        itemHeight: null,
        initialValue: _values[field.key] as String?,
        isExpanded: true,
        decoration: InputDecoration(labelText: context.tr(field.label)),
        items: field.choices!
            .map(
              (value) => DropdownMenuItem(
                value: value,
                child: Text(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? context.tr(value)
                      : value.replaceAll('_', ' '),
                  softWrap: true,
                ),
              ),
            )
            .toList(),
        onChanged: !_allowed ? null : (value) => _values[field.key] = value,
      );
    }
    final numeric = field.initial is int;
    return TextFormField(
      controller: _controllers[field.key],
      enabled: _allowed && !_confirming,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(signed: true)
          : TextInputType.text,
      minLines: numeric || field.date ? 1 : 2,
      maxLines: numeric || field.date ? 1 : 5,
      decoration: InputDecoration(
        labelText: context.tr(field.label),
        helperText: field.help == null ? null : context.tr(field.help!),
        helperMaxLines: 5,
      ),
      validator: (text) {
        final value = (text ?? '').trim();
        if (field.date) {
          final parsed = DateTime.tryParse('${value}T00:00:00Z');
          if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ||
              parsed == null ||
              WorkspaceTime.dateKey(parsed.toUtc(), 'Etc/UTC') != value) {
            return context.tr('Enter a real calendar date.');
          }
          final today = WorkspaceTime.dateKey(
            DateTime.now(),
            widget.scope.timezone,
          );
          if (value.compareTo(today) <= 0 ||
              (widget.afterDate != null &&
                  value.compareTo(widget.afterDate!) <= 0)) {
            return context.tr('Choose a future date after the latest version.');
          }
        } else if (numeric) {
          final number = int.tryParse(value);
          if (number == null ||
              number < field.minimum! ||
              number > field.maximum! ||
              (field.key == 'amount' && number == 0)) {
            return context.tr(
              field.key == 'amount'
                  ? 'Enter {minimum} to {maximum}, excluding zero.'
                  : 'Enter {minimum} to {maximum}.',
              {'minimum': '${field.minimum}', 'maximum': '${field.maximum}'},
            );
          }
        } else if (value.length < (field.minimum ?? 1) ||
            value.length > (field.maximum ?? 1000)) {
          return context.tr('Use {minimum}–{maximum} characters.', {
            'minimum': '${field.minimum ?? 1}',
            'maximum': '${field.maximum ?? 1000}',
          });
        }
        return null;
      },
    );
  }

  Future<void> _confirm() async {
    if (!_allowed || !_form.currentState!.validate()) {
      return;
    }
    final payload = {
      ..._values,
      for (final field in widget.fields)
        if (_controllers.containsKey(field.key))
          field.key: field.initial is int
              ? int.parse(_controllers[field.key]!.text.trim())
              : _controllers[field.key]!.text.trim(),
    };
    setState(() => _confirming = true);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ManagerConfirmationDialog(
        cubit: widget.cubit,
        scope: widget.scope,
        title: Localizations.localeOf(context).languageCode == 'ar'
            ? context.tr('Confirm {action}?', {
                'action': context.tr(widget.title),
              })
            : 'Confirm ${widget.title.toLowerCase()}?',
        details: widget.fields
            .map((field) {
              final value = '${payload[field.key]}';
              final displayValue = field.boolean || field.choices != null
                  ? context.tr(value)
                  : value;
              return '${context.tr(field.label)}: $displayValue';
            })
            .join('\n\n'),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() => _confirming = false);
    if (confirmed == true && _allowed) {
      Navigator.pop(context, payload);
    }
  }
}
