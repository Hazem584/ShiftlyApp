import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/legacy_clock_in_review.dart';

class LegacyClockInReviewCard extends StatelessWidget {
  const LegacyClockInReviewCard({
    required this.reviews,
    required this.onRefresh,
    super.key,
  });
  final List<LegacyClockInReview> reviews;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          reviews.any((v) => v.requiresReview)
              ? context.tr('Saved legacy clock-in needs review')
              : context.tr('Legacy clock-in confirmed'),
        ),
        for (final review in reviews) Text(context.tr(review.message)),
        OutlinedButton(
          onPressed: onRefresh,
          child: Text(context.tr('Check attendance again')),
        ),
      ],
    ),
  );
}
