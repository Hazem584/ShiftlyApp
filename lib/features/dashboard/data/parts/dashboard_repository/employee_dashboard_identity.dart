part of '../../dashboard_repository.dart';

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
        membershipId: _uuid(json, 'membershipId'),
        fullName: ApiModelParser.string(json, 'fullName'),
        avatarUrl: ApiModelParser.optionalString(json['avatarUrl']),
        jobTitle: ApiModelParser.optionalString(json['jobTitle']),
      );

  @override
  List<Object?> get props => [membershipId, ...super.props];
}
