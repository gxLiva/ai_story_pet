import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/story.dart';
import '../repository/story_repository.dart';

final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return const StoryRepository();
});

final storyProvider = Provider.family<Story?, String>((ref, storyId) {
  return ref.watch(storyRepositoryProvider).getStory(storyId);
});

final storyReadingProvider =
    NotifierProvider<StoryReadingNotifier, StoryReadingState>(
      StoryReadingNotifier.new,
    );

class StoryReadingNotifier extends Notifier<StoryReadingState> {
  @override
  StoryReadingState build() => const StoryReadingState();

  void selectAnswer(String questionId, String optionId) {
    state = state.copyWith(
      selectedAnswers: {...state.selectedAnswers, questionId: optionId},
    );
  }

  bool canLeavePage(StoryPage page) {
    final check = page.feelingCheck;
    return check == null || state.completedFeelingCheckIds.contains(check.id);
  }

  bool canNavigateToPage(Story story, int pageIndex) {
    if (pageIndex < 0 || pageIndex >= story.pages.length) return false;
    return story.pages.take(pageIndex).every(canLeavePage);
  }

  void goToPage(Story story, int pageIndex) {
    if (!canNavigateToPage(story, pageIndex)) return;
    state = state.copyWith(currentPageIndex: pageIndex);
  }

  void previousPage() {
    if (state.currentPageIndex == 0) return;
    state = state.copyWith(currentPageIndex: state.currentPageIndex - 1);
  }

  void nextPage(Story story) {
    final currentPage = story.pages[state.currentPageIndex];
    final isLastPage = state.currentPageIndex >= story.pages.length - 1;
    if (isLastPage || !canLeavePage(currentPage)) return;
    state = state.copyWith(currentPageIndex: state.currentPageIndex + 1);
  }

  bool hasAnsweredEveryQuestion(FeelingCheck check) {
    return check.questions.every(
      (question) => state.selectedAnswers.containsKey(question.id),
    );
  }

  bool submitFeelingCheck(FeelingCheck check) {
    final isCorrect = check.questions.every(
      (question) =>
          state.selectedAnswers[question.id] == question.correctOptionId,
    );

    if (isCorrect) {
      state = state.copyWith(
        completedFeelingCheckIds: {...state.completedFeelingCheckIds, check.id},
      );
    }

    return isCorrect;
  }
}
