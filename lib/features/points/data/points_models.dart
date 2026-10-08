import 'package:equatable/equatable.dart';
import 'package:shiftly/core/network/api_model_parser.dart';

enum PointType { green, black, red, orange, blue, unknown }

enum PerformanceStatus {
  present,
  late,
  absent,
  incomplete,
  excused,
  dayOff,
  pending,
  unknown,
}

enum AchievementType {
  perfectWeek,
  onTime10,
  reliability30Days,
  teamSupporter,
  nightShiftHero,
  zeroAbsenceMonth,
  unknown,
}

PointType pointTypeFromJson(Object? value) => switch (value) {
  'GREEN' => PointType.green,
  'BLACK' => PointType.black,
  'RED' => PointType.red,
  'ORANGE' => PointType.orange,
  'BLUE' => PointType.blue,
  _ => PointType.unknown,
};

PerformanceStatus performanceStatusFromJson(Object? value) => switch (value) {
  'PRESENT' => PerformanceStatus.present,
  'LATE' => PerformanceStatus.late,
  'ABSENT' => PerformanceStatus.absent,
  'INCOMPLETE' => PerformanceStatus.incomplete,
  'EXCUSED' || 'APPROVED_LEAVE' => PerformanceStatus.excused,
  'DAY_OFF' => PerformanceStatus.dayOff,
  'PENDING' ||
  'POINTS_HISTORICAL_CONTEXT_UNAVAILABLE' => PerformanceStatus.pending,
  _ => PerformanceStatus.unknown,
};

AchievementType achievementTypeFromJson(Object? value) => switch (value) {
  'PERFECT_WEEK' => AchievementType.perfectWeek,
  'ON_TIME_10' => AchievementType.onTime10,
  'RELIABILITY_30_DAYS' => AchievementType.reliability30Days,
  'TEAM_SUPPORTER' => AchievementType.teamSupporter,
  'NIGHT_SHIFT_HERO' => AchievementType.nightShiftHero,
  'ZERO_ABSENCE_MONTH' => AchievementType.zeroAbsenceMonth,
  _ => AchievementType.unknown,
};

class OperationalDate extends Equatable implements Comparable<OperationalDate> {
  const OperationalDate._(this.value, this.year, this.month, this.day);

  factory OperationalDate.parse(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) throw const FormatException('Invalid operationalDate');
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final check = DateTime.utc(year, month, day);
    if (check.year != year || check.month != month || check.day != day) {
      throw const FormatException('Invalid operationalDate');
    }
    return OperationalDate._(value, year, month, day);
  }

  final String value;
  final int year;
  final int month;
  final int day;
  DateTime get calendarDate => DateTime(year, month, day);

  @override
  int compareTo(OperationalDate other) => value.compareTo(other.value);
  @override
  List<Object> get props => [value];
  @override
  String toString() => value;
}

class PointBalance extends Equatable {
  const PointBalance({
    this.earned = 0,
    this.bonuses = 0,
    this.adjusted = 0,
    this.redeemed = 0,
    this.compensated = 0,
    this.active = 0,
    this.available = 0,
    this.total = 0,
    this.currentMonth = 0,
  });

  factory PointBalance.fromJson(Map<String, Object?> json) => PointBalance(
    earned: json['earned'] as int? ?? 0,
    bonuses: json['bonuses'] as int? ?? 0,
    adjusted: json['adjusted'] as int? ?? 0,
    redeemed: json['redeemed'] as int? ?? 0,
    compensated: json['compensated'] as int? ?? 0,
    active: json['active'] as int? ?? 0,
    available: json['available'] as int? ?? 0,
    total: json['total'] as int? ?? 0,
    currentMonth: json['currentMonth'] as int? ?? 0,
  );

