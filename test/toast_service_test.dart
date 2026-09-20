import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/widgets/app_toast_widget.dart';

Future<BuildContext> _pumpToastHost(WidgetTester tester) async {
  late BuildContext toastContext;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            toastContext = context;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
  );
  return toastContext;
}

void main() {
  tearDown(ToastService.dismissAll);

  for (final type in ToastType.values) {
    testWidgets('${type.name} toast uses branded custom content', (
      tester,
    ) async {
      final context = await _pumpToastHost(tester);
      switch (type) {
        case ToastType.success:
          ToastService.success(context, message: 'Success message');
          break;
        case ToastType.error:
          ToastService.error(context, message: 'Error message');
          break;
        case ToastType.warning:
          ToastService.warning(context, message: 'Warning message');
          break;
        case ToastType.info:
          ToastService.info(context, message: 'Information message');
          break;
      }
      await tester.pump();

      final toast = tester.widget<AppToastWidget>(find.byType(AppToastWidget));
      expect(toast.type, type);
      expect(find.textContaining('message'), findsOneWidget);
      ToastService.dismissAll();
    });
  }

  testWidgets('toast service inserts custom content into the overlay', (
    tester,
  ) async {
    final context = await _pumpToastHost(tester);
    ToastService.success(context, message: 'Saved');
    await tester.pump();

    expect(find.byType(AppToastWidget), findsOneWidget);
    expect(
      find.descendant(of: find.byType(Overlay), matching: find.text('Saved')),
      findsOneWidget,
    );
    ToastService.dismissAll();
  });

  testWidgets('long toast text wraps without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final context = await _pumpToastHost(tester);
    ToastService.info(
      context,
      message: 'This is a deliberately long informational toast message that must wrap safely on compact mobile screens without overflowing.',
    );
    await tester.pump();

    expect(find.byType(AppToastWidget), findsOneWidget);
    expect(tester.takeException(), isNull);
    ToastService.dismissAll();
  });

  testWidgets('toast call safely ignores a disposed context', (tester) async {
    final context = await _pumpToastHost(tester);
    await tester.pumpWidget(const SizedBox());

    expect(
      () => ToastService.info(context, message: 'No longer mounted'),
      returnsNormally,
    );
    expect(find.byType(AppToastWidget), findsNothing);
  });
}
