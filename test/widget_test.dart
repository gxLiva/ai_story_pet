import 'package:ai_story_pet/app/app_shell.dart';
import 'package:ai_story_pet/app/story_pet_app.dart';
import 'package:ai_story_pet/providers/auth_providers.dart';
import 'package:ai_story_pet/screens/onboarding/onboarding_screen.dart';
import 'package:ai_story_pet/widgets/app_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<void> pumpSignedOutApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const StoryPetApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('navigates between welcome, login, and signup with go_router', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpSignedOutApp(tester);

    expect(find.text('AI Story Pet'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);

    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('you@example.com'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Jamie Rivera'), findsNothing);

    await tester.tap(find.text('New to StoryPet? Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Already have an account? Log in'), findsOneWidget);

    await tester.tap(find.text('Already have an account? Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('AI Story Pet'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
  });

  testWidgets('login validates form data before authentication', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpSignedOutApp(tester);
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log in'));
    await tester.pump();

    expect(find.text('Please enter your email.'), findsOneWidget);
    expect(find.text('Please enter your password.'), findsOneWidget);

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('signup validates form data before authentication', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpSignedOutApp(tester);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(find.text('Please enter your name.'), findsOneWidget);
    expect(find.text('Please enter your email.'), findsOneWidget);
    expect(find.text('Please create a password.'), findsOneWidget);

    expect(find.text('Create your account'), findsOneWidget);
  });

  testWidgets('redirects signed-out users away from the home route', (
    WidgetTester tester,
  ) async {
    await pumpSignedOutApp(tester);

    GoRouter.of(tester.element(find.text('AI Story Pet').first)).go('/home');
    await tester.pumpAndSettle();

    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Keep reading 📖'), findsNothing);
  });

  testWidgets('onboarding requires age, gender, a goal, and a hobby', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentUserProvider.overrideWithValue(null)],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );

    final continueButton = find.text('Continue');
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pump();

    expect(find.text('Please enter an age.'), findsOneWidget);
    expect(find.text('Please select an option.'), findsOneWidget);
    expect(find.text('Choose or write a reading goal.'), findsOneWidget);
    expect(find.text('Choose or write at least one hobby.'), findsOneWidget);
  });

  testWidgets('onboarding back button asks before signing out', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentUserProvider.overrideWithValue(null)],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Leave onboarding?'), findsOneWidget);
    expect(find.text('Stay'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);

    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();

    expect(find.text('Leave onboarding?'), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('onboarding turns custom entries into labels and limits them', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentUserProvider.overrideWithValue(null)],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );

    final goalInput = find.byType(TextFormField).at(1);
    await tester.ensureVisible(goalInput);
    for (final goal in ['Explore space', 'Learn kindness', 'Read aloud']) {
      await tester.enterText(goalInput, goal);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
    }

    expect(find.text('Explore space'), findsOneWidget);
    expect(find.text('Learn kindness'), findsOneWidget);
    expect(find.text('Read aloud'), findsOneWidget);

    await tester.enterText(goalInput, 'Fourth goal');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(
      find.text('You can add up to 3 custom reading goals.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('custom-choice-Fourth goal')),
      findsNothing,
    );

    final hobbyInput = find.byType(TextFormField).at(2);
    await tester.ensureVisible(hobbyInput);
    await tester.enterText(hobbyInput, 'Chess');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('Chess'), findsOneWidget);
  });

  testWidgets('app shell keeps one bottom navigation bar while tabs change', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const Text('Home content'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/library',
                  builder: (context, state) => const Text('Library content'),
                ),
              ],
            ),
            for (var index = 0; index < 3; index++)
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/placeholder-$index',
                    builder: (context, state) => Text('Placeholder $index'),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomNavigationBar), findsOneWidget);
    expect(find.text('Home content'), findsOneWidget);

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();

    expect(find.text('Library content'), findsOneWidget);
    expect(find.byType(AppBottomNavigationBar), findsOneWidget);
  });
}
