import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/features/chat/presentation/dialogs/shiftly_chat_dialog.dart';

void main() {
  testWidgets('confirmation returns true and keeps the host route mounted', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                result = await ShiftlyChatDialog.confirm(
                  context,
                  title: 'Archive group?',
                  message: 'Members can still read its history.',
                  confirmText: 'Archive',
                  destructive: true,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Archive group?'), findsOneWidget);

    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Archive group?'), findsNothing);
  });
}
