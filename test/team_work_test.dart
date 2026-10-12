import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/entities/chat_outbox_operation.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/presentation/dialogs/chat_search_dialog.dart';
import 'package:shiftly/features/team_work/data/api_team_work_repository.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/cubit/work_feed_cubit.dart';
import 'package:shiftly/features/team_work/presentation/widgets/announcements_view.dart';
import 'package:shiftly/features/team_work/presentation/widgets/correction_request_card.dart';
import 'package:shiftly/features/team_work/presentation/widgets/pending_announcements.dart';

final correctionJson = <String, Object?>{
  'id': 'correction',
  'attendanceId': 'attendance',
  'requester': {
    'profile': {'fullName': 'Sam'},
  },
  'reviewer': null,
  'reason': 'Forgot to clock out',
  'status': 'PENDING',
  'originalClockInAt': '2026-10-01T08:00:00Z',
  'originalClockOutAt': '2026-10-01T15:00:00Z',
  'requestedClockInAt': '2026-10-01T08:00:00Z',
  'requestedClockOutAt': '2026-10-01T16:00:00Z',
};
final announcementJson = <String, Object?>{
  'id': 'announcement',
  'title': 'Tomorrow’s shift',
  'body': 'Please arrive at 9 tomorrow.',
  'author': {
    'profile': {'fullName': 'Manager'},
  },
  'createdAt': '2026-10-01T08:00:00Z',
  'requiresAcknowledgment': true,
  'receipt': {'readAt': null, 'acknowledgedAt': null},
};

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  Object? response;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(response ?? {}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Announcements implements TeamWorkRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  int reads = 0, confirms = 0;
  bool failRead = false;
  bool failRefreshAfterRead = false;
  bool requiresAcknowledgment = true;
  final dismissed = <String>{};
  final pendingQueries = <bool>[];
  @override
  Future<WorkPage<TeamAnnouncement>> announcements(
    String workspaceId, {
    int page = 1,
    bool pendingOnly = false,
  }) async {
    pendingQueries.add(pendingOnly);
    if (failRefreshAfterRead && dismissed.contains(workspaceId)) {
      throw const ApiException(message: 'Try again');
    }
    return WorkPage(
      dismissed.contains(workspaceId)
          ? []
          : [
              TeamAnnouncement.fromJson({
                ...announcementJson,
                'requiresAcknowledgment': requiresAcknowledgment,
              }),
            ],
      dismissed.contains(workspaceId) ? 0 : 1,
    );
  }

  @override
  Future<void> markAnnouncement(
    String workspaceId,
    String id, {
    bool acknowledge = false,
  }) async {
    if (failRead) throw const ApiException(message: 'Try again');
    dismissed.add(workspaceId);
    if (acknowledge) {
      confirms++;
    } else {
      reads++;
    }
  }
}

