import 'package:ai_story_pet/features/stories/models/story.dart';

const testStoryId = 'sam-stargazing';

final testStoryDocument = <String, dynamic>{
  'id': testStoryId,
  'formatVersion': 2,
  'title': 'Sam Looks at the Stars',
  'category': 'Curiosity',
  'coverImagePath': 'assets/images/lumi_fox.png',
  'pages': [
    {
      'id': 'sam-page-1',
      'imagePath': 'assets/images/lumi_fox.png',
      'text': 'Sam carried a little telescope into the garden.',
    },
    {
      'id': 'sam-page-2',
      'imagePath': 'assets/images/lumie_celebrate_jump.png',
      'text': 'A bright star made Sam feel curious.',
      'feelingCheck': {
        'id': 'sam-curious-check',
        'title': 'What does curious feel like?',
        'focusPhrase': 'curious',
        'quote': '“Sam felt curious.”',
        'questions': [
          {
            'id': 'sam-feeling',
            'prompt': 'Pick a feeling',
            'correctOptionId': 'curious',
            'options': [
              {'id': 'curious', 'label': 'Curious', 'emoji': '🤔'},
              {'id': 'sleepy', 'label': 'Sleepy', 'emoji': '😴'},
            ],
          },
          {
            'id': 'sam-evidence',
            'prompt': 'How do you know?',
            'correctOptionId': 'looked-closer',
            'options': [
              {
                'id': 'looked-closer',
                'label': 'Sam wanted to look closer',
                'emoji': '🔭',
              },
              {'id': 'went-inside', 'label': 'Sam went inside', 'emoji': '🏠'},
            ],
          },
        ],
      },
    },
    {
      'id': 'sam-page-3',
      'imagePath': 'assets/images/lumi_fox.png',
      'text': 'Sam found the star and drew it in a notebook.',
    },
    {
      'id': 'sam-page-4',
      'imagePath': 'assets/images/lumi_fox.png',
      'text': 'Sam compared the bright star with a picture in a book.',
    },
    {
      'id': 'sam-page-5',
      'imagePath': 'assets/images/lumi_fox.png',
      'text': 'Sam smiled and planned another night of stargazing.',
    },
  ],
};

Story buildTestStory() => Story.fromMap(testStoryDocument);
