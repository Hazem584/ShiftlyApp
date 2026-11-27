import 'package:shiftly/core/utils/workspace_time.dart';

enum ReportPeriod { weekly, monthly, custom }

class ReportRange {
  ReportRange(DateTime start, DateTime end)
    : start = DateTime.utc(start.year, start.month, start.day),
      end = DateTime.utc(end.year, end.month, end.day) {
    if (this.end.isBefore(this.start) || days > 366) {
      throw const FormatException('Choose a period of up to 366 days.');
    }
  }

  final DateTime start, end;
  int get days => end.difference(start).inDays + 1;
  String get startKey => _key(start);
  String get endKey => _key(end);
  String get label => '$startKey — $endKey';

  static String _key(DateTime d) =>
      WorkspaceTime.localDateKey(year: d.year, month: d.month, day: d.day);

  static ReportRange forPeriod(ReportPeriod period, DateTime localDate) {
    final date = DateTime.utc(localDate.year, localDate.month, localDate.day);
    if (period == ReportPeriod.monthly) {
      return ReportRange(
        DateTime.utc(date.year, date.month),
        DateTime.utc(date.year, date.month + 1, 0),
      );
    }
    final start = date.subtract(Duration(days: (date.weekday + 1) % 7));
    return ReportRange(start, start.add(const Duration(days: 6)));
  }

  ReportRange move(ReportPeriod period, int direction) {
    if (period == ReportPeriod.monthly) {
      return forPeriod(
        period,
        DateTime.utc(start.year, start.month + direction),
      );
    }
    final delta = Duration(days: days * direction);
    return ReportRange(start.add(delta), end.add(delta));
  }

  ({DateTime from, DateTime to}) utcBounds(String timezone) {
    if (!WorkspaceTime.isValid(timezone)) {
      throw const FormatException('Invalid report timezone');
    }
    final next = end.add(const Duration(days: 1));
    return (
      from: WorkspaceTime.wallTimeToUtc(
        date: start,
        hour: 0,
        minute: 0,
        timezoneName: timezone,
      ),
      to: WorkspaceTime.wallTimeToUtc(
        date: next,
        hour: 0,
        minute: 0,
        timezoneName: timezone,
      ).subtract(const Duration(microseconds: 1)),
    );
  }
}
