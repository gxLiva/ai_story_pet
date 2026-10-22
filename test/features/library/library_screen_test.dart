import 'package:ai_story_pet/features/library/presentation/screens/library_screen.dart';
import 'package:ai_story_pet/features/stories/models/story.dart';
import 'package:ai_story_pet/features/stories/presentation/screens/feeling_check_screen.dart';
import 'package:ai_story_pet/features/stories/presentation/screens/story_screen.dart';
import 'package:ai_story_pet/features/stories/providers/story_providers.dart';
import 'package:ai_story_pet/features/stories/repository/story_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../stories/test_story_fixture.dart';

void main() {
  Story story({
    required String id,
    required String title,
    required String description,
    String category = 'Friendship',
  }) {
    return Story.fromMap({
      ...testStoryDocument,
      'id': id,
      'title': title,
      'description': description,
      'category': category,
    });
  }

  Future<void> pumpLibrary(
    WidgetTester tester, {
    List<Story> shared = const [],
    List<Story> personalized = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedThemeStoriesSeedProvider.overrideWith((ref) async {}),
          sharedStoriesProvider.overrideWith((ref) => Stream.value(shared)),
          personalizedStoriesProvider.overrideWith(
            (ref) => Stream.value(personalized),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: LibraryScreen())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows four themes and a personalized carousel', (tester) async {
    final personalized = [
      story(id: 'one', title: 'Story One', description: 'First'),
      story(id: 'two', title: 'Story Two', description: 'Second'),
      story(id: 'three', title: 'Story Three', description: 'Third'),
      story(id: 'four', title: 'Story Four', description: 'Fourth'),
    ];

    await pumpLibrary(tester, personalized: personalized);

    expect(find.byKey(const ValueKey('library-title-search')), findsOneWidget);
    expect(find.text('Friendship'), findsOneWidget);
    expect(find.text('Big Feelings'), findsOneWidget);
    expect(find.text('Transition'), findsOneWidget);
    expect(find.text('Courage'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('personalized-story-carousel')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const ValueKey('personalized-story-carousel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('view-all-personalized-stories')),
      findsOneWidget,
    );
    expect(find.text('Story Four'), findsNothing);
  });

  testWidgets('search matches story titles but not descriptions', (
    tester,
  ) async {
    final shared = [
      story(
        id: 'sun-story',
        title: 'The Bright Sun',
        description: 'A quiet moon appears.',
      ),
      story(
        id: 'moon-story',
        title: 'Moonlight Friends',
        description: 'Two friends explore.',
      ),
    ];
    await pumpLibrary(tester, shared: shared);

    await tester.enterText(
      find.byKey(const ValueKey('library-title-search')),
      'moon',
    );
    await tester.pump();

    expect(find.text('Moonlight Friends'), findsOneWidget);
    expect(find.text('The Bright Sun'), findsNothing);
  });

  testWidgets('uses clear empty-state wording', (tester) async {
    await pumpLibrary(tester);

    await tester.enterText(
      find.byKey(const ValueKey('library-title-search')),
      'missing',
    );
    await tester.pump();

    expect(find.text('Cannot find story.'), findsOneWidget);
  });

  testWidgets('opens a theme story and completes its full reader flow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final courageStory = story(
      id: 'theme-courage',
      title: 'The Brave Little Step',
      description: 'A gentle story about trying something new.',
      category: 'Courage',
    );
    final router = GoRouter(
      initialLocation: '/library',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(
            body: SizedBox(key: ValueKey('completed-story-home')),
          ),
        ),
        GoRoute(
          path: '/library',
          builder: (_, _) => const Scaffold(body: LibraryScreen()),
          routes: [
            GoRoute(
              path: 'theme/:theme',
              builder: (_, state) => Scaffold(
                body: LibraryStoryCollectionScreen.theme(
                  theme: Uri.decodeComponent(state.pathParameters['theme']!),
                ),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/story/:storyId',
          builder: (_, state) =>
              StoryScreen(storyId: state.pathParameters['storyId']!),
          routes: [
            GoRoute(
              path: 'feeling-check/:checkId',
              builder: (_, state) => FeelingCheckScreen(
                storyId: state.pathParameters['storyId']!,
                checkId: state.pathParameters['checkId']!,
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedThemeStoriesSeedProvider.overrideWith((ref) async {}),
          sharedStoriesProvider.overrideWith(
            (ref) => Stream.value([courageStory]),
          ),
          personalizedStoriesProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
          storyRepositoryProvider.overrideWithValue(
            StoryRepository(additionalStories: [courageStory]),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('library-theme-courage')));
    await tester.pumpAndSettle();
    expect(find.text('The Brave Little Step'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('library-story-theme-courage')));
    await tester.pumpAndSettle();
    expect(find.text('1 / 5'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('next-page-button')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('feeling-check-prompt')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('answer-sam-feeling-curious')));
    final evidence = find.byKey(
      const ValueKey('answer-sam-evidence-looked-closer'),
    );
    await tester.ensureVisible(evidence);
    await tester.tap(evidence);
    await tester.pump();
    final submit = find.byKey(const ValueKey('submit-feeling-check'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('feeling-check-success-overlay')),
    );
    await tester.pumpAndSettle();

    for (var index = 0; index < 3; index++) {
      await tester.tap(find.byKey(const ValueKey('next-page-button')));
      await tester.pump();
    }
    expect(find.text('5 / 5'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('next-page-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('story-complete-overlay')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('story-complete-overlay')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('completed-story-home')), findsOneWidget);
  });
}
