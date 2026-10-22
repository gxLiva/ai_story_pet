import 'package:cloud_firestore/cloud_firestore.dart';

abstract interface class PracticeProgressDataSource {
  Future<void> saveChoice({
    required String userId,
    required String storyId,
    required String actionId,
  });
}

class FirestorePracticeProgressDataSource
    implements PracticeProgressDataSource {
  FirestorePracticeProgressDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> saveChoice({
    required String userId,
    required String storyId,
    required String actionId,
  }) {
    return _firestore
        .collection('userProfiles')
        .doc(userId)
        .collection('practiceProgress')
        .doc(storyId)
        .set({
          'storyId': storyId,
          'selectedActionId': actionId,
          'completed': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }
}

class PracticeRepository {
  PracticeRepository(this._dataSource);

  final PracticeProgressDataSource _dataSource;

  Future<void> saveChoice({
    required String userId,
    required String storyId,
    required String actionId,
  }) {
    return _dataSource.saveChoice(
      userId: userId,
      storyId: storyId,
      actionId: actionId,
    );
  }
}
