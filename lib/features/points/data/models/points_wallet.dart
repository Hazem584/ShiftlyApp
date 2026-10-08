import 'package:equatable/equatable.dart';
import 'package:shiftly/core/network/api_model_parser.dart';
import 'package:shiftly/features/points/data/models/point_balance.dart';

class PointsWallet extends Equatable {
  const PointsWallet({
    required this.workspaceId,
    required this.workspaceName,
    required this.timezone,
    required this.green,
    required this.black,
    required this.red,
    required this.orange,
    required this.blue,
    required this.currentStreak,
    required this.bestStreak,
    required this.nextRewardAt,
    required this.greenCostPerRed,
    required this.monthlyRedLimit,
    required this.remainingMonthlyCompensations,
  });

  factory PointsWallet.fromJson(Map<String, Object?> json) {
    final workspace = ApiModelParser.map(json['workspace'], 'workspace');
    final streak = ApiModelParser.map(json['streak'], 'streak');
    final policy = ApiModelParser.map(json['policy'], 'policy');
    return PointsWallet(
      workspaceId: ApiModelParser.string(workspace, 'id'),
      workspaceName: ApiModelParser.string(workspace, 'name'),
      timezone: ApiModelParser.string(workspace, 'timezone'),
      green: PointBalance.fromJson(ApiModelParser.map(json['green'], 'green')),
      black: PointBalance.fromJson(ApiModelParser.map(json['black'], 'black')),
      red: PointBalance.fromJson(ApiModelParser.map(json['red'], 'red')),
      orange: PointBalance.fromJson(
        ApiModelParser.map(json['orange'], 'orange'),
      ),
      blue: PointBalance.fromJson(ApiModelParser.map(json['blue'], 'blue')),
      currentStreak: ApiModelParser.integer(streak, 'current'),
      bestStreak: ApiModelParser.integer(streak, 'best'),
      nextRewardAt: ApiModelParser.optionalInteger(streak['nextRewardAt']),
      greenCostPerRed: ApiModelParser.integer(
        policy,
        'greenCostPerRedCompensation',
        minimum: 1,
      ),
      monthlyRedLimit: ApiModelParser.integer(
        policy,
        'monthlyRedCompensationLimit',
      ),
      remainingMonthlyCompensations: ApiModelParser.integer(
        policy,
        'remainingMonthlyCompensations',
      ),
    );
  }

  final String workspaceId, workspaceName, timezone;
  final PointBalance green, black, red, orange, blue;
  final int currentStreak,
      bestStreak,
      greenCostPerRed,
      monthlyRedLimit,
      remainingMonthlyCompensations;
  final int? nextRewardAt;
  int get greenNeededForOneRed =>
      (greenCostPerRed - green.available).clamp(0, greenCostPerRed);
  int get maxRedeemable => [
    green.available ~/ greenCostPerRed,
    red.active,
    remainingMonthlyCompensations,
  ].reduce((a, b) => a < b ? a : b);
  @override
  List<Object?> get props => [
    workspaceId,
    workspaceName,
    timezone,
    green,
    black,
    red,
    orange,
    blue,
    currentStreak,
    bestStreak,
    nextRewardAt,
    greenCostPerRed,
    monthlyRedLimit,
    remainingMonthlyCompensations,
  ];
}
