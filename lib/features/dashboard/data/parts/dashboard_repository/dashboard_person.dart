part of '../../dashboard_repository.dart';

class DashboardPerson extends Equatable {
  const DashboardPerson({
    required this.fullName,
    this.avatarUrl,
    this.jobTitle,
  });

  final String fullName;
  final String? avatarUrl;
  final String? jobTitle;

  factory DashboardPerson.fromJson(Map<String, Object?> json) =>
      DashboardPerson(
        fullName: ApiModelParser.string(json, 'fullName'),
        avatarUrl: ApiModelParser.optionalString(json['avatarUrl']),
        jobTitle: ApiModelParser.optionalString(json['jobTitle']),
      );

  @override
  List<Object?> get props => [fullName, avatarUrl, jobTitle];
}
