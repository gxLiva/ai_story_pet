import 'package:ai_story_pet/features/auth/providers/auth_providers.dart';
import 'package:ai_story_pet/features/home/presentation/screens/home_screen.dart';
import 'package:ai_story_pet/features/navigation/presentation/widgets/app_bottom_navigation_bar.dart';
import 'package:ai_story_pet/features/stories/presentation/screens/feeling_check_screen.dart';
import 'package:ai_story_pet/features/stories/presentation/screens/story_screen.dart';
import 'package:ai_story_pet/features/stories/repository/story_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late GoRouter router;

  Future<void> pumpReadingApp(WidgetTester tester) async {
    router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(
          path: '/story/:storyId',
          builder: (_, state) =>
              StoryScreen(storyId: pathParameter(state, 'storyId')),
          routes: [
            GoRoute(
              path: 'feeling-check/:checkId',
              builder: (_, state) => FeelingCheckScreen(
                storyId: pathParameter(state, 'storyId'),
                checkId: pathParameter(state, 'checkId'),
              ),
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
  }

  testWidgets('Mia card opens a focused reader and navigates pages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpReadingApp(tester);

    final storyCard = find.byKey(const ValueKey('mia-story-card'));
    await tester.ensureVisible(storyCard);
    await tester.tap(storyCard);
    await tester.pumpAndSettle();

    expect(find.text('Mia Joins the Game'), findsOneWidget);
    expect(find.text('1 / 5'), findsOneWidget);
    expect(find.byType(AppBottomNavigationBar), findsNothing);

    final previousButton = tester.widget<IconButton>(
      find.descendant(
        of: find.byKey(const ValueKey('previous-page-button')),
        matching: find.byType(IconButton),
      ),
    );
    expect(previousButton.onPressed, isNull);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

    final nextButton = tester.widget<IconButton>(
      find.descendant(
        of: find.byKey(const ValueKey('next-page-button')),
        matching: find.byType(IconButton),
      ),
    );
    final previousShape = previousButton.style!.shape!.resolve({})!;
    final nextShape = nextButton.style!.shape!.resolve({})!;
    expect(
      previousShape,
      isA<RoundedRectangleBorder>().having(
        (shape) => shape.borderRadius,
        'rounded left edge',
        const BorderRadius.only(
          topLeft: Radius.circular(27),
          bottomLeft: Radius.circular(27),
        ),
      ),
    );
    expect(
      nextShape,
      isA<RoundedRectangleBorder>().having(
        (shape) => shape.borderRadius,
        'rounded right edge',
        const BorderRadius.only(
          topRight: Radius.circular(27),
          bottomRight: Radius.circular(27),
        ),
      ),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('previous-page-button'))),
      tester.getSize(find.byKey(const ValueKey('next-page-button'))),
    );

    await tester.tap(find.byKey(const ValueKey('next-page-button')));
    await tester.pump();

    expect(find.text('2 / 5'), findsOneWidget);
  });

  testWidgets('Feeling Check blocks progress until both answers are correct', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpReadingApp(tester);
    router.go('/story/$miaStoryId');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('next-page-button')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('next-page-button')));
    await tester.pump();

    expect(find.text('3 / 5'), findsOneWidget);
    expect(find.text('wobbly'), findsOneWidget);
    final storyText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('story-page-text')),
        matching: find.byType(Text),
      ),
    );
    final storySpans = (storyText.textSpan! as TextSpan).children!;
    final highlightedPhrase = storySpans[1] as TextSpan;
    expect(highlightedPhrase.text, 'wobbly');
    expect(highlightedPhrase.style!.decoration, TextDecoration.underline);
    expect(highlightedPhrase.style!.decorationColor, const Color(0xFFFFD59A));
    final lockedNext = tester.widget<IconButton>(
      find.descendant(
        of: find.byKey(const ValueKey('next-page-button')),
        matching: find.byType(IconButton),
      ),
    );
    expect(lockedNext.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('feeling-check-prompt')));
    await tester.pumpAndSettle();

    expect(find.text('Answer both questions'), findsOneWidget);
    var submitButton = tester.widget<ElevatedButton>(
      find.byKey(const ValueKey('submit-feeling-check')),
    );
    expect(submitButton.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('answer-mia-feeling-happy')));
    final wrongEvidence = find.byKey(
      const ValueKey('answer-mia-evidence-did-not-know'),
    );
    await tester.ensureVisible(wrongEvidence);
    await tester.tap(wrongEvidence);
    await tester.pump();

    final submit = find.byKey(const ValueKey('submit-feeling-check'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('feeling-check-feedback')),
      findsOneWidget,
    );
    expect(find.textContaining('that was a thoughtful try'), findsOneWidget);
    expect(find.textContaining('You’ve got this!'), findsOneWidget);

    final correctFeeling = find.byKey(
      const ValueKey('answer-mia-feeling-worried'),
    );
    await tester.ensureVisible(correctFeeling);
    await tester.tap(correctFeeling);
    final correctEvidence = find.byKey(
      const ValueKey('answer-mia-evidence-wobbly-tummy'),
    );
    await tester.ensureVisible(correctEvidence);
    await tester.tap(correctEvidence);
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('3 / 5'), findsOneWidget);
    expect(find.text('Feeling Check complete!'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('next-page-button')));
    await tester.pump();
    expect(find.text('4 / 5'), findsOneWidget);
  });
}

String pathParameter(GoRouterState state, String name) {
  return state.pathParameters[name]!;
}
