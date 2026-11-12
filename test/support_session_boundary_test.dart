import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/support/presentation/support_session_boundary.dart';

SessionState _user(String id) => SessionState(
  status: SessionStatus.authenticatedEmployee,
  currentUser: CurrentUser(
    id: id,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    memberships: const [],
  ),
);

class _Session extends Cubit<SessionState> implements SessionCoordinator {
  _Session() : super(_user('first-user'));
  void change(SessionState value) => emit(value);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'erases private in-progress support UI when the signed-in account changes',
    (tester) async {
      final session = _Session();
      addTearDown(session.close);
      await tester.pumpWidget(
        BlocProvider<SessionCoordinator>.value(
          value: session,
          child: const MaterialApp(
            home: Scaffold(body: SupportSessionBoundary(child: TextField())),
          ),
        ),
      );
      await tester.enterText(
        find.byType(TextField),
        'Private report belonging to the first account',
      );
      session.change(_user('second-user'));
      await tester.pumpAndSettle();
      expect(
        find.text('Private report belonging to the first account'),
        findsNothing,
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        isEmpty,
      );
      session.change(const SessionState.initializing());
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
    },
  );
}
