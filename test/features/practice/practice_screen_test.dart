import 'package:ai_story_pet/features/auth/providers/auth_providers.dart';
import 'package:ai_story_pet/features/practice/presentation/screens/practice_screen.dart';
import 'package:ai_story_pet/features/stories/models/story.dart';
import 'package:ai_story_pet/features/stories/providers/story_providers.dart';
import 'package:ai_story_pet/features/stories/repository/story_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<void> pumpPracticeList(
    WidgetTester tester, {
    required StoryActivity activity,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(null),
          sharedThemeStoriesSeedProvider.overrideWith((ref) async {}),
          sharedStoriesProvider.overrideWith((ref) => Stream.value(const [])),
          personalizedStoriesProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
          storyActivityProvider.overrideWith((ref) => Stream.value(activity)),
        ],
        child: const MaterialApp(home: Scaffold(body: PracticeScreen())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('locks unread stories and offers to open the reader', (
    tester,
  ) async {
    await pumpPracticeList(tester, activity: const StoryActivity([]));

    expect(find.text('Mia Joins the Game'), findsOneWidget);
    expect(find.text('🔒 Read first'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('practice-story-mia-joins-the-game')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Read this story first'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('open-locked-story-button')),
      findsOneWidget,
    );
  });

  testWidgets('opens an unlocked practice and shows Lumi feedback', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/practice/mia-joins-the-game',
      routes: [
        GoRoute(
          path: '/practice',
          builder: (_, _) => const Scaffold(body: PracticeScreen()),
          routes: [
            GoRoute(
              path: ':storyId',
              builder: (_, state) => PracticeScenarioScreen(
                storyId: state.pathParameters['storyId']!,
              ),
              routes: [
                GoRoute(
                  path: 'feedback/:actionId',
                  builder: (_, state) => PracticeFeedbackScreen(
                    storyId: state.pathParameters['storyId']!,
                    actionId: state.pathParameters['actionId']!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentUserProvider.overrideWithValue(null)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('There is no wrong answer! 💛'), findsOneWidget);
    final action = find.byKey(const ValueKey('practice-action-ask-to-play'));
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pump();

    final tryButton = find.byKey(const ValueKey('try-practice-action-button'));
    await tester.ensureVisible(tryButton);
    await tester.tap(tryButton);
    await tester.pumpAndSettle();

    expect(find.text('That was a thoughtful choice! ✨'), findsOneWidget);
    expect(
      find.text('Speaking up is one brave way to join in.'),
      findsOneWidget,
    );
    expect(find.text('What happened next'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('try-another-choice-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('finish-practice-button')),
      findsOneWidget,
    );
  });
}
