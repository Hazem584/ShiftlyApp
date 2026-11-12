import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/features/profile/domain/repositories/profile_image_picker.dart';
import 'package:shiftly/features/support/data/api_support_repository.dart';
import 'package:shiftly/features/support/domain/support_models.dart';
import 'package:shiftly/features/support/domain/support_repository.dart';
import 'package:shiftly/features/support/presentation/support_create_screen.dart';
import 'package:shiftly/features/support/presentation/support_detail_screen.dart';

class _Picker implements ProfileImagePicker {
  _Picker(this.image);
  final ProfileImageSelection? image;
  @override
  Future<ProfileImageSelection?> pickImage() async => image;
}

class _Repository implements SupportRepository {
  int creates = 0, uploads = 0;
  bool failUpload = false, failCreate = false;
  final nonces = <String>[];
  SupportTicket get ticket => SupportTicket(
    id: '00000000-0000-4000-8000-000000000001',
    title: 'Attendance report',
    description: 'The attendance calendar needs correction.',
    status: 'WAITING_REPORTER',
    updatedAt: DateTime.utc(2026, 11, 12),
    assignee: 'Support agent',
    replies: [
      SupportReply(
        id: 'reply',
        body: 'Please confirm the shift date.',
        staff: true,
        createdAt: DateTime.utc(2026, 11, 12),
        author: 'Support agent',
      ),
    ],
  );
  @override
  Future<List<SupportContext>> contexts(String workspaceId) async => const [
    SupportContext(id: 'shift', kind: 'SHIFT', label: 'Morning shift'),
  ];
  @override
  Future<SupportTicket> create({
    required String workspaceId,
    required String clientId,
    required String title,
    required String description,
    SupportContext? related,
  }) async {
    creates++;
    nonces.add(clientId);
    if (failCreate) {
      failCreate = false;
      throw const ApiException(
        message: 'The request timed out. Please try again.',
      );
    }
    return ticket;
  }

  @override
  Future<void> uploadImage({
    required String id,
    required Uint8List bytes,
    required String mime,
  }) async {
    uploads++;
    if (failUpload) {
      failUpload = false;
      throw const ApiException(message: 'Image transfer failed');
    }
  }

  @override
  Future<SupportPage> list({required int page}) async =>
      SupportPage([ticket], false);
  @override
  Future<SupportTicket> get(String id) async => ticket;
  @override
  Future<Uint8List> image(String id) async => Uint8List(0);
  @override
  Future<void> reply({
    required String id,
    required String clientId,
    required String body,
  }) async {}
}

Future<void> _openForm(
  WidgetTester tester,
  _Repository repo,
  ProfileImagePicker picker,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push<String>(
              MaterialPageRoute(
                builder: (_) => SupportCreateScreen(
                  repository: repo,
                  workspaceId: 'workspace',
                  picker: picker,
                ),
              ),
            ),
            child: const Text('Open form'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open form'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byType(TextFormField).at(0),
    'Attendance problem',
  );
  await tester.enterText(
    find.byType(TextFormField).at(1),
    'I attended the shift, but the calendar still shows absent.',
  );
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('retries only the image after the report was saved', (
    tester,
  ) async {
    final repo = _Repository()..failUpload = true;
    final image = ProfileImageSelection(
      bytes: File('assets/images/shiftly-mark.png').readAsBytesSync(),
      fileName: 'proof.png',
    );
    await _openForm(tester, repo, _Picker(image));
    await tester.scrollUntilVisible(
      find.text('Attach an image (optional)'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Attach an image (optional)'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Send report'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();
    expect(repo.creates, 1);
    expect(repo.uploads, 1);
    expect(
      find.text(
        'Your report was saved, but its image was not uploaded. Retry or open the saved report.',
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Retry image upload'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry image upload'));
    await tester.pumpAndSettle();
    expect(repo.creates, 1);
    expect(repo.uploads, 2);
    expect(tester.takeException(), isNull);
  });
  testWidgets('keeps the creation nonce when a request times out', (
    tester,
  ) async {
    final repo = _Repository()..failCreate = true;
    await _openForm(tester, repo, _Picker(null));
    await tester.scrollUntilVisible(
      find.text('Send report'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Send report'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();
    expect(repo.nonces.length, 2);
    expect(repo.nonces.toSet().length, 1);
  });
  testWidgets(
    'shows status, responsible person and support reply on a narrow phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: SupportDetailScreen(repository: _Repository(), id: 'ticket'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Waiting for your reply'), findsOneWidget);
      expect(find.text('Responsible person: Support agent'), findsOneWidget);
      expect(find.text('Please confirm the shift date.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  test('sends the chosen reference and client nonce, leaving reporter identity to the server', () async {
    final dio = Dio();
    addTearDown(dio.close);
    RequestOptions? sent;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          sent = o;
          h.resolve(
            Response(
              requestOptions: o,
              statusCode: 201,
              data: {
                'id': 'ticket',
                'title': 'Problem',
                'description': 'Full problem description',
                'status': 'OPEN',
                'updatedAt': '2026-11-12T12:00:00Z',
                'hasImage': false,
              },
            ),
          );
        },
      ),
    );
    await ApiSupportRepository(dio).create(
      workspaceId: 'workspace',
      clientId: 'nonce',
      title: 'Problem',
      description: 'Full problem description',
      related: const SupportContext(
        id: 'shift',
        kind: 'SHIFT',
        label: 'Morning',
      ),
    );
    expect(sent!.data, {
      'workspaceId': 'workspace',
      'clientId': 'nonce',
      'title': 'Problem',
      'description': 'Full problem description',
      'relatedKind': 'SHIFT',
      'relatedId': 'shift',
    });
  });
}
