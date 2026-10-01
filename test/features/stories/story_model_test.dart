import 'dart:convert';

import 'package:ai_story_pet/features/stories/models/story.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_story_fixture.dart';

void main() {
  group('Story Firestore document parsing', () {
    test('parses and serializes a valid dynamic story', () {
      final story = Story.fromMap(testStoryDocument, documentId: testStoryId);

      expect(story.id, testStoryId);
      expect(story.title, 'Sam Looks at the Stars');
      expect(story.pages, hasLength(3));
      expect(story.pages[1].feelingCheck?.questions, hasLength(2));
      expect(Story.fromMap(story.toMap()).toMap(), story.toMap());
    });

    test('uses the Firestore document id when id is omitted', () {
      final document = Map<String, dynamic>.from(testStoryDocument)
        ..remove('id');

      expect(Story.fromMap(document, documentId: testStoryId).id, testStoryId);
    });

    test('rejects an empty page list', () {
      final document = <String, dynamic>{
        ...testStoryDocument,
        'pages': <Map<String, dynamic>>[],
      };

      expect(() => Story.fromMap(document), throwsFormatException);
    });

    test('rejects a correct answer that is not one of the options', () {
      final document = _deepCopy(testStoryDocument);
      final pages = document['pages'] as List<dynamic>;
      final check =
          (pages[1] as Map<String, dynamic>)['feelingCheck']
              as Map<String, dynamic>;
      final questions = check['questions'] as List<dynamic>;
      (questions.first as Map<String, dynamic>)['correctOptionId'] = 'missing';

      expect(() => Story.fromMap(document), throwsFormatException);
    });

    test('rejects a focus phrase absent from the page text', () {
      final document = _deepCopy(testStoryDocument);
      final pages = document['pages'] as List<dynamic>;
      final check =
          (pages[1] as Map<String, dynamic>)['feelingCheck']
              as Map<String, dynamic>;
      check['focusPhrase'] = 'worried';

      expect(() => Story.fromMap(document), throwsFormatException);
    });
  });
}

Map<String, dynamic> _deepCopy(Map<String, dynamic> value) {
  return jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
}
