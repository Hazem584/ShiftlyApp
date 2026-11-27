import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/communication/presentation/announcement_detail_screen.dart';
import 'package:shiftly/features/communication/presentation/communication_actions.dart';
import 'package:shiftly/features/communication/presentation/communication_appearance.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/cubit/work_feed_cubit.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/publish_announcement_dialog.dart';
import 'package:shiftly/features/team_work/presentation/widgets/announcements_feed_list.dart';

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

  Future<void> _publish() async {
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
  }

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
                  child: AnnouncementsFeedList(
                    state: state,
                    items: items,
                    archive: _archive,
                    unread: _unread,
                    timezone: widget.timezone,
                    onRefresh: widget.cubit.load,
                    onLoadMore: () => widget.cubit.load(more: true),
                    onFilterArchive: _filter,
                    onToggleUnread: (v) => setState(() => _unread = v),
                    onOpenItem: _open,
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
                      onPressed: _publish,
                      child: Text(context.tr('Publish update')),
                    ),
                  ),
              ],
            );
          },
        ),
  );
}
