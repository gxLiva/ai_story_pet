class Story {
  const Story({
    required this.id,
    required this.title,
    required this.category,
    required this.coverImagePath,
    required this.pages,
    this.description = '',
    this.readingTimeMinutes = 0,
    this.formatVersion = 1,
    this.mainCharacterName = '',
    this.mainCharacterDescription = '',
    this.practice,
  });

  final String id;
  final String title;
  final String category;
  final String coverImagePath;
  final List<StoryPage> pages;
  final String description;
  final int readingTimeMinutes;
  final int formatVersion;
  final String mainCharacterName;
  final String mainCharacterDescription;
  final PracticeScenario? practice;

  PracticeScenario get practiceScenario =>
      practice ?? PracticeScenario.fromStory(this);

  factory Story.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final storyId = map['id'] == null
        ? _requiredStringValue(documentId, 'id')
        : _requiredString(map, 'id', 'story');
    if (documentId != null && storyId != documentId) {
      throw const FormatException('Story id must match its document id.');
    }

    final pages = _mapList(map, 'pages', 'story', StoryPage.fromMap);
    if (pages.length < 5 || pages.length > 10) {
      throw const FormatException('A story must contain 5 to 10 pages.');
    }
    _requireUniqueIds(pages.map((page) => page.id), 'story pages');
    final checks = pages
        .map((page) => page.feelingCheck)
        .whereType<FeelingCheck>()
        .toList(growable: false);
    final rawFormatVersion = map['formatVersion'];
    final formatVersion = rawFormatVersion is int && rawFormatVersion > 0
        ? rawFormatVersion
        : 1;
    if (formatVersion >= 2 && (checks.isEmpty || checks.length > 2)) {
      throw const FormatException(
        'A story must contain 1 or 2 feeling checks.',
      );
    }
    _requireUniqueIds(checks.map((check) => check.id), 'feeling checks');

    return Story(
      id: storyId,
      title: _requiredString(map, 'title', 'story'),
      category: _requiredString(map, 'category', 'story'),
      coverImagePath: _requiredString(map, 'coverImagePath', 'story'),
      pages: List.unmodifiable(pages),
      description: _optionalString(map, 'description'),
      readingTimeMinutes: _optionalPositiveInt(map, 'readingTimeMinutes'),
      formatVersion: formatVersion,
      mainCharacterName: _optionalString(map, 'mainCharacterName'),
      mainCharacterDescription: _optionalString(
        map,
        'mainCharacterDescription',
      ),
      practice: map['practice'] == null
          ? null
          : PracticeScenario.fromMap(_stringMap(map['practice'], 'practice')),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'category': category,
    'coverImagePath': coverImagePath,
    'pages': pages.map((page) => page.toMap()).toList(growable: false),
    if (description.isNotEmpty) 'description': description,
    if (readingTimeMinutes > 0) 'readingTimeMinutes': readingTimeMinutes,
    if (formatVersion > 1) 'formatVersion': formatVersion,
    if (mainCharacterName.isNotEmpty) 'mainCharacterName': mainCharacterName,
    if (mainCharacterDescription.isNotEmpty)
      'mainCharacterDescription': mainCharacterDescription,
    if (practice != null) 'practice': practice!.toMap(),
  };
}

class PracticeScenario {
  const PracticeScenario({
    required this.situation,
    required this.prompt,
    required this.actions,
  });

  final String situation;
  final String prompt;
  final List<PracticeAction> actions;

  factory PracticeScenario.fromMap(Map<String, dynamic> map) {
    final actions = _mapList(
      map,
      'actions',
      'practice',
      PracticeAction.fromMap,
    );
    if (actions.length < 2 || actions.length > 4) {
      throw const FormatException('A practice must contain 2 to 4 actions.');
    }
    _requireUniqueIds(actions.map((action) => action.id), 'practice actions');
    return PracticeScenario(
      situation: _requiredString(map, 'situation', 'practice'),
      prompt: _requiredString(map, 'prompt', 'practice'),
      actions: List.unmodifiable(actions),
    );
  }

