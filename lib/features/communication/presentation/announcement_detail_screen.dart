import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/confirm_action.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';

import 'announcement_readers_screen.dart';
import 'communication_actions.dart';
import 'communication_page.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  const AnnouncementDetailScreen({
    required this.item,
    required this.repository,
    required this.workspaceId,
    required this.timezone,
    this.manager = false,
    this.onChanged,
    super.key,
  });
  final TeamAnnouncement item;
  final TeamWorkRepository repository;
  final String workspaceId, timezone;
  final bool manager;
  final Future<void> Function()? onChanged;
  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  late bool _read = widget.item.readAt != null,
      _ack = widget.item.acknowledgedAt != null;
  bool _busy = false;
  String? _error;
  SessionCoordinator? _session;
  String? _identity;
  String? get _currentIdentity => _session == null
      ? null
      : '${_session!.state.currentUser?.id}:${_session!.state.activeMembership?.id}';
  bool get _current => mounted && _identity == _currentIdentity;
  @override
  void initState() {
    super.initState();
    _session = context.read<SessionCoordinator?>();
    _identity = _currentIdentity;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_read) _record(false);
    });
  }

  Future<void> _record(bool acknowledge) async {
    if (_busy || !_current) return;
    if (acknowledge) {
      final confirmed = await confirmAction(
        context,
        title: 'Acknowledge this update?',
        message: 'Confirm that you have read and understood this update. Your manager can see your acknowledgment.',
        action: 'Acknowledge',
        actionKey: 'confirm-announcement-acknowledgment',
      );
      if (!confirmed || !_current) return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.markAnnouncement(
        widget.workspaceId,
        widget.item.id,
        acknowledge: acknowledge,
      );
      if (!_current) return;
      setState(() {
        _read = true;
        if (acknowledge) _ack = true;
      });
      await widget.onChanged?.call();
    } catch (error) {
      if (_current) {
        setState(() => _error = ApiErrorParser.parse(error).message);
      }
    } finally {
      if (_current) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return CommunicationPage(
      title: _ack ? 'Acknowledged' : item.title,
      localizeTitle: _ack,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (item.requiresAcknowledgment && !_ack)
            FilledButton(
              key: const Key('acknowledge-announcement'),
              onPressed: _busy || !_read ? null : () => _record(true),
              child: Text(context.tr('Acknowledge update')),
            )
          else
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('Back to announcements')),
            ),
          if (widget.manager)
            TextButton(
              key: const Key('announcement-recipient-progress'),
              onPressed: _busy
                  ? null
                  : () => openCommunicationPage(
                      context,
                      AnnouncementReadersScreen(
                        item: item,
                        repository: widget.repository,
                        workspaceId: widget.workspaceId,
                        timezone: widget.timezone,
                      ),
                    ),
              child: Text(context.tr('Recipient progress')),
            ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '${item.author} · ${WorkspaceTime.dateTime(item.createdAt, widget.timezone, locale: Localizations.localeOf(context).toString())}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          Text(item.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SelectableText(
            item.body,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 28),
          if (item.requiresAcknowledgment)
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                        _ack
                            ? 'Acknowledgment saved.'
                            : 'Acknowledgment required',
                      ),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr(
                        _ack
                            ? 'Your manager can now see that you acknowledged the announcement.'
                            : 'Reading this update does not confirm acknowledgment.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_read && !_ack)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                context.tr(
                  item.requiresAcknowledgment
                      ? 'Read · Still needs your acknowledgment.'
                      : 'Read',
                ),
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              context.tr(_error!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            TextButton(
              onPressed: _busy ? null : () => _record(false),
              child: Text(context.tr('Retry')),
            ),
          ],
        ],
      ),
    );
  }
}
