import 'package:cloud_functions/cloud_functions.dart';

abstract interface class StoryCreationService {
  Future<String> createSampleStory();
}

class FirebaseStoryCreationService implements StoryCreationService {
  FirebaseStoryCreationService(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<String> createSampleStory() async {
    final result = await _functions.httpsCallable('createSampleStory').call();
    final data = result.data;
    if (data is! Map || data['storyId'] is! String) {
      throw const FormatException(
        'The story creation function returned an invalid response.',
      );
    }

    final storyId = (data['storyId'] as String).trim();
    if (storyId.isEmpty) {
      throw const FormatException(
        'The story creation function returned an empty story id.',
      );
    }
    return storyId;
  }
}
