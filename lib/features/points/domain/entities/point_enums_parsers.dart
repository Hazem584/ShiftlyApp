import 'package:shiftly/features/points/domain/entities/achievement_type.dart';
import 'package:shiftly/features/points/domain/entities/performance_status.dart';
import 'package:shiftly/features/points/domain/entities/point_type.dart';

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
