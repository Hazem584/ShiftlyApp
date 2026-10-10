import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/widgets/app_form_dialog.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/usecases/load_active_chat_members.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_group_details_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/chat/presentation/dialogs/shiftly_chat_dialog.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';

class ChatMembersSheet extends StatelessWidget {
  const ChatMembersSheet({super.key, required this.canManage});
  final bool canManage;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ChatGroupDetailsCubit, ChatGroupDetailsState>(
        builder: (context, state) {
          final group = state.group;
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
              ),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * .65,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.tr('Members'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        if (canManage && group != null)
                          IconButton(
                            onPressed: () => _add(context, group),
                            tooltip: 'Add members',
                            icon: const Icon(Icons.person_add_alt_1),
                          ),
                      ],
                    ),
                    if (state.mutating) const LinearProgressIndicator(),
                    Expanded(
                      child: group == null
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              itemCount: group.members.length,
                              itemBuilder: (_, index) {
                                final member = group.members[index];
                                return ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.person_outline),
                                  ),
                                  title: Text(member.displayName),
                                  subtitle: member.email == null
                                      ? null
                                      : Text(member.email!),
                                  trailing: canManage
                                      ? IconButton(
                                          tooltip: 'Remove member',
                                          onPressed: state.mutating
                                              ? null
                                              : () => _remove(context, member),
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                          ),
                                        )
                                      : null,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

  Future<void> _remove(BuildContext context, ChatMember member) async {
    final confirmed = await ShiftlyChatDialog.confirm(
      context,
      title: 'Remove member?',
      message: '${member.displayName} will lose access to this group.',
      confirmText: 'Remove',
      destructive: true,
    );
    if (confirmed && context.mounted) {
      await context.read<ChatGroupDetailsCubit>().removeMember(
        member.membershipId,
      );
    }
  }

  Future<void> _add(BuildContext context, ChatGroup group) async {
    final scope = context.read<ChatGroupsCubit>().scope;
    if (scope == null) return;
    List<Employee> employees;
    try {
      employees = await loadActiveChatMembers(
        context.read<EmployeeRepository>(),
        scope,
      );
    } catch (_) {
      Fluttertoast.showToast(msg: 'Could not load active workspace members.');
      return;
    }
    if (!context.mounted || context.read<ChatGroupsCubit>().scope != scope) {
      return;
    }
    final existing = group.members.map((m) => m.membershipId).toSet();
    final choices = employees.where((e) => !existing.contains(e.id)).toList();
    final selected = <String>{};
    var submitting = false;
    String? failure;
    final details = context.read<ChatGroupDetailsCubit>();
    await ShiftlyChatDialog.showBody<void>(
      context,
      body: StatefulBuilder(
        builder: (dialogContext, setState) => AppFormDialog(
          title: 'Add members',
          subtitle: 'Choose the people you want to include.',
          icon: Icons.person_add_alt_1_outlined,
          busy: submitting,
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (submitting) const LinearProgressIndicator(),
                if (failure != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      failure!,
                      style: TextStyle(
                        color: Theme.of(dialogContext).colorScheme.error,
                      ),
                    ),
                  ),
                Flexible(
                  child: choices.isEmpty
                      ? const Text(
                          'No other active workspace members are available.',
                        )
                      : ListView(
                          shrinkWrap: true,
                          children: [
                            for (final employee in choices)
                              CheckboxListTile(
                                value: selected.contains(employee.id),
                                title: Text(employee.displayName),
                                onChanged: submitting
                                    ? null
                                    : (value) => setState(
                                        () => value == true
                                            ? selected.add(employee.id)
                                            : selected.remove(employee.id),
                                      ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(dialogContext),
              child: Text(context.tr('Cancel')),
            ),
            FilledButton(
              onPressed: selected.isEmpty || submitting
                  ? null
                  : () async {
                      setState(() {
                        submitting = true;
                        failure = null;
                      });
                      final added = await details.addMembers(selected.toList());
                      if (!dialogContext.mounted) return;
                      if (added) {
                        Navigator.pop(dialogContext);
                      } else {
                        setState(() {
                          submitting = false;
                          failure =
                              details.state.failure?.message ??
                              'Could not add members.';
                        });
                      }
                    },
              child: Text(submitting ? 'Adding…' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
}
