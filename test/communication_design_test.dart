import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/app.dart';
import 'package:shiftly/core/localization/language_cubit.dart';
import 'package:shiftly/core/localization/language_settings.dart';
import 'package:shiftly/core/localization/memory_language_store.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/theme/theme_cubit.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/communication/presentation/announcement_detail_screen.dart';
import 'package:shiftly/features/communication/presentation/communication_actions.dart';
import 'package:shiftly/features/communication/presentation/communication_page.dart';
import 'package:shiftly/features/communication/presentation/notification_permission_screen.dart';
import 'package:shiftly/features/communication/presentation/notification_unavailable_screen.dart';
import 'package:shiftly/features/communication/presentation/preference_editor_screen.dart';
import 'package:shiftly/features/device_sessions/presentation/device_sessions_screen.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:shiftly/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:shiftly/features/notifications/presentation/widgets/notification_card.dart';
import 'package:shiftly/features/profile/data/mock_profile_repository.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/cubit/work_feed_cubit.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/publish_announcement_dialog.dart';
import 'package:shiftly/features/team_work/presentation/widgets/announcements_view.dart';

import 'support/communication_repositories.dart';

class _Updates implements TeamWorkRepository {
  final item = TeamAnnouncement.fromJson({
    'id': 'daily-update',
    'title': 'Morning team briefing',
    'body': 'Please review the updated opening checklist before your next shift. Ask your manager if you need help.',
    'author': {
      'profile': {'fullName': 'Sarah Hassan'},
    },
    'createdAt': '2026-11-14T07:00:00Z',
    'requiresAcknowledgment': true,
    'receipt': {'readAt': null, 'acknowledgedAt': null},
  });
  @override
  Future<void> markAnnouncement(
    String workspaceId,
    String id, {
    bool acknowledge = false,
  }) async {}
  @override
  Future<List<AnnouncementReader>> readers(
    String workspaceId,
    String id,
  ) async => [
    AnnouncementReader.fromJson({
      'membership': {
        'profile': {'fullName': 'Omar Adel'},
      },
      'readAt': '2026-11-14T07:05:00Z',
      'acknowledgedAt': '2026-11-14T07:06:00Z',
    }),
    AnnouncementReader.fromJson({
      'membership': {
        'profile': {'fullName': 'Mona Ali'},
      },
      'readAt': '2026-11-14T07:10:00Z',
    }),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _capture(WidgetTester tester, String name) async {
  expect(tester.takeException(), isNull);
  if (!const bool.fromEnvironment('COMMUNICATION_PREVIEWS')) return;
  await tester.pump(const Duration(milliseconds: 350));
  await tester.runAsync(() async {
    final image = await tester
        .renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('communication-capture')),
        )
        .toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('.artifacts/communication-design/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void main() {
  for (final locale in ['en', 'ar']) {
    for (final dark in [false, true]) {
      testWidgets('communication and settings routes $locale dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        for (final name in ['InterTight', 'Cairo']) {
          await (FontLoader(name)
                ..addFont(rootBundle.load('assets/fonts/$name-Variable.ttf')))
              .load();
        }
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
        await tester.pumpWidget(
          RepaintBoundary(
            key: const Key('communication-capture'),
            child: ShiftlyApp.preview(
              languageStore: MemoryLanguageStore(locale),
              profileRepository: MockProfileRepository(delay: Duration.zero),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(
          find.byKey(const Key('manager-bottom-navigation')),
        );
        final router = GoRouter.of(context);
        await context.read<ThemeCubit>().select(
          dark ? ThemeMode.dark : ThemeMode.light,
        );
        router.go('/profile');
        await tester.pumpAndSettle();
        final suffix = '$locale-${dark ? 'dark' : 'light'}';
        await _capture(tester, 'profile-$suffix');
        await tester.tap(find.byKey(const Key('edit-profile')));
        await tester.pumpAndSettle();
        await _capture(tester, 'personal-information-$suffix');
        await tester.tap(find.byKey(const Key('change-photo')));
        await tester.pumpAndSettle();
        await _capture(tester, 'photo-options-$suffix');
        await _back(tester);
        await tester.pumpAndSettle();
        await _back(tester);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('profile-preferences')));
        await tester.pumpAndSettle();
        await _capture(tester, 'preferences-$suffix');
        for (final key in ['language-selector', 'theme-selector']) {
          await tester.tap(find.byKey(Key(key)));
          await tester.pumpAndSettle();
          await _capture(tester, '$key-$suffix');
          await _back(tester);
          await tester.pumpAndSettle();
        }
        await _back(tester);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('profile-devices-storage')));
        await tester.pumpAndSettle();
        await _capture(tester, 'devices-storage-$suffix');
        await tester.tap(find.byKey(const Key('chat-cache-settings')));
        await tester.pumpAndSettle();
        await _capture(tester, 'cache-$suffix');
        await tester.tap(find.byKey(const Key('clear-chat-cache')));
        await tester.pumpAndSettle();
        await _capture(tester, 'cache-confirmation-$suffix');
        await _back(tester);
        await tester.pumpAndSettle();
        await _back(tester);
        await tester.pumpAndSettle();
        await _back(tester);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('profile-support-service')));
        await tester.pumpAndSettle();
        await _capture(tester, 'service-$suffix');
        await _back(tester);
        await tester.pumpAndSettle();
        final updates = _Updates();
        final feed = WorkFeedCubit<TeamAnnouncement>(
          (_) async => WorkPage([updates.item], 1),
        );
        await feed.load();
        addTearDown(feed.close);
        void open(Widget page) {
          openCommunicationPage(context, page);
        }

        open(
          CommunicationPage(
            title: 'Pending updates',
            child: AnnouncementsView(
              repository: updates,
              cubit: feed,
              workspaceId: 'workspace',
              timezone: 'Africa/Cairo',
              manager: false,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await _capture(tester, 'pending-updates-$suffix');
        await tester.tap(find.byKey(const Key('announcements-archive')));
        await tester.pumpAndSettle();
        await _capture(tester, 'archive-$suffix');
        await _back(tester);
        await tester.pumpAndSettle();
        open(
          AnnouncementDetailScreen(
            item: updates.item,
            repository: updates,
            workspaceId: 'workspace',
            timezone: 'Africa/Cairo',
            manager: true,
          ),
        );
        await tester.pumpAndSettle();
        await _capture(tester, 'announcement-$suffix');
        await tester.tap(
          find.byKey(const Key('announcement-recipient-progress')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
        final bars = tester
            .widgetList<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .toList();
        expect(bars[0].value, 1);
        expect(bars[1].value, .5);
        await _capture(tester, 'recipient-progress-$suffix');
        await tester.tap(find.text('Omar Adel'));
        await tester.pumpAndSettle();
        await _capture(tester, 'recipient-detail-$suffix');
        await _back(tester);
        await tester.pumpAndSettle();
        await _back(tester);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('acknowledge-announcement')));
        await tester.pumpAndSettle();
        await _capture(tester, 'acknowledge-confirmation-$suffix');
        await tester.tap(
          find.byKey(const Key('confirm-announcement-acknowledgment')),
        );
        await tester.pumpAndSettle();
        await _capture(tester, 'acknowledged-$suffix');
        await _back(tester);
        await tester.pumpAndSettle();
        open(
          PublishAnnouncementDialog(
            repository: updates,
            workspaceId: 'workspace',
          ),
        );
        await tester.pumpAndSettle();
        await _capture(tester, 'publish-update-$suffix');
        await _back(tester);
        await tester.pumpAndSettle();
        for (final page in <(String, Widget)>[
          ('notification-permission', const NotificationPermissionScreen()),
          ('unavailable', const NotificationUnavailableScreen()),
        ]) {
          open(page.$2);
          await tester.pumpAndSettle();
          await _capture(tester, '${page.$1}-$suffix');
          await _back(tester);
          await tester.pumpAndSettle();
        }
        final notices = NotificationsCubit(CommunicationNotifications())
          ..bindSession(
            const FeatureSessionScope(
              userId: 'preview',
              workspaceId: 'workspace',
              membershipId: 'member',
              role: WorkspaceRole.manager,
              timezone: 'Africa/Cairo',
            ),
          );
        addTearDown(notices.close);
        open(
          BlocProvider.value(
            value: notices,
            child: const NotificationsScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(NotificationCard), findsNWidgets(3));
        await _capture(tester, 'inbox-$suffix');
        await tester.tap(find.byKey(const Key('notifications-unread-filter')));
        await tester.pumpAndSettle();
        expect(find.byType(NotificationCard), findsNWidgets(2));
        await _capture(tester, 'inbox-unread-$suffix');
        await _back(tester);
        open(
          DeviceSessionsScreen(
            repository: CommunicationDevices(),
            onCurrentSessionRevoked: () async {},
          ),
        );
        await tester.pumpAndSettle();
        await _capture(tester, 'device-sessions-$suffix');
        await tester.tap(find.byKey(const Key('logout-all-devices')));
        await tester.pumpAndSettle();
        await _capture(tester, 'revoke-sessions-$suffix');
        await _back(tester);
        await _back(tester);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
  testWidgets('preference choices wait for explicit apply', (tester) async {
    await tester.pumpWidget(
      ShiftlyApp.preview(languageStore: MemoryLanguageStore('en')),
    );
    await tester.pumpAndSettle();
    final context = tester.element(
      find.byKey(const Key('manager-bottom-navigation')),
    );
    final language = context.read<LanguageCubit>();
    final theme = context.read<ThemeCubit>();
    openCommunicationPage(
      context,
      const PreferenceEditorScreen(language: true),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-arabic')));
    await tester.pumpAndSettle();
    expect(language.state.language, AppLanguage.english);
    await tester.tap(find.byKey(const Key('apply-language')));
    await tester.pumpAndSettle();
    expect(language.state.language, AppLanguage.arabic);
    await theme.select(ThemeMode.dark);
    openCommunicationPage(context, const PreferenceEditorScreen());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('appearance-light')));
    await tester.pumpAndSettle();
    expect(theme.state.mode, ThemeMode.dark);
    await tester.tap(find.byKey(const Key('apply-appearance')));
    await tester.pumpAndSettle();
    expect(theme.state.mode, ThemeMode.light);
    await tester.pumpWidget(const SizedBox());
  });
}
