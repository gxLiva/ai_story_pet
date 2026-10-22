import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../../profile/providers/user_profile_providers.dart';
import '../models/story.dart';
import '../repository/story_creation_service.dart';
import '../repository/story_repository.dart';

final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return StoryRepository();
});

final userStoryProvider = StreamProvider.family<Story?, String>((ref, storyId) {
  final userId = ref.watch(currentUserProvider)?.uid;
  if (userId == null) return Stream.value(null);

  return StoryRepository(
    userStoryDataSource: FirestoreUserStoryDataSource(
      ref.watch(firestoreProvider),
    ),
  ).watchUserStory(userId: userId, storyId: storyId);
});

final sharedStoriesProvider = StreamProvider<List<Story>>((ref) {
  if (ref.watch(currentUserProvider) == null) return Stream.value(const []);

  return FirestoreStoryCatalogDataSource(ref.watch(firestoreProvider))
      .watchStories()
      .map((documents) => documents.map(Story.fromMap).toList(growable: false));
});

final sharedStoryProvider = StreamProvider.family<Story?, String>((
  ref,
  storyId,
) {
  if (ref.watch(currentUserProvider) == null) return Stream.value(null);

  return FirestoreStoryCatalogDataSource(ref.watch(firestoreProvider))
      .watchStory(storyId)
      .map((document) => document == null ? null : Story.fromMap(document));
});

final personalizedStoriesProvider = StreamProvider<List<Story>>((ref) {
  final userId = ref.watch(currentUserProvider)?.uid;
  if (userId == null) return Stream.value(const []);

  return FirestoreUserStoryCollectionDataSource(ref.watch(firestoreProvider))
      .watchStories(userId)
      .map((documents) => documents.map(Story.fromMap).toList(growable: false));
});

final storyActivityRepositoryProvider = Provider<StoryActivityRepository>((
  ref,
) {
  return StoryActivityRepository(
    FirestoreStoryActivityDataSource(ref.watch(firestoreProvider)),
  );
});

final storyActivityProvider = StreamProvider<StoryActivity>((ref) {
  final userId = ref.watch(currentUserProvider)?.uid;
  if (userId == null) return Stream.value(const StoryActivity([]));
  return ref.watch(storyActivityRepositoryProvider).watchActivity(userId);
});

final storyOpenedProvider = FutureProvider.family<void, String>((ref, storyId) {
  final userId = ref.watch(currentUserProvider)?.uid;
  if (userId == null) return Future.value();
  return ref
      .watch(storyActivityRepositoryProvider)
      .recordOpened(userId: userId, storyId: storyId);
});

final latestPersonalizedStoryIdProvider = StreamProvider<String?>((ref) {
  final userId = ref.watch(currentUserProvider)?.uid;
  if (userId == null) return Stream.value(null);

  return ref
      .watch(firestoreProvider)
      .collection('userProfiles')
      .doc(userId)
      .snapshots()
      .map((snapshot) {
        final value = snapshot.data()?['latestStoryId'];
        return value is String && value.trim().isNotEmpty ? value.trim() : null;
      });
});

final latestPersonalizedStoryProvider = Provider<AsyncValue<Story?>>((ref) {
  if (ref.watch(currentUserProvider) == null) {
    return ref.watch(storyProvider(personalizedStoryId));
  }

  final latestId = ref.watch(latestPersonalizedStoryIdProvider);
  if (latestId.isLoading) return const AsyncLoading();
  if (latestId.hasError) {
    return AsyncError(latestId.error!, latestId.stackTrace!);
  }
  final storyId = latestId.asData?.value;
  return ref.watch(storyProvider(storyId ?? personalizedStoryId));
});

final storyProvider = Provider.family<AsyncValue<Story?>, String>((
  ref,
  storyId,
) {
  final localStory = ref.watch(storyRepositoryProvider).getLocalStory(storyId);
  if (localStory != null) return AsyncData(localStory);
  if (ref.watch(currentUserProvider) == null) {
    return const AsyncData(null);
  }
  final userStory = ref.watch(userStoryProvider(storyId));
  if (userStory.hasValue && userStory.value != null) return userStory;

  final sharedStory = ref.watch(sharedStoryProvider(storyId));
  if (sharedStory.hasValue) return sharedStory;
  if (userStory.hasError) return userStory;
  return sharedStory;
});

final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instance;
});

final storyCreationServiceProvider = Provider<StoryCreationService>((ref) {
  return FirebaseStoryCreationService(ref.watch(firebaseFunctionsProvider));
});

final sharedThemeStoryServiceProvider = Provider<SharedThemeStoryService>((
  ref,
) {
  return FirebaseSharedThemeStoryService(ref.watch(firebaseFunctionsProvider));
});

final sharedThemeStoriesSeedProvider = FutureProvider<void>((ref) async {
  if (ref.watch(currentUserProvider) == null) return;
  await ref.watch(sharedThemeStoryServiceProvider).ensureStoriesExist();
});

final personalizedStoryCreationProvider =
    NotifierProvider<PersonalizedStoryCreationNotifier, StoryCreationState>(
      PersonalizedStoryCreationNotifier.new,
    );

class StoryCreationState {
  const StoryCreationState({this.isLoading = false, this.error});

  final bool isLoading;
  final Object? error;

  bool get hasError => error != null;
}

class PersonalizedStoryCreationNotifier extends Notifier<StoryCreationState> {
  @override
  StoryCreationState build() => const StoryCreationState();

  Future<void> create() async {
    if (state.isLoading) {
      debugPrint('[StoryGeneration] Ignored duplicate create request');
      return;
    }
    debugPrint('[StoryGeneration] Creation state: loading');
    state = const StoryCreationState(isLoading: true);
    try {
      await ref.read(storyCreationServiceProvider).createPersonalizedStory();
      debugPrint('[StoryGeneration] Creation state: success');
      state = const StoryCreationState();
    } catch (error, stackTrace) {
      debugPrint('[StoryGeneration] Creation state: error=$error');
      debugPrintStack(
        label: '[StoryGeneration] Provider stack trace',
        stackTrace: stackTrace,
      );
      state = StoryCreationState(error: error);
    }
  }
}

@immutable
class StoryReadingKey {
  const StoryReadingKey({required this.userId, required this.storyId});

  final String userId;
  final String storyId;

  @override
  bool operator ==(Object other) =>
      other is StoryReadingKey &&
      other.userId == userId &&
      other.storyId == storyId;

  @override
  int get hashCode => Object.hash(userId, storyId);
}

final storyReadingKeyProvider = Provider.family<StoryReadingKey, String>((
  ref,
  storyId,
) {
  return StoryReadingKey(
    userId: ref.watch(currentUserProvider)?.uid ?? 'signed-out',
    storyId: storyId,
  );
});

final storyReadingProvider =
    NotifierProvider.family<
      StoryReadingNotifier,
      StoryReadingState,
      StoryReadingKey
    >(StoryReadingNotifier.new);

class StoryReadingNotifier extends Notifier<StoryReadingState> {
  StoryReadingNotifier(this.key);

  final StoryReadingKey key;
  bool _hydrated = false;

  @override
  StoryReadingState build() => const StoryReadingState();

  void hydrate(StoryReadingState savedState) {
    if (_hydrated) return;
    _hydrated = true;
    state = savedState;
  }

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
