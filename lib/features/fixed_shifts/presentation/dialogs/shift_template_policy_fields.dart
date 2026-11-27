import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';

List<TextEditingController> createTemplatePolicyControllers(
  ShiftTemplate? value,
) => [
  TextEditingController(text: (value?.graceMinutes ?? 10).toString()),
  TextEditingController(
    text: (value?.allowedEarlyCheckInMinutes ?? 30).toString(),
  ),
  TextEditingController(
    text: (value?.allowedLateCheckInMinutes ?? 120).toString(),
  ),
  TextEditingController(text: (value?.minimumWorkMinutes ?? 0).toString()),
  TextEditingController(text: (value?.breakMinutes ?? 60).toString()),
];

ShiftTemplateInput buildShiftTemplateInput({
  required TextEditingController name,
  required TextEditingController description,
  required List<TextEditingController> policies,
  required TimeOfDay start,
  required TimeOfDay end,
  required TimeOfDay? breakAt,
  required String colorValue,
}) => ShiftTemplateInput(
  breakMinutes: int.tryParse(policies[4].text) ?? -1,
  breakStartMinute: breakAt == null ? null : breakAt.hour * 60 + breakAt.minute,
  name: name.text,
  description: description.text,
  color: colorValue,
  startMinute: start.hour * 60 + start.minute,
  endMinute: end.hour * 60 + end.minute,
  graceMinutes: int.tryParse(policies[0].text) ?? -1,
  allowedEarlyCheckInMinutes: int.tryParse(policies[1].text) ?? -1,
  allowedLateCheckInMinutes: int.tryParse(policies[2].text) ?? -1,
  minimumWorkMinutes: int.tryParse(policies[3].text) ?? -1,
);

Widget buildTemplatePolicyFieldsGrid({
  required List<TextEditingController> policies,
  required VoidCallback onChanged,
}) => LayoutBuilder(
  builder: (context, constraints) {
    final width = constraints.maxWidth >= 440
        ? (constraints.maxWidth - 10) / 2
        : constraints.maxWidth;
    const labels = [
      'Grace minutes',
      'Early check-in minutes',
      'Late check-in minutes',
      'Minimum work minutes',
      'Break minutes',
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < 5; i++)
          SizedBox(
            width: width,
            child: TextFormField(
              controller: policies[i],
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: context.tr(labels[i])),
              onChanged: (_) => onChanged(),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n == null || n < 0 || n > 1440
                    ? context.tr('Use 0 to 1440')
                    : null;
              },
            ),
          ),
      ],
    );
  },
);
