import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/home/home_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/signup/signup_screen.dart';
import '../screens/welcome/welcome_screen.dart';

abstract final class AppRoutes {
  static const welcome = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
}

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.welcome,
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) {
          return WelcomeScreen(
            onGetStarted: () => context.push(AppRoutes.signup),
            onLogIn: () => context.push(AppRoutes.login),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) {
          return LoginScreen(
            onBack: () => _goBackOrWelcome(context),
            onLogIn: (email, password) => context.go(AppRoutes.home),
            onCreateAccount: () {
              context.pushReplacement(AppRoutes.signup);
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) {
          return SignupScreen(
            onBack: () => _goBackOrWelcome(context),
            onCreateAccount: (name, email, password) {
              context.go(AppRoutes.home);
            },
            onLogIn: () {
              context.pushReplacement(AppRoutes.login);
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
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
}

void _goBackOrWelcome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.welcome);
  }
}