  factory PracticeScenario.fromStory(Story story) {
    final character = story.mainCharacterName.isEmpty
        ? 'the character'
        : story.mainCharacterName;
    final situation = story.description.isNotEmpty
        ? story.description
        : story.pages.first.text;
    final templates =
        _practiceTemplates[story.category] ?? _practiceTemplates['Friendship']!;
    return PracticeScenario(
      situation: situation,
      prompt: 'If you were $character, what would you choose to do?',
      actions: List.unmodifiable(
        templates.indexed
            .map(
              (entry) => PracticeAction(
                id: 'choice-${entry.$1 + 1}',
                label: entry.$2.$1,
                emoji: entry.$2.$2,
                feedback: entry.$2.$3,
                outcome: entry.$2.$4.replaceAll('{name}', character),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'situation': situation,
    'prompt': prompt,
    'actions': actions.map((action) => action.toMap()).toList(growable: false),
  };
}

class PracticeAction {
  const PracticeAction({
    required this.id,
    required this.label,
    required this.emoji,
    required this.feedback,
    required this.outcome,
  });

  final String id;
  final String label;
  final String emoji;
  final String feedback;
  final String outcome;

  factory PracticeAction.fromMap(Map<String, dynamic> map) {
    return PracticeAction(
      id: _requiredString(map, 'id', 'practice action'),
      label: _requiredString(map, 'label', 'practice action'),
      emoji: _requiredString(map, 'emoji', 'practice action'),
      feedback: _requiredString(map, 'feedback', 'practice action'),
      outcome: _requiredString(map, 'outcome', 'practice action'),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'emoji': emoji,
    'feedback': feedback,
    'outcome': outcome,
  };
}

const _practiceTemplates = <String, List<(String, String, String, String)>>{
  'Friendship': [
    (
      'Say what you need',
      '💬',
      'Speaking up can help others understand you.',
      '{name} shares what they need, and the others have a chance to respond.',
    ),
    (
      'Watch and listen first',
      '👀',
      'Taking time to notice can help you feel ready.',
      '{name} learns more about the situation before choosing a next step.',
    ),
    (
      'Ask someone for help',
      '🤝',
      'Getting support is a thoughtful choice.',
      '{name} finds someone who can help make the next step feel easier.',
    ),
    (
      'Take a little time',
      '🌤️',
      'It is okay to move at your own pace.',
      '{name} pauses, feels steadier, and can try again later.',
    ),
  ],
  'Big Feelings': [
    (
      'Name the feeling',
      '💬',
      'Naming a feeling can make it easier to understand.',
      '{name} recognizes the feeling and has a clearer idea of what they need.',
    ),
    (
      'Take slow breaths',
      '🌬️',
      'A calm breath gives your body time to settle.',
      '{name} slows down and feels ready to decide what comes next.',
    ),
    (
      'Talk to someone',
      '🤝',
      'Sharing a big feeling can make it less lonely.',
      '{name} receives care and a helpful new point of view.',
    ),
    (
      'Find a quiet space',
      '🌿',
      'A short break can give a feeling room to soften.',
      '{name} takes a pause and returns when they feel ready.',
    ),
  ],
  'Transition': [
    (
      'Ask what happens next',
      '❓',
      'Knowing the next step can make change feel smaller.',
      '{name} gets useful information and feels more prepared.',
    ),
    (
      'Bring something familiar',
      '🧸',
      'A familiar object can bring comfort during change.',
      '{name} carries a reminder of safety into the new situation.',
    ),
    (
      'Try one part first',
      '🌱',
      'Small steps still move you forward.',
      '{name} tries a manageable part and builds confidence.',
    ),
    (
      'Tell someone how you feel',
      '💬',
      'Others can support you when they know what is hard.',
      '{name} is heard and gets help with the change.',
    ),
  ],
  'Courage': [
    (
      'Try one small step',
      '🌱',
      'Courage can begin with one manageable step.',
      '{name} tries a little, learns something, and feels more ready.',
    ),
    (
      'Make a simple plan',
      '📋',
      'A plan can make a brave choice feel clearer.',
      '{name} knows what to do first and moves ahead carefully.',
    ),
    (
      'Ask for support',
      '🤝',
      'Being brave does not mean doing everything alone.',
      '{name} gets encouragement and faces the moment with support.',
    ),
    (
      'Pause and try later',
      '⏳',
      'Waiting until you are ready can be a wise choice.',
      '{name} takes time to prepare and keeps the choice open.',
    ),
  ],
};

String _optionalString(Map<String, dynamic> map, String key) {
  final value = map[key];
  return value is String ? value.trim() : '';
}

int _optionalPositiveInt(Map<String, dynamic> map, String key) {
  final value = map[key];
  return value is int && value > 0 ? value : 0;
}

class StoryPage {
  const StoryPage({
    required this.id,
    required this.imagePath,
    required this.text,
    this.feelingCheck,
  });

  final String id;
  final String imagePath;
  final String text;
  final FeelingCheck? feelingCheck;

  factory StoryPage.fromMap(Map<String, dynamic> map) {
    final text = _requiredString(map, 'text', 'story page');
    final rawCheck = map['feelingCheck'];
    final check = rawCheck == null
        ? null
        : FeelingCheck.fromMap(_stringMap(rawCheck, 'feelingCheck'));
    if (check != null &&
        !text.toLowerCase().contains(check.focusPhrase.toLowerCase())) {
      throw const FormatException(
        'A feeling check focus phrase must appear in its story page text.',
      );
    }

    return StoryPage(
      id: _requiredString(map, 'id', 'story page'),
      imagePath: _requiredString(map, 'imagePath', 'story page'),
      text: text,
      feelingCheck: check,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'imagePath': imagePath,
    'text': text,
    if (feelingCheck != null) 'feelingCheck': feelingCheck!.toMap(),
  };
}

class FeelingCheck {
  const FeelingCheck({
    required this.id,
    required this.title,
    required this.focusPhrase,
    required this.quote,
    required this.questions,
  });

  final String id;
  final String title;
  final String focusPhrase;
  final String quote;
  final List<FeelingQuestion> questions;

  factory FeelingCheck.fromMap(Map<String, dynamic> map) {
    final questions = _mapList(
      map,
      'questions',
      'feeling check',
      FeelingQuestion.fromMap,
    );
    if (questions.length != 2) {
      throw const FormatException(
        'A feeling check must contain exactly two questions.',
      );
    }
    _requireUniqueIds(questions.map((question) => question.id), 'questions');

    return FeelingCheck(
      id: _requiredString(map, 'id', 'feeling check'),
      title: _requiredString(map, 'title', 'feeling check'),
      focusPhrase: _requiredString(map, 'focusPhrase', 'feeling check'),
      quote: _requiredString(map, 'quote', 'feeling check'),
      questions: List.unmodifiable(questions),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'focusPhrase': focusPhrase,
    'quote': quote,
    'questions': questions
        .map((question) => question.toMap())
        .toList(growable: false),
  };
}

class FeelingQuestion {
  const FeelingQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctOptionId,
  });

  final String id;
  final String prompt;
  final List<FeelingOption> options;
  final String correctOptionId;

  factory FeelingQuestion.fromMap(Map<String, dynamic> map) {
    final options = _mapList(
      map,
      'options',
      'feeling question',
      FeelingOption.fromMap,
    );
    if (options.length < 2) {
      throw const FormatException(
        'A feeling question must have at least two options.',
      );
    }
    _requireUniqueIds(options.map((option) => option.id), 'answer options');
    final correctOptionId = _requiredString(
      map,
      'correctOptionId',
      'feeling question',
    );
    if (!options.any((option) => option.id == correctOptionId)) {
      throw const FormatException(
        'A correct option must reference one of the question options.',
      );
    }

    return FeelingQuestion(
      id: _requiredString(map, 'id', 'feeling question'),
      prompt: _requiredString(map, 'prompt', 'feeling question'),
      options: List.unmodifiable(options),
      correctOptionId: correctOptionId,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'prompt': prompt,
    'options': options.map((option) => option.toMap()).toList(growable: false),
    'correctOptionId': correctOptionId,
  };
}

class FeelingOption {
  const FeelingOption({
    required this.id,
    required this.label,
    required this.emoji,
  });

  final String id;
  final String label;
  final String emoji;

  factory FeelingOption.fromMap(Map<String, dynamic> map) {
    return FeelingOption(
      id: _requiredString(map, 'id', 'feeling option'),
      label: _requiredString(map, 'label', 'feeling option'),
      emoji: _requiredString(map, 'emoji', 'feeling option'),
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'label': label, 'emoji': emoji};
}

String _requiredString(Map<String, dynamic> map, String key, String owner) {
  return _requiredStringValue(map[key], '$owner.$key');
}

String _requiredStringValue(Object? value, String path) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$path must be a non-empty string.');
  }
  return value.trim();
}

Map<String, dynamic> _stringMap(Object? value, String path) {
  if (value is! Map) {
    throw FormatException('$path must be an object.');
  }
  try {
    return Map<String, dynamic>.from(value);
  } on TypeError {
    throw FormatException('$path must use string keys.');
  }
}

List<T> _mapList<T>(
  Map<String, dynamic> map,
  String key,
  String owner,
  T Function(Map<String, dynamic>) convert,
) {
  final value = map[key];
  if (value is! List) {
    throw FormatException('$owner.$key must be a list.');
  }
  return [
    for (var index = 0; index < value.length; index++)
      convert(_stringMap(value[index], '$owner.$key[$index]')),
  ];
}

void _requireUniqueIds(Iterable<String> ids, String owner) {
  final seen = <String>{};
  for (final id in ids) {
    if (!seen.add(id)) {
      throw FormatException('$owner must have unique ids.');
    }
  }
}

class StoryReadingState {
  const StoryReadingState({
    this.currentPageIndex = 0,
    this.selectedAnswers = const {},
    this.completedFeelingCheckIds = const {},
  });

  final int currentPageIndex;
  final Map<String, String> selectedAnswers;
  final Set<String> completedFeelingCheckIds;

  StoryReadingState copyWith({
    int? currentPageIndex,
    Map<String, String>? selectedAnswers,
    Set<String>? completedFeelingCheckIds,
  }) {
    return StoryReadingState(
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      completedFeelingCheckIds:
          completedFeelingCheckIds ?? this.completedFeelingCheckIds,
    );
  }
}
