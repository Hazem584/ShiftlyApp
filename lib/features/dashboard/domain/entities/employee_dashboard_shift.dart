import 'package:equatable/equatable.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/dashboard/domain/entities/dashboard_models_parsers.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

class EmployeeDashboardShift extends Equatable {
  const EmployeeDashboardShift({
    required this.id,
    required this.startsAt,
    required this.endsAt,
    required this.status,
  });

  final String id;
  final DateTime startsAt;
  final DateTime endsAt;
  final ShiftStatus status;

  factory EmployeeDashboardShift.fromJson(Map<String, Object?> json) =>
      EmployeeDashboardShift(
        id: dashboardModelsUuid(json, 'id'),
        startsAt: ApiModelParser.date(json, 'startsAt'),
        endsAt: ApiModelParser.date(json, 'endsAt'),
        status: ShiftStatus.parse(json['status']),
      );

  @override
  List<Object?> get props => [id, startsAt, endsAt, status];
}
