import 'package:equatable/equatable.dart';
import 'package:shiftly/core/network/api_model_parser.dart';

class RedemptionIntent extends Equatable {
  const RedemptionIntent({
    required this.workspaceId,
    required this.redPoints,
    required this.clientRedemptionId,
  });
  factory RedemptionIntent.fromJson(Map<String, Object?> json) =>
      RedemptionIntent(
        workspaceId: ApiModelParser.string(json, 'workspaceId'),
        redPoints: json['redPoints'] is int
            ? json['redPoints']! as int
            : throw const FormatException('Invalid redPoints'),
        clientRedemptionId: ApiModelParser.string(json, 'clientRedemptionId'),
      );
  final String workspaceId;
  final int redPoints;
  final String clientRedemptionId;
  Map<String, Object> toJson() => {
    'workspaceId': workspaceId,
    'redPoints': redPoints,
    'clientRedemptionId': clientRedemptionId,
  };
  @override
  List<Object> get props => [workspaceId, redPoints, clientRedemptionId];
}
