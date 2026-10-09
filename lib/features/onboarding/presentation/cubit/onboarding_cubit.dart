import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/features/onboarding/domain/repositories/onboarding_storage.dart';
import 'package:shiftly/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:shiftly/features/onboarding/presentation/models/onboarding_page_content.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this.storage) : super(const OnboardingState());
  final OnboardingStorage storage;
  bool _busy = false;
  bool _validatedSessionSeen = false;
  bool get bypassed => _validatedSessionSeen;
  void bypassForValidatedSession() {
    _validatedSessionSeen = true;
  }

  int _revision = 0;
  Future<void> restore() async {
    if (_busy || state.completed) {
      return;
    }
    _busy = true;
    final revision = ++_revision;
    emit(OnboardingState(page: state.page));
    try {
      final completed = await storage.readCompleted();
      if (!isClosed && revision == _revision) {
        emit(
          OnboardingState(
            loading: false,
            completed: completed,
            page: state.page,
          ),
        );
      }
    } catch (_) {
      if (!isClosed && revision == _revision) {
        emit(
          OnboardingState(
            loading: false,
            page: state.page,
            error: 'Could not read your welcome preference. Retry to continue.',
          ),
        );
      }
    } finally {
      if (revision == _revision) {
        _busy = false;
      }
    }
  }

  void showPage(int page) {
    if (_busy ||
        state.loading ||
        state.completed ||
        page < 0 ||
        page >= OnboardingPageContent.pages.length) {
      return;
    }
    emit(
      OnboardingState(
        loading: false,
        completed: state.completed,
        page: page,
        error: state.error,
      ),
    );
  }

  Future<void> complete() async {
    if (_busy || state.completed || state.loading) {
      return;
    }
    _busy = true;
    final revision = ++_revision;
    emit(OnboardingState(loading: false, saving: true, page: state.page));
    try {
      await storage.complete();
      if (!isClosed && revision == _revision) {
        emit(
          OnboardingState(loading: false, completed: true, page: state.page),
        );
      }
    } catch (_) {
      if (!isClosed && revision == _revision) {
        emit(
          OnboardingState(
            loading: false,
            page: state.page,
            error: 'Could not save your welcome preference. Try again to continue.',
          ),
        );
      }
    } finally {
      if (revision == _revision) {
        _busy = false;
      }
    }
  }
}
