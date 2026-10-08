import 'package:equatable/equatable.dart';
import 'package:shiftly/core/network/api_model_parser.dart';
import 'package:shiftly/features/points/data/models/point_enums.dart';

class Achievement extends Equatable {
  const Achievement({
    required this.id,
    required this.type,
    required this.earnedAt,
    this.period,
  });
  factory Achievement.fromJson(Map<String, Object?> json) => Achievement(
    id: ApiModelParser.string(json, 'id'),
    type: achievementTypeFromJson(json['badgeType']),
    earnedAt: ApiModelParser.date(json, 'earnedAt'),
    period: ApiModelParser.optionalString(json['period']),
  );
  final String id;
  final AchievementType type;
  final DateTime earnedAt;
  final String? period;
  @override
  List<Object?> get props => [id, type, earnedAt, period];
}
