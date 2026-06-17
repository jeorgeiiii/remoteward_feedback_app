part of 'feedback_bloc.dart';

sealed class FeedbackEvent extends Equatable {
  const FeedbackEvent();
  @override
  List<Object?> get props => [];
}

/// Begin a fresh feedback draft, stamping it with the device owner.
class FeedbackStarted extends FeedbackEvent {
  final AppUser owner;
  const FeedbackStarted(this.owner);
  @override
  List<Object?> get props => [owner];
}

/// Step 1 — user details captured.
class UserDetailsSubmitted extends FeedbackEvent {
  final String name;
  final String email;
  final String contact;
  const UserDetailsSubmitted({
    required this.name,
    required this.email,
    required this.contact,
  });
  @override
  List<Object?> get props => [name, email, contact];
}

/// Step 2 — bug/issue captured.
class BugDetailsSubmitted extends FeedbackEvent {
  final String title;
  final String description;
  const BugDetailsSubmitted({required this.title, required this.description});
  @override
  List<Object?> get props => [title, description];
}

class MediaAdded extends FeedbackEvent {
  final String path;
  const MediaAdded(this.path);
  @override
  List<Object?> get props => [path];
}

class MediaRemoved extends FeedbackEvent {
  final String path;
  const MediaRemoved(this.path);
  @override
  List<Object?> get props => [path];
}

/// Step 3 — persist the whole draft.
class FeedbackSubmitted extends FeedbackEvent {
  const FeedbackSubmitted();
}

/// Reset back to a clean draft (after the Thank You screen).
class FeedbackReset extends FeedbackEvent {
  const FeedbackReset();
}
