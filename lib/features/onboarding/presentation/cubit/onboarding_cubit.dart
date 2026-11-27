import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/features/onboarding/domain/repositories/onboarding_storage.dart';
import 'package:shiftly/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:shiftly/features/onboarding/presentation/models/onboarding_page_content.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this.storage) : super(const OnboardingState());
  final OnboardingStorage storage;
  bool _busy = false, _validatedSessionSeen = false;
  int _revision = 0;

  bool get bypassed => _validatedSessionSeen;
  void bypassForValidatedSession() => _validatedSessionSeen = true;

  Future<void> restore() => _run(
    allowed: !_busy && !state.completed,
    initial: OnboardingState(page: state.page),
    action: () async => OnboardingState(
      loading: false,
      completed: await storage.readCompleted(),
      page: state.page,
    ),
    errorMsg: 'Could not read your welcome preference. Retry to continue.',
  );

  void showPage(int page) {
    final valid = page >= 0 && page < OnboardingPageContent.pages.length;
    if (_busy || state.loading || state.completed || !valid) return;
    emit(
      OnboardingState(
        loading: false,
        completed: state.completed,
        page: page,
        error: state.error,
      ),
    );
  }

  Future<void> complete() => _run(
    allowed: !_busy && !state.completed && !state.loading,
    initial: OnboardingState(loading: false, saving: true, page: state.page),
    action: () async {
      await storage.complete();
      return OnboardingState(loading: false, completed: true, page: state.page);
    },
    errorMsg: 'Could not save your welcome preference. Try again to continue.',
  );

  Future<void> _run({
    required bool allowed,
    required OnboardingState initial,
    required Future<OnboardingState> Function() action,
    required String errorMsg,
  }) async {
    if (!allowed) return;
    _busy = true;
    final rev = ++_revision;
    emit(initial);
    try {
      final next = await action();
      if (!isClosed && rev == _revision) emit(next);
    } catch (_) {
      if (!isClosed && rev == _revision) {
        emit(OnboardingState(loading: false, page: state.page, error: errorMsg));
      }
    } finally {
      if (rev == _revision) _busy = false;
    }
  }
}
