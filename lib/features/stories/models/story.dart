class Story {
  const Story({
    required this.id,
    required this.title,
    required this.category,
    required this.coverImagePath,
    required this.pages,
  });

  final String id;
  final String title;
  final String category;
  final String coverImagePath;
  final List<StoryPage> pages;
}

class StoryPage {
  const StoryPage({
    required this.id,
    required this.imagePath,
    required this.text,
    this.feelingCheck,
  });

  final String id;
  final String imagePath;
  final String text;
  final FeelingCheck? feelingCheck;
}

class FeelingCheck {
  const FeelingCheck({
    required this.id,
    required this.title,
    required this.focusPhrase,
    required this.quote,
    required this.questions,
  });

  final String id;
  final String title;
  final String focusPhrase;
  final String quote;
  final List<FeelingQuestion> questions;
}

class FeelingQuestion {
  const FeelingQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctOptionId,
  });

  final String id;
  final String prompt;
  final List<FeelingOption> options;
  final String correctOptionId;
}

class FeelingOption {
  const FeelingOption({
    required this.id,
    required this.label,
    required this.emoji,
  });

  final String id;
  final String label;
  final String emoji;
}

class StoryReadingState {
  const StoryReadingState({
    this.currentPageIndex = 0,
    this.selectedAnswers = const {},
    this.completedFeelingCheckIds = const {},
  });

  final int currentPageIndex;
  final Map<String, String> selectedAnswers;
  final Set<String> completedFeelingCheckIds;

  StoryReadingState copyWith({
    int? currentPageIndex,
    Map<String, String>? selectedAnswers,
    Set<String>? completedFeelingCheckIds,
  }) {
    return StoryReadingState(
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      completedFeelingCheckIds:
          completedFeelingCheckIds ?? this.completedFeelingCheckIds,
    );
  }
}
