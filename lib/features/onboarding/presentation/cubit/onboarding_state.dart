import 'package:equatable/equatable.dart';

class OnboardingState extends Equatable {
  const OnboardingState({
    this.loading = true,
    this.completed = false,
    this.saving = false,
    this.page = 0,
    this.error,
  });
  final bool loading, completed, saving;
  final int page;
  final String? error;
  @override
  List<Object?> get props => [loading, completed, saving, page, error];
}
