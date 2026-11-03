import 'dart:typed_data';

// The generated host API is used only to verify the native save dialog contract.
// ignore: implementation_imports
import 'package:file_saver/src/messages.g.dart';
// ignore: implementation_imports
import 'package:file_saver/src/platform_handler/platform_handler_all.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/presentation/controllers/chat_document_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Host host;
  setUp(() {
    host = _Host();
    PlatformHandlerAll.hostApiOverride = host;
  });
  tearDown(() {
    PlatformHandlerAll.hostApiOverride = null;
  });
  final bytes = Uint8List.fromList([37, 80, 68, 70]);
  final attachment = ChatAttachment(
    id: 'fixture',
    category: 'DOCUMENT',
    mimeType: 'application/pdf',
    sizeBytes: bytes.length,
    fileName: 'Lecture 01.pdf',
  );
  test(
    'download opens Save As with original filename, MIME and complete bytes',
    () async {
      expect(
        await ChatDocumentController().download(bytes, attachment),
        isTrue,
      );
      final request = host.requests.single;
      expect(request.name, 'Lecture 01');
      expect(request.fileExtension, '.pdf');
      expect(request.mimeType, 'application/pdf');
      expect(request.bytes, bytes);
    },
  );
  test('cancelled native dialog is not reported as a saved file', () async {
    host.result = null;
    expect(await ChatDocumentController().download(bytes, attachment), isFalse);
  });
  test('a mismatched byte count never opens the save dialog', () async {
    await expectLater(
      ChatDocumentController().download(Uint8List(2), attachment),
      throwsFormatException,
    );
    expect(host.requests, isEmpty);
  });
}

class _Host extends FileSaverHostApi {
  String? result = 'content://documents/lecture.pdf';
  final requests = <SaveRequest>[];
  @override
  Future<String?> saveAs(SaveRequest request) async {
    requests.add(request);
    return result;
  }
}
