import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/team_work/domain/shift_exchange.dart';
import 'package:shiftly/features/team_work/domain/shift_exchange_repository.dart';
import 'package:shiftly/features/team_work/presentation/cubit/work_feed_cubit.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/create_exchange_dialog.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/review_note_dialog.dart';
import 'package:shiftly/features/team_work/presentation/widgets/exchange_request_card.dart';
import 'package:shiftly/features/team_work/presentation/widgets/work_feed_view.dart';

class ShiftExchangesView extends StatefulWidget {
  const ShiftExchangesView({
    super.key,
    required this.workspaceId,
    required this.membershipId,
    required this.timezone,
    required this.manager,
    required this.repository,
    required this.isCurrent,
  });
  final String workspaceId, membershipId, timezone;
  final bool manager;
  final ShiftExchangeRepository repository;
  final bool Function() isCurrent;
  @override
  State<ShiftExchangesView> createState() => _ShiftExchangesViewState();
}

class _ShiftExchangesViewState extends State<ShiftExchangesView> {
  late final _feed = WorkFeedCubit<ShiftExchange>(
    (p) => widget.repository.list(widget.workspaceId, page: p),
  )..load();
  @override
  void dispose() {
    _feed.close();
    super.dispose();
  }

  Future<void> _decision(ShiftExchange r, String decision) async {
    String? note;
    if (['DECLINE', 'REJECT'].contains(decision)) {
      note = await requestReviewNote(context, minimumLength: 5);
      if (note == null) return;
    }
    if (!mounted || !widget.isCurrent()) return;
    await _feed.mutate(
      r.id,
      () => widget.repository.decide(
        widget.workspaceId,
        r.id,
        decision,
        note: note,
      ),
    );
  }

  Future<void> _create() async {
    if (!widget.isCurrent()) return;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreateExchangeDialog(
        repository: widget.repository,
        workspaceId: widget.workspaceId,
        membershipId: widget.membershipId,
        timezone: widget.timezone,
        isCurrent: widget.isCurrent,
      ),
    );
    if (saved == true && mounted && widget.isCurrent()) await _feed.load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('Shift swaps and coverage'))),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: WorkFeedView(
          cubit: _feed,
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr(
                  'Your colleague must accept, then a manager must approve. Your schedule stays the same until approval.',
                ),
              ),
              if (!widget.manager)
                FilledButton.icon(
                  onPressed: _create,
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(context.tr('Request shift swap / coverage')),
                ),
            ],
          ),
          itemBuilder: (context, r, busy) => ExchangeRequestCard(
            request: r,
            membershipId: widget.membershipId,
            manager: widget.manager,
            timezone: widget.timezone,
            busy: busy,
            onDecision: (d) => _decision(r, d),
          ),
        ),
      ),
    ),
  );
}
