import 'package:equatable/equatable.dart';

class PointBalance extends Equatable {
  const PointBalance({this.earned = 0, this.bonuses = 0, this.adjusted = 0, this.redeemed = 0, this.compensated = 0, this.active = 0, this.available = 0, this.total = 0, this.currentMonth = 0});

  factory PointBalance.fromJson(Map<String, Object?> json) => PointBalance(
    earned: json['earned'] as int? ?? 0, bonuses: json['bonuses'] as int? ?? 0,
    adjusted: json['adjusted'] as int? ?? 0, redeemed: json['redeemed'] as int? ?? 0,
    compensated: json['compensated'] as int? ?? 0, active: json['active'] as int? ?? 0,
    available: json['available'] as int? ?? 0, total: json['total'] as int? ?? 0,
    currentMonth: json['currentMonth'] as int? ?? 0,
  );

  final int earned, bonuses, adjusted, redeemed, compensated, active, available, total, currentMonth;
  @override
  List<Object> get props => [earned, bonuses, adjusted, redeemed, compensated, active, available, total, currentMonth];
}
