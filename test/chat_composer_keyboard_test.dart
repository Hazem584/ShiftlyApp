import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/chat/data/mock_chat_repository.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_message_composer.dart';

void main() {
  late TextEditingController text;
  late ChatConversationCubit cubit;
  late int sent;
  setUp(() {
    text = TextEditingController();
    cubit = ChatConversationCubit(
      const MockChatRepository(),
      const NoopChatRealtime(),
    );
    sent = 0;
  });
  tearDown(() async {
    await cubit.close();
    text.dispose();
  });
  Future<void> pump(
    WidgetTester tester, {
    bool web = true,
    bool disabled = false,
    bool saving = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: ChatMessageComposer(
              disabled: disabled,
              sendOnEnter: web,
              textController: text,
              savingText: saving,
              mediaBusy: false,
              recording: false,
              hasPreparedMedia: false,
              recordingLabel: '',
              onTextChanged: () {},
              onSend: () async {
                sent++;
              },
              onRetryPrepared: () async {},
              onPickImage: () async {},
              onStartRecording: () async {},
              onShareLocation: () async {},
              onFinishRecording: ({required send}) async {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('send icon remains visible when typing enables the button', (
    tester,
  ) async {
    await pump(tester);
    final button = find.byKey(const Key('send-chat-message'));
    expect(tester.widget<IconButton>(button).onPressed, isNull);
    await tester.enterText(
      find.byKey(const Key('chat-message-input')),
      'hello',
    );
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(button).onPressed, isNotNull);
    final icon = find.descendant(
      of: button,
      matching: find.byIcon(Icons.send_rounded),
    );
    final colors = Theme.of(tester.element(icon)).colorScheme;
    expect(IconTheme.of(tester.element(icon)).color, colors.onPrimary);
    expect(colors.onPrimary, isNot(colors.primary));
    await tester.tap(button);
    expect(sent, 1);
  });

  testWidgets('web Enter sends once and Shift Enter adds a new line', (
    tester,
  ) async {
    await pump(tester);
    final input = find.byKey(const Key('chat-message-input'));
    await tester.enterText(input, 'hello');
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    expect(sent, 1);
    expect(text.text, 'hello');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(sent, 1);
    expect(text.text, 'hello\n');
  });

  testWidgets('empty, blocked and saving inputs cannot send with Enter', (
    tester,
  ) async {
    await pump(tester);
    final input = find.byKey(const Key('chat-message-input'));
    await tester.tap(input);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(sent, 0);
    await tester.enterText(input, 'hello');
    await pump(tester, saving: true);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(sent, 0);
    await pump(tester, disabled: true);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('send-chat-message')))
          .onPressed,
      isNull,
    );
    expect(sent, 0);
  });

  testWidgets('native multiline Enter and composing input do not send', (
    tester,
  ) async {
    await pump(tester, web: false);
    final input = find.byKey(const Key('chat-message-input'));
    await tester.enterText(input, 'hello');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(sent, 0);
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'hello\n',
        selection: TextSelection.collapsed(offset: 6),
      ),
    );
    expect(text.text, 'hello\n');
    await pump(tester);
    text.value = const TextEditingValue(
      text: 'hello',
      selection: TextSelection.collapsed(offset: 5),
      composing: TextRange(start: 0, end: 5),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(sent, 0);
  });
}
