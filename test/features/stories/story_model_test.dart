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
      expect(story.pages, hasLength(5));
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

    test('rejects stories longer than ten pages', () {
      final document = _deepCopy(testStoryDocument);
      final pages = document['pages'] as List<dynamic>;
      while (pages.length < 11) {
        final index = pages.length + 1;
        pages.add({
          'id': 'sam-page-$index',
          'imagePath': 'assets/images/lumi_fox.png',
          'text': 'Extra page $index.',
        });
      }

      expect(() => Story.fromMap(document), throwsFormatException);
    });

    test('rejects a story without a feeling check', () {
      final document = _deepCopy(testStoryDocument);
      final pages = document['pages'] as List<dynamic>;
      for (final page in pages) {
        (page as Map<String, dynamic>).remove('feelingCheck');
      }

      expect(() => Story.fromMap(document), throwsFormatException);
    });

    test('keeps legacy saved stories readable before migration', () {
      final document = _deepCopy(testStoryDocument)..remove('formatVersion');
      final pages = document['pages'] as List<dynamic>;
      for (final page in pages) {
        (page as Map<String, dynamic>).remove('feelingCheck');
      }

      expect(Story.fromMap(document).formatVersion, 1);
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
