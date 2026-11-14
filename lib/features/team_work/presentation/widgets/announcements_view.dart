import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/features/communication/presentation/announcement_detail_screen.dart';
import 'package:shiftly/features/communication/presentation/communication_actions.dart';
import 'package:shiftly/features/communication/presentation/communication_appearance.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/cubit/work_feed_cubit.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/publish_announcement_dialog.dart';

class AnnouncementsView extends StatefulWidget {
  const AnnouncementsView({
    required this.repository,
    required this.cubit,
    required this.workspaceId,
    required this.timezone,
    required this.manager,
    this.onPendingChanged,
    super.key,
  });
  final TeamWorkRepository repository;
  final WorkFeedCubit<TeamAnnouncement> cubit;
  final String workspaceId, timezone;
  final bool manager;
  final ValueChanged<bool>? onPendingChanged;
  @override
  State<AnnouncementsView> createState() => _AnnouncementsViewState();
}

class _AnnouncementsViewState extends State<AnnouncementsView> {
  late bool _archive = widget.manager;
  bool _unread = false;
  void _filter(bool archive) {
    setState(() {
      _archive = archive;
      _unread = false;
    });
    widget.onPendingChanged?.call(!archive);
  }

  Future<void> _open(TeamAnnouncement item) => openCommunicationPage(
    context,
    AnnouncementDetailScreen(
      item: item,
      repository: widget.repository,
      workspaceId: widget.workspaceId,
      timezone: widget.timezone,
      manager: widget.manager,
      onChanged: () async {
        if (!widget.cubit.isClosed) await widget.cubit.load();
      },
    ),
  );
  @override
  Widget build(BuildContext context) => CommunicationAppearance(
    child:
        BlocBuilder<
          WorkFeedCubit<TeamAnnouncement>,
          WorkFeedState<TeamAnnouncement>
        >(
          bloc: widget.cubit,
          builder: (context, state) {
            final items = state.items
                .where(
                  (i) =>
                      (_archive ||
                          i.readAt == null ||
                          (i.requiresAcknowledgment &&
                              i.acknowledgedAt == null)) &&
                      (!_unread || i.readAt == null),
                )
                .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: widget.cubit.load,
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              key: const Key('announcements-pending'),
                              label: Text(context.tr('Pending updates')),
                              selected: !_archive,
                              onSelected: (_) => _filter(false),
                            ),
                            ChoiceChip(
                              key: const Key('announcements-archive'),
                              label: Text(context.tr('Archive')),
                              selected: _archive,
                              onSelected: (_) => _filter(true),
                            ),
                            if (_archive)
                              FilterChip(
                                label: Text(context.tr('Unread')),
                                selected: _unread,
                                onSelected: (v) => setState(() => _unread = v),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (state.loading) const AppContentLoading(rows: 1),
                        if (state.error != null) ...[
                          Text(context.tr(state.error!)),
                          TextButton(
                            onPressed: widget.cubit.load,
                            child: Text(context.tr('Retry')),
                          ),
                        ],
                        if (!state.loading &&
                            items.isEmpty &&
                            state.error == null)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              context.tr(
                                _archive
                                    ? 'No updates here yet.'
                                    : 'No pending updates.',
                              ),
                            ),
                          ),
                        for (final item in items) ...[
                          Card(
                            child: ListTile(
                              key: ValueKey('announcement-${item.id}'),
                              contentPadding: const EdgeInsets.all(16),
                              leading: Icon(
                                item.requiresAcknowledgment &&
                                        item.acknowledgedAt == null
                                    ? Icons.notifications_outlined
                                    : Icons.article_outlined,
                              ),
                              title: Text(item.title),
                              subtitle: Text(
                                '${item.author} · ${WorkspaceTime.dateTime(item.createdAt, widget.timezone, locale: Localizations.localeOf(context).toString())}\n${context.tr(item.acknowledgedAt != null
                                    ? 'Acknowledged'
                                    : item.requiresAcknowledgment
                                    ? 'Acknowledgment required'
                                    : item.readAt == null
                                    ? 'Unread'
                                    : 'Read')}',
                              ),
                              onTap: state.busyId != null
                                  ? null
                                  : () => _open(item),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (state.hasMore)
                          TextButton(
                            onPressed: state.loadingMore
                                ? null
                                : () => widget.cubit.load(more: true),
                            child: Text(context.tr('Load more')),
                          ),
                        const SizedBox(height: 12),
                        Card(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              context.tr(
                                'Open an update to read it. Acknowledgment is a separate action.',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                  child: FilledButton(
                    onPressed: () => _filter(!_archive),
                    child: Text(
                      context.tr(
                        _archive
                            ? 'View pending updates'
                            : 'View announcement archive',
                      ),
                    ),
                  ),
                ),
                if (widget.manager)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    child: FilledButton(
                      key: const Key('publish-announcement'),
                      onPressed: () async {
                        final published = await openCommunicationPage<bool>(
                          context,
                          PublishAnnouncementDialog(
                            repository: widget.repository,
                            workspaceId: widget.workspaceId,
                          ),
                        );
                        if (published == true && !widget.cubit.isClosed) {
                          await widget.cubit.load();
                        }
                      },
                      child: Text(context.tr('Publish update')),
                    ),
                  ),
              ],
            );
          },
        ),
  );
}
