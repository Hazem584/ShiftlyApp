import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/features/manager_performance/data/api_manager_points_repository.dart';

import 'points_feature_test.dart'
    show walletJson, dayJson, entryJson, workspaceId;
import 'support/manager_points_adapter.dart';

Map<String, Object?> policyJson() => {
  'id': 'p',
  'workspaceId': workspaceId,
  'effectiveFrom': '2026-10-09',
  'greenPointsForCompletedAttendance': 1,
  'blackPointsForLateAttendance': 1,
  'redPointsForAbsence': 1,
  'orangePointsForIncompleteAttendance': 1,
  'bluePointsForExtraEffort': 1,
  'blueGreenEquivalent': 2,
  'greenCostPerRedCompensation': 5,
  'monthlyRedCompensationLimit': 2,
  'blackPointsWarningThreshold': 3,
  'disputeWindowHours': 48,
  'earlyDepartureToleranceMinutes': 15,
  'incompleteAttendanceResolutionMinutes': 720,
  'streakRewardEnabled': true,
  'streakRequiredDays': 5,
  'streakGreenReward': 1,
  'isEnabled': true,
};

void main() {
  late ManagerPointsAdapter adapter;
  late ApiManagerPointsRepository repository;
  setUp(() {
    adapter = ManagerPointsAdapter();
    repository = ApiManagerPointsRepository(
      Dio(BaseOptions(baseUrl: 'https://local.test/api/v1'))
        ..httpClientAdapter = adapter,
    );
  });
  test('exact manager list paths, filters and pagination envelopes', () async {
    for (final resource in ['summary', 'disputes', 'history']) {
      adapter.response = {
        'data': [
          resource == 'history' ? entryJson() : {'id': 'member-1'},
        ],
        'pagination': {'page': 2, 'limit': 20, 'total': 40, 'totalPages': 2},
      };
      final target = resource == 'history' ? 'member-1' : null;
      final query = {
        'page': 2,
        'limit': 20,
        if (resource == 'summary') 'search': 'Ahmed',
        if (resource == 'disputes') 'status': 'PENDING',
        if (resource == 'history') ...{
          'pointType': 'GREEN',
          'from': '2026-10-01',
          'to': '2026-10-08',
          'reason': 'ATTENDANCE_COMPLETED',
        },
      };
      final page = await repository.list(
        workspaceId,
        resource,
        target: target,
        query: query,
      );
      expect(page.pagination!.page, 2);
      expect(adapter.requests.last.method, 'GET');
      expect(
        adapter.requests.last.path,
        '/workspaces/$workspaceId/${target == null ? '' : 'employees/member-1/'}points/$resource',
      );
      expect(adapter.requests.last.queryParameters, query);
    }
  });
  test('all workspace and employee read contracts', () async {
    for (final resource in [
      'policies',
      'warnings',
      'extra-effort',
      'adjustments',
      'achievements',
      'calendar',
    ]) {
      final target = ['policies', 'warnings'].contains(resource)
          ? null
          : 'member-1';
      adapter.response = resource == 'calendar' ? [dayJson()] : [];
      await repository.list(
        workspaceId,
        resource,
        target: target,
        query: resource == 'calendar' ? {'year': 2026, 'month': 10} : {},
      );
      expect(
        adapter.requests.last.path,
        '/workspaces/$workspaceId/${target == null ? '' : 'employees/member-1/'}points/$resource',
      );
    }
    for (final resource in [
      '',
      'adjustments/a',
      'policies/current',
      'disputes/d',
    ]) {
      final target = resource == '' || resource == 'adjustments/a'
          ? 'member-1'
          : null;
      adapter.response = resource.isEmpty
          ? walletJson()
          : resource == 'policies/current'
          ? policyJson()
          : {
              'id': 'id',
              'workspaceId': workspaceId,
              'employeeMembershipId': ?target,
            };
      await repository.get(workspaceId, resource, target: target);
      expect(
        adapter.requests.last.path,
        '/workspaces/$workspaceId/${target == null ? '' : 'employees/member-1/'}points${resource.isEmpty ? '' : '/$resource'}',
      );
    }
  });
  test('exact adjustment, award and reversal payloads require matching canonical responses', () async {
    final payloads = <String, Map<String, Object?>>{
      'adjustments': {
        'pointType': 'RED',
        'amount': -1,
        'reason': 'TECHNICAL_CORRECTION',
        'explanation': 'Fixed evidence',
        'clientAdjustmentId': 'uuid',
      },
      'extra-effort': {
        'bluePoints': 2,
        'reason': 'APPROVED_OVERTIME',
        'explanation': 'Approved coverage',
        'clientAwardId': 'uuid',
      },
      'adjustments/a/reverse': {
        'reason': 'OTHER',
        'explanation': 'Correction reversed',
        'clientReversalId': 'uuid',
      },
      'extra-effort/a/reverse': {
        'reason': 'Changed decision',
        'explanation': 'Coverage reversed',
        'clientReversalId': 'uuid',
      },
    };
    for (final operation in payloads.entries) {
      final reverse = operation.key.endsWith('/reverse');
      adapter.response = {
        'id': 'a',
        'workspaceId': workspaceId,
        'employeeMembershipId': 'member-1',
        for (final entry in operation.value.entries)
          (reverse && entry.key == 'reason'
                  ? 'reversalReason'
                  : reverse && entry.key == 'explanation'
                  ? 'reversalExplanation'
                  : entry.key):
              entry.value,
        if (reverse) 'reversedAt': '2026-10-08T12:00:00Z',
      };
      await repository.mutate(
        workspaceId,
        operation.key,
        operation.value,
        target: 'member-1',
      );
      expect(adapter.requests.last.method, 'POST');
      expect(adapter.requests.last.data, operation.value);
      expect(
        adapter.requests.last.path,
        '/workspaces/$workspaceId/employees/member-1/points/${operation.key}',
      );
      adapter.response = {
        'id': 'a',
        'workspaceId': workspaceId,
        'employeeMembershipId': 'wrong-member',
      };
      await expectLater(
        repository.mutate(
          workspaceId,
          operation.key,
          operation.value,
          target: 'member-1',
        ),
        throwsA(isA<ApiException>()),
      );
    }
  });
  test('policy and review never gain invented UUID fields', () async {
    final policy = {
      'effectiveFrom': '2026-10-09',
      'streakRewardEnabled': true,
      'blueGreenEquivalent': 2,
    };
    adapter.response = {'id': 'p', 'workspaceId': workspaceId, ...policy};
    await repository.mutate(workspaceId, 'policies', policy);
    expect(adapter.requests.last.data, policy);
    final review = {
      'decision': 'REJECTED',
      'response': 'Attendance evidence confirmed',
    };
    adapter.response = {
      'id': 'd',
      'workspaceId': workspaceId,
      'status': 'REJECTED',
      'managerResponse': review['response'],
    };
    await repository.mutate(
      workspaceId,
      'disputes/d/review',
      review,
      patch: true,
    );
    expect(adapter.requests.last.method, 'PATCH');
    expect(adapter.requests.last.data, review);
  });
  test(
    'malformed successful wallet/calendar responses become parsed failures',
    () async {
      adapter.response = {'id': 'bad'};
      await expectLater(
        repository.get(workspaceId, '', target: 'member-1'),
        throwsA(isA<ApiException>()),
      );
      adapter.response = [
        {'operationalDate': '2026-02-31', 'pointChanges': []},
      ];
      await expectLater(
        repository.list(workspaceId, 'calendar', target: 'member-1'),
        throwsA(isA<ApiException>()),
      );
    },
  );
}
