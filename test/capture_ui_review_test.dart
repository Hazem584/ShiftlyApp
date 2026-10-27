import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shiftly/app.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/localization/memory_language_store.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_repository.dart';
import 'package:shiftly/features/auth/presentation/screens/login_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/workspace_selection_screen.dart';
import 'package:shiftly/features/breaks/application/shift_break_controller.dart';
import 'package:shiftly/features/chat/data/mock_chat_repository.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_message_composer.dart';
import 'package:shiftly/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/dashboard/presentation/screens/employee_dashboard_screen.dart';
import 'package:shiftly/features/employees/data/mock_employee_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/invitations/data/mock_invitation_repository.dart';
import 'package:shiftly/features/operations/presentation/handover_detail.dart';
import 'package:shiftly/features/tasks/application/tasks_cubit.dart';
import 'package:shiftly/features/tasks/data/memory_task_repository.dart';
import 'package:shiftly/features/tasks/domain/task_reminders.dart';
import 'package:shiftly/features/tasks/presentation/tasks_screen.dart';
import 'package:shiftly/features/workspaces/data/mock_workspace_repository.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_cubit.dart';

import 'dashboard_fixtures.dart';
import 'operations_workflows_test.dart' show FakeOperations;
import 'support/attendance_test_cubit.dart';
import 'support/onboarding_test_auth.dart';

class ReviewDashboardRepository extends MockDashboardRepository {
  ReviewDashboardRepository(MockEmployeeRepository repository)
    : super(employeeRepository: repository, delay: Duration.zero);
  @override
  Future<EmployeeDashboardData> getEmployeeDashboard(String workspaceId) async {
    final base = employeeDashboard(timezone: 'Africa/Cairo');
    final now = DateTime.now();
    return EmployeeDashboardData(
      date: WorkspaceTime.dateKey(now, 'Africa/Cairo'),
      timezone: base.timezone,
      generatedAt: now,
      employee: base.employee,
      summary: base.summary,
      recentLeaveRequests: base.recentLeaveRequests,
      todayShift: EmployeeDashboardShift(
        id: base.todayShift!.id,
        startsAt: now.subtract(const Duration(hours: 2, minutes: 48)),
        endsAt: now.add(const Duration(hours: 5, minutes: 12)),
        status: base.todayShift!.status,
      ),
      nextShift: null,
      attendance: base.attendance,
    );
  }
}

