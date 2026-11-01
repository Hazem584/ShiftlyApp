import 'package:flutter/material.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/schedule_exception.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/schedule_exception_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/dialogs/schedule_exception_dialog.dart';

class ScheduleExceptionsSection extends StatefulWidget {
  const ScheduleExceptionsSection({
    super.key,
    required this.scope,
    required this.repository,
    required this.fixedShifts,
    required this.isCurrent,
    this.employeeMembershipId,
    this.canEdit = true,
    this.onChanged,
  });
  final FeatureSessionScope scope;
  final String? employeeMembershipId;
  final ScheduleExceptionRepository repository;
  final FixedShiftRepository fixedShifts;
  final bool Function() isCurrent;
  final bool canEdit;
  final VoidCallback? onChanged;
  @override
  State<ScheduleExceptionsSection> createState() =>
      _ScheduleExceptionsSectionState();
}

class _ScheduleExceptionsSectionState extends State<ScheduleExceptionsSection> {
  List<ScheduleException> _records = [];
  bool _loading = true, _busy = false, _more = false;
  int _page = 1, _generation = 0;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ScheduleExceptionsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope != widget.scope ||
        oldWidget.employeeMembershipId != widget.employeeMembershipId) {
      _generation++;
      _records = [];
      _busy = false;
      _page = 1;
      _load();
    }
  }

  Future<void> _load({bool more = false}) async {
    final generation = ++_generation;
    final scope = widget.scope;
    if (!scope.isManager || !widget.isCurrent()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.repository.list(
        scope.workspaceId,
        employeeMembershipId: widget.employeeMembershipId,
        page: more ? _page + 1 : 1,
      );
      if (!mounted || generation != _generation || !widget.isCurrent()) return;
      setState(() {
        _records = more ? [..._records, ...page.data] : page.data;
        _page = page.pagination.page;
        _more = _page < page.pagination.totalPages;
        _loading = false;
      });
    } catch (e) {
      if (mounted && generation == _generation && widget.isCurrent()) {
        setState(() {
          _loading = false;
          _error = ApiErrorParser.parse(e).message;
        });
      }
    }
  }

  Future<void> _create() async {
    if (_busy || !widget.isCurrent()) return;
    final scope = widget.scope, generation = _generation;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final templates = <ShiftTemplate>[];
      if (widget.employeeMembershipId != null) {
        for (var page = 1; ; page++) {
          final result = await widget.fixedShifts.listTemplates(
            scope.workspaceId,
            page: page,
          );
          if (!mounted || generation != _generation || !widget.isCurrent()) {
            return;
          }
          templates.addAll(result.data.where((e) => e.active));
          if (page >= result.pagination.totalPages) break;
        }
      }
      if (!mounted || generation != _generation || !widget.isCurrent()) return;
      final changed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ScheduleExceptionDialog(
          repository: widget.repository,
          workspaceId: scope.workspaceId,
          timezone: scope.timezone,
          employeeMembershipId: widget.employeeMembershipId,
          templates: templates,
          isCurrent: widget.isCurrent,
        ),
      );
      if (changed == true &&
          mounted &&
          generation == _generation &&
          widget.isCurrent()) {
        widget.onChanged?.call();
        await _load();
      }
    } catch (e) {
      if (mounted && generation == _generation && widget.isCurrent()) {
        setState(() => _error = ApiErrorParser.parse(e).message);
      }
    } finally {
      if (mounted && widget.scope == scope) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(ScheduleException entry) async {
    if (_busy || !widget.isCurrent()) return;
    final scope = widget.scope, generation = _generation;
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Cancel day exception?')),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          maxLength: 1000,
          decoration: InputDecoration(
            labelText: context.tr(
              'Cancellation reason (at least 5 characters)',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('Keep exception')),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().length >= 5) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: Text(context.tr('Cancel exception')),
          ),
        ],
      ),
    );
    // Keep the controller alive until the dialog's closing animation completes.
    Future<void>.delayed(const Duration(seconds: 1), controller.dispose);
    if (reason == null ||
        !mounted ||
        generation != _generation ||
        !widget.isCurrent()) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.cancel(scope.workspaceId, entry.id, reason);
      if (!mounted || generation != _generation || !widget.isCurrent()) return;
      widget.onChanged?.call();
      await _load();
    } catch (e) {
      if (mounted && generation == _generation && widget.isCurrent()) {
        setState(() => _error = ApiErrorParser.parse(e).message);
      }
    } finally {
      if (mounted && widget.scope == scope) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr(
            widget.employeeMembershipId == null
                ? 'Workspace holidays'
                : 'Schedule exceptions and holidays',
          ),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          context.tr(
            'Employee instructions take priority over a workspace holiday. The weekly assignment stays the same.',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            if (widget.canEdit)
              OutlinedButton.icon(
                onPressed: _busy || _loading ? null : _create,
                icon: const Icon(Icons.event_note_outlined),
                label: Text(
                  context.tr(
                    widget.employeeMembershipId == null
                        ? 'Add workspace holiday'
                        : 'Add day exception',
                  ),
                ),
              ),
            IconButton(
              onPressed: _busy || _loading ? null : () => _load(),
              tooltip: context.tr('Refresh'),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        if (_error != null)
          Text(
            context.tr(_error!),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (_loading) const AppContentLoading(rows: 1),
        if (!_loading && _records.isEmpty && _error == null)
          Text(context.tr('No schedule exceptions yet.')),
        for (final entry in _records)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${entry.operationalDate} · ${context.tr(entry.kind == 'SHIFT'
                      ? 'One-day shift change'
                      : entry.kind == 'DAY_OFF'
                      ? 'Employee day off'
                      : 'Workspace holiday')}',
                ),
                if (entry.shiftName != null)
                  Text('${entry.originalShiftName ?? ''} → ${entry.shiftName}'),
                Text(entry.reason),
                Text(
                  context.tr('Created by {manager} on {date}', {
                    'manager': entry.creatorName ?? context.tr('Manager'),
                    'date': WorkspaceTime.dateTime(
                      entry.createdAt,
                      widget.scope.timezone,
                    ),
                  }),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (!entry.active)
                  Text(
                    '${context.tr('Cancelled')} · ${entry.cancellationReason ?? ''}',
                  ),
                if (!entry.active && entry.cancelledAt != null)
                  Text(
                    context.tr('Cancelled by {manager} on {date}', {
                      'manager': entry.cancellerName ?? context.tr('Manager'),
                      'date': WorkspaceTime.dateTime(
                        entry.cancelledAt!,
                        widget.scope.timezone,
                      ),
                    }),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (widget.canEdit &&
                    entry.active &&
                    entry.employeeMembershipId == widget.employeeMembershipId)
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: _busy || _loading
                          ? null
                          : () => _cancel(entry),
                      child: Text(context.tr('Cancel exception')),
                    ),
                  ),
              ],
            ),
          ),
        if (_more)
          TextButton(
            onPressed: _busy || _loading ? null : () => _load(more: true),
            child: Text(context.tr('Load more')),
          ),
      ],
    ),
  );
}
