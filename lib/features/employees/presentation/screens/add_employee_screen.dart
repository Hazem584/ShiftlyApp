import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/models/shift.dart';
import 'package:shiftly/core/models/work_location.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/features/employees/data/employee_repository.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_cubit.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_form_actions.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_form_header.dart';
import 'package:shiftly/features/employees/presentation/widgets/personal_information_section.dart';
import 'package:shiftly/features/employees/presentation/widgets/work_information_section.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _jobTitle = TextEditingController();
  late WorkLocation _location;
  late Shift _shift;
  DateTime _startDate = DateTime.now();
  EmploymentStatus _status = EmploymentStatus.active;
  bool _valid = false;
  bool _submitting = false;

  EmployeeRepository get _repository => context.read<EmployeeRepository>();

  @override
  void initState() {
    super.initState();
    _location = _repository.availableLocations.first;
    _shift = _repository.availableShifts.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _jobTitle.dispose();
    super.dispose();
  }

  void _revalidate() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (valid != _valid) setState(() => _valid = valid);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _startDate = date);
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    final employee = Employee(
      id: 'emp-${DateTime.now().microsecondsSinceEpoch}',
      fullName: _name.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      jobTitle: _jobTitle.text.trim(),
      location: _location,
      shift: _shift,
      startDate: _startDate,
      employmentStatus: _status,
    );
    try {
      await context.read<EmployeesCubit>().add(employee);
      if (mounted) context.pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ToastService.error(
        context,
        message: 'Could not add employee. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Add New Employee'),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.borderColor),
      ),
    ),
    body: SafeArea(
      top: false,
      child: Form(
        key: _formKey,
        onChanged: _revalidate,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          key: const Key('add-employee-form'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
          children: [
            const EmployeeFormHeader(),
            PersonalInformationSection(
              nameController: _name,
              phoneController: _phone,
              emailController: _email,
            ),
            WorkInformationSection(
              jobTitleController: _jobTitle,
              locations: _repository.availableLocations,
              shifts: _repository.availableShifts,
              selectedLocation: _location,
              selectedShift: _shift,
              startDate: _startDate,
              status: _status,
              enabled: !_submitting,
              onLocationChanged: (value) => setState(() => _location = value),
              onShiftChanged: (value) => setState(() => _shift = value),
              onPickDate: _pickDate,
              onStatusChanged: (value) => setState(() => _status = value),
            ),
            EmployeeFormActions(
              submitting: _submitting,
              canSubmit: _valid,
              onCancel: context.pop,
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    ),
  );
}
