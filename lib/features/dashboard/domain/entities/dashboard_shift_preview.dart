import 'package:equatable/equatable.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/dashboard/domain/entities/dashboard_attendance.dart';
import 'package:shiftly/features/dashboard/domain/entities/dashboard_models_parsers.dart';
import 'package:shiftly/features/dashboard/domain/entities/dashboard_person.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

class DashboardShiftPreview extends Equatable {
  const DashboardShiftPreview({
    required this.shiftId,
    required this.employeeMembershipId,
    required this.employee,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    this.attendance,
  });

  final String shiftId;
  final String employeeMembershipId;
  final DashboardPerson employee;
  final DateTime startsAt;
  final DateTime endsAt;
  final ShiftStatus status;
  final DashboardAttendance? attendance;

  factory DashboardShiftPreview.fromJson(Map<String, Object?> json) {
    final attendance = ApiModelParser.optionalMap(
      json['attendance'],
      'attendance',
    );
    return DashboardShiftPreview(
      shiftId: dashboardModelsUuid(json, 'shiftId'),
      employeeMembershipId: dashboardModelsUuid(json, 'employeeMembershipId'),
      employee: DashboardPerson.fromJson(
        ApiModelParser.map(json['employee'], 'employee'),
      ),
      startsAt: ApiModelParser.date(json, 'startsAt'),
      endsAt: ApiModelParser.date(json, 'endsAt'),
      status: ShiftStatus.parse(json['shiftStatus']),
      attendance: attendance == null
          ? null
          : DashboardAttendance.fromJson(attendance),
    );
  }

  @override
  List<Object?> get props => [
    shiftId,
    employeeMembershipId,
    employee,
    startsAt,
    endsAt,
    status,
    attendance,
  ];
}
