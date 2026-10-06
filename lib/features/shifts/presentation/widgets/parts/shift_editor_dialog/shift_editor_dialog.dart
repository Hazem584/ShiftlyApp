part of '../../shift_editor_dialog.dart';

class ShiftEditorDialog extends StatefulWidget {
  const ShiftEditorDialog({
    required this.employees,
    required this.timezone,
    this.initial,
    super.key,
  });

  final List<Employee> employees;
  final String timezone;
  final ShiftRecord? initial;

  @override
  State<ShiftEditorDialog> createState() => _ShiftEditorDialogState();
}
