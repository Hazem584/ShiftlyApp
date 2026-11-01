import 'package:flutter/material.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';

class ManagerEmployeePicker extends StatefulWidget {
  const ManagerEmployeePicker({
    required this.repository,
    required this.workspaceId,
    required this.isCurrent,
    super.key,
  });
  final EmployeeRepository repository;
  final String workspaceId;
  final bool Function() isCurrent;
  @override
  State<ManagerEmployeePicker> createState() => _ManagerEmployeePickerState();
}

class _ManagerEmployeePickerState extends State<ManagerEmployeePicker> {
  final _search = TextEditingController();
  final _items = <Employee>[];
  int _request = 0, _page = 0, _totalPages = 0;
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    if (!widget.isCurrent() || more && _loading) return;
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      if (!more) _items.clear();
    });
    try {
      final page = await widget.repository.listEmployees(
        workspaceId: widget.workspaceId,
        search: _search.text.trim(),
        status: EmployeeStatusFilter.active,
        page: more ? _page + 1 : 1,
      );
      if (!mounted || request != _request || !widget.isCurrent()) return;
      setState(() {
        _items.addAll(page.data.where((e) => e.role == EmployeeRole.employee));
        _page = page.page;
        _totalPages = page.totalPages;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _request || !widget.isCurrent()) return;
      final failure = ApiErrorParser.parse(error);
      setState(() {
        _loading = false;
        _error = failure.requestId == null
            ? failure.message
            : '${failure.message} · ${failure.requestId}';
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr('Employee')),
    content: SizedBox(
      width: 520,
      height: MediaQuery.sizeOf(context).height * .55,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => _load(),
            decoration: InputDecoration(
              labelText: context.tr('Search by name or email'),
              prefixIcon: const Icon(Icons.search_outlined),
            ),
          ),
          const SizedBox(height: 12),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            TextButton(
              onPressed: _load,
              child: Text('${_error!} · ${context.tr('Retry')}'),
            ),
          Expanded(
            child: ListView(
              children: [
                for (final employee in _items)
                  ListTile(
                    title: Text(employee.displayName),
                    subtitle: Text(employee.displayJobTitle),
                    onTap: () {
                      if (widget.isCurrent()) Navigator.pop(context, employee);
                    },
                  ),
                if (!_loading && _items.isEmpty && _error == null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(context.tr('No matching employees')),
                  ),
                if (_page < _totalPages)
                  TextButton(
                    onPressed: _loading ? null : () => _load(more: true),
                    child: Text(context.tr('Load more')),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.tr('Cancel')),
      ),
    ],
  );
}
