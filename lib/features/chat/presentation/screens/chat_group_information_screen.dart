import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/collaboration_appearance.dart';
import 'package:shiftly/core/widgets/collaboration_session_boundary.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_page.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_tile.dart';

import '../cubit/chat_group_details_cubit.dart';

class ChatGroupInformationScreen extends StatelessWidget {
  const ChatGroupInformationScreen({
    required this.details,
    required this.manager,
    required this.onMembers,
    required this.onSearch,
    required this.onPinned,
    required this.onEdit,
    required this.onArchive,
    super.key,
  });
  final ChatGroupDetailsCubit details;
  final bool manager;
  final VoidCallback onMembers, onSearch, onPinned, onEdit, onArchive;
  @override
  Widget build(BuildContext context) =>
      CollaborationSessionBoundary(child: Builder(builder: _build));
  Widget _build(BuildContext context) => CollaborationAppearance(
    child: BlocBuilder<ChatGroupDetailsCubit, ChatGroupDetailsState>(
      bloc: details,
      builder: (context, state) {
        final group = state.group;
        return EmployeePage(
          title: 'Group information',
          footer: group != null && manager && !group.isArchived
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: onEdit,
                      child: Text(context.tr('Edit group')),
                    ),
                    TextButton(
                      onPressed: onArchive,
                      child: Text(context.tr('Archive group')),
                    ),
                  ],
                )
              : null,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (group != null) ...[
                Text(
                  '${group.name} · ${group.memberCount} ${context.tr('members')}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                EmployeeTile(
                  title: context.tr('About this group'),
                  subtitle: group.description ?? context.tr('No description'),
                  icon: Icons.info_outline,
                ),
                const SizedBox(height: 14),
                EmployeeTile(
                  title: context.tr('Members'),
                  subtitle: group.members
                      .take(4)
                      .map((m) => m.displayName)
                      .join(' · '),
                  icon: Icons.group_outlined,
                  onTap: onMembers,
                ),
                const SizedBox(height: 14),
                EmployeeTile(
                  title: context.tr('Search conversation'),
                  icon: Icons.search,
                  onTap: onSearch,
                ),
                const SizedBox(height: 14),
                EmployeeTile(
                  title: context.tr('Pinned messages'),
                  icon: Icons.push_pin_outlined,
                  onTap: onPinned,
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
}
