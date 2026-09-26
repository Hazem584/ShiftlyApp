import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class ManagerProfile extends Equatable {
  const ManagerProfile({
    required this.fullName,
    required this.role,
    required this.email,
    required this.phone,
    required this.workplace,
    this.id = '',
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
    this.photoBytes,
  });

  final String? fullName;
  final String role;
  final String? email;
  final String? phone;
  final String workplace;
  final String id;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Uint8List? photoBytes;

  String get displayName => fullName ?? 'Shiftly user';
  String get displayEmail => email ?? 'Not provided';
  String get displayPhone => phone ?? 'Not provided';

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    final value = parts
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return value.isEmpty ? 'S' : value;
  }

  ManagerProfile copyWith({
    String? fullName,
    String? role,
    String? email,
    String? phone,
    bool clearPhone = false,
    String? workplace,
    String? id,
    String? avatarUrl,
    bool clearAvatarUrl = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    Uint8List? photoBytes,
  }) => ManagerProfile(
    fullName: fullName ?? this.fullName,
    role: role ?? this.role,
    email: email ?? this.email,
    phone: clearPhone ? null : phone ?? this.phone,
    workplace: workplace ?? this.workplace,
    id: id ?? this.id,
    avatarUrl: clearAvatarUrl ? null : avatarUrl ?? this.avatarUrl,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    photoBytes: photoBytes ?? this.photoBytes,
  );

  @override
  List<Object?> get props => [
    fullName,
    role,
    email,
    phone,
    workplace,
    id,
    avatarUrl,
    createdAt,
    updatedAt,
    photoBytes,
  ];
}
