import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/widgets/confirm_action.dart';
import 'package:shiftly/features/communication/presentation/announcement_detail_content.dart';
import 'package:shiftly/features/communication/presentation/announcement_detail_footer.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';

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
        message:
            'Confirm that you have read and understood this update. Your manager can see your acknowledgment.',
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
  Widget build(BuildContext context) => CommunicationPage(
    title: _ack ? 'Acknowledged' : widget.item.title,
    localizeTitle: _ack,
    footer: buildAnnouncementDetailFooter(
      context,
      item: widget.item,
      repository: widget.repository,
      workspaceId: widget.workspaceId,
      timezone: widget.timezone,
      manager: widget.manager,
      busy: _busy,
      read: _read,
      acknowledged: _ack,
      onAcknowledge: () => _record(true),
    ),
    child: buildAnnouncementDetailContent(
      context,
      item: widget.item,
      timezone: widget.timezone,
      read: _read,
      acknowledged: _ack,
      busy: _busy,
      error: _error,
      onRetry: () => _record(false),
    ),
  );
}