  final int earned;
  final int bonuses;
  final int adjusted;
  final int redeemed;
  final int compensated;
  final int active;
  final int available;
  final int total;
  final int currentMonth;
  @override
  List<Object> get props => [
    earned,
    bonuses,
    adjusted,
    redeemed,
    compensated,
    active,
    available,
    total,
    currentMonth,
  ];
}

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

  final String workspaceId;
  final String workspaceName;
  final String timezone;
  final PointBalance green;
  final PointBalance black;
  final PointBalance red;
  final PointBalance orange;
  final PointBalance blue;
  final int currentStreak;
  final int bestStreak;
  final int? nextRewardAt;
  final int greenCostPerRed;
  final int monthlyRedLimit;
  final int remainingMonthlyCompensations;

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

class PointLedgerEntry extends Equatable {
  const PointLedgerEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.reason,
    required this.createdAt,
    this.operationalDate,
    this.redemptionId,
    this.reversedEntryId,
  });

  factory PointLedgerEntry.fromJson(Map<String, Object?> json) =>
      PointLedgerEntry(
        id: ApiModelParser.string(json, 'id'),
        type: pointTypeFromJson(json['pointType']),
        amount: json['amount'] is int
            ? json['amount']! as int
            : throw const FormatException('Invalid amount'),
        reason: ApiModelParser.string(json, 'reason'),
        createdAt: ApiModelParser.date(json, 'createdAt'),
        operationalDate: json['operationalDate'] is String
            ? OperationalDate.parse(json['operationalDate']! as String)
            : null,
        redemptionId: ApiModelParser.optionalString(json['redemptionId']),
        reversedEntryId: ApiModelParser.optionalString(json['reversedEntryId']),
      );

  final String id;
  final PointType type;
  final int amount;
  final String reason;
  final DateTime createdAt;
  final OperationalDate? operationalDate;
  final String? redemptionId;
  final String? reversedEntryId;
  @override
  List<Object?> get props => [
    id,
    type,
    amount,
    reason,
    createdAt,
    operationalDate,
    redemptionId,
    reversedEntryId,
  ];
}

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

class PerformanceDay extends Equatable {
  const PerformanceDay({
    required this.date,
    required this.status,
    required this.extraEffort,
    required this.pointChanges,
    this.templateName,
    this.clockInAt,
    this.clockOutAt,
    this.workDurationMinutes,
    this.lateMinutes,
  });
  factory PerformanceDay.fromJson(Map<String, Object?> json) => PerformanceDay(
    date: OperationalDate.parse(ApiModelParser.string(json, 'operationalDate')),
    status: performanceStatusFromJson(json['status']),
    extraEffort: json['extraEffort'] == true,
    templateName: ApiModelParser.optionalString(json['templateName']),
    clockInAt: ApiModelParser.optionalDate(json['clockInAt']),
    clockOutAt: ApiModelParser.optionalDate(json['clockOutAt']),
    workDurationMinutes: ApiModelParser.optionalInteger(
      json['workDurationMinutes'],
    ),
    lateMinutes: ApiModelParser.optionalInteger(json['lateMinutes']),
    pointChanges: ApiModelParser.list(json['pointChanges'], 'pointChanges')
        .map(
          (item) => CalendarPointChange.fromJson(
            ApiModelParser.map(item, 'pointChange'),
          ),
        )
        .toList(growable: false),
  );
  final OperationalDate date;
  final PerformanceStatus status;
  final bool extraEffort;
  final String? templateName;
  final DateTime? clockInAt;
  final DateTime? clockOutAt;
  final int? workDurationMinutes;
  final int? lateMinutes;
  final List<CalendarPointChange> pointChanges;
  @override
  List<Object?> get props => [
    date,
    status,
    extraEffort,
    templateName,
    clockInAt,
    clockOutAt,
    workDurationMinutes,
    lateMinutes,
    pointChanges,
  ];
}

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

class RedemptionIntent extends Equatable {
  const RedemptionIntent({
    required this.workspaceId,
    required this.redPoints,
    required this.clientRedemptionId,
  });
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
