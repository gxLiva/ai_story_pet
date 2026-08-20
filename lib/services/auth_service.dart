import 'package:firebase_auth/firebase_auth.dart';

/// Provides the app's Firebase Authentication operations.
///
/// Firebase must be initialized before the default constructor is used.
/// Authentication errors are intentionally allowed to propagate as
/// [FirebaseAuthException] so the calling screen can display an appropriate
/// message.
class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  /// The currently authenticated user, or `null` when signed out.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Whether Firebase currently has an authenticated user.
  bool get isSignedIn => currentUser != null;

  /// Emits the current user when authentication is initialized and whenever
  /// the user signs in or out.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Creates an email/password account and assigns the supplied display name.
  Future<UserCredential> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw StateError(
        'Firebase did not return a user after account creation.',
      );
    }

    await user.updateDisplayName(name.trim());
    return credential;
  }

  /// Signs in an existing user with an email address and password.
  Future<UserCredential> logIn({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Requests a password-reset email for the supplied address.
  Future<void> sendPasswordResetEmail({required String email}) {
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  /// Signs out the current user.
  Future<void> logOut() {
    return _firebaseAuth.signOut();
  }
}
