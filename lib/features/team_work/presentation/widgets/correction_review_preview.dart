import 'package:flutter/material.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/presentation/widgets/correction_request_card.dart';

class CorrectionReviewPreview extends StatelessWidget {
  const CorrectionReviewPreview({
    required this.request,
    required this.timezone,
    required this.busy,
    required this.onApprove,
    required this.onDecline,
    super.key,
  });
  final Future<CorrectionRequest> request;
  final String timezone;
  final bool busy;
  final VoidCallback onApprove, onDecline;

  @override
  Widget build(BuildContext context) => FutureBuilder<CorrectionRequest>(
    future: request,
    builder: (context, s) {
      if (s.hasError) {
        return Text(context.tr(ApiErrorParser.parse(s.error!).message));
      }
      if (!s.hasData) return const AppContentLoading();
      return CorrectionRequestCard(
        request: s.data!,
        timezone: timezone,
        busy: busy,
        onApprove: onApprove,
        onDecline: onDecline,
      );
    },
  );
}
