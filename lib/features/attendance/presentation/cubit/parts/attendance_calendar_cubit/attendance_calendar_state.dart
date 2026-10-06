part of '../../attendance_calendar_cubit.dart';

class AttendanceCalendarState extends Equatable {
  const AttendanceCalendarState({
    this.year,
    this.month,
    this.data,
    this.selectedDate,
    this.loading = false,
    this.refreshing = false,
    this.failure,
  });

  final int? year;
  final int? month;
  final AttendanceCalendarMonth? data;
  final DateTime? selectedDate;
  final bool loading;
  final bool refreshing;
  final Failure? failure;

  bool get hasData => data != null;

  AttendanceCalendarState copyWith({
    int? year,
    int? month,
    AttendanceCalendarMonth? data,
    DateTime? selectedDate,
    bool clearSelectedDate = false,
    bool? loading,
    bool? refreshing,
    Failure? failure,
    bool clearFailure = false,
  }) => AttendanceCalendarState(
    year: year ?? this.year,
    month: month ?? this.month,
    data: data ?? this.data,
    selectedDate: clearSelectedDate ? null : selectedDate ?? this.selectedDate,
    loading: loading ?? this.loading,
    refreshing: refreshing ?? this.refreshing,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [
    year,
    month,
    data,
    selectedDate,
    loading,
    refreshing,
    failure,
  ];
}
