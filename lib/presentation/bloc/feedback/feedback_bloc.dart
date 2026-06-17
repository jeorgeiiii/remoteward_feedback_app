import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/models/app_user.dart';
import '../../../data/models/feedback_entry.dart';
import '../../../data/repositories/feedback_repository.dart';

part 'feedback_event.dart';
part 'feedback_state.dart';

/// Owns the lifecycle of a single feedback submission. The draft is held in
/// state and enriched step-by-step as the user moves through the three
/// collection screens, then persisted on [FeedbackSubmitted].
class FeedbackBloc extends Bloc<FeedbackEvent, FeedbackState> {
  final FeedbackRepository _repository;

  FeedbackBloc({required FeedbackRepository repository})
      : _repository = repository,
        super(FeedbackState()) {
    on<FeedbackStarted>(_onStarted);
    on<UserDetailsSubmitted>(_onUserDetails);
    on<BugDetailsSubmitted>(_onBugDetails);
    on<MediaAdded>(_onMediaAdded);
    on<MediaRemoved>(_onMediaRemoved);
    on<FeedbackSubmitted>(_onSubmitted);
    on<FeedbackReset>(_onReset);
  }

  void _onStarted(FeedbackStarted event, Emitter<FeedbackState> emit) {
    emit(FeedbackState(
      draft: FeedbackEntry.empty().copyWith(
        ownerName: event.owner.name,
        ownerEmail: event.owner.email,
      ),
    ));
  }

  void _onUserDetails(
    UserDetailsSubmitted event,
    Emitter<FeedbackState> emit,
  ) {
    emit(state.copyWith(
      draft: state.draft.copyWith(
        userName: event.name,
        userEmail: event.email,
        userContact: event.contact,
      ),
    ));
  }

  void _onBugDetails(BugDetailsSubmitted event, Emitter<FeedbackState> emit) {
    emit(state.copyWith(
      draft: state.draft.copyWith(
        issueTitle: event.title,
        description: event.description,
      ),
    ));
  }

  void _onMediaAdded(MediaAdded event, Emitter<FeedbackState> emit) {
    if (state.draft.mediaPaths.contains(event.path)) return;
    emit(state.copyWith(
      draft: state.draft.copyWith(
        mediaPaths: [...state.draft.mediaPaths, event.path],
      ),
    ));
  }

  void _onMediaRemoved(MediaRemoved event, Emitter<FeedbackState> emit) {
    emit(state.copyWith(
      draft: state.draft.copyWith(
        mediaPaths:
            state.draft.mediaPaths.where((p) => p != event.path).toList(),
      ),
    ));
  }

  Future<void> _onSubmitted(
    FeedbackSubmitted event,
    Emitter<FeedbackState> emit,
  ) async {
    emit(state.copyWith(status: SubmitStatus.submitting, error: null));
    try {
      await _repository.submit(state.draft);
      emit(state.copyWith(status: SubmitStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: SubmitStatus.failure,
        error: 'Could not save feedback. Please try again.',
      ));
    }
  }

  void _onReset(FeedbackReset event, Emitter<FeedbackState> emit) {
    // Keep the owner, drop everything else.
    emit(FeedbackState(
      draft: FeedbackEntry.empty().copyWith(
        ownerName: state.draft.ownerName,
        ownerEmail: state.draft.ownerEmail,
      ),
    ));
  }
}