class _Search extends ChatRepository {
  final queries = <String?>[];
  @override
  Future<ChatMessagePage> searchMessages(
    String workspaceId,
    String groupId, {
    String? query,
    bool pinned = false,
    String? cursor,
  }) async {
    queries.add(query);
    return ChatMessagePage(
      messages: [
        ChatMessage(
          id: 'message',
          groupId: groupId,
          type: 'TEXT',
          text: 'Earlier message from last month',
          sender: const ChatSender(membershipId: 'sender', fullName: 'Sam'),
          createdAt: DateTime.utc(2026, 9),
        ),
      ],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'dashboard announcements request server filtering before pagination',
    () async {
      final adapter = _Adapter()..response = {'data': [], 'total': 0};
      final dio = Dio()..httpClientAdapter = adapter;
      await ApiTeamWorkRepository(dio)
          .announcements('workspace', pendingOnly: true, page: 2);
      expect(adapter.requests.single.queryParameters, {
        'page': 2,
        'pendingOnly': true,
      });
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'dashboard announcement hides only after explicit confirmation (dark: $dark)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 750);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = _Announcements()..requiresAcknowledgment = dark;
        final button = dark ? 'Confirm I have read this' : 'I have read this';
        Widget screen(String workspaceId) => MaterialApp(
          theme: dark ? AppTheme.darkTheme() : AppTheme.lightTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: PendingAnnouncements(
                key: const ValueKey('pending'),
                repository: repository,
                workspaceId: workspaceId,
                timezone: 'Africa/Cairo',
              ),
            ),
          ),
        );
        await tester.pumpWidget(screen('one'));
        await tester.pumpAndSettle();
        expect(find.text(announcementJson['body'] as String), findsOneWidget);
        expect(repository.reads + repository.confirms, 0);
        expect(repository.pendingQueries, [true]);
        repository.failRead = true;
        await tester.tap(find.text(button));
        await tester.pumpAndSettle();
        expect(find.text(announcementJson['body'] as String), findsOneWidget);
        expect(
          find.text('Could not update team announcements.'),
          findsOneWidget,
        );
        repository.failRead = false;
        repository.failRefreshAfterRead = dark;
        await tester.tap(find.text(button));
        await tester.pumpAndSettle();
        expect(repository.confirms, dark ? 1 : 0);
        expect(repository.reads, dark ? 0 : 1);
        expect(find.text(announcementJson['body'] as String), findsNothing);
        await tester.pumpWidget(screen('one'));
        await tester.pumpAndSettle();
        expect(find.text(announcementJson['body'] as String), findsNothing);
        await tester.pumpWidget(screen('two'));
        await tester.pumpAndSettle();
        expect(find.text(announcementJson['body'] as String), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  test('correction times remain UTC and requester/reviewer are parsed', () {
    final request = CorrectionRequest.fromJson(correctionJson);
    expect(request.name, 'Sam');
    expect(request.originalIn!.isUtc, isTrue);
    expect(
      request.requestedOut.difference(request.originalOut!),
      const Duration(hours: 1),
    );
  });
  test('correction requests send canonical UTC times with a reason', () async {
    final adapter = _Adapter();
    final dio = Dio()..httpClientAdapter = adapter;
    await ApiTeamWorkRepository(dio).requestCorrection(
      'workspace',
      attendanceId: 'attendance',
      clockIn: DateTime.parse('2026-10-01T10:00:00+02:00'),
      clockOut: DateTime.parse('2026-10-01T18:00:00+02:00'),
      reason: ' Forgot to clock out ',
    );
    expect(
      adapter.requests.single.path,
      '/workspaces/workspace/team-work/corrections',
    );
    expect(adapter.requests.single.data, {
      'attendanceId': 'attendance',
      'clockInAt': '2026-10-01T08:00:00.000Z',
      'clockOutAt': '2026-10-01T16:00:00.000Z',
      'reason': 'Forgot to clock out',
    });
    dio.close();
  });
  test(
    'announcement publish carries stable request ID and acknowledgment choice',
    () async {
      final adapter = _Adapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final repository = ApiTeamWorkRepository(dio);
      await repository.publish(
        'workspace',
        clientId: 'stable-id',
        title: ' Schedule ',
        body: ' New schedule ',
        acknowledgment: true,
      );
      expect(adapter.requests.single.data, {
        'clientId': 'stable-id',
        'title': 'Schedule',
        'body': 'New schedule',
        'requiresAcknowledgment': true,
      });
      dio.close();
    },
  );
  test('an older feed response cannot replace a later refresh', () async {
    final old = Completer<WorkPage<int>>(), latest = Completer<WorkPage<int>>();
    var calls = 0;
    final cubit = WorkFeedCubit<int>(
      (_) => ++calls == 1 ? old.future : latest.future,
    );
    final first = cubit.load();
    final second = cubit.load();
    latest.complete(const WorkPage([2], 1));
    await second;
    old.complete(const WorkPage([1], 1));
    await first;
    expect(cubit.state.items, [2]);
    await cubit.close();
  });
  test('pagination appends and stops at the server total', () async {
    final cubit = WorkFeedCubit<int>((page) async => WorkPage([page], 2));
    await cubit.load();
    expect(cubit.state.hasMore, isTrue);
    await cubit.load(more: true);
    expect(cubit.state.items, [1, 2]);
    expect(cubit.state.hasMore, isFalse);
    await cubit.close();
  });
  test('failed mutations preserve records and unlock controls', () async {
    final cubit = WorkFeedCubit<int>((_) async => const WorkPage([1], 1));
    await cubit.load();
    expect(
      await cubit.mutate(
        'one',
        () async => throw const ApiException(message: 'Already reviewed'),
      ),
      isFalse,
    );
    expect(cubit.state.items, [1]);
    expect(cubit.state.busyId, isNull);
    expect(cubit.state.error, 'Already reviewed');
    await cubit.close();
  });
  test(
    'only one review is submitted while the first review is pending',
    () async {
      final cubit = WorkFeedCubit<int>((_) async => const WorkPage([1], 1));
      await cubit.load();
      final gate = Completer<void>();
      var calls = 0;
      final first = cubit.mutate('one', () {
        calls++;
        return gate.future;
      });
      expect(
        await cubit.mutate('two', () async {
          calls++;
        }),
        isFalse,
      );
      expect(calls, 1);
      gate.complete();
      await first;
      await cubit.close();
    },
  );
  test('reply IDs survive serialization for offline retry', () {
    final original = ChatOutboxOperation(
      id: 'client',
      type: 'TEXT',
      createdAt: DateTime.utc(2026),
      text: 'Reply',
      replyToMessageId: 'target',
    );
    final restored = ChatOutboxOperation.fromJson(original.toJson());
    expect(restored.replyToMessageId, 'target');
    expect(restored.id, original.id);
  });
  for (final dark in [false, true]) {
    testWidgets(
      'correction shows old and requested times at mobile width, dark=$dark',
      (tester) async {
        tester.view.resetPhysicalSize();
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.darkTheme() : AppTheme.lightTheme(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: CorrectionRequestCard(
                  request: CorrectionRequest.fromJson(correctionJson),
                  timezone: 'Africa/Cairo',
                  onApprove: () {},
                  onDecline: () {},
                ),
              ),
            ),
          ),
        );
        expect(find.text('Original times'), findsOneWidget);
        expect(find.text('Requested times'), findsOneWidget);
        expect(find.text('Approve'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'opening the full announcement records read, but requires a separate confirmation',
    (tester) async {
      final repository = _Announcements();
      final cubit = WorkFeedCubit<TeamAnnouncement>(
        (_) async => WorkPage([
          TeamAnnouncement.fromJson({
            ...announcementJson,
            'receipt': {
              'readAt': repository.reads == 0 ? null : '2026-10-11T08:00:00Z',
              'acknowledgedAt': null,
            },
          }),
        ], 1),
      );
      await cubit.load();
      addTearDown(cubit.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnnouncementsView(
              repository: repository,
              cubit: cubit,
              workspaceId: 'workspace',
              timezone: 'Etc/UTC',
              manager: false,
            ),
          ),
        ),
      );
      expect(repository.reads, 0);
      expect(find.text('I have read and understood'), findsNothing);
      await tester.tap(find.text('Read announcement'));
      await tester.pumpAndSettle();
      expect(repository.reads, 1);
      expect(repository.confirms, 0);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I have read and understood'));
      await tester.pumpAndSettle();
      expect(repository.confirms, 1);
    },
  );
  testWidgets(
    'chat search asks the repository for history and offers a reply',
    (tester) async {
      final repository = _Search();
      await tester.pumpWidget(
        MaterialApp(
          home: ChatSearchDialog(
            repository: repository,
            workspaceId: 'workspace',
            groupId: 'group',
            timezone: 'Etc/UTC',
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'earlier');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(repository.queries, ['earlier']);
      expect(find.text('Earlier message from last month'), findsOneWidget);
      expect(find.byTooltip('Reply'), findsOneWidget);
    },
  );
}
