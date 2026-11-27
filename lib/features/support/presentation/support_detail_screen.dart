import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/communication/presentation/communication_appearance.dart';
import 'package:uuid/uuid.dart';

import '../domain/support_models.dart';
import '../domain/support_repository.dart';
import 'support_detail_actions.dart';
import 'support_detail_body.dart';

class SupportDetailScreen extends StatefulWidget {
  const SupportDetailScreen({
    required this.repository,
    required this.id,
    super.key,
  });
  final SupportRepository repository;
  final String id;
  @override
  State<SupportDetailScreen> createState() => _SupportDetailScreenState();
}

class _SupportDetailScreenState extends State<SupportDetailScreen> {
  final _reply = TextEditingController();
  SupportTicket? _ticket;
  String? _error;
  bool _loading = false, _sending = false, _refreshRequested = false;
  Timer? _timer;
  String _replyId = const Uuid().v4();

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _reply.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading) {
      _refreshRequested = true;
      return;
    }
    _loading = true;
    try {
      final t = await widget.repository.get(widget.id);
      if (mounted) setState(() => (_ticket = t, _error = null));
    } catch (e) {
      if (mounted) setState(() => _error = supportLoadError(e));
    } finally {
      _loading = false;
      if (_refreshRequested && mounted) {
        _refreshRequested = false;
        unawaited(_load());
      }
    }
  }

  Future<void> _send() async {
    if (_sending || _ticket?.canReply != true || _reply.text.trim().isEmpty) {
      return;
    }
    setState(() => (_sending = true, _error = null));
    try {
      await widget.repository.reply(
        id: widget.id,
        clientId: _replyId,
        body: _reply.text.trim(),
      );
      _reply.clear();
      _replyId = const Uuid().v4();
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = supportReplyError(e));
      if (mounted && e is ApiException && e.statusCode == 409) {
        await _load();
        if (mounted && _ticket?.canReply == true) {
          setState(() => _error = e.message);
        }
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => CommunicationAppearance(
    child: Builder(
      builder: (c) => Scaffold(
        appBar: AppBar(
          title: Text(c.tr('Support report')),
          actions: [
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              tooltip: c.tr('Refresh'),
            ),
          ],
        ),
        body: _ticket == null
            ? buildSupportDetailPlaceholder(c, error: _error, onRetry: _load)
            : SupportDetailBody(
                ticket: _ticket!,
                repository: widget.repository,
                replyController: _reply,
                sending: _sending,
                error: _error,
                onReplyChanged: (_) => _replyId = const Uuid().v4(),
                onSend: _send,
              ),
      ),
    ),
  );
}
