import 'package:equatable/equatable.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';

class ShiftEmployeeSummary extends Equatable {
  const ShiftEmployeeSummary({
    required this.membershipId,
    required this.profileId,
    required this.role,
    required this.membershipStatus,
    this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
    this.jobTitle,
    this.joinedAt,
  });

  final String membershipId;
  final String profileId;
  final WorkspaceRole role;
  final MembershipStatus membershipStatus;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? jobTitle;
  final DateTime? joinedAt;

  String get displayName => fullName ?? email ?? 'Unnamed employee';

  factory ShiftEmployeeSummary.fromJson(Map<String, Object?> json) =>
      ShiftEmployeeSummary(
        membershipId: ApiModelParser.string(json, 'id'),
        profileId: ApiModelParser.string(json, 'profileId'),
        role: WorkspaceRole.parse(json['role']),
        membershipStatus: MembershipStatus.parse(json['status']),
        fullName: ApiModelParser.optionalString(json['fullName']),
        email: ApiModelParser.optionalString(json['email']),
        phone: ApiModelParser.optionalString(json['phone']),
        avatarUrl: ApiModelParser.optionalString(json['avatarUrl']),
        jobTitle: ApiModelParser.optionalString(json['jobTitle']),
        joinedAt: ApiModelParser.optionalDate(json['joinedAt']),
      );

  @override
  List<Object?> get props => [
    membershipId,
    profileId,
    role,
    membershipStatus,
    fullName,
    email,
    phone,
    avatarUrl,
    jobTitle,
    joinedAt,
  ];
}
