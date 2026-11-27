import 'package:equatable/equatable.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';

class EmployeeDashboardSummary extends Equatable {
  const EmployeeDashboardSummary({
    required this.pendingLeaveRequests,
    required this.approvedLeaveRequests,
    required this.unreadNotifications,
    this.currency = 'EGP',
    this.monthlySalary,
    this.hourlyRate = 0,
    this.workedMinutesMonth = 0,
    this.lateMinutesMonth = 0,
    this.overtimeMinutesMonth = 0,
    this.absentDaysMonth = 0,
    this.basePayMonth = 0,
    this.deductionsMonth = 0,
    this.overtimePayMonth = 0,
    this.netPayMonth = 0,
  });

  final int pendingLeaveRequests;
  final int approvedLeaveRequests;
  final int unreadNotifications;
  final String currency;
  final double? monthlySalary;
  final double hourlyRate;
  final int workedMinutesMonth;
  final int lateMinutesMonth;
  final int overtimeMinutesMonth;
  final int absentDaysMonth;
  final double basePayMonth;
  final double deductionsMonth;
  final double overtimePayMonth;
  final double netPayMonth;

  factory EmployeeDashboardSummary.fromJson(
    Map<String, Object?> json,
  ) => EmployeeDashboardSummary(
    pendingLeaveRequests: ApiModelParser.integer(json, 'pendingLeaveRequests'),
    approvedLeaveRequests: ApiModelParser.integer(
      json,
      'approvedLeaveRequests',
    ),
    unreadNotifications: ApiModelParser.integer(json, 'unreadNotifications'),
    currency: ApiModelParser.optionalString(json['currency']) ?? 'EGP',
    monthlySalary: (json['monthlySalary'] as num?)?.toDouble(),
    hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 0,
    workedMinutesMonth:
        ApiModelParser.optionalInteger(json['workedMinutesMonth']) ?? 0,
    lateMinutesMonth:
        ApiModelParser.optionalInteger(json['lateMinutesMonth']) ?? 0,
    overtimeMinutesMonth:
        ApiModelParser.optionalInteger(json['overtimeMinutesMonth']) ?? 0,
    absentDaysMonth:
        ApiModelParser.optionalInteger(json['absentDaysMonth']) ?? 0,
    basePayMonth: (json['basePayMonth'] as num?)?.toDouble() ?? 0,
    deductionsMonth: (json['deductionsMonth'] as num?)?.toDouble() ?? 0,
    overtimePayMonth: (json['overtimePayMonth'] as num?)?.toDouble() ?? 0,
    netPayMonth: (json['netPayMonth'] as num?)?.toDouble() ?? 0,
  );

  @override
  List<Object?> get props => [
    pendingLeaveRequests,
    approvedLeaveRequests,
    unreadNotifications,
    currency,
    monthlySalary,
    hourlyRate,
    workedMinutesMonth,
    lateMinutesMonth,
    overtimeMinutesMonth,
    absentDaysMonth,
    basePayMonth,
    deductionsMonth,
    overtimePayMonth,
    netPayMonth,
  ];
}
