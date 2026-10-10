import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/routing/app_routes.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/surface_card.dart';

class DashboardApprovalsCard extends StatelessWidget {
  const DashboardApprovalsCard({required this.pendingRequests, super.key});
  final int pendingRequests;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        context.tr('Pending leave'),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: AppSpacing.s),
      SurfaceCard(
        onTap: () => context.go(AppRoutes.attendanceLeaveRequests),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppPalette.of(context).warningSoft,
                borderRadius: BorderRadius.circular(AppRadii.s),
              ),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.pending_actions_outlined,
                  color: AppPalette.of(context).warning,
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('{value1} leave requests waiting', {
                      'value1': (pendingRequests).toString(),
                    }),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    context.tr('Tap to review and reply'),
                    style: TextStyle(
                      color: AppPalette.of(context).textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => context.go(AppRoutes.attendanceLeaveRequests),
              tooltip: context.tr('Review leave requests'),
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
      ),
    ],
  );
}
