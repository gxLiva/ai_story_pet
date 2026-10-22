import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../stories/models/story.dart';
import '../../../stories/presentation/widgets/story_image.dart';
import '../../../stories/providers/story_providers.dart';
import '../../../stories/repository/story_repository.dart';
import '../../providers/practice_providers.dart';

const _background = Color(0xFFF9F5FF);
const _ink = Color(0xFF171B2C);
const _purple = Color(0xFF7561E8);
const _orange = Color(0xFFFF7657);

class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(sharedThemeStoriesSeedProvider);
    final shared = ref.watch(sharedStoriesProvider);
    final personalized = ref.watch(personalizedStoriesProvider);
    final activity = ref.watch(storyActivityProvider);
    final isLoading =
        shared.isLoading || personalized.isLoading || activity.isLoading;

    if (isLoading) {
      return const ColoredBox(
        color: _background,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final hasError =
        shared.hasError || personalized.hasError || activity.hasError;
    if (hasError) {
      return _PracticeStatus(
        icon: Icons.cloud_off_rounded,
        message: 'We could not load your practice stories.',
        actionLabel: 'Try again',
        onAction: () {
          ref.invalidate(sharedStoriesProvider);
          ref.invalidate(personalizedStoriesProvider);
          ref.invalidate(storyActivityProvider);
        },
      );
    }

    final storiesById = <String, Story>{};
    final mia = ref.read(storyRepositoryProvider).getLocalStory(miaStoryId);
    if (mia != null) storiesById[mia.id] = mia;
    for (final story in [...?shared.value, ...?personalized.value]) {
      storiesById[story.id] = story;
    }
    final stories = storiesById.values.toList(growable: false);
    final completedIds = activity.value?.completedStoryIds ?? const <String>{};

    if (stories.isEmpty) {
      return const _PracticeStatus(
        icon: Icons.auto_stories_rounded,
        message: 'Read a story to unlock practice activities.',
      );
    }

    return ColoredBox(
      color: _background,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          key: const ValueKey('practice-screen'),
          slivers: [
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(24, 22, 24, 18),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Practice',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Try out choices from the stories you have read.',
                      style: TextStyle(
                        color: Color(0xFF707487),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              sliver: SliverList.separated(
                itemCount: stories.length,
                itemBuilder: (context, index) {
                  final story = stories[index];
                  final unlocked = completedIds.contains(story.id);
                  return _PracticeStoryCard(
                    story: story,
                    unlocked: unlocked,
                    onTap: () => unlocked
                        ? context.push(AppRoutes.practiceStoryPath(story.id))
                        : _showReadFirstDialog(context, story),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(height: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReadFirstDialog(BuildContext context, Story story) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('read-story-first-dialog'),
        title: const Text('Read this story first'),
        content: Text(
          'Finish “${story.title}” to unlock its practice activity.',
        ),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(),
            child: const Text('Not now'),
          ),
          FilledButton(
            key: const ValueKey('open-locked-story-button'),
            onPressed: () {
              dialogContext.pop();
              context.push(AppRoutes.storyPath(story.id));
            },
            child: const Text('Open story'),
          ),
        ],
      ),
    );
  }
}

class _PracticeStoryCard extends StatelessWidget {
  const _PracticeStoryCard({
    required this.story,
    required this.unlocked,
    required this.onTap,
  });

  final Story story;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = unlocked ? _ink : const Color(0xFF8A8790);
    return Material(
      color: unlocked ? Colors.white : const Color(0xFFE8E6EB),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('practice-story-${story.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: ColorFiltered(
                  colorFilter: unlocked
                      ? const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.dst,
                        )
                      : const ColorFilter.mode(
                          Color(0xFFB9B6BE),
                          BlendMode.saturation,
                        ),
                  child: StoryImage(
                    path: story.coverImagePath,
                    width: 72,
                    height: 72,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      story.category,
                      style: TextStyle(
                        color: unlocked ? _purple : const Color(0xFF8A8790),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (!unlocked) ...[
                      const SizedBox(height: 5),
                      const Text(
                        '🔒 Read first',
                        style: TextStyle(
                          color: Color(0xFF74717A),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                unlocked ? Icons.chevron_right_rounded : Icons.lock_rounded,
                color: const Color(0xFF9A8EB1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PracticeScenarioScreen extends ConsumerStatefulWidget {
  const PracticeScenarioScreen({super.key, required this.storyId});

  final String storyId;

  @override
  ConsumerState<PracticeScenarioScreen> createState() =>
      _PracticeScenarioScreenState();
}

class _PracticeScenarioScreenState
    extends ConsumerState<PracticeScenarioScreen> {
  String? _selectedActionId;
  bool _saving = false;

  Future<void> _tryAction(Story story) async {
    final actionId = _selectedActionId;
    if (actionId == null || _saving) return;
    setState(() => _saving = true);
    try {
      final userId = ref.read(currentUserProvider)?.uid;
      if (userId != null) {
        await ref
            .read(practiceRepositoryProvider)
            .saveChoice(userId: userId, storyId: story.id, actionId: actionId);
      }
      if (mounted) {
        context.push(AppRoutes.practiceFeedbackPath(story.id, actionId));
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('We could not save that choice. Please try again.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final storyState = ref.watch(storyProvider(widget.storyId));
    return storyState.when(
      loading: () => const _PracticeLoading(),
      error: (_, _) => _PracticeStoryError(storyId: widget.storyId),
      data: (story) {
        if (story == null) return const _PracticeNotFound();
        final scenario = story.practiceScenario;
        return ColoredBox(
          color: _background,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _PracticeHeader(
                  title: 'What would you do?',
                  onBack: () => context.pop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ScenarioArtwork(story: story, scenario: scenario),
                        const SizedBox(height: 18),
                        const _LumiEncouragement(),
                        const SizedBox(height: 24),
                        Text(
                          scenario.prompt,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 14),
                        for (
                          var index = 0;
                          index < scenario.actions.length;
                          index++
                        ) ...[
                          _ActionCard(
                            index: index,
                            action: scenario.actions[index],
                            selected:
                                _selectedActionId == scenario.actions[index].id,
                            onTap: () => setState(
                              () => _selectedActionId =
                                  scenario.actions[index].id,
                            ),
                          ),
                          if (index != scenario.actions.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: FilledButton(
                      key: const ValueKey('try-practice-action-button'),
                      onPressed: _selectedActionId == null || _saving
                          ? null
                          : () => _tryAction(story),
                      style: FilledButton.styleFrom(
                        backgroundColor: _orange,
                        disabledBackgroundColor: const Color(0xFFD8D2DC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Try it!  →',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PracticeFeedbackScreen extends ConsumerWidget {
  const PracticeFeedbackScreen({
    super.key,
    required this.storyId,
    required this.actionId,
  });

  final String storyId;
  final String actionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyState = ref.watch(storyProvider(storyId));
    return storyState.when(
      loading: () => const _PracticeLoading(),
      error: (_, _) => _PracticeStoryError(storyId: storyId),
      data: (story) {
        if (story == null) return const _PracticeNotFound();
        final actions = story.practiceScenario.actions;
        final action = actions.where((item) => item.id == actionId).firstOrNull;
        if (action == null) return const _PracticeNotFound();
        return ColoredBox(
          color: _background,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _PracticeHeader(
                  title: 'Here’s what happened',
                  onBack: () => context.pop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/lumie_celebrate_heart.png',
                          width: 170,
                          height: 170,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'That was a thoughtful choice! ✨',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _ink,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _FeedbackCard(
                          title: '${action.emoji} Your choice',
                          body: action.label,
                          color: const Color(0xFFE9E4FF),
                        ),
                        const SizedBox(height: 12),
                        _FeedbackCard(
                          title: 'Lumi says',
                          body: action.feedback,
                          color: const Color(0xFFFFD487),
                        ),
                        const SizedBox(height: 12),
                        _FeedbackCard(
                          title: 'What happened next',
                          body: action.outcome,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: const ValueKey('try-another-choice-button'),
                          onPressed: () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            foregroundColor: _purple,
                            side: const BorderSide(color: _purple),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                          ),
                          child: const Text('Try another'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          key: const ValueKey('finish-practice-button'),
                          onPressed: () => context.go(AppRoutes.practice),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            backgroundColor: _orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                          ),
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScenarioArtwork extends StatelessWidget {
  const _ScenarioArtwork({required this.story, required this.scenario});

  final Story story;
  final PracticeScenario scenario;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 1.35,
            child: StoryImage(path: story.coverImagePath),
          ),
          Positioned(
            left: 16,
            top: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                child: Text(
                  story.category.toUpperCase(),
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 42, 18, 18),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xD95B4CDD)],
                  ),
                ),
                child: Text(
                  scenario.situation,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LumiEncouragement extends StatelessWidget {
  const _LumiEncouragement();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD487),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          ClipOval(
            child: ColoredBox(
              color: Colors.white,
              child: Image.asset(
                'assets/images/lumi_fox.png',
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'There is no wrong answer! 💛',
              style: TextStyle(
                color: Color(0xFF3A2B14),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.index,
    required this.action,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final PracticeAction action;
  final bool selected;
  final VoidCallback onTap;

  static const _badgeColors = [
    Color(0xFF8074EE),
    Color(0xFFFFAD72),
    Color(0xFF6FD3B5),
    Color(0xFFEE9BC4),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: selected ? _purple : Colors.transparent,
          width: selected ? 2.5 : 0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('practice-action-${action.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: _badgeColors[index % _badgeColors.length],
                child: Text(
                  String.fromCharCode(65 + index),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  '${action.label} ${action.emoji}',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: _purple),
            ],
          ),
        ),
      ),
    );
  }
}

class _PracticeHeader extends StatelessWidget {
  const _PracticeHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Row(
        children: [
          IconButton.filled(
            tooltip: 'Back',
            onPressed: onBack,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _ink,
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.title,
    required this.body,
    required this.color,
  });

  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF4E4A59),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeLoading extends StatelessWidget {
  const _PracticeLoading();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: _background,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _PracticeStoryError extends ConsumerWidget {
  const _PracticeStoryError({required this.storyId});

  final String storyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _PracticeStatus(
      icon: Icons.cloud_off_rounded,
      message: 'We could not load this practice.',
      actionLabel: 'Try again',
      onAction: () {
        ref.invalidate(userStoryProvider(storyId));
        ref.invalidate(sharedStoryProvider(storyId));
      },
    );
  }
}

class _PracticeNotFound extends StatelessWidget {
  const _PracticeNotFound();

  @override
  Widget build(BuildContext context) {
    return const _PracticeStatus(
      icon: Icons.search_off_rounded,
      message: 'We could not find this practice.',
    );
  }
}

class _PracticeStatus extends StatelessWidget {
  const _PracticeStatus({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42, color: const Color(0xFF9A8EB1)),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF707487),
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 14),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
