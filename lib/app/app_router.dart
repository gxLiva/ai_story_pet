import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/auth/presentation/screens/welcome_screen.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/navigation/presentation/screens/tab_placeholder_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/stories/presentation/screens/feeling_check_screen.dart';
import '../features/stories/presentation/screens/story_screen.dart';
import 'app_shell.dart';

abstract final class AppRoutes {
  static const welcome = '/';
  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const library = '/library';
  static const practice = '/practice';
  static const growth = '/growth';
  static const profile = '/profile';
  static const story = '/story/:storyId';

  static String storyPath(String storyId) => '/story/$storyId';

  static String feelingCheckPath(String storyId, String checkId) {
    return '/story/$storyId/feeling-check/$checkId';
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(appSessionProvider);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: session,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isOnSplash = location == AppRoutes.splash;

      if (session.status == AppSessionStatus.loading) {
        return isOnSplash ? null : AppRoutes.splash;
      }

      final isOnAuthRoute =
          location == AppRoutes.welcome ||
          location == AppRoutes.login ||
          location == AppRoutes.signup;
      final isOnShellRoute =
          location == AppRoutes.home ||
          location == AppRoutes.library ||
          location == AppRoutes.practice ||
          location == AppRoutes.growth ||
          location == AppRoutes.profile;
      final isOnProtectedRoute =
          isOnShellRoute || location.startsWith('/story/');

      if (session.status == AppSessionStatus.signedOut) {
        if (isOnSplash ||
            isOnProtectedRoute ||
            location == AppRoutes.onboarding) {
          return AppRoutes.welcome;
        }
        return null;
      }

      if (session.status == AppSessionStatus.needsOnboarding) {
        return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }

      if (isOnSplash || isOnAuthRoute || location == AppRoutes.onboarding) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _AuthLoadingScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.story,
        builder: (context, state) =>
            StoryScreen(storyId: state.pathParameters['storyId']!),
        routes: [
          GoRoute(
            path: 'feeling-check/:checkId',
            builder: (context, state) => FeelingCheckScreen(
              storyId: state.pathParameters['storyId']!,
              checkId: state.pathParameters['checkId']!,
            ),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.library,
                builder: (context, state) => const TabPlaceholderScreen(
                  title: 'Library',
                  icon: Icons.menu_book_rounded,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.practice,
                builder: (context, state) => const TabPlaceholderScreen(
                  title: 'Practice',
                  icon: Icons.extension_rounded,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.growth,
                builder: (context, state) => const TabPlaceholderScreen(
                  title: 'Growth',
                  icon: Icons.show_chart_rounded,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const TabPlaceholderScreen(
                  title: 'Profile',
                  icon: Icons.person_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('We could not find that page.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.welcome),
                child: const Text('Return to welcome'),
              ),
            ],
          ),
        ),
      );
    },
  );

  ref.onDispose(router.dispose);
  return router;
});

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
