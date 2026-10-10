import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/auth/presentation/widgets/workspace_invitation_card.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';

void main() {
  for (final locale in ['en', 'ar']) {
    for (final width in [320.0, 1000.0]) {
      testWidgets('invitation actions fit $locale at $width with large text', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var accepts = 0;
        var declines = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme(),
            locale: Locale(locale),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 800),
                  textScaler: const TextScaler.linear(2),
                ),
                child: WorkspaceInvitationCard(
                  invitation: const WorkspaceInvitation(
                    id: 'invite',
                    workspaceId: 'workspace',
                    status: InvitationStatus.pending,
                  ),
                  disabled: false,
                  accepting: false,
                  declining: false,
                  onAccept: () => accepts++,
                  onDecline: () => declines++,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('accept-invitation-invite')));
        await tester.tap(find.byKey(const Key('decline-invitation-invite')));
        expect(accepts, 1);
        expect(declines, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
