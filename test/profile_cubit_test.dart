import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/models/manager_profile.dart';
import 'package:shiftly/features/profile/data/profile_image_picker.dart';
import 'package:shiftly/features/profile/data/profile_repository.dart';
import 'package:shiftly/features/profile/presentation/cubit/profile_cubit.dart';

ManagerProfile _profile({String? avatarUrl, String name = 'Mona Ibrahim'}) =>
    ManagerProfile(
      id: 'profile-id',
      fullName: name,
      role: 'Manager',
      email: 'mona@example.com',
      phone: '+20123456789',
      workplace: 'Shift Lab',
      avatarUrl: avatarUrl,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

ProfileImageSelection _png() => ProfileImageSelection(
  fileName: 'avatar.png',
  bytes: Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
);

class _Repository implements ProfileRepository {
  ManagerProfile profile = _profile();
  Object? updateError;
  Object? uploadError;
  Object? deleteError;
  Completer<ManagerProfile>? updateCompleter;
  Completer<ManagerProfile>? uploadCompleter;
  Completer<ManagerProfile>? deleteCompleter;
  int updateCalls = 0;
  int uploadCalls = 0;
  int deleteCalls = 0;

  @override
  Future<ManagerProfile> getProfile() async => profile;

  @override
  Future<ManagerProfile> updateProfile({
    String? fullName,
    String? phone,
  }) async {
    updateCalls++;
    if (updateError case final Object error) throw error;
    if (updateCompleter case final completer?) return completer.future;
    profile = _profile(name: fullName ?? profile.fullName);
    return profile;
  }

  @override
  Future<ManagerProfile> uploadAvatar(ProfileImageSelection image) async {
    uploadCalls++;
    if (uploadError case final Object error) throw error;
    if (uploadCompleter case final completer?) return completer.future;
    profile = _profile(avatarUrl: 'https://cdn.example/new.png');
    return profile;
  }

  @override
  Future<ManagerProfile> deleteAvatar() async {
    deleteCalls++;
    if (deleteError case final Object error) throw error;
    if (deleteCompleter case final completer?) return completer.future;
    profile = _profile();
    return profile;
  }
}

Future<ProfileCubit> _loaded(
  _Repository repository, {
  void Function(ManagerProfile)? sync,
}) async {
  final cubit = ProfileCubit(repository, onProfileChanged: sync);
  addTearDown(cubit.close);
  await cubit.load();
  return cubit;
}

void main() {
  test('initial load emits the repository profile', () async {
    final repository = _Repository();
    final cubit = await _loaded(repository);
    expect((cubit.state as ProfileLoaded).profile, repository.profile);
  });

  test(
    'successful edit updates profile and synchronizes session source',
    () async {
      final repository = _Repository();
      ManagerProfile? synchronized;
      final cubit = await _loaded(
        repository,
        sync: (value) => synchronized = value,
      );
      final result = await cubit.update(
        fullName: '  New Name  ',
        phone: '+20123456789',
      );
      expect(result, ProfileOperationResult.success);
      expect((cubit.state as ProfileLoaded).profile.fullName, 'New Name');
      expect(synchronized?.fullName, 'New Name');
    },
  );

  test('failed edit retains the previous profile', () async {
    final repository = _Repository()
      ..updateError = const ApiException(message: 'safe failure');
    final cubit = await _loaded(repository);
    final before = (cubit.state as ProfileLoaded).profile;
    expect(
      await cubit.update(fullName: 'Changed'),
      ProfileOperationResult.failure,
    );
    final state = cubit.state as ProfileLoaded;
    expect(state.profile, before);
    expect(state.failure?.message, 'safe failure');
  });

  test('duplicate edit is prevented while submitting', () async {
    final repository = _Repository()
      ..updateCompleter = Completer<ManagerProfile>();
    final cubit = await _loaded(repository);
    final first = cubit.update(fullName: 'Changed');
    expect(
      await cubit.update(fullName: 'Duplicate'),
      ProfileOperationResult.busy,
    );
    expect(repository.updateCalls, 1);
    repository.updateCompleter!.complete(_profile(name: 'Changed'));
    expect(await first, ProfileOperationResult.success);
  });

  test(
    'avatar upload and replacement use the canonical returned URL',
    () async {
      final repository = _Repository()
        ..profile = _profile(avatarUrl: 'https://cdn.example/old.png');
      final cubit = await _loaded(repository);
      expect(await cubit.uploadAvatar(_png()), ProfileOperationResult.success);
      expect(
        (cubit.state as ProfileLoaded).profile.avatarUrl,
        'https://cdn.example/new.png',
      );
    },
  );

  test('failed and cancelled upload retain the previous avatar', () async {
    final repository = _Repository()
      ..profile = _profile(avatarUrl: 'https://cdn.example/old.png')
      ..uploadError = const ApiException(
        message: 'cancelled',
        kind: FailureKind.cancelled,
      );
    final cubit = await _loaded(repository);
    expect(await cubit.uploadAvatar(_png()), ProfileOperationResult.cancelled);
    expect(
      (cubit.state as ProfileLoaded).profile.avatarUrl,
      'https://cdn.example/old.png',
    );
  });

  test(
    'oversized and unsupported images are rejected before repository',
    () async {
      final repository = _Repository();
      final cubit = await _loaded(repository);
      final oversized = ProfileImageSelection(
        fileName: 'large.png',
        bytes: Uint8List(ProfileCubit.maxAvatarBytes + 1),
      );
      final unsupported = ProfileImageSelection(
        fileName: 'text.txt',
        bytes: Uint8List.fromList([1, 2, 3]),
      );
      expect(
        await cubit.uploadAvatar(oversized),
        ProfileOperationResult.imageTooLarge,
      );
      expect(
        await cubit.uploadAvatar(unsupported),
        ProfileOperationResult.unsupportedImage,
      );
      expect(repository.uploadCalls, 0);
    },
  );

  test('delete success clears avatar and failure retains it', () async {
    final repository = _Repository()
      ..profile = _profile(avatarUrl: 'https://cdn.example/old.png');
    final cubit = await _loaded(repository);
    expect(await cubit.deleteAvatar(), ProfileOperationResult.success);
    expect((cubit.state as ProfileLoaded).profile.avatarUrl, isNull);

    repository.profile = _profile(avatarUrl: 'https://cdn.example/again.png');
    await cubit.load();
    repository.deleteError = const ApiException(message: 'delete failed');
    expect(await cubit.deleteAvatar(), ProfileOperationResult.failure);
    expect(
      (cubit.state as ProfileLoaded).profile.avatarUrl,
      'https://cdn.example/again.png',
    );
  });

  test('duplicate upload and delete are prevented', () async {
    final repository = _Repository()
      ..uploadCompleter = Completer<ManagerProfile>();
    final cubit = await _loaded(repository);
    final upload = cubit.uploadAvatar(_png());
    expect(await cubit.deleteAvatar(), ProfileOperationResult.busy);
    expect(repository.deleteCalls, 0);
    repository.uploadCompleter!.complete(
      _profile(avatarUrl: 'https://cdn.example/new.png'),
    );
    expect(await upload, ProfileOperationResult.success);
  });
}
