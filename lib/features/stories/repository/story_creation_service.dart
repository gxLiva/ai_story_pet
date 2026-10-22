import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

abstract interface class StoryCreationService {
  Future<String> createPersonalizedStory();
}

abstract interface class SharedThemeStoryService {
  Future<void> ensureStoriesExist();
}

class FirebaseStoryCreationService implements StoryCreationService {
  FirebaseStoryCreationService(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<String> createPersonalizedStory() async {
    debugPrint('[StoryGeneration] Calling createPersonalizedStory');
    try {
      final result = await _functions
          .httpsCallable(
            'createPersonalizedStory',
            options: HttpsCallableOptions(timeout: const Duration(minutes: 5)),
          )
          .call();
      final data = result.data;
      debugPrint(
        '[StoryGeneration] Callable completed; '
        'responseType=${data.runtimeType}',
      );
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
      debugPrint('[StoryGeneration] Created storyId=$storyId');
      return storyId;
    } on FirebaseFunctionsException catch (error, stackTrace) {
      debugPrint(
        '[StoryGeneration] FirebaseFunctionsException '
        'code=${error.code} message=${error.message} '
        'details=${error.details}',
      );
      debugPrintStack(
        label: '[StoryGeneration] Callable stack trace',
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('[StoryGeneration] Unexpected error: $error');
      debugPrintStack(
        label: '[StoryGeneration] Unexpected stack trace',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

class FirebaseSharedThemeStoryService implements SharedThemeStoryService {
  FirebaseSharedThemeStoryService(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<void> ensureStoriesExist() async {
    await _functions
        .httpsCallable(
          'ensureSharedThemeStories',
          options: HttpsCallableOptions(timeout: const Duration(minutes: 9)),
        )
        .call();
  }
}
