import 'package:bloc_test/bloc_test.dart';
import 'package:feedback_app/data/models/app_user.dart';
import 'package:feedback_app/data/repositories/feedback_repository.dart';
import 'package:feedback_app/presentation/bloc/feedback/feedback_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFeedbackRepository extends Mock implements FeedbackRepository {}

void main() {
  late MockFeedbackRepository repository;

  setUp(() => repository = MockFeedbackRepository());

  const owner = AppUser(uid: 'u1', name: 'Owner', email: 'owner@test.com');

  group('FeedbackBloc', () {
    blocTest<FeedbackBloc, FeedbackState>(
      'accumulates user + bug details into the draft',
      build: () => FeedbackBloc(repository: repository),
      act: (bloc) => bloc
        ..add(const FeedbackStarted(owner))
        ..add(const UserDetailsSubmitted(
          name: 'Jane',
          email: 'jane@test.com',
          contact: '123',
        ))
        ..add(const BugDetailsSubmitted(
          title: 'Crash',
          description: 'Crashes on launch',
        )),
      verify: (bloc) {
        final draft = bloc.state.draft;
        expect(draft.ownerEmail, 'owner@test.com');
        expect(draft.userName, 'Jane');
        expect(draft.issueTitle, 'Crash');
        expect(draft.description, 'Crashes on launch');
      },
    );

    blocTest<FeedbackBloc, FeedbackState>(
      'emits submitting then success on FeedbackSubmitted',
      setUp: () =>
          when(() => repository.submit(any())).thenAnswer((_) async {}),
      build: () => FeedbackBloc(repository: repository),
      act: (bloc) => bloc
        ..add(const FeedbackStarted(owner))
        ..add(const FeedbackSubmitted()),
      expect: () => [
        isA<FeedbackState>(), // started → fresh draft
        isA<FeedbackState>()
            .having((s) => s.status, 'status', SubmitStatus.submitting),
        isA<FeedbackState>()
            .having((s) => s.status, 'status', SubmitStatus.success),
      ],
      verify: (_) => verify(() => repository.submit(any())).called(1),
    );
  });
}
