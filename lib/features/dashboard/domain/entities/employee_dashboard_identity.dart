import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/dashboard/domain/entities/dashboard_models_parsers.dart';
import 'package:shiftly/features/dashboard/domain/entities/dashboard_person.dart';

class EmployeeDashboardIdentity extends DashboardPerson {
  const EmployeeDashboardIdentity({
    required this.membershipId,
    required super.fullName,
    super.avatarUrl,
    super.jobTitle,
  });

  final String membershipId;

  factory EmployeeDashboardIdentity.fromJson(Map<String, Object?> json) =>
      EmployeeDashboardIdentity(
        membershipId: dashboardModelsUuid(json, 'membershipId'),
        fullName: ApiModelParser.string(json, 'fullName'),
        avatarUrl: ApiModelParser.optionalString(json['avatarUrl']),
        jobTitle: ApiModelParser.optionalString(json['jobTitle']),
      );

  @override
  List<Object?> get props => [membershipId, ...super.props];
}
