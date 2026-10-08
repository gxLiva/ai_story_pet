import 'dart:async';

import 'package:ai_story_pet/features/stories/models/story.dart';
import 'package:ai_story_pet/features/stories/repository/story_creation_service.dart';
import 'package:ai_story_pet/features/stories/providers/story_providers.dart';
import 'package:ai_story_pet/features/stories/repository/story_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_story_fixture.dart';

void main() {
  test('repository resolves an arbitrary injected story by id', () {
    final story = buildTestStory();
    final repository = StoryRepository(additionalStories: [story]);

    expect(repository.getLocalStory(testStoryId), same(story));
    expect(repository.getLocalStory('missing-story'), isNull);
  });

  test('repository parses a user story data source document', () async {
    final repository = StoryRepository(
      userStoryDataSource: _FakeUserStoryDataSource(testStoryDocument),
    );

    await expectLater(
      repository.watchUserStory(userId: 'reader-1', storyId: testStoryId),
      emits(
        isA<Story>().having(
          (story) => story.title,
          'title',
          'Sam Looks at the Stars',
        ),
      ),
    );
  });

  test('reading progress and answers are independent for every story', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final mia = container.read(storyProvider(miaStoryId)).asData!.value!;
    final fixture = buildTestStory();
    final miaReader = container.read(storyReadingProvider(miaStoryId).notifier);
    final fixtureReader = container.read(
      storyReadingProvider(testStoryId).notifier,
    );

    miaReader.nextPage(mia);
    fixtureReader.selectAnswer('sam-feeling', 'curious');

    expect(
      container.read(storyReadingProvider(miaStoryId)).currentPageIndex,
      1,
    );
    expect(
      container.read(storyReadingProvider(miaStoryId)).selectedAnswers,
      isEmpty,
    );
    expect(
      container.read(storyReadingProvider(testStoryId)).currentPageIndex,
      0,
    );
    expect(
      container
          .read(storyReadingProvider(testStoryId))
          .selectedAnswers['sam-feeling'],
      'curious',
    );
    expect(fixture.pages, hasLength(5));
  });

  test('story creation notifier reports success', () async {
    final service = _FakeStoryCreationService();
    final container = ProviderContainer(
      overrides: [storyCreationServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    await container.read(personalizedStoryCreationProvider.notifier).create();

    expect(service.callCount, 1);
    expect(container.read(personalizedStoryCreationProvider).isLoading, false);
    expect(container.read(personalizedStoryCreationProvider).hasError, false);
  });

  test('story creation notifier exposes failures for retry UI', () async {
    final container = ProviderContainer(
      overrides: [
        storyCreationServiceProvider.overrideWithValue(
          _FakeStoryCreationService(error: StateError('offline')),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(personalizedStoryCreationProvider.notifier).create();

    expect(container.read(personalizedStoryCreationProvider).hasError, true);
  });
}

class _FakeUserStoryDataSource implements UserStoryDataSource {
  _FakeUserStoryDataSource(this.document);

  final Map<String, dynamic>? document;

  @override
  Stream<Map<String, dynamic>?> watchStory({
    required String userId,
    required String storyId,
  }) {
    return Stream.value(document);
  }
}

class _FakeStoryCreationService implements StoryCreationService {
  _FakeStoryCreationService({this.error});

  final Object? error;
  int callCount = 0;

  @override
  Future<String> createPersonalizedStory() async {
    callCount++;
    if (error case final error?) throw error;
    return personalizedStoryId;
  }
}
