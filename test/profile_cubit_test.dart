import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/models/manager_profile.dart';
import 'package:shiftly/features/profile/data/profile_image_picker.dart';
import 'package:shiftly/features/profile/domain/repositories/profile_repository.dart';
import 'package:shiftly/features/profile/presentation/cubit/profile_cubit.dart';

ManagerProfile _profile({
  String? avatarUrl,
  String name = 'Mona Ibrahim',
  String email = 'mona@example.com',
  String? phone = '+20123456789',
}) => ManagerProfile(
  id: 'profile-id',
  fullName: name,
  role: 'Manager',
  email: email,
  phone: phone,
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
  int loadCalls = 0;
  String? lastPhone;
  Completer<ManagerProfile>? loadCompleter;
  final loadResults = <Future<ManagerProfile>>[];

  @override
  Future<ManagerProfile> getProfile() async {
    loadCalls++;
    if (loadResults.isNotEmpty) return loadResults.removeAt(0);
    if (loadCompleter case final completer?) return completer.future;
    return profile;
  }

  @override
  Future<ManagerProfile> updateProfile({
    required String fullName,
    required String? phone,
  }) async {
    updateCalls++;
    lastPhone = phone;
    if (updateError case final Object error) throw error;
    if (updateCompleter case final completer?) return completer.future;
    profile = _profile(name: fullName, phone: phone);
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

  test('successful edit can clear the canonical nullable phone', () async {
    final repository = _Repository();
    ManagerProfile? synchronized;
    final cubit = await _loaded(
      repository,
      sync: (value) => synchronized = value,
    );

    expect(
      await cubit.update(fullName: 'Mona Ibrahim', phone: null),
      ProfileOperationResult.success,
    );
    expect(repository.lastPhone, isNull);
    expect((cubit.state as ProfileLoaded).profile.phone, isNull);
    expect(synchronized?.phone, isNull);
  });

  test(
    'successful edit changes a phone and preserves an already-null phone',
    () async {
      final repository = _Repository();
      final cubit = await _loaded(repository);

      await cubit.update(fullName: 'Mona Ibrahim', phone: ' +201111111111 ');
      expect(repository.lastPhone, '+201111111111');
      expect((cubit.state as ProfileLoaded).profile.phone, '+201111111111');

      repository.profile = _profile(phone: null);
      await cubit.load();
      await cubit.update(fullName: 'Mona Ibrahim', phone: null);
      expect((cubit.state as ProfileLoaded).profile.phone, isNull);
    },
  );

  test('failed edit retains the previous profile', () async {
    final repository = _Repository()
      ..updateError = const ApiException(message: 'safe failure');
    final cubit = await _loaded(repository);
    final before = (cubit.state as ProfileLoaded).profile;
    expect(
      await cubit.update(fullName: 'Changed', phone: null),
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
    final first = cubit.update(fullName: 'Changed', phone: null);
    expect(
      await cubit.update(fullName: 'Duplicate', phone: null),
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

  test('session binding isolates logout and a different user login', () async {
    final repository = _Repository()
      ..profile = _profile(
        name: 'User A',
        email: 'a@example.com',
        phone: '+201000000001',
        avatarUrl: 'https://cdn.example/a.png',
      );
    final cubit = ProfileCubit(repository);
    addTearDown(cubit.close);
    const scopeA = ProfileSessionScope(userId: 'a', workspaceId: 'one');
    const scopeB = ProfileSessionScope(userId: 'b', workspaceId: 'two');

    cubit.bindSession(scopeA);
    await Future<void>.delayed(Duration.zero);
    expect((cubit.state as ProfileLoaded).profile.fullName, 'User A');

    cubit.bindSession(null);
    expect(cubit.state, isA<ProfileLoading>());

    repository.profile = _profile(
      name: 'User B',
      email: 'b@example.com',
      phone: null,
    );
    cubit.bindSession(scopeB);
    expect(cubit.state, isA<ProfileLoading>());
    await Future<void>.delayed(Duration.zero);
    final profile = (cubit.state as ProfileLoaded).profile;
    expect(profile.fullName, 'User B');
    expect(profile.email, 'b@example.com');
    expect(profile.phone, isNull);
    expect(profile.avatarUrl, isNull);
  });

  test('an in-flight load from a signed-out scope is ignored', () async {
    final pending = Completer<ManagerProfile>();
    final repository = _Repository()..loadResults.add(pending.future);
    var synchronizations = 0;
    final cubit = ProfileCubit(
      repository,
      onProfileChanged: (_) => synchronizations++,
    );
    addTearDown(cubit.close);

    cubit.bindSession(
      const ProfileSessionScope(userId: 'a', workspaceId: 'one'),
    );
    cubit.bindSession(null);
    pending.complete(
      _profile(name: 'User A', avatarUrl: 'https://cdn.example/a.png'),
    );
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, isA<ProfileLoading>());
    expect(synchronizations, 0);
  });

  test('an old mutation cannot overwrite a newly bound user', () async {
    final pending = Completer<ManagerProfile>();
    final repository = _Repository()..profile = _profile(name: 'User A');
    final synchronized = <String?>[];
    final cubit = ProfileCubit(
      repository,
      onProfileChanged: (profile) => synchronized.add(profile.fullName),
    );
    addTearDown(cubit.close);
    const scopeA = ProfileSessionScope(userId: 'a', workspaceId: 'one');
    const scopeB = ProfileSessionScope(userId: 'b', workspaceId: 'two');

    cubit.bindSession(scopeA);
    await Future<void>.delayed(Duration.zero);
    repository.updateCompleter = pending;
    final oldMutation = cubit.update(fullName: 'Changed A', phone: null);

    repository.profile = _profile(name: 'User B', phone: null);
    cubit.bindSession(scopeB);
    await Future<void>.delayed(Duration.zero);
    pending.complete(
      _profile(name: 'Changed A', avatarUrl: 'https://cdn.example/a.png'),
    );

    expect(await oldMutation, ProfileOperationResult.stale);
    expect((cubit.state as ProfileLoaded).profile.fullName, 'User B');
    expect(synchronized.last, 'User B');
  });

  test(
    'same-scope refresh and profile synchronization do not reload',
    () async {
      final repository = _Repository();
      const first = ProfileSessionScope(userId: 'a', workspaceId: 'one');
      const second = ProfileSessionScope(userId: 'a', workspaceId: 'two');
      var emittedScope = first;
      late final ProfileCubit cubit;
      cubit = ProfileCubit(
        repository,
        onProfileChanged: (_) => cubit.bindSession(emittedScope),
      );
      addTearDown(cubit.close);

      cubit.bindSession(first);
      await Future<void>.delayed(Duration.zero);
      cubit.bindSession(first);
      cubit.bindSession(first);
      await cubit.update(fullName: 'Updated', phone: null);
      await Future<void>.delayed(Duration.zero);
      expect(repository.loadCalls, 1);

      repository.profile = ManagerProfile(
        id: 'profile-id',
        fullName: 'Mona Ibrahim',
        role: 'Employee',
        email: 'mona@example.com',
        phone: null,
        workplace: 'Second Workspace',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      emittedScope = second;
      cubit.bindSession(second);
      await Future<void>.delayed(Duration.zero);

      expect(repository.loadCalls, 2);
      final profile = (cubit.state as ProfileLoaded).profile;
      expect(profile.role, 'Employee');
      expect(profile.workplace, 'Second Workspace');
    },
  );
}
