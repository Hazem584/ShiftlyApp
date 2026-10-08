import 'package:equatable/equatable.dart';
import 'package:shiftly/core/network/api_model_parser.dart';
import 'package:shiftly/features/points/data/models/operational_date.dart';
import 'package:shiftly/features/points/data/models/point_enums.dart';

class PointLedgerEntry extends Equatable {
  const PointLedgerEntry({required this.id, required this.type, required this.amount, required this.reason, required this.createdAt, this.operationalDate, this.redemptionId, this.reversedEntryId});
  factory PointLedgerEntry.fromJson(Map<String, Object?> json) => PointLedgerEntry(
    id: ApiModelParser.string(json, 'id'), type: pointTypeFromJson(json['pointType']),
    amount: json['amount'] is int ? json['amount']! as int : throw const FormatException('Invalid amount'),
    reason: ApiModelParser.string(json, 'reason'), createdAt: ApiModelParser.date(json, 'createdAt'),
    operationalDate: json['operationalDate'] is String ? OperationalDate.parse(json['operationalDate']! as String) : null,
    redemptionId: ApiModelParser.optionalString(json['redemptionId']),
    reversedEntryId: ApiModelParser.optionalString(json['reversedEntryId']),
  );
  final String id, reason;
  final PointType type;
  final int amount;
  final DateTime createdAt;
  final OperationalDate? operationalDate;
  final String? redemptionId, reversedEntryId;
  @override
  List<Object?> get props => [id, type, amount, reason, createdAt, operationalDate, redemptionId, reversedEntryId];
}
