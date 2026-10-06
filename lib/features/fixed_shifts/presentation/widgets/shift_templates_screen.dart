import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/fixed_shifts/data/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';

class ShiftTemplatesScreen extends StatelessWidget {
  const ShiftTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final workspace = context
        .watch<SessionCoordinator>()
        .state
        .activeMembership
        ?.workspace;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fixed shift templates'),
        actions: [
          IconButton(
            tooltip: 'Create template',
            onPressed: () => _openEditor(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: BlocConsumer<ManagerTemplatesCubit, ManagerTemplatesState>(
        listenWhen: (a, b) => a.failure != b.failure && b.failure != null,
        listener: (context, state) => ToastService.error(
          context,
          message: _supportMessage(
            state.failure!.message,
            state.failure!.requestId,
          ),
        ),
        builder: (context, state) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
              child: SurfaceCard(
                child: Row(
                  children: [
                    const CircleAvatar(child: Icon(Icons.schedule_rounded)),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workspace?.name ?? 'Current workspace',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${workspace?.timezone ?? 'Etc/UTC'} • ${state.templates.where((item) => item.active).length} active templates',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    FilterChip(
                      key: const Key('show-archived-templates'),
                      label: const Text('Archived'),
                      selected: state.includeArchived,
                      onSelected: (value) => context
                          .read<ManagerTemplatesCubit>()
                          .load(includeArchived: value),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: _body(context, state)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New template'),
      ),
    );
  }

  Widget _body(BuildContext context, ManagerTemplatesState state) {
    if (state.loading) return const Center(child: CircularProgressIndicator());
    if (state.templates.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            context.read<ManagerTemplatesCubit>().load(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            EmptyState(
              icon: state.failure == null
                  ? Icons.schedule_outlined
                  : Icons.cloud_off_outlined,
              title: state.failure == null
                  ? 'No fixed shifts yet'
                  : 'Templates unavailable',
              message:
                  state.failure?.message ??
                  'Create one reusable schedule for many employees.',
              action: state.failure == null
                  ? null
                  : FilledButton(
                      onPressed: () =>
                          context.read<ManagerTemplatesCubit>().load(),
                      child: const Text('Retry'),
                    ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () =>
          context.read<ManagerTemplatesCubit>().load(refresh: true),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 760 ? 2 : 1;
          return GridView.builder(
            key: const Key('shift-template-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 96),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 238,
            ),
            itemCount: state.templates.length,
            itemBuilder: (context, index) => _TemplateCard(
              template: state.templates[index],
              busy: state.archivingId == state.templates[index].id,
              onEdit: () => _openEditor(context, state.templates[index]),
              onArchive: () => _archive(context, state.templates[index]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context, [
    ShiftTemplate? template,
  ]) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<ManagerTemplatesCubit>(),
        child: _TemplateEditorDialog(template: template),
      ),
    );
  }

  Future<void> _archive(BuildContext context, ShiftTemplate template) async {
    if (!template.active) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Archive template?'),
        content: Text(
          '${template.name} will become read-only and remain in history. Existing attendance is preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep active'),
          ),
          FilledButton(
            key: const Key('confirm-archive-template'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await context.read<ManagerTemplatesCubit>().archive(
      template.id,
    );
    if (context.mounted && result == FixedShiftMutationResult.success) {
      ToastService.success(context, message: 'Template archived.');
    }
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.busy,
    required this.onEdit,
    required this.onArchive,
  });
  final ShiftTemplate template;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final color = _color(template.color);
    return Opacity(
      opacity: template.active ? 1 : .68,
      child: SurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    template.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Chip(
                  avatar: Icon(
                    template.active
                        ? Icons.check_circle_outline
                        : Icons.archive_outlined,
                    size: 16,
                  ),
                  label: Text(template.active ? 'Active' : 'Archived'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${_time(template.startMinute)} – ${_time(template.endMinute)}  •  ${_duration(template.durationMinutes)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (template.overnight)
              const Padding(
                padding: EdgeInsets.only(top: 3),
                child: Row(
                  children: [
                    Icon(Icons.nights_stay_outlined, size: 15),
                    SizedBox(width: 4),
                    Text('Overnight / next-day end'),
                  ],
                ),
              ),
            const SizedBox(height: 9),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _policy(
                  Icons.hourglass_top_rounded,
                  '${template.graceMinutes}m grace',
                ),
                _policy(
                  Icons.login_rounded,
                  '${template.allowedEarlyCheckInMinutes}m early',
                ),
                _policy(
                  Icons.more_time_rounded,
                  '${template.allowedLateCheckInMinutes}m late',
                ),
                _policy(
                  Icons.timer_outlined,
                  '${_duration(template.minimumWorkMinutes)} minimum',
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (template.active) ...[
                  TextButton.icon(
                    onPressed: busy ? null : onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: busy ? null : onArchive,
                    icon: busy
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.archive_outlined),
                    label: const Text('Archive'),
                  ),
                ] else
                  const Text(
                    'Read-only history',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _policy(IconData icon, String text) => Chip(
    avatar: Icon(icon, size: 15),
    label: Text(text),
    visualDensity: VisualDensity.compact,
  );
}

class _TemplateEditorDialog extends StatefulWidget {
  const _TemplateEditorDialog({this.template});
  final ShiftTemplate? template;
  @override
  State<_TemplateEditorDialog> createState() => _TemplateEditorDialogState();
}

class _TemplateEditorDialogState extends State<_TemplateEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final List<TextEditingController> _policies;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late String _colorValue;
  String? _localError;
  static const _colors = [
    '#2563EB',
    '#0F766E',
    '#7C3AED',
    '#C2410C',
    '#BE123C',
    '#334155',
  ];

  @override
  void initState() {
    super.initState();
    final value = widget.template;
    _name = TextEditingController(text: value?.name);
    _description = TextEditingController(text: value?.description);
    _start = _tod(value?.startMinute ?? 540);
    _end = _tod(value?.endMinute ?? 1020);
    _colorValue = value?.color ?? _colors.first;
    _policies = [
      TextEditingController(text: '${value?.graceMinutes ?? 10}'),
      TextEditingController(text: '${value?.allowedEarlyCheckInMinutes ?? 30}'),
      TextEditingController(text: '${value?.allowedLateCheckInMinutes ?? 120}'),
      TextEditingController(text: '${value?.minimumWorkMinutes ?? 0}'),
    ];
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    for (final controller in _policies) {
      controller.dispose();
    }
    super.dispose();
  }

  ShiftTemplateInput get _input => ShiftTemplateInput(
    name: _name.text,
    description: _description.text,
    color: _colorValue,
    startMinute: _start.hour * 60 + _start.minute,
    endMinute: _end.hour * 60 + _end.minute,
    graceMinutes: int.tryParse(_policies[0].text) ?? -1,
    allowedEarlyCheckInMinutes: int.tryParse(_policies[1].text) ?? -1,
    allowedLateCheckInMinutes: int.tryParse(_policies[2].text) ?? -1,
    minimumWorkMinutes: int.tryParse(_policies[3].text) ?? -1,
  );

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<ManagerTemplatesCubit, ManagerTemplatesState>(
    builder: (context, state) => AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(
        widget.template == null ? 'Create fixed shift' : 'Edit fixed shift',
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Template name'),
                  validator: (_) => _input.validate()?.contains('name') == true
                      ? _input.validate()
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _description,
                  maxLength: 1000,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: state.saving ? null : () => _pick(true),
                      icon: const Icon(Icons.login_rounded),
                      label: Text('Start ${_start.format(context)}'),
                    ),
                    OutlinedButton.icon(
                      onPressed: state.saving ? null : () => _pick(false),
                      icon: const Icon(Icons.logout_rounded),
                      label: Text('End ${_end.format(context)}'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Semantics(
                  label: 'Template color',
                  child: Wrap(
                    spacing: 10,
                    children: [
                      if (!_colors.contains(_colorValue))
                        ChoiceChip(
                          label: Text(_colorValue),
                          avatar: CircleAvatar(
                            backgroundColor: _color(_colorValue),
                          ),
                          selected: true,
                          onSelected: null,
                        ),
                      for (final value in _colors)
                        ChoiceChip(
                          label: const SizedBox.square(dimension: 20),
                          avatar: CircleAvatar(backgroundColor: _color(value)),
                          selected: _colorValue == value,
                          onSelected: state.saving
                              ? null
                              : (_) => setState(() => _colorValue = value),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth >= 440
                        ? (constraints.maxWidth - 10) / 2
                        : constraints.maxWidth;
                    final labels = [
                      'Grace minutes',
                      'Early check-in minutes',
                      'Late check-in minutes',
                      'Minimum work minutes',
                    ];
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (var i = 0; i < 4; i++)
                          SizedBox(
                            width: width,
                            child: TextFormField(
                              controller: _policies[i],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(labelText: labels[i]),
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                final number = int.tryParse(value ?? '');
                                return number == null ||
                                        number < 0 ||
                                        number > 1440
                                    ? 'Use 0 to 1440'
                                    : null;
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_start.format(context)} – ${_end.format(context)} • ${_duration(_input.durationMinutes)} • ${_input.durationMinutes == 1440
                        ? '24-hour'
                        : _input.endMinute <= _input.startMinute
                        ? 'Overnight'
                        : 'Same day'}',
                  ),
                ),
                if (state.failure != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _supportMessage(
                      state.failure!.message,
                      state.failure!.requestId,
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (_localError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _localError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: state.saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('save-shift-template'),
          onPressed: state.saving ? null : _save,
          child: state.saving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save template'),
        ),
      ],
    ),
  );

  Future<void> _pick(bool start) async {
    final value = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (value != null) setState(() => start ? _start = value : _end = value);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final validation = _input.validate();
    if (validation != null) {
      setState(() => _localError = validation);
      return;
    }
    setState(() => _localError = null);
    final result = await context.read<ManagerTemplatesCubit>().save(
      _input,
      templateId: widget.template?.id,
    );
    if (mounted && result == FixedShiftMutationResult.success) {
      Navigator.pop(context);
    }
  }
}

TimeOfDay _tod(int minute) =>
    TimeOfDay(hour: minute ~/ 60, minute: minute % 60);
String _time(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
String _duration(int minutes) => '${minutes ~/ 60}h ${minutes % 60}m';
Color _color(String value) {
  final hex = value.replaceFirst('#', '');
  final parsed = hex.length == 6 ? int.tryParse('FF$hex', radix: 16) : null;
  return parsed == null ? AppColors.ink : Color(parsed);
}

String _supportMessage(String message, String? requestId) =>
    requestId == null ? message : '$message\nSupport reference: $requestId';