class ReviewAudio implements AudioPlayer {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ReviewAuthRepository implements AuthenticationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ReviewWorkspaceSession extends SessionCoordinator {
  ReviewWorkspaceSession(OnboardingTestAuth auth, CurrentUser user)
    : super(auth, ReviewAuthRepository(), MemoryActiveWorkspaceStorage()) {
    emit(
      SessionState(
        status: SessionStatus.workspaceSelectionRequired,
        currentUser: user,
      ),
    );
  }
}

class ReviewChats extends MockChatRepository {
  const ReviewChats(this.ar);
  final bool ar;
  @override
  Future<ChatGroup> getGroup(String w, String id) async => ChatGroup(
    id: id,
    workspaceId: w,
    name: ar ? 'فريق الاستقبال' : 'Front desk team',
    memberCount: 12,
    unreadCount: 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    members: const [
      ChatMember(
        membershipId: 'preview-membership',
        fullName: 'Hazem',
        role: 'MANAGER',
      ),
      ChatMember(membershipId: 'other', fullName: 'Sara', role: 'EMPLOYEE'),
    ],
  );
  @override
  Future<ChatMessagePage> listMessages(
    String w,
    String id, {
    String? cursor,
    int limit = 30,
  }) async => ChatMessagePage(
    messages: [
      ChatMessage(
        id: '00000000-0000-4000-8000-000000000101',
        groupId: id,
        type: 'TEXT',
        text: ar
            ? 'صباح الخير، فيه توريد هيوصل بعد الساعة ٥.'
            : 'Morning team, a delivery is arriving after 5.',
        sender: const ChatSender(membershipId: 'other', fullName: 'Sara'),
        createdAt: DateTime.now().subtract(const Duration(minutes: 6)),
      ),
      ChatMessage(
        id: '00000000-0000-4000-8000-000000000102',
        groupId: id,
        type: 'TEXT',
        text: ar
            ? 'تمام، هسجلها في التسليم.'
            : 'Great, I will include it in the handover.',
        sender: const ChatSender(
          membershipId: 'preview-membership',
          fullName: 'Hazem',
        ),
        createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
      ),
      ChatMessage(
        id: '00000000-0000-4000-8000-000000000103',
        groupId: id,
        type: 'LOCATION',
        location: ChatLocation(
          latitude: 30.0444,
          longitude: 31.2357,
          label: ar ? 'المخزن · المدخل الرئيسي' : 'Warehouse · main entrance',
        ),
        sender: const ChatSender(membershipId: 'other', fullName: 'Sara'),
        createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ],
  );

  @override
  Future<int> unreadCount(String w) async => 5;
  @override
  Future<List<ChatGroup>> listGroups(String w) async => [
    for (int i = 0; i < 3; i++)
      ChatGroup(
        id: '00000000-0000-4000-8000-${(i + 1).toString().padLeft(12, '0')}',
        workspaceId: w,
        name: (ar
            ? ['فريق العمليات', 'تسليم الشيفت المسائي', 'أخبار الفريق']
            : ['Operations team', 'Evening handover', 'Team updates'])[i],
        memberCount: [12, 6, 18][i],
        unreadCount: [3, 2, 0][i],
        createdAt: DateTime.utc(2026, 10, 26, 8),
        updatedAt: DateTime.utc(2026, 10, 26, 10),
        lastMessage: ChatMessage(
          id: 'message-$i',
          groupId: 'group-$i',
          type: 'TEXT',
          text: (ar
              ? [
                  'صباح الخير يا فريق، جاهزين ليوم جديد؟',
                  'تم تسليم كل البنود، شكرًا على مجهودكم',
                  'جدول الأسبوع الجديد جاهز للمراجعة',
                ]
              : [
                  'Morning team, ready for a great day?',
                  'All items handed over. Thank you!',
                  'Next week’s schedule is ready to review',
                ])[i],
          sender: const ChatSender(
            membershipId: 'preview-member',
            fullName: 'Mariam',
          ),
          createdAt: DateTime.utc(2026, 10, 26, 10, i * 10),
        ),
      ),
  ];
}

void main() {
  const enabled = bool.fromEnvironment('UI_CAPTURE');
  const stage = String.fromEnvironment('UI_STAGE', defaultValue: 'after');
  testWidgets('capture real Shiftly screens for visual review', (tester) async {
    if (!enabled) return;
    final font = FontLoader('Cairo')
      ..addFont(rootBundle.load('assets/fonts/Cairo-Variable.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final out = Directory('docs/ui-review/$stage');
    out.createSync(recursive: true);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final language in ['ar', 'en']) {
      final key = GlobalKey();
      final employees = MockEmployeeRepository(delay: Duration.zero);
      tester.view.physicalSize = const Size(430, 932);
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: ShiftlyApp.preview(
            key: ValueKey('$stage-$language'),
            languageStore: MemoryLanguageStore(language),
            employeeRepository: employees,
            dashboardRepository: MockDashboardRepository(
              employeeRepository: employees,
              delay: Duration.zero,
            ),
            chatRepository: stage != 'before'
                ? ReviewChats(language == 'ar')
                : null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pumpAndSettle();
      Future<void> save(String name) async {
        expect(tester.takeException(), isNull);
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('${out.path}/$name.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }

      await save('dashboard-$language');
      final router = GoRouter.of(tester.element(find.byType(Navigator).last));
      for (final route in <String, String>{
        'employees': '/employees',
        'chat': '/chat',
        'profile': '/profile',
        'shifts': '/dashboard/shifts',
      }.entries) {
        router.go(route.value);
        await tester.pumpAndSettle();
        await save('${route.key}-$language');
      }
      router.go('/dashboard');
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(1440, 1000);
      await tester.pumpAndSettle();
      await save('desktop-$language');
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(430, 932);
      await tester.pumpAndSettle();
      await save('dark-$language');
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      if (stage != 'before') {
        MaterialApp reviewApp(Widget child) => MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: (stage == 'reference' || stage == 'layout')
              ? AppTheme.darkTheme()
              : AppTheme.lightTheme(),
          home: child,
        );
        final dashboard = DashboardCubit(ReviewDashboardRepository(employees))
          ..bindSession(
            const FeatureSessionScope(
              userId: 'review-user',
              workspaceId: dashboardWorkspaceId,
              membershipId: dashboardMembershipId,
              timezone: 'Africa/Cairo',
              role: WorkspaceRole.employee,
            ),
          );
        final breaks = ShiftBreakController()..bind('review-user');
        await tester.pumpWidget(
          RepositoryProvider.value(
            value: breaks,
            child: RepaintBoundary(
              key: key,
              child: BlocProvider.value(
                value: dashboard,
                child: BlocProvider<FlexibleAttendanceCubit>(
                  create: (_) => AttendanceTestCubit(
                    stage != 'layout'
                        ? const FlexibleAttendanceState(loading: false)
                        : FlexibleAttendanceState(
                            loading: false,
                            current: FlexibleAttendance(
                              id: 'review-active',
                              workspaceId: dashboardWorkspaceId,
                              employeeMembershipId: dashboardMembershipId,
                              source: AttendanceSource.template,
                              classification: AttendanceClassification.onTime,
                              clockInAt: DateTime.now().subtract(
                                const Duration(hours: 2, minutes: 48),
                              ),
                              scheduledStartAt: DateTime.now().subtract(
                                const Duration(hours: 2, minutes: 48),
                              ),
                              scheduledEndAt: DateTime.now().add(
                                const Duration(hours: 5, minutes: 12),
                              ),
                              minutesLate: 0,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            ),
                          ),
                  ),
                  child: reviewApp(
                    const Scaffold(
                      body: SafeArea(child: EmployeeDashboardScreen()),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await save('employee-$language');
        if (stage == 'layout') {
          await breaks.start(arabic: language == 'ar');
          await tester.pump();
          await save('break-$language');
        }
        if (stage == 'reference' || stage == 'layout') {
          Future<void> capturePage(String name, Widget page) async {
            await tester.pumpWidget(
              RepaintBoundary(key: key, child: reviewApp(page)),
            );
            await tester.pumpAndSettle();
            await save('$name-$language');
          }

          final taskRepo = MemoryTaskRepository();
          for (var i = 0; i < 4; i++) {
            await taskRepo.create(
              workspaceId: 'review',
              title: (language == 'ar'
                  ? [
                      'تجهيز مستلزمات الاستقبال',
                      'مراجعة تسليم الشيفت',
                      'قائمة فتح الفرع',
                      'تأكيد طلبات الفريق',
                    ]
                  : [
                      'Restock front desk supplies',
                      'Review evening handover',
                      'Opening checklist',
                      'Confirm team requests',
                    ])[i],
              description: language == 'ar'
                  ? 'جهّز الفريق لبداية الشيفت'
                  : 'Prepare the team for the next shift',
              dueAt: DateTime.now().add(Duration(hours: i + 1)),
            );
          }
          final open = await taskRepo.list(completed: false, page: 1);
          await taskRepo.update(open.items.last, completed: true);
          final taskCubit = TasksCubit(taskRepo, const NoTaskReminders());
          await taskCubit.bindSession(
            const FeatureSessionScope(
              userId: 'preview-user',
              workspaceId: 'review',
              membershipId: 'review',
              timezone: 'Africa/Cairo',
              role: WorkspaceRole.employee,
            ),
          );
          await capturePage(
            'tasks',
            BlocProvider.value(value: taskCubit, child: const TasksScreen()),
          );
          final workspaceAuth = OnboardingTestAuth();
          final workspaceSession = ReviewWorkspaceSession(
            workspaceAuth,
            CurrentUser(
              id: 'review-user',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              memberships: [
                for (var i = 0; i < 2; i++)
                  WorkspaceMembership(
                    id: 'member-$i',
                    role: i == 0
                        ? WorkspaceRole.employee
                        : WorkspaceRole.manager,
                    status: MembershipStatus.active,
                    workspace: Workspace(
                      id: 'review-$i',
                      name: (language == 'ar'
                          ? ['فندق النيل', 'مطعم الضيافة']
                          : ['Nile Hotel', 'Hospitality Restaurant'])[i],
                      code: 'REVIEW',
                      timezone: 'Africa/Cairo',
                    ),
                  ),
              ],
            ),
          );
          final workspaceCubit = WorkspacesCubit(
            MockWorkspaceRepository(),
            MockInvitationRepository(),
            onMembershipChanged: (a, b) async =>
                const MembershipRefreshResult.failed(),
          )..bindUser('review-user');
          await capturePage(
            'workspace',
            MultiBlocProvider(
              providers: [
                BlocProvider<SessionCoordinator>.value(value: workspaceSession),
                BlocProvider.value(value: workspaceCubit),
              ],
              child: const WorkspaceSelectionScreen(),
            ),
          );
          await tester.tap(find.byKey(const Key('workspace-review-0')));
          await tester.pumpAndSettle();
          await save('workspace-$language');
          await tester.runAsync(taskCubit.close);
          await tester.runAsync(() async {
            await workspaceCubit.close();
            await workspaceSession.close();
            await workspaceAuth.events.close();
          });
          final chatRepo = ReviewChats(language == 'ar');
          final chatCubit = ChatConversationCubit(
            chatRepo,
            const NoopChatRealtime(),
          );
          final chatText = TextEditingController();
          final chatMessages = (await chatRepo.listMessages(
            'review',
            'group',
          )).messages;
          await capturePage(
            'conversation',
            BlocProvider.value(
              value: chatCubit,
              child: Scaffold(
                appBar: AppBar(
                  title: Text(
                    language == 'ar' ? 'فريق الاستقبال' : 'Front desk team',
                  ),
                ),
                body: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          for (final message in chatMessages)
                            ChatMessageBubble(
                              message: message,
                              mine:
                                  message.sender.membershipId ==
                                  'preview-membership',
                              showSender: true,
                              repository: chatRepo,
                              workspaceId: 'review',
                              timezone: 'Africa/Cairo',
                              player: ReviewAudio(),
                            ),
                        ],
                      ),
                    ),
                    ChatMessageComposer(
                      disabled: false,
                      textController: chatText,
                      savingText: false,
                      mediaBusy: false,
                      recording: false,
                      hasPreparedMedia: false,
                      recordingLabel: '',
                      onTextChanged: () {},
                      onSend: () async {},
                      onRetryPrepared: () async {},
                      onPickImage: () async {},
                      onStartRecording: () async {},
                      onShareLocation: () async {},
                      onFinishRecording: ({required bool send}) async {},
                    ),
                  ],
                ),
              ),
            ),
          );
          await capturePage(
            'handover',
            HandoverDetail(
              repository: FakeOperations(),
              workspaceId: 'review',
              membershipId: 'receiver',
              timezone: 'Africa/Cairo',
              manager: false,
              isCurrent: () => true,
              id: 'review',
            ),
          );
          chatText.dispose();
          await tester.runAsync(chatCubit.close);
        }
        await tester.pumpWidget(const SizedBox());
        breaks.dispose();
        await tester.runAsync(dashboard.close);
        final auth = OnboardingTestAuth();
        final session = SessionCoordinator(
          auth,
          ReviewAuthRepository(),
          MemoryActiveWorkspaceStorage(),
        );
        await session.initialize();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: BlocProvider.value(
              value: session,
              child: reviewApp(const LoginScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)),
        );
        await tester.pumpAndSettle();
        await save('login-$language');
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(() async {
          await session.close();
          await auth.events.close();
        });
      }
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
