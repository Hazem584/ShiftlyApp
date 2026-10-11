import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/app_toast_widget.dart';

Future<BuildContext> _pumpToastHost(
  WidgetTester tester, {
  bool dark = false,
}) async {
  late BuildContext toastContext;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
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

  for (final dark in [false, true]) {
    for (final type in ToastType.values) {
      testWidgets(
        '${type.name} overlay has readable text and icons in ${dark ? 'dark' : 'light'} mode',
        (tester) async {
          final context = await _pumpToastHost(tester, dark: dark);
          ToastService.show(context, message: 'Account update', type: type);
          await tester.pump();
          final toast = find.byType(AppToastWidget);
          final box = tester.widget<DecoratedBox>(
            find
                .descendant(of: toast, matching: find.byType(DecoratedBox))
                .first,
          );
          final background = (box.decoration as BoxDecoration).color!;
          final foreground = tester
              .widget<Text>(find.text('Account update'))
              .style!
              .color!;
          expect(_contrast(foreground, background), greaterThanOrEqualTo(4.5));
          final icon = tester.widget<Icon>(
            find.descendant(of: toast, matching: find.byType(Icon)).first,
          );
          expect(_contrast(icon.color!, background), greaterThanOrEqualTo(3));
          final close = tester.widget<IconButton>(
            find.descendant(of: toast, matching: find.byType(IconButton)),
          );
          expect(_contrast(close.color!, background), greaterThanOrEqualTo(3));
          expect(
            background.computeLuminance(),
            dark ? lessThan(.1) : greaterThan(.8),
          );
          await tester.tap(find.byIcon(Icons.close_rounded));
          await tester.pumpAndSettle();
          expect(find.byType(AppToastWidget), findsNothing);
        },
      );
    }
  }

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

double _contrast(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  return a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05);
}
