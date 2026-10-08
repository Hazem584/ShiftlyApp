import 'package:equatable/equatable.dart';
import 'package:shiftly/core/utils/clock_time.dart';

class Shift extends Equatable {
  const Shift({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
  });

  final String id;
  final String name;
  final DateTime startTime;
  final DateTime endTime;

  String get timeRange => formattedTimeRange();

  String formattedTimeRange({String? locale}) =>
      '${ClockTime.wallTime(startTime, locale: locale)} – ${ClockTime.wallTime(endTime, locale: locale)}';

  @override
  List<Object?> get props => [id, name, startTime, endTime];
}
