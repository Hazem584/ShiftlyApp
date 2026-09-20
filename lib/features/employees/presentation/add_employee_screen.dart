import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/models/shift.dart';
import 'package:shiftly/core/models/work_location.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/employees/data/employee_repository.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_cubit.dart';

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
  late final WorkLocation _initialLocation;
  late final Shift _initialShift;
  late WorkLocation _location;
  late Shift _shift;
  DateTime _startDate = DateTime.now();
  EmploymentStatus _status = EmploymentStatus.active;
  bool _valid = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final repository = context.read<EmployeeRepository>();
    _initialLocation = repository.availableLocations.first;
    _initialShift = repository.availableShifts.first;
    _location = _initialLocation;
    _shift = _initialShift;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not add employee. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<EmployeeRepository>();
    return Scaffold(
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.selected,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New team member',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Add their contact details and work assignment.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),
              const _SectionTitle(
                title: 'Personal information',
                subtitle: 'Basic contact details for this employee',
              ),
              const SizedBox(height: 14),
              _LabeledControl(
                label: 'Full name',
                child: TextFormField(
                  key: const Key('full-name-field'),
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Enter full name',
                  ),
                  validator: (value) => (value?.trim().length ?? 0) < 3
                      ? 'Enter the employee’s full name'
                      : null,
                ),
              ),
              const SizedBox(height: 13),
              _LabeledControl(
                label: 'Phone number',
                child: TextFormField(
                  key: const Key('phone-field'),
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Enter phone number',
                  ),
                  validator: (value) =>
                      (value?.replaceAll(RegExp(r'\D'), '').length ?? 0) < 8
                      ? 'Enter a valid phone number'
                      : null,
                ),
              ),
              const SizedBox(height: 13),
              _LabeledControl(
                label: 'Email address',
                child: TextFormField(
                  key: const Key('email-field'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Enter email address',
                  ),
                  validator: (value) =>
                      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(value?.trim() ?? '')
                      ? null
                      : 'Enter a valid email address',
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              const _SectionTitle(
                title: 'Work details',
                subtitle: 'Role, workplace, shift, and employment status',
              ),
              const SizedBox(height: 14),
              _LabeledControl(
                label: 'Job title',
                child: TextFormField(
                  key: const Key('job-title-field'),
                  controller: _jobTitle,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'Enter job title',
                  ),
                  validator: (value) => (value?.trim().length ?? 0) < 2
                      ? 'Enter a job title'
                      : null,
                ),
              ),
              const SizedBox(height: 13),
              _LabeledControl(
                label: 'Workplace / location',
                child: DropdownButtonFormField<WorkLocation>(
                  isExpanded: true,
                  initialValue: _initialLocation,
                  decoration: const InputDecoration(),
                  items: repository.availableLocations
                      .map(
                        (location) => DropdownMenuItem(
                          value: location,
                          child: Text(
                            location.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _submitting
                      ? null
                      : (value) =>
                            setState(() => _location = value ?? _location),
                ),
              ),
              const SizedBox(height: 13),
              _LabeledControl(
                label: 'Assigned shift',
                child: DropdownButtonFormField<Shift>(
                  isExpanded: true,
                  initialValue: _initialShift,
                  decoration: const InputDecoration(),
                  items: repository.availableShifts
                      .map(
                        (shift) => DropdownMenuItem(
                          value: shift,
                          child: Text(
                            '${shift.name} • ${shift.timeRange}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() => _shift = value ?? _shift),
                ),
              ),
              const SizedBox(height: 13),
              _LabeledControl(
                label: 'Start date',
                child: InkWell(
                  onTap: _submitting ? null : _pickDate,
                  borderRadius: BorderRadius.circular(AppRadii.m),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                    ),
                    child: Text(
                      '${_startDate.month.toString().padLeft(2, '0')}/${_startDate.day.toString().padLeft(2, '0')}/${_startDate.year}',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 13),
              _LabeledControl(
                label: 'Employment status',
                child: DropdownButtonFormField<EmploymentStatus>(
                  isExpanded: true,
                  initialValue: EmploymentStatus.active,
                  decoration: const InputDecoration(),
                  items: EmploymentStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(_statusLabel(status)),
                        ),
                      )
                      .toList(),
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() => _status = value ?? _status),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting ? null : context.pop,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      key: const Key('submit-employee'),
                      onPressed: _valid && !_submitting ? _submit : null,
                      icon: _submitting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 19,
                            ),
                      label: Text(
                        _submitting ? 'Adding employee…' : 'Add Employee',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(EmploymentStatus status) => switch (status) {
    EmploymentStatus.active => 'Active',
    EmploymentStatus.onLeave => 'On leave',
    EmploymentStatus.inactive => 'Inactive',
  };
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 2),
      Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    ],
  );
}

class _LabeledControl extends StatelessWidget {
  const _LabeledControl({required this.label, required this.child});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 6),
      child,
    ],
  );
}
