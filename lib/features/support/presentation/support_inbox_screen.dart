import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/communication/presentation/communication_appearance.dart';
import 'package:shiftly/features/profile/domain/repositories/profile_image_picker.dart';

import '../domain/support_models.dart';
import '../domain/support_repository.dart';
import 'support_create_screen.dart';
import 'support_inbox_list.dart';
import 'support_session_boundary.dart';

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
    setState(() => (_loading = true, _error = null));
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
      final msg = e is ApiException
          ? e.message
          : 'Could not load support reports.';
      if (mounted) setState(() => _error = msg);
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
  Widget build(BuildContext context) => CommunicationAppearance(
    child: Builder(
      builder: (c) => Scaffold(
        appBar: AppBar(
          title: Text(c.tr('Help and problem reports')),
          actions: [
            IconButton(
              onPressed: _load,
              tooltip: c.tr('Refresh'),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _create,
          icon: const Icon(Icons.add),
          label: Text(c.tr('Report a problem')),
        ),
        body: SupportInboxList(
          tickets: _tickets,
          loading: _loading,
          hasNext: _hasNext,
          error: _error,
          onRefresh: _load,
          onLoadMore: () => _load(next: true),
          onOpenTicket: (t) async {
            await c.push('/support/${t.id}');
            if (mounted) await _load();
          },
        ),
      ),
    ),
  );
}
