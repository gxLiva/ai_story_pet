import '../models/story.dart';

const miaStoryId = 'mia-joins-the-game';

class StoryRepository {
  const StoryRepository();

  Story? getStory(String storyId) {
    return storyId == miaStoryId ? _miaStory : null;
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
