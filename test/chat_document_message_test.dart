import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/data/mock_chat_repository.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_media_store.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/presentation/controllers/chat_document_controller.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/chat/presentation/screens/chat_document_preview_screen.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_document_message.dart';

import 'chat_cache_outbox_test.dart' as f;

final _bytes = Uint8List.fromList(utf8.encode('Preview content'));
ChatMessage _message() => ChatMessage(
  id: f.message(1).id,
  groupId: f.group,
  type: 'DOCUMENT',
  sender: f.message(1).sender,
  createdAt: DateTime.utc(2026),
  attachment: ChatAttachment(
    id: f.message(1).id,
    category: 'DOCUMENT',
    mimeType: 'text/plain',
    sizeBytes: _bytes.length,
    fileName: 'notes.txt',
  ),
);

Future<void> _host(WidgetTester tester, ChatGroupsCubit groups, _Files files) =>
    tester.pumpWidget(
      BlocProvider.value(
        value: groups,
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: ChatDocumentMessage(
                message: _message(),
                repository: const MockChatRepository(),
                workspaceId: f.workspace,
                controller: files,
              ),
            ),
          ),
        ),
      ),
    );
Future<void> _contentReady(WidgetTester tester) async {
  for (var i = 0; i < 100; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (find.text('Preview content').evaluate().isNotEmpty) return;
  }
  fail('Preview content did not appear');
}

void main() {
  testWidgets(
    'preview and download are separate, lazy and reuse loaded bytes',
    (tester) async {
      final groups = ChatGroupsCubit(const MockChatRepository())
        ..bindSession(f.session);
      final files = _Files();
      await _host(tester, groups, files);
      await tester.pumpAndSettle();
      expect(find.text('Preview file'), findsOneWidget);
      expect(find.text('Download file'), findsOneWidget);
      expect(files.loads, 0);
      await tester.tap(find.byKey(const Key('preview-chat-document')));
      await tester.pump(const Duration(milliseconds: 400));
      await _contentReady(tester);
      await tester.pumpAndSettle();
      expect(find.text('Preview content'), findsOneWidget);
      await tester.tap(find.byKey(const Key('download-preview-document')));
      await tester.pumpAndSettle();
      expect(files.downloads, 1);
      expect(files.savedBytes, _bytes);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('download-chat-document')));
      await tester.pumpAndSettle();
      expect(files.loads, 1);
      expect(files.downloads, 2);
      expect(tester.takeException(), isNull);
      await groups.close();
    },
  );

  testWidgets('cancelled save does not claim the file was downloaded', (
    tester,
  ) async {
    final groups = ChatGroupsCubit(const MockChatRepository())
      ..bindSession(f.session);
    final files = _Files()..saved = false;
    await _host(tester, groups, files);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('download-chat-document')));
    await tester.pumpAndSettle();
    expect(files.downloads, 1);
    expect(find.text('File downloaded.'), findsNothing);
    await groups.close();
  });

  testWidgets('sign out during loading prevents preview and export', (
    tester,
  ) async {
    final groups = ChatGroupsCubit(const MockChatRepository())
      ..bindSession(f.session);
    final gate = Completer<Uint8List>();
    final files = _Files()..gate = gate;
    await _host(tester, groups, files);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('preview-chat-document')));
    await tester.pump();
    groups.bindSession(null);
    gate.complete(_bytes);
    await tester.pumpAndSettle();
    expect(find.byType(ChatDocumentPreviewScreen), findsNothing);
    expect(files.downloads, 0);
    await groups.close();
  });

  testWidgets('revoking access hides the open preview and download action', (
    tester,
  ) async {
    final changes = StreamController<int>.broadcast();
    var allowed = true;
    await tester.pumpWidget(
      MaterialApp(
        home: ChatDocumentPreviewScreen(
          bytes: _bytes,
          fileName: 'notes.txt',
          sourceId: 'fixture',
          hasAccess: () => allowed,
          onDownload: () async => true,
          accessChanges: changes.stream,
        ),
      ),
    );
    await _contentReady(tester);
    allowed = false;
    changes.add(1);
    await tester.pumpAndSettle();
    expect(find.text('Preview content'), findsNothing);
    expect(find.text('Chat access unavailable.'), findsOneWidget);
    expect(find.byKey(const Key('download-preview-document')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await changes.close();
  });

  testWidgets('file actions fit compact screens with large text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final groups = ChatGroupsCubit(const MockChatRepository())
      ..bindSession(f.session);
    await tester.pumpWidget(
      BlocProvider.value(
        value: groups,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChatDocumentMessage(
                message: _message(),
                repository: const MockChatRepository(),
                workspaceId: f.workspace,
                controller: _Files(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await groups.close();
  });
}

class _Files extends ChatDocumentController {
  int loads = 0, downloads = 0;
  bool saved = true;
  Completer<Uint8List>? gate;
  Uint8List? savedBytes;
  @override
  Future<Uint8List> load({
    required ChatMessage message,
    required ChatRepository repository,
    required FeatureSessionScope session,
    required bool Function() hasAccess,
    ChatMediaStore? cache,
  }) async {
    loads++;
    return gate == null ? _bytes : gate!.future;
  }

  @override
  Future<bool> download(Uint8List bytes, ChatAttachment attachment) async {
    downloads++;
    savedBytes = bytes;
    return saved;
  }
}
