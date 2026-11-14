import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/features/communication/presentation/communication_appearance.dart';
import 'package:uuid/uuid.dart';

import '../domain/support_models.dart';
import '../domain/support_repository.dart';
import 'support_image_preview.dart';

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
      final ticket = await widget.repository.get(widget.id);
      if (mounted) {
        setState(() {
          _ticket = ticket;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ApiException
              ? e.message
              : 'Could not load the support report.',
        );
      }
    } finally {
      _loading = false;
      if (_refreshRequested && mounted) {
        _refreshRequested = false;
        unawaited(_load());
      }
    }
  }

  Future<void> _send() async {
    if (_sending || _reply.text.trim().isEmpty) return;
    setState(() {
      _sending = true;
      _error = null;
    });
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
      if (mounted) {
        setState(
          () => _error = e is ApiException
              ? e.message
              : 'Could not send the reply. Retry safely.',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      CommunicationAppearance(child: Builder(builder: _build));
  Widget _build(BuildContext context) {
    final ticket = _ticket;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Support report')),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: context.tr('Refresh'),
          ),
        ],
      ),
      body: ticket == null
          ? (_error == null
                ? const AppContentLoading()
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(context.tr(_error!)),
                        TextButton(
                          onPressed: _load,
                          child: Text(context.tr('Retry')),
                        ),
                      ],
                    ),
                  ))
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Text(
                  ticket.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(context.tr(supportStatusLabel(ticket.status))),
                ),
                if (ticket.assignee != null)
                  Text(
                    context.tr('Responsible person: {name}', {
                      'name': ticket.assignee!,
                    }),
                  ),
                if (ticket.relatedLabel != null) Text(ticket.relatedLabel!),
                const SizedBox(height: 12),
                SelectableText(ticket.description),
                if (ticket.hasImage)
                  SupportImagePreview(
                    repository: widget.repository,
                    ticketId: widget.id,
                  ),
                const SizedBox(height: 20),
                Text(
                  context.tr('Replies'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final reply in ticket.replies)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reply.author.isEmpty
                                ? context.tr(
                                    reply.staff ? 'Support team' : 'You',
                                  )
                                : reply.author,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            reply.createdAt
                                .toLocal()
                                .toString()
                                .split('.')
                                .first,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          SelectableText(reply.body),
                        ],
                      ),
                    ),
                  ),
                if (_error != null)
                  Text(
                    context.tr(_error!),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _reply,
                  enabled: !_sending,
                  minLines: 2,
                  maxLines: 6,
                  maxLength: 5000,
                  onChanged: (_) => _replyId = const Uuid().v4(),
                  decoration: InputDecoration(
                    labelText: context.tr('Write a reply'),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.send_outlined),
                  label: Text(context.tr(_sending ? 'Sending…' : 'Send reply')),
                ),
              ],
            ),
    );
  }
}
