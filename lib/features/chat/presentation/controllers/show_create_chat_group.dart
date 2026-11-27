import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/features/chat/domain/usecases/load_active_chat_members.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';

import '../cubit/chat_groups_cubit.dart';
import '../dialogs/create_chat_group_dialog.dart';
import '../dialogs/shiftly_chat_dialog.dart';

Future<void> showCreateChatGroup(BuildContext context) async {
  final cubit = context.read<ChatGroupsCubit>();
  final scope = cubit.scope;
  if (scope == null) return;
  List<Employee> employees;
  try {
    employees = await loadActiveChatMembers(
      context.read<EmployeeRepository>(),
      scope,
    );
  } catch (_) {
    if (!context.mounted) return;
    Fluttertoast.showToast(
      msg: context.tr('Could not load active workspace members.'),
    );
    return;
  }
  if (!context.mounted || cubit.scope != scope) return;
  await ShiftlyChatDialog.showBody<void>(
    context,
    body: CreateChatGroupDialog(
      cubit: cubit,
      scope: scope,
      employees: employees,
    ),
  );
}
