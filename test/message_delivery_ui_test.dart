import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/features/chat/presentation/cubit/pending_chat_message.dart';
import 'package:shiftly/features/chat/presentation/widgets/message_delivery_status.dart';
import 'package:shiftly/features/chat/presentation/widgets/pending_message_footer.dart';

void main() {
  testWidgets(
    'outgoing acknowledgements distinguish sending, sent and read by all',
    (tester) async {
      for (final entry in [
        (
          const MessageDeliveryStatus(pending: true),
          Icons.schedule_rounded,
          'Sending',
        ),
        (const MessageDeliveryStatus(), Icons.check_rounded, 'Sent'),
        (
          const MessageDeliveryStatus(readByAll: true),
          Icons.done_all_rounded,
          'Read by everyone',
        ),
      ]) {
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: entry.$1)));
        await tester.pumpAndSettle();
        expect(find.byIcon(entry.$2), findsOneWidget);
        expect(find.byTooltip(entry.$3), findsOneWidget);
      }
    },
  );

  testWidgets('pending text stays compact; retry wraps at large text sizes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final status in [ChatUploadState.sending, ChatUploadState.failed]) {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Center(
                child: SizedBox(
                  width: 238,
                  child: PendingMessageFooter(
                    pending: PendingChatMessage(
                      clientMessageId: 'pending',
                      mediaType: PendingChatMediaType.text,
                      status: status,
                      createdAt: DateTime.utc(2026, 10, 10, 10),
                    ),
                    timezone: 'Etc/UTC',
                    onRetry: (_) async {
                      retried = true;
                    },
                    onCancel: (_) async {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
      if (status == ChatUploadState.failed) {
        await tester.tap(find.text('Retry'));
        expect(retried, isTrue);
      }
    }
  });
}
