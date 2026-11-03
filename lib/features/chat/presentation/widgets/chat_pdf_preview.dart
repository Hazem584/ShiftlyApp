
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/features/chat/presentation/controllers/chat_pdf_initialize.dart';

class ChatPdfPreview extends StatefulWidget {
  const ChatPdfPreview({required this.bytes, super.key});
  final Uint8List bytes;
  @override
  State<ChatPdfPreview> createState() => _ChatPdfPreviewState();
}

class _ChatPdfPreviewState extends State<ChatPdfPreview> {
  PdfControllerPinch? _pinch;
  PdfController? _pages;
  bool get _windows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
  @override
  void initState() {
    super.initState();
    final document = _open();
    if (_windows) {
      _pages = PdfController(document: document);
    } else {
      _pinch = PdfControllerPinch(document: document);
    }
  }

  Future<PdfDocument> _open() async {
    await initializeChatPdf();
    return PdfDocument.openData(widget.bytes);
  }

  @override
  void dispose() {
    _pinch?.dispose();
    _pages?.dispose();
    super.dispose();
  }

  Widget _error(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        context.tr(
          'Preview unavailable. Download this file to open it in another app.',
        ),
        textAlign: TextAlign.center,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    if (_pages != null) {
      return PdfView(
        controller: _pages!,
        builders: PdfViewBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(),
          documentLoaderBuilder: (_) => const AppContentLoading(),
          errorBuilder: (context, error) => _error(context),
        ),
      );
    }
    return PdfViewPinch(
      controller: _pinch!,
      builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (_) => const AppContentLoading(),
        errorBuilder: (context, error) => _error(context),
      ),
    );
  }
}
