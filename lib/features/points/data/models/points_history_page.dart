import 'package:shiftly/core/network/api_model_parser.dart';
import 'package:shiftly/features/points/data/models/point_ledger_entry.dart';

class PointsHistoryPage {
  const PointsHistoryPage({required this.data, required this.pagination});
  factory PointsHistoryPage.fromJson(Map<String, Object?> json) =>
      PointsHistoryPage(
        data: ApiModelParser.list(json['data'], 'history')
            .map(
              (item) => PointLedgerEntry.fromJson(
                ApiModelParser.map(item, 'ledgerEntry'),
              ),
            )
            .toList(growable: false),
        pagination: ApiPagination.fromJson(
          ApiModelParser.map(json['pagination'], 'pagination'),
        ),
      );
  final List<PointLedgerEntry> data;
  final ApiPagination pagination;
}
