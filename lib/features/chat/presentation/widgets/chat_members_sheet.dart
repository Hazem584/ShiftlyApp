import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/usecases/load_active_chat_members.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_group_details_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/chat/presentation/dialogs/shiftly_chat_dialog.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_form_page.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';

class ChatMembersSheet extends StatelessWidget {
  const ChatMembersSheet({super.key, required this.canManage});
  final bool canManage;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<ChatGroupDetailsCubit, ChatGroupDetailsState>(
    builder: (context, state) {
      final group = state.group;
      return Scaffold(
        appBar: AppBar(
          title: Text(context.tr('Group members')),
          actions: [
            if (canManage && group != null)
              TextButton(
                onPressed: state.mutating ? null : () => _add(context, group),
                child: Text(context.tr('Add members')),
              ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: group == null
              ? const AppContentLoading()
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    if (state.mutating) const AppContentLoading(rows: 1),
                    for (final member in group.members)
                      Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              member.displayName.characters.take(1).toString(),
                            ),
                          ),
                          title: Text(member.displayName),
                          subtitle: member.email == null
                              ? null
                              : Text(member.email!),
                          trailing: canManage
                              ? IconButton(
                                  tooltip: context.tr('Remove member'),
                                  onPressed: state.mutating
                                      ? null
                                      : () => _remove(context, member),
                                  icon: const Icon(Icons.remove_circle_outline),
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
        ),
      );
    },
  );

  Future<void> _remove(BuildContext context, ChatMember member) async {
    final confirmed = await ShiftlyChatDialog.confirm(
      context,
      title: 'Remove member?',
      message: context.tr('{value1} will lose access to this group.', {
        'value1': member.displayName,
      }),
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
      if (!context.mounted) return;
      Fluttertoast.showToast(
        msg: context.tr('Could not load active workspace members.'),
      );
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
    var query = "";
    final details = context.read<ChatGroupDetailsCubit>();
    await ShiftlyChatDialog.showBody<void>(
      context,
      body: StatefulBuilder(
        builder: (dialogContext, setState) => ChatFormPage(
          title: context.tr('Add members'),
          subtitle: context.tr('Choose the people you want to include.'),
          icon: Icons.person_add_alt_1_outlined,
          busy: submitting,
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (submitting) const AppContentLoading(rows: 1),
                if (failure != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      context.tr(failure!),
                      style: TextStyle(
                        color: Theme.of(dialogContext).colorScheme.error,
                      ),
                    ),
                  ),
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: context.tr('Search members'),
                  ),
                  onChanged: (value) =>
                      setState(() => query = value.trim().toLowerCase()),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  child: choices.isEmpty
                      ? Text(
                          context.tr(
                            'No other active workspace members are available.',
                          ),
                        )
                      : ListView(
                          shrinkWrap: true,
                          children: [
                            for (final employee in choices.where(
                              (e) =>
                                  e.displayName.toLowerCase().contains(query),
                            ))
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
              child: Text(
                submitting ? context.tr('Adding…') : context.tr('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
