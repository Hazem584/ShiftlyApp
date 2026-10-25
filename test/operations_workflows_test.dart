import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/features/operations/domain/operations_repository.dart';
import 'package:shiftly/features/operations/presentation/handover_detail.dart';
import 'package:shiftly/features/operations/presentation/handover_editor.dart';
import 'package:shiftly/features/operations/presentation/operations_view.dart';
import 'package:shiftly/features/operations/presentation/proposal_review.dart';

OperationMap shift(String member) => {
  'key': 'shift-$member',
  'memberId': member,
  'name': member,
  'startsAt': '2026-10-25T06:00:00Z',
  'endsAt': '2026-10-25T15:00:00Z',
};

class FakeOperations implements OperationsRepository {
  int approvals = 0, receipts = 0, updates = 0;
  OperationMap? update;
  bool received = false;
  @override
  Future<List<OperationMap>> profiles(String w) async => [];
  @override
  Future<List<OperationMap>> proposals(String w) async => [];
  @override
  Future<OperationMap> handovers(String w, int page) async => {
    'data': <OperationMap>[],
    'hasNext': false,
  };
  @override
  Future<List<OperationMap>> occurrences(String w, String from) async => [
    shift('sender'),
    shift('receiver'),
  ];
  @override
  Future<OperationMap> approve(String w, String id, OperationMap value) async {
    approvals++;
    return {...value, 'status': 'APPLIED'};
  }

  @override
  Future<void> receive(String w, String id, int revision) async {
    receipts++;
    received = true;
  }

  @override
  Future<void> updateItem(
    String w,
    String id,
    String item,
    OperationMap value,
  ) async {
    updates++;
    update = value;
  }

  @override
  Future<OperationMap> handover(String w, String id) async => {
    'id': id,
    'source': shift('sender'),
    'target': shift('receiver'),
    'sender_id': 'sender',
    'receiver_id': 'receiver',
    'status': received ? 'RECEIVED' : 'WAITING_RECEIPT',
    'revision': received ? 2 : 1,
    'parent_id': null,
    'items': [
      {
        'id': 'item',
        'title': 'Reconcile register',
        'detail': 'Pending receipt',
        'due_at': '2026-10-25T15:00:00Z',
        'owner_id': received ? 'receiver' : 'sender',
        'status': received ? 'RECEIVED' : 'OPEN',
        'priority': 'URGENT',
        'revision': received ? 2 : 1,
        'overdue': true,
      },
    ],
    'events': [
      {
        'action': 'CREATED',
        'actorName': 'sender',
        'note': 'Record saved',
        'created_at': '2026-10-25T06:00:00Z',
      },
    ],
  };
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Future<void> mount(WidgetTester t, Widget child) async {
  await t.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  await t.pumpAndSettle();
}

void main() {
  testWidgets(
    'manager sees planner, skills and handovers while employees only see handovers',
    (t) async {
      final repo = FakeOperations();
      await mount(
        t,
        OperationsView(
          repository: repo,
          workspaceId: 'w',
          membershipId: 'm',
          timezone: 'Africa/Cairo',
          manager: true,
          isCurrent: () => true,
        ),
      );
      expect(find.text('Weekly planning'), findsOneWidget);
      expect(find.text('Availability and skills'), findsOneWidget);
      await mount(
        t,
        OperationsView(
          key: const ValueKey('employee'),
          repository: repo,
          workspaceId: 'w',
          membershipId: 'e',
          timezone: 'Africa/Cairo',
          manager: false,
          isCurrent: () => true,
        ),
      );
      expect(find.text('Weekly planning'), findsNothing);
      expect(find.text('Availability and skills'), findsNothing);
      expect(find.text('Create shift handover'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets('publishing is explicit and sends one manager choice per seat', (
    t,
  ) async {
    final repo = FakeOperations();
    OperationMap? applied;
    final draft = <String, Object?>{
      'id': 'draft',
      'status': 'DRAFT',
      'input': {
        'demands': [
          {'label': 'Morning', 'startsAt': '2026-10-31T06:00:00Z'},
        ],
      },
      'result': {
        'seats': [
          {
            'demand': 0,
            'memberId': 'employee',
            'reasons': ['AVAILABLE', 'SKILLS_MATCH'],
            'rejected': <OperationMap>[],
          },
        ],
        'members': [
          {'id': 'employee', 'name': 'Ahmed'},
        ],
        'shortage': 0,
      },
    };
    await mount(
      t,
      SingleChildScrollView(
        child: ProposalReview(
          repository: repo,
          workspaceId: 'w',
          timezone: 'Africa/Cairo',
          draft: draft,
          isCurrent: () => true,
          onApplied: (v) => applied = v,
        ),
      ),
    );
    expect(repo.approvals, 0);
    await t.ensureVisible(find.text('Approve and publish shifts'));
    await t.tap(find.text('Approve and publish shifts'));
    await t.pumpAndSettle();
    expect(repo.approvals, 1);
    expect(applied?['choices'], ['employee']);
  });
  testWidgets('only the designated receiver gets a receipt action', (t) async {
    final repo = FakeOperations();
    await mount(
      t,
      HandoverDetail(
        repository: repo,
        workspaceId: 'w',
        membershipId: 'sender',
        timezone: 'Africa/Cairo',
        manager: false,
        isCurrent: () => true,
        id: 'h',
      ),
    );
    expect(find.text('Confirm receipt and take responsibility'), findsNothing);
    await mount(
      t,
      HandoverDetail(
        key: const ValueKey('receiver'),
        repository: repo,
        workspaceId: 'w',
        membershipId: 'receiver',
        timezone: 'Africa/Cairo',
        manager: false,
        isCurrent: () => true,
        id: 'h',
      ),
    );
    await t.tap(find.text('Confirm receipt and take responsibility'));
    await t.pumpAndSettle();
    expect(repo.receipts, 1);
    expect(
      find.text('Carry unresolved items to the next shift'),
      findsOneWidget,
    );
    await t.ensureVisible(find.text('Resolve'));
    await t.tap(find.text('Resolve'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'Receipt reconciled');
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(repo.update, {
      'revision': 2,
      'status': 'RESOLVED',
      'note': 'Receipt reconciled',
    });
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
  });
  testWidgets(
    'a handover requires two shifts and at least one operational item',
    (t) async {
      final repo = FakeOperations();
      await mount(
        t,
        HandoverEditor(
          repository: repo,
          workspaceId: 'w',
          membershipId: 'sender',
          timezone: 'Africa/Cairo',
          manager: false,
          isCurrent: () => true,
        ),
      );
      await t.tap(find.text('Send handover'));
      await t.pumpAndSettle();
      expect(
        find.text('Choose both shifts and add at least one item'),
        findsOneWidget,
      );
    },
  );
  testWidgets('stale workspace screens cannot publish', (t) async {
    final repo = FakeOperations();
    final draft = <String, Object?>{
      'id': 'd',
      'status': 'DRAFT',
      'input': {'demands': <OperationMap>[]},
      'result': {'seats': <OperationMap>[], 'members': <OperationMap>[]},
    };
    await mount(
      t,
      ProposalReview(
        repository: repo,
        workspaceId: 'w',
        timezone: 'Africa/Cairo',
        draft: draft,
        isCurrent: () => false,
        onApplied: (_) {},
      ),
    );
    await t.tap(find.text('Approve and publish shifts'));
    await t.pumpAndSettle();
    expect(repo.approvals, 0);
  });
}
