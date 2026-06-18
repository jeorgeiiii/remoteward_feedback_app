part of 'feedback_bloc.dart';

enum SubmitStatus { idle, submitting, success, failure }

class FeedbackState extends Equatable {
  /// The draft currently being assembled across the three collection screens.
  final FeedbackEntry draft;
  final SubmitStatus status;
  final String? error;

  FeedbackState({
    FeedbackEntry? draft,
    this.status = SubmitStatus.idle,
    this.error,
  }) : draft = draft ?? FeedbackEntry.empty();

  FeedbackState copyWith({
    FeedbackEntry? draft,
    SubmitStatus? status,
    String? error,
  }) {
    return FeedbackState(
      draft: draft ?? this.draft,
      status: status ?? this.status,
      error: error,
    );
  }

  @override
  List<Object?> get props => [draft, status, error];
}
