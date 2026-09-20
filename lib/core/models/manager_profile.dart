import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class ManagerProfile extends Equatable {
  const ManagerProfile({
    required this.fullName,
    required this.role,
    required this.email,
    required this.phone,
    required this.workplace,
    this.photoBytes,
  });

  final String fullName;
  final String role;
  final String email;
  final String phone;
  final String workplace;
  final Uint8List? photoBytes;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
  }

  ManagerProfile copyWith({
    String? fullName,
    String? role,
    String? email,
    String? phone,
    String? workplace,
    Uint8List? photoBytes,
  }) => ManagerProfile(
    fullName: fullName ?? this.fullName,
    role: role ?? this.role,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    workplace: workplace ?? this.workplace,
    photoBytes: photoBytes ?? this.photoBytes,
  );

  @override
  List<Object?> get props => [
    fullName,
    role,
    email,
    phone,
    workplace,
    photoBytes,
  ];
}
