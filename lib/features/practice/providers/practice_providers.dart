import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/providers/user_profile_providers.dart';
import '../repository/practice_repository.dart';

final practiceRepositoryProvider = Provider<PracticeRepository>((ref) {
  return PracticeRepository(
    FirestorePracticeProgressDataSource(ref.watch(firestoreProvider)),
  );
});
