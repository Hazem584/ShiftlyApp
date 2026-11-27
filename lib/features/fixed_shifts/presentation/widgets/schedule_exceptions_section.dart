import 'package:flutter/material.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/schedule_exception.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/schedule_exception_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/dialogs/schedule_exception_dialog.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/schedule_exception_cancel_dialog.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/schedule_exceptions_card.dart';

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

  bool _alive(int gen) => mounted && gen == _generation && widget.isCurrent();

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
    final gen = ++_generation;
    if (!widget.scope.isManager || !widget.isCurrent()) return;
    setState(() => (_loading = true, _error = null));
    try {
      final page = await widget.repository.list(
        widget.scope.workspaceId,
        employeeMembershipId: widget.employeeMembershipId,
        page: more ? _page + 1 : 1,
      );
      if (!_alive(gen)) return;
      setState(() {
        _records = more ? [..._records, ...page.data] : page.data;
        _page = page.pagination.page;
        _more = _page < page.pagination.totalPages;
        _loading = false;
      });
    } catch (e) {
      if (_alive(gen)) {
        setState(
          () => (_loading = false, _error = ApiErrorParser.parse(e).message),
        );
      }
    }
  }

  Future<void> _create() async {
    if (_busy || !widget.isCurrent()) return;
    final scope = widget.scope, gen = _generation;
    setState(() => (_busy = true, _error = null));
    try {
      final templates = await loadTemplatesForScheduleException(
        fixedShifts: widget.fixedShifts,
        workspaceId: scope.workspaceId,
        employeeMembershipId: widget.employeeMembershipId,
        isAlive: () => _alive(gen),
      );
      if (!mounted || !_alive(gen)) return;
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
      if (changed == true && _alive(gen)) {
        widget.onChanged?.call();
        await _load();
      }
    } catch (e) {
      if (_alive(gen)) setState(() => _error = ApiErrorParser.parse(e).message);
    } finally {
      if (mounted && widget.scope == scope) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(ScheduleException entry) async {
    if (_busy || !widget.isCurrent()) return;
    final scope = widget.scope, gen = _generation;
    final reason = await showCancelScheduleExceptionDialog(context);
    if (reason == null || !_alive(gen)) return;
    setState(() => (_busy = true, _error = null));
    try {
      await widget.repository.cancel(scope.workspaceId, entry.id, reason);
      if (!_alive(gen)) return;
      widget.onChanged?.call();
      await _load();
    } catch (e) {
      if (_alive(gen)) setState(() => _error = ApiErrorParser.parse(e).message);
    } finally {
      if (mounted && widget.scope == scope) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => buildScheduleExceptionsCard(
    context: context,
    employeeMembershipId: widget.employeeMembershipId,
    timezone: widget.scope.timezone,
    canEdit: widget.canEdit,
    busy: _busy,
    loading: _loading,
    more: _more,
    error: _error,
    records: _records,
    onCreate: _create,
    onRefresh: _load,
    onLoadMore: () => _load(more: true),
    onCancel: _cancel,
  );
}
