import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/story.dart';

const miaStoryId = 'mia-joins-the-game';
const personalizedStoryId = 'personalized';

abstract interface class UserStoryDataSource {
  Stream<Map<String, dynamic>?> watchStory({
    required String userId,
    required String storyId,
  });
}

abstract interface class StoryCatalogDataSource {
  Stream<List<Map<String, dynamic>>> watchStories();

  Stream<Map<String, dynamic>?> watchStory(String storyId);
}

abstract interface class StoryActivityDataSource {
  Stream<List<Map<String, dynamic>>> watchActivity(String userId);

  Future<void> recordOpened({required String userId, required String storyId});

  Future<void> saveProgress({
    required String userId,
    required String storyId,
    required StoryReadingState state,
    required bool? completed,
  });
}

class FirestoreUserStoryDataSource implements UserStoryDataSource {
  FirestoreUserStoryDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<Map<String, dynamic>?> watchStory({
    required String userId,
    required String storyId,
  }) {
    return _firestore
        .collection('userProfiles')
        .doc(userId)
        .collection('stories')
        .doc(storyId)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }
}

class FirestoreStoryCatalogDataSource implements StoryCatalogDataSource {
  FirestoreStoryCatalogDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<Map<String, dynamic>>> watchStories() {
    return _firestore
        .collection('stories')
        .where('published', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => {...document.data(), 'id': document.id})
              .toList(growable: false),
        );
  }

  @override
  Stream<Map<String, dynamic>?> watchStory(String storyId) {
    return _firestore.collection('stories').doc(storyId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null || data['published'] != true) return null;
      return {...data, 'id': doc.id};
    });
  }
}

class FirestoreUserStoryCollectionDataSource {
  FirestoreUserStoryCollectionDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<Map<String, dynamic>>> watchStories(String userId) {
    return _firestore
        .collection('userProfiles')
        .doc(userId)
        .collection('stories')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => {...document.data(), 'id': document.id})
              .toList(growable: false),
        );
  }
}

class FirestoreStoryActivityDataSource implements StoryActivityDataSource {
  FirestoreStoryActivityDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _activity(String userId) {
    return _firestore
        .collection('userProfiles')
        .doc(userId)
        .collection('readingProgress');
  }

