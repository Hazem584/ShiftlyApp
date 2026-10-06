part of '../../dashboard_repository.dart';

sealed class DashboardData extends Equatable {
  const DashboardData({
    required this.date,
    required this.timezone,
    required this.generatedAt,
  });

  final String date;
  final String timezone;
  final DateTime generatedAt;
  bool get isEmpty;
}
