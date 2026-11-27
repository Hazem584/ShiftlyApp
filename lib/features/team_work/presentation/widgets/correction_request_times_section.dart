import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/presentation/widgets/correction_request_card_helpers.dart';

class CorrectionRequestTimesSection extends StatelessWidget {
  const CorrectionRequestTimesSection({
    super.key,
    required this.request,
    required this.timezone,
  });
  final CorrectionRequest request;
  final String timezone;

  @override
  Widget build(BuildContext context) {
    String time(DateTime v) =>
        formatCorrectionRequestTime(context, v, timezone);
    final reqDiff = request.requestedOut.difference(request.requestedIn);
    final labelStyle = Theme.of(context).textTheme.labelLarge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('Original times'), style: labelStyle),
        Text(
          request.originalIn == null || request.originalOut == null
              ? context.tr('No attendance recorded')
              : '${time(request.originalIn!)}\n${time(request.originalOut!)}',
        ),
        const SizedBox(height: 10),
        Text(context.tr('Requested times'), style: labelStyle),
        Text('${time(request.requestedIn)}\n${time(request.requestedOut)}'),
        Text(
          context.tr('Requested period: {hours}h {minutes}m', {
            'hours': '${reqDiff.inHours}',
            'minutes': '${reqDiff.inMinutes % 60}',
          }),
        ),
        if (request.approvedIn != null && request.approvedOut != null) ...[
          const SizedBox(height: 10),
          Text(context.tr('Approved times'), style: labelStyle),
          Text('${time(request.approvedIn!)}\n${time(request.approvedOut!)}'),
          Text(
            context.tr('Approved period: {hours}h {minutes}m', {
              'hours':
                  '${request.approvedOut!.difference(request.approvedIn!).inHours}',
              'minutes':
                  '${request.approvedOut!.difference(request.approvedIn!).inMinutes % 60}',
            }),
          ),
        ],
      ],
    );
  }
}