  @override
  Stream<List<Map<String, dynamic>>> watchActivity(String userId) {
    return _activity(userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => {...document.data(), 'storyId': document.id})
              .toList(growable: false),
        );
  }

  @override
  Future<void> recordOpened({required String userId, required String storyId}) {
    return _activity(userId).doc(storyId).set({
      'storyId': storyId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> saveProgress({
    required String userId,
    required String storyId,
    required StoryReadingState state,
    required bool? completed,
  }) {
    return _activity(userId).doc(storyId).set({
      'storyId': storyId,
      'currentPageIndex': state.currentPageIndex,
      'selectedAnswers': state.selectedAnswers,
      'completedFeelingCheckIds': state.completedFeelingCheckIds.toList(),
      'updatedAt': FieldValue.serverTimestamp(),
      ...?completed == null ? null : {'completed': completed},
      if (completed == true) 'completedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

class StoryProgress {
  const StoryProgress({
    required this.storyId,
    required this.state,
    required this.completed,
  });

  final String storyId;
  final StoryReadingState state;
  final bool completed;

  factory StoryProgress.fromMap(Map<String, dynamic> map) {
    final rawAnswers = map['selectedAnswers'];
    final rawChecks = map['completedFeelingCheckIds'];
    return StoryProgress(
      storyId: map['storyId'] as String,
      state: StoryReadingState(
        currentPageIndex: map['currentPageIndex'] is int
            ? map['currentPageIndex'] as int
            : 0,
        selectedAnswers: rawAnswers is Map
            ? rawAnswers.map(
                (key, value) => MapEntry(key.toString(), value.toString()),
              )
            : const {},
        completedFeelingCheckIds: rawChecks is Iterable
            ? rawChecks.map((value) => value.toString()).toSet()
            : const {},
      ),
      completed: map['completed'] == true,
    );
  }
}

class StoryActivity {
  const StoryActivity(this.items);

  final List<StoryProgress> items;

  String? get mostRecentStoryId => items.isEmpty ? null : items.first.storyId;

  Set<String> get completedStoryIds =>
      items.where((item) => item.completed).map((item) => item.storyId).toSet();

  StoryProgress? progressFor(String storyId) {
    for (final item in items) {
      if (item.storyId == storyId) return item;
    }
    return null;
  }
}

class StoryActivityRepository {
  StoryActivityRepository(this._dataSource);

  final StoryActivityDataSource _dataSource;

  Stream<StoryActivity> watchActivity(String userId) {
    return _dataSource
        .watchActivity(userId)
        .map(
          (documents) => StoryActivity(
            documents.map(StoryProgress.fromMap).toList(growable: false),
          ),
        );
  }

  Future<void> recordOpened({required String userId, required String storyId}) {
    return _dataSource.recordOpened(userId: userId, storyId: storyId);
  }

  Future<void> saveProgress({
    required String userId,
    required String storyId,
    required StoryReadingState state,
    bool? completed,
  }) {
    return _dataSource.saveProgress(
      userId: userId,
      storyId: storyId,
      state: state,
      completed: completed,
    );
  }
}

class StoryRepository {
  StoryRepository({
    this.userStoryDataSource,
    Iterable<Story> additionalStories = const [],
  }) : _stories = {
         miaStoryId: _miaStory,
         for (final story in additionalStories) story.id: story,
       };

  final UserStoryDataSource? userStoryDataSource;
  final Map<String, Story> _stories;

  Story? getLocalStory(String storyId) {
    return _stories[storyId];
  }

  Stream<Story?> watchUserStory({
    required String userId,
    required String storyId,
  }) {
    final dataSource = userStoryDataSource;
    if (dataSource == null) {
      return Stream.error(
        StateError('A user story data source has not been configured.'),
      );
    }

    return dataSource
        .watchStory(userId: userId, storyId: storyId)
        .map(
          (document) => document == null
              ? null
              : Story.fromMap(document, documentId: storyId),
        );
  }
}

const _miaFeelingCheck = FeelingCheck(
  id: 'mia-worried-check',
  title: 'What does wobbly feel like?',
  focusPhrase: 'wobbly',
  quote: '“My tummy feels wobbly...”',
  questions: [
    FeelingQuestion(
      id: 'mia-feeling',
      prompt: 'Pick a feeling',
      correctOptionId: 'worried',
      options: [
        FeelingOption(id: 'happy', label: 'Happy', emoji: '😊'),
        FeelingOption(id: 'worried', label: 'Worried', emoji: '😟'),
        FeelingOption(id: 'sad', label: 'Sad', emoji: '😢'),
        FeelingOption(id: 'excited', label: 'Excited', emoji: '🤩'),
      ],
    ),
    FeelingQuestion(
      id: 'mia-evidence',
      prompt: 'How do you know?',
      correctOptionId: 'wobbly-tummy',
      options: [
        FeelingOption(
          id: 'wobbly-tummy',
          label: 'Her tummy felt wobbly',
          emoji: '🫃',
        ),
        FeelingOption(
          id: 'did-not-know',
          label: "She didn't know what to say",
          emoji: '🤐',
        ),
        FeelingOption(
          id: 'watched',
          label: 'She watched from far away',
          emoji: '👀',
        ),
      ],
    ),
  ],
);

const _miaStory = Story(
  id: miaStoryId,
  title: 'Mia Joins the Game',
  category: 'Friendship',
  coverImagePath: 'assets/images/mia_joins_game.png',
  practice: PracticeScenario(
    situation: 'Mia wants to join the soccer game, but she feels unsure.',
    prompt: 'If you were Mia, what would you choose to do?',
    actions: [
      PracticeAction(
        id: 'ask-to-play',
        label: 'Ask “Can I play?”',
        emoji: '😊',
        feedback: 'Speaking up is one brave way to join in.',
        outcome: 'The players hear Mia and make room for her in the game.',
      ),
      PracticeAction(
        id: 'watch-first',
        label: 'Watch first',
        emoji: '👀',
        feedback: 'Watching can help you learn the game and feel ready.',
        outcome:
            'Mia notices how the game works and chooses a good moment to join.',
      ),
      PracticeAction(
        id: 'find-grown-up',
        label: 'Find a grown-up',
        emoji: '🧑‍🏫',
        feedback: 'Asking for support is a thoughtful choice.',
        outcome: 'A grown-up helps Mia find the words to introduce herself.',
      ),
      PracticeAction(
        id: 'play-alone',
        label: 'Play on my own',
        emoji: '🎨',
        feedback: 'Choosing your own activity can feel comfortable and fun.',
        outcome:
            'Mia enjoys her own game and can decide to join the group later.',
      ),
    ],
  ),
  pages: [
    StoryPage(
      id: 'mia-page-1',
      imagePath: 'assets/images/mia_joins_game.png',
      text: 'Mia saw some kids playing soccer in the park.',
    ),
    StoryPage(
      id: 'mia-page-2',
      imagePath: 'assets/images/mia_joins_game.png',
      text: 'She wanted to join them, but she did not know what to say.',
    ),
    StoryPage(
      id: 'mia-page-3',
      imagePath: 'assets/images/mia_joins_game.png',
      text: 'Mia watched the game. Her tummy felt wobbly.',
      feelingCheck: _miaFeelingCheck,
    ),
    StoryPage(
      id: 'mia-page-4',
      imagePath: 'assets/images/mia_joins_game.png',
      text: 'Mia took a slow breath and asked, “Can I play too?”',
    ),
    StoryPage(
      id: 'mia-page-5',
      imagePath: 'assets/images/mia_joins_game.png',
      text: 'The kids smiled and made room. Mia joined the game!',
    ),
  ],
);
