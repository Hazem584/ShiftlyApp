import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import '../domain/support_repository.dart';

class SupportImagePreview extends StatefulWidget {
  const SupportImagePreview({
    required this.repository,
    required this.ticketId,
    super.key,
  });
  final SupportRepository repository;
  final String ticketId;
  @override
  State<SupportImagePreview> createState() => _SupportImagePreviewState();
}

class _SupportImagePreviewState extends State<SupportImagePreview> {
  Uint8List? _bytes;
  bool _loading = false;
  bool _failed = false;
  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final bytes = await widget.repository.image(widget.ticketId);
      if (mounted) setState(() => _bytes = bytes);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_bytes == null)
        OutlinedButton.icon(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.image_outlined),
          label: Text(
            context.tr(_loading ? 'Loading…' : 'View attached image'),
          ),
        ),
      if (_failed)
        Text(context.tr('Could not load the report image. Try again.')),
      if (_bytes != null)
        InteractiveViewer(
          child: Image.memory(_bytes!, height: 320, fit: BoxFit.contain),
        ),
    ],
  );
}
