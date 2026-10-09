import 'package:equatable/equatable.dart';
import 'package:shiftly/features/points/domain/entities/point_enums.dart';

class CalendarPointChange extends Equatable {
  const CalendarPointChange({required this.type, required this.amount});
  factory CalendarPointChange.fromJson(Map<String, Object?> json) =>
      CalendarPointChange(
        type: pointTypeFromJson(json['pointType']),
        amount: json['amount'] is int
            ? json['amount']! as int
            : throw const FormatException('Invalid amount'),
      );
  final PointType type;
  final int amount;
  @override
  List<Object> get props => [type, amount];
}
