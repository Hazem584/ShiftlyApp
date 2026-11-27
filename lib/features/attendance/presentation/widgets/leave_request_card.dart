import 'package:flutter/material.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_card_actions.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_card_body.dart';

class LeaveRequestCard extends StatelessWidget {
  const LeaveRequestCard({
    required this.request,
    required this.updating,
    required this.timezone,
    super.key,
  });
  final LeaveRequestRecord request;
  final bool updating;
  final String timezone;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    key: Key('request-${request.id}'),
    onTap: () => openLeaveRequestDetails(context, request.id, timezone),
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...buildLeaveRequestCardBody(context, request, timezone),
        if (request.canReview) ...[
          const SizedBox(height: 14),
          buildLeaveRequestActionButtons(context, request, updating),
        ],
      ],
    ),
  );
}
