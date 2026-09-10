import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/providers/user_profile_providers.dart';
import '../../profile/repository/user_profile_repository.dart';
import '../repository/auth_repository.dart';

/// Provides the Firebase Authentication instance used by the app.
///
/// Keeping this behind a provider allows tests to replace Firebase with a
/// controlled implementation.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provides the repository responsible for authentication data operations.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(firebaseAuth: ref.watch(firebaseAuthProvider));
});

/// Emits the signed-in user and updates whenever the session changes.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Provides the current user when authentication has finished loading.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).asData?.value;
});

enum AppSessionStatus { loading, signedOut, needsOnboarding, ready }

class AppSessionNotifier extends ChangeNotifier {
  AppSessionStatus _status = AppSessionStatus.loading;
  StreamSubscription<bool>? _profileSubscription;

  AppSessionStatus get status => _status;

  void updateAuth(
    AsyncValue<User?> authState,
    UserProfileRepository Function() getProfileRepository,
  ) {
    if (authState.isLoading) {
      _setStatus(AppSessionStatus.loading);
      return;
    }

    final user = authState.asData?.value;
    if (user == null) {
      _profileSubscription?.cancel();
      _profileSubscription = null;
      _setStatus(AppSessionStatus.signedOut);
      return;
    }

    _profileSubscription?.cancel();
    _setStatus(AppSessionStatus.loading);
    _profileSubscription = getProfileRepository()
        .watchOnboardingCompleted(user.uid)
        .listen(
          (completed) => _setStatus(
            completed
                ? AppSessionStatus.ready
                : AppSessionStatus.needsOnboarding,
          ),
          onError: (_) => _setStatus(AppSessionStatus.needsOnboarding),
        );
  }

  void _setStatus(AppSessionStatus value) {
    if (_status == value) return;
    _status = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }
}

final appSessionProvider = Provider<AppSessionNotifier>((ref) {
  final notifier = AppSessionNotifier();

  ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
    notifier.updateAuth(next, () => ref.read(userProfileRepositoryProvider));
  }, fireImmediately: true);

  ref.onDispose(notifier.dispose);
  return notifier;
});
