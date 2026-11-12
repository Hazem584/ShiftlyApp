import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/features/profile/domain/repositories/profile_image_picker.dart';

import '../domain/support_models.dart';
import '../domain/support_repository.dart';
import 'support_create_screen.dart';
import 'support_session_boundary.dart';
import 'support_ticket_card.dart';

class SupportInboxScreen extends StatefulWidget {
  const SupportInboxScreen({
    required this.repository,
    required this.workspaceId,
    required this.picker,
    super.key,
  });
  final SupportRepository repository;
  final String workspaceId;
  final ProfileImagePicker picker;
  @override
  State<SupportInboxScreen> createState() => _SupportInboxScreenState();
}

class _SupportInboxScreenState extends State<SupportInboxScreen> {
  final _tickets = <SupportTicket>[];
  int _page = 1;
  bool _loading = false, _hasNext = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool next = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final page = next ? _page + 1 : 1;
    try {
      final data = await widget.repository.list(page: page);
      if (!mounted) return;
      setState(() {
        if (!next) _tickets.clear();
        _tickets.addAll(data.items);
        _page = page;
        _hasNext = data.hasNext;
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ApiException
              ? e.message
              : 'Could not load support reports.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => SupportSessionBoundary(
          child: SupportCreateScreen(
            repository: widget.repository,
            workspaceId: widget.workspaceId,
            picker: widget.picker,
          ),
        ),
      ),
    );
    if (!mounted) return;
    await _load();
    if (mounted && id != null) await context.push('/support/$id');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.tr('Help and problem reports')),
      actions: [
        IconButton(
          onPressed: () => _load(),
          tooltip: context.tr('Refresh'),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _create,
      icon: const Icon(Icons.add),
      label: Text(context.tr('Report a problem')),
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Text(
            context.tr(
              'Your reports stay here so you can follow the status and support replies.',
            ),
          ),
          if (_error != null) ...[
            Text(
              context.tr(_error!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            TextButton(
              onPressed: () => _load(),
              child: Text(context.tr('Retry')),
            ),
          ],
          if (_loading && _tickets.isEmpty) const AppContentLoading(),
          if (!_loading && _tickets.isEmpty && _error == null)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(context.tr('No support reports yet.')),
            ),
          for (final ticket in _tickets)
            SupportTicketCard(
              ticket: ticket,
              onTap: () async {
                await context.push('/support/${ticket.id}');
                if (mounted) await _load();
              },
            ),
          if (_hasNext)
            TextButton(
              onPressed: _loading ? null : () => _load(next: true),
              child: Text(context.tr('Load more')),
            ),
        ],
      ),
    ),
  );
}
