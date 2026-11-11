import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/theme/app_theme.dart';

double contrast(Color first, Color second) {
  final a = first.computeLuminance(), b = second.computeLuminance();
  return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
}

void main() {
  for (final brightness in Brightness.values) {
    for (final selected in [false, true]) {
      testWidgets(
        '$brightness weekday chips and attendance table text remain readable, selected=$selected',
        (tester) async {
          final theme = brightness == Brightness.light
              ? AppTheme.lightTheme()
              : AppTheme.darkTheme();
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: Scaffold(
                body: Column(
                  children: [
                    FilterChip(
                      label: const Text('Monday'),
                      selected: selected,
                      onSelected: (_) {},
                    ),
                    ChoiceChip(
                      label: const Text('Weekly'),
                      selected: selected,
                      onSelected: (_) {},
                    ),
                    DataTable(
                      columns: const [DataColumn(label: Text('Employee'))],
                      rows: const [
                        DataRow(cells: [DataCell(Text('Adel'))]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
          final label = tester
              .renderObject<RenderParagraph>(find.text('Monday'))
              .text
              .style!
              .color!;
          final weekly = tester
              .renderObject<RenderParagraph>(find.text('Weekly'))
              .text
              .style!
              .color!;
          final background = selected
              ? theme.chipTheme.selectedColor!
              : theme.chipTheme.backgroundColor!;
          expect(contrast(label, background), greaterThanOrEqualTo(4.5));
          expect(contrast(weekly, background), greaterThanOrEqualTo(4.5));
          for (final value in ['Employee', 'Adel']) {
            final color = tester
                .renderObject<RenderParagraph>(find.text(value))
                .text
                .style!
                .color!;
            expect(
              contrast(color, theme.colorScheme.surface),
              greaterThanOrEqualTo(4.5),
            );
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
