import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/app.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/models/manager_profile.dart';
import 'package:shiftly/features/profile/data/profile_image_picker.dart';
import 'package:shiftly/features/profile/data/profile_repository.dart';
import 'package:shiftly/features/profile/presentation/cubit/profile_cubit.dart';

ManagerProfile _profile({String? avatarUrl}) => ManagerProfile(
  id: 'profile-id',
  fullName: 'Backend User',
  role: 'Operations Manager',
  email: 'backend@example.com',
  phone: 'Not provided',
  workplace: 'Cairo Operations',
  avatarUrl: avatarUrl,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

class _Picker implements ProfileImagePicker {
  _Picker(this.selection);
  final ProfileImageSelection? selection;

  @override
  Future<ProfileImageSelection?> pickImage() async => selection;
}

class _Repository implements ProfileRepository {
  _Repository(this.profile);
  ManagerProfile profile;
  int uploadCalls = 0;
  Object? uploadError;

  @override
  Future<ManagerProfile> getProfile() async => profile;
  @override
  Future<ManagerProfile> updateProfile({
    String? fullName,
    String? phone,
  }) async {
    profile = profile.copyWith(fullName: fullName, phone: phone);
    return profile;
  }

  @override
  Future<ManagerProfile> uploadAvatar(ProfileImageSelection image) async {
    uploadCalls++;
    if (uploadError case final Object error) throw error;
    profile = profile.copyWith(avatarUrl: 'https://cdn.example/avatar.png');
    return profile;
  }

  @override
  Future<ManagerProfile> deleteAvatar() async {
    profile = profile.copyWith(clearAvatarUrl: true);
    return profile;
  }
}

Future<_Repository> _openProfile(
  WidgetTester tester, {
  required ProfileImageSelection selection,
  String? avatarUrl,
}) async {
  final repository = _Repository(_profile(avatarUrl: avatarUrl));
  await tester.pumpWidget(
    ShiftlyApp(
      profileRepository: repository,
      profileImagePicker: _Picker(selection),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Profile').last);
  await tester.pumpAndSettle();
  return repository;
}

Future<void> _edit(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('edit-profile')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('backend profile and nullable fallback are displayed', (
    tester,
  ) async {
    await _openProfile(
      tester,
      selection: ProfileImageSelection(fileName: 'unused', bytes: Uint8List(0)),
    );
    expect(find.text('Backend User'), findsOneWidget);
    expect(find.text('backend@example.com'), findsOneWidget);
    expect(find.text('Not provided'), findsOneWidget);
    expect(find.text('Cairo Operations'), findsAtLeastNWidgets(1));
  });

  testWidgets('oversized avatar is rejected before upload', (tester) async {
    final repository = await _openProfile(
      tester,
      selection: ProfileImageSelection(
        fileName: 'large.png',
        bytes: Uint8List(ProfileCubit.maxAvatarBytes + 1),
      ),
    );
    await _edit(tester);
    await tester.tap(find.byKey(const Key('change-photo')));
    await tester.pump();
    expect(find.text('Avatar must not exceed 2 MiB.'), findsOneWidget);
    expect(repository.uploadCalls, 0);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('unsupported avatar content is rejected safely', (tester) async {
    final repository = await _openProfile(
      tester,
      selection: ProfileImageSelection(
        fileName: 'spoofed.png',
        bytes: Uint8List.fromList([1, 2, 3]),
      ),
    );
    await _edit(tester);
    await tester.tap(find.byKey(const Key('change-photo')));
    await tester.pump();
    expect(find.text('Choose a JPEG, PNG, or WebP image.'), findsOneWidget);
    expect(repository.uploadCalls, 0);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('upload and delete update the displayed avatar', (tester) async {
    final repository = await _openProfile(
      tester,
      selection: ProfileImageSelection(
        fileName: 'avatar.png',
        bytes: Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
        ]),
      ),
    );
    await _edit(tester);
    await tester.tap(find.byKey(const Key('change-photo')));
    await tester.pump();
    expect(repository.uploadCalls, 1);
    expect(find.byKey(const Key('delete-avatar')), findsOneWidget);

    await tester.tap(find.byKey(const Key('delete-avatar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete-avatar')));
    await tester.pump();
    expect(find.byKey(const Key('profile-initials')), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('network upload errors use the existing safe toast', (
    tester,
  ) async {
    final repository = await _openProfile(
      tester,
      selection: ProfileImageSelection(
        fileName: 'avatar.png',
        bytes: Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
        ]),
      ),
    );
    repository.uploadError = const ApiException(
      message: 'You appear to be offline. Check your connection and retry.',
      kind: FailureKind.network,
    );
    await _edit(tester);
    await tester.tap(find.byKey(const Key('change-photo')));
    await tester.pump();
    expect(
      find.text('You appear to be offline. Check your connection and retry.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 4));
  });
}
