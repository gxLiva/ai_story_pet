import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileRepository {
  UserProfileRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _profile(String userId) {
    return _firestore.collection('userProfiles').doc(userId);
  }

  Future<void> createProfileIfMissing({
    required String userId,
    required String name,
    required String email,
  }) {
    final profile = _profile(userId);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(profile);
      if (snapshot.exists) return;

      transaction.set(profile, {
        'name': name.trim(),
        'email': email.trim(),
        'age': null,
        'gender': null,
        'readingGoals': <String>[],
        'hobbies': <String>[],
        'onboardingCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<bool> watchOnboardingCompleted(String userId) {
    return _profile(userId).snapshots().map(
      (snapshot) => snapshot.data()?['onboardingCompleted'] == true,
    );
  }

  Future<void> completeOnboarding({
    required String userId,
    required int age,
    required String gender,
    required List<String> readingGoals,
    required List<String> hobbies,
  }) {
    return _profile(userId).set({
      'age': age,
      'gender': gender,
      'readingGoals': readingGoals,
      'hobbies': hobbies,
      'onboardingCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
