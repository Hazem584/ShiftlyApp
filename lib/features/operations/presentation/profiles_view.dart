import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import '../domain/operations_repository.dart';
import 'operations_helpers.dart';
import 'profile_editor.dart';

class ProfilesView extends StatefulWidget {
  const ProfilesView({
    super.key,
    required this.repository,
    required this.workspaceId,
    required this.timezone,
    required this.isCurrent,
  });
  final OperationsRepository repository;
  final String workspaceId, timezone;
  final bool Function() isCurrent;
  @override
  State<ProfilesView> createState() => _ProfilesViewState();
}

class _ProfilesViewState extends State<ProfilesView> {
  List<OperationMap>? _profiles;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await widget.repository.profiles(widget.workspaceId);
      if (mounted && widget.isCurrent()) setState(() => _profiles = p);
    } catch (e) {
      if (mounted) setState(() => _error = operationError(e));
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        context.tr(
          'Set explicit availability and verified skills before generating a proposal. Missing availability excludes an employee.',
        ),
      ),
      Text(
        context.tr(
          'Defaults: 48 actual hours per rolling 7 days, 8 daily, 12 hours between shifts, and 24 hours weekly rest after at most 6 work days.',
        ),
      ),
      TextButton(onPressed: _load, child: Text(context.tr('Refresh'))),
      if (_error != null) Text(_error!),
      if (_profiles == null && _error == null)
        const Center(child: CircularProgressIndicator()),
      for (final p in _profiles ?? <OperationMap>[])
        Card(
          child: ListTile(
            title: Text(p['name'] as String),
            subtitle: Text(
              '${(p['skills'] as List?)?.join(', ') ?? ''}\n${context.tr('Availability windows')}: ${(p['availability'] as List?)?.length ?? 0}',
            ),
            trailing: const Icon(Icons.edit),
            onTap: () async {
              final changed = await showDialog<bool>(
                context: context,
                builder: (_) => ProfileEditor(
                  repository: widget.repository,
                  workspaceId: widget.workspaceId,
                  timezone: widget.timezone,
                  profile: p,
                  isCurrent: widget.isCurrent,
                ),
              );
              if (changed == true && mounted && widget.isCurrent()) {
                await _load();
              }
            },
          ),
        ),
    ],
  );
}
