import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/employee_design.dart';
import 'package:shiftly/features/chat/data/mock_chat_repository.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/screens/chat_media_review_screen.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_conversation_header.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_message_composer.dart';
import 'package:shiftly/features/tasks/application/tasks_cubit.dart';
import 'package:shiftly/features/tasks/data/memory_task_repository.dart';
import 'package:shiftly/features/tasks/domain/task_reminders.dart';
import 'package:shiftly/features/tasks/presentation/tasks_screen.dart';

import 'tasks_feature_test.dart' as fixtures;

Future<void> _host(
  WidgetTester tester,
  Widget page, {
  String locale = 'en',
  bool dark = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  for (final name in ['InterTight', 'Cairo']) {
    await (FontLoader(
      name,
    )..addFont(rootBundle.load('assets/fonts/$name-Variable.ttf'))).load();
  }
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: EmployeeDesign.theme(
        ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
        arabic: locale == 'ar',
      ),
      builder: (context, child) =>
          RepaintBoundary(key: const Key('capture'), child: child!),
      home: page,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('COLLABORATION_PREVIEWS')) return;
  await tester.pump(const Duration(milliseconds: 350));
  await tester.runAsync(() async {
    final image = await tester
        .renderObject<RenderRepaintBoundary>(find.byKey(const Key('capture')))
        .toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('.artifacts/collaboration-design/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  for (final locale in ['en', 'ar']) {
    for (final dark in [false, true]) {
      testWidgets(
        'tasks two-step flow and detail actions render in $locale dark=$dark',
        (tester) async {
          final repo = MemoryTaskRepository();
          for (final title in [
            'Prepare the morning briefing',
            'Check stock delivery',
            'Review the closing checklist',
          ]) {
            await repo.create(
              workspaceId: 'workspace',
              title: title,
              description: 'Keep the team ready for the next shift.',
              dueAt: DateTime.now().add(const Duration(hours: 3)),
              durationMinutes: 25,
            );
          }
          final cubit = TasksCubit(repo, NoTaskReminders());
          await cubit.bindSession(fixtures.scope);
          await _host(
            tester,
            BlocProvider.value(value: cubit, child: const TasksScreen()),
            locale: locale,
            dark: dark,
          );
          await _capture(tester, 'tasks-$locale-${dark ? 'dark' : 'light'}');
          await tester.tap(find.byKey(const Key('add-personal-task')));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byType(TextFormField).first,
            locale == 'ar' ? 'مراجعة مخزون الشيفت' : 'Review shift inventory',
          );
          await _capture(
            tester,
            'task-create-$locale-${dark ? 'dark' : 'light'}',
          );
          await tester.tap(find.byKey(const Key('save-personal-task')));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('task-remind-hour')), findsOneWidget);
          await _capture(
            tester,
            'task-reminders-$locale-${dark ? 'dark' : 'light'}',
          );
          await tester.tap(find.byKey(const Key('save-personal-task')));
          await tester.pumpAndSettle();
          expect(cubit.state.items.length, 4);
          await tester.tap(
            find.text(
              locale == 'ar' ? 'مراجعة مخزون الشيفت' : 'Review shift inventory',
            ),
          );
          await tester.pumpAndSettle();
          await _capture(
            tester,
            'task-details-$locale-${dark ? 'dark' : 'light'}',
          );
          await tester.tap(find.byKey(const Key('task-detail-complete')));
          await tester.pumpAndSettle();
          expect(cubit.state.items.length, 3);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await cubit.close();
        },
      );
      testWidgets(
        'chat bubble menu and composer render in $locale dark=$dark',
        (tester) async {
          final player = AudioPlayer();
          final input = TextEditingController();
          final conversation = ChatConversationCubit(
            const MockChatRepository(),
            const NoopChatRealtime(),
          );
          final now = DateTime.utc(2026, 11, 1, 9, 42);
          final group = ChatGroup(
            id: 'group',
            workspaceId: 'workspace',
            name: locale == 'ar' ? 'فريق التشغيل' : 'Riverside operations',
            memberCount: 12,
            unreadCount: 0,
            createdAt: now,
            updatedAt: now,
          );
          final messages = [
            ChatMessage(
              id: 'one',
              groupId: 'group',
              type: 'TEXT',
              text: locale == 'ar'
                  ? 'ترتيب الرفوف الجديد جاهز. راجع الممر ٣ قبل البريك.'
                  : 'The new shelf layout is ready.\nPlease check aisle 3 before lunch.',
              sender: const ChatSender(
                membershipId: 'other',
                fullName: 'Lina Nasser',
              ),
              createdAt: now,
            ),
            ChatMessage(
              id: 'two',
              groupId: 'group',
              type: 'TEXT',
              text: locale == 'ar'
                  ? 'تمام، هراجعه دلوقتي.'
                  : 'Thanks, I’ll check it now.',
              sender: const ChatSender(membershipId: 'mine', fullName: 'Hazem'),
              createdAt: now.add(const Duration(minutes: 6)),
            ),
          ];
          await _host(
            tester,
            Scaffold(
              appBar: ChatConversationHeader(
                group: group,
                manager: false,
                onInformation: () {},
                onSearch: () {},
                onPinned: () {},
                onMembers: () {},
                onEdit: () {},
                onArchive: () {},
              ),
              body: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          locale == 'ar'
                              ? 'اليوم · ١ نوفمبر'
                              : 'Today · 1 November',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 28),
                        for (final message in messages)
                          ChatMessageBubble(
                            message: message,
                            mine: message.id == 'two',
                            showSender: true,
                            repository: const MockChatRepository(),
                            workspaceId: 'workspace',
                            timezone: 'Africa/Cairo',
                            player: player,
                            onReply: () {},
                            onReact: (_) {},
                          ),
                      ],
                    ),
                  ),
                  BlocProvider.value(
                    value: conversation,
                    child: ChatMessageComposer(
                      disabled: false,
                      textController: input,
                      savingText: false,
                      mediaBusy: false,
                      recording: false,
                      hasPreparedMedia: false,
                      recordingLabel: '',
                      onTextChanged: () {},
                      onSend: () async {},
                      onRetryPrepared: () async {},
                      onPickImage: () async {},
                      onPickDocument: () async {},
                      onStartRecording: () async {},
                      onShareLocation: () async {},
                      onFinishRecording: ({required send}) async {},
                    ),
                  ),
                ],
              ),
            ),
            locale: locale,
            dark: dark,
          );
          await _capture(tester, 'chat-$locale-${dark ? 'dark' : 'light'}');
          await tester.longPress(find.text(messages.last.text!));
          await tester.pumpAndSettle();
          expect(
            find.text(locale == 'ar' ? 'نسخ النص' : 'Copy text'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          player.dispose();
          await tester.pump(const Duration(seconds: 1));
          input.dispose();
          await conversation.close();
        },
      );
    }
  }
  testWidgets('location cancel never returns a send decision', (tester) async {
    ChatMediaDecision? decision;
    var closed = false;
    await _host(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              decision = await Navigator.push(
                context,
                MaterialPageRoute<ChatMediaDecision>(
                  builder: (_) => const ChatMediaReviewScreen(
                    kind: 'LOCATION',
                    location: ChatLocation(latitude: 30.04, longitude: 31.23),
                  ),
                ),
              );
              closed = true;
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(decision, isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('image preview only returns a caption after explicit send', (
    tester,
  ) async {
    ChatMediaDecision? decision;
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
    );
    await _host(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              decision = await Navigator.push(
                context,
                MaterialPageRoute<ChatMediaDecision>(
                  builder: (_) =>
                      ChatMediaReviewScreen(kind: 'IMAGE', bytes: bytes),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(decision, isNull);
    await tester.enterText(find.byType(TextField), 'Shelf layout');
    await tester.tap(find.byKey(const Key('confirm-chat-media')));
    await tester.pumpAndSettle();
    expect(decision?.caption, 'Shelf layout');
    expect(decision?.reselect, isFalse);
    expect(tester.takeException(), isNull);
  });
}
