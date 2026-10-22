import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../stories/models/story.dart';
import '../../../stories/presentation/widgets/story_image.dart';
import '../../../stories/providers/story_providers.dart';

const libraryThemes = <LibraryTheme>[
  LibraryTheme(
    title: 'Friendship',
    description: 'Kindness, sharing, and connecting with others.',
    icon: Icons.people_alt_rounded,
    color: Color(0xFFFFD9B8),
  ),
  LibraryTheme(
    title: 'Big Feelings',
    description: 'Understand and navigate strong emotions.',
    icon: Icons.favorite_rounded,
    color: Color(0xFFFFCFE0),
  ),
  LibraryTheme(
    title: 'Transition',
    description: 'Feel steadier through changes and new experiences.',
    icon: Icons.autorenew_rounded,
    color: Color(0xFFCFEDE5),
  ),
  LibraryTheme(
    title: 'Courage',
    description: 'Try brave things and grow confidence.',
    icon: Icons.shield_rounded,
    color: Color(0xFFDCD5FF),
  ),
];

class LibraryTheme {
  const LibraryTheme({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
}

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeSeed = ref.watch(sharedThemeStoriesSeedProvider);
    final sharedStories = ref.watch(sharedStoriesProvider);
    final personalizedStories = ref.watch(personalizedStoriesProvider);
    final normalizedQuery = _query.trim().toLowerCase();
    final searchResults =
        sharedStories.asData?.value
            .where(
              (story) => story.title.toLowerCase().contains(normalizedQuery),
            )
            .toList(growable: false) ??
        const <Story>[];

    return ColoredBox(
      color: const Color(0xFFF9F5FF),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          key: const ValueKey('library-screen'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Library',
                      style: TextStyle(
                        color: Color(0xFF111626),
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Find a story for every kind of moment.',
                      style: TextStyle(
                        color: Color(0xFF707487),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      key: const ValueKey('library-title-search'),
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search by story title',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: normalizedQuery.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _searchController.clear();
                                  FocusScope.of(context).unfocus();
                                  setState(() => _query = '');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (normalizedQuery.isNotEmpty)
              _SearchResultsSliver(
                stories: searchResults,
                isLoading:
                    sharedStories.isLoading ||
                    (sharedStories.asData?.value.isEmpty ?? true) &&
                        themeSeed.isLoading,
                hasError:
                    sharedStories.hasError ||
                    (sharedStories.asData?.value.isEmpty ?? true) &&
                        themeSeed.hasError,
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle('Browse by theme'),
                      const SizedBox(height: 14),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: libraryThemes.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.9,
                            ),
                        itemBuilder: (context, index) {
                          final theme = libraryThemes[index];
                          return _ThemeCard(
                            theme: theme,
                            onTap: () => context.push(
                              AppRoutes.libraryThemePath(theme.title),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 32),
                sliver: SliverToBoxAdapter(
                  child: _PersonalizedStorySection(
                    stories: personalizedStories,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LibraryStoryCollectionScreen extends ConsumerWidget {
  const LibraryStoryCollectionScreen.theme({super.key, required this.theme})
    : personalized = false;

  const LibraryStoryCollectionScreen.personalized({super.key})
    : theme = null,
      personalized = true;

  final String? theme;
  final bool personalized;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSeed = personalized
        ? const AsyncValue<void>.data(null)
        : ref.watch(sharedThemeStoriesSeedProvider);
    final state = personalized
        ? ref.watch(personalizedStoriesProvider)
        : ref.watch(sharedStoriesProvider);
    final stories =
        state.asData?.value
            .where(
              (story) =>
                  personalized ||
                  story.category.toLowerCase() == theme!.toLowerCase(),
            )
            .toList(growable: false) ??
        const <Story>[];
    final title = personalized ? 'My stories' : theme!;

    return ColoredBox(
      color: const Color(0xFFF9F5FF),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: const Color(0xFFF9F5FF),
              foregroundColor: const Color(0xFF111626),
              surfaceTintColor: Colors.transparent,
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            if (stories.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                sliver: SliverList.separated(
                  itemCount: stories.length,
                  itemBuilder: (context, index) =>
                      LibraryStoryListCard(story: stories[index]),
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                ),
              )
            else if (state.isLoading || themeSeed.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.hasError || themeSeed.hasError)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _LibraryMessage(
                  icon: Icons.cloud_off_rounded,
                  message: 'We could not load these stories.',
                  actionLabel: 'Try again',
                  onAction: () {
                    ref.invalidate(sharedStoriesProvider);
                    ref.invalidate(sharedThemeStoriesSeedProvider);
                  },
                ),
              )
            else if (stories.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _LibraryMessage(
                  icon: Icons.auto_stories_rounded,
                  message: personalized
                      ? 'Your personalized stories will appear here.'
                      : 'No stories found.',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultsSliver extends StatelessWidget {
  const _SearchResultsSliver({
    required this.stories,
    required this.isLoading,
    required this.hasError,
  });

  final List<Story> stories;
  final bool isLoading;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (hasError) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: _LibraryMessage(
          icon: Icons.cloud_off_rounded,
          message: 'We could not search the library.',
        ),
      );
    }
    if (stories.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: _LibraryMessage(
          icon: Icons.search_off_rounded,
          message: 'Cannot find story.',
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      sliver: SliverList.separated(
        itemCount: stories.length,
        itemBuilder: (context, index) =>
            LibraryStoryListCard(story: stories[index]),
        separatorBuilder: (_, _) => const SizedBox(height: 12),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({required this.theme, required this.onTap});

  final LibraryTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.color,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('library-theme-${theme.title.toLowerCase()}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(theme.icon, color: const Color(0xFF4C3C69), size: 28),
              const Spacer(),
              Text(
                theme.title,
                style: const TextStyle(
                  color: Color(0xFF2A2138),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                theme.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF655B71),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonalizedStorySection extends StatefulWidget {
  const _PersonalizedStorySection({required this.stories});

  final AsyncValue<List<Story>> stories;

  @override
  State<_PersonalizedStorySection> createState() =>
      _PersonalizedStorySectionState();
}

class _PersonalizedStorySectionState extends State<_PersonalizedStorySection> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.84);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stories = widget.stories;
    final items =
        stories.asData?.value.take(3).toList(growable: false) ??
        const <Story>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Made just for you ✨'),
        const SizedBox(height: 14),
        if (stories.isLoading)
          const SizedBox(
            height: 250,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (stories.hasError)
          const SizedBox(
            height: 180,
            child: _LibraryMessage(
              icon: Icons.cloud_off_rounded,
              message: 'We could not load your stories.',
            ),
          )
        else if (items.isEmpty)
          const SizedBox(
            height: 180,
            child: _LibraryMessage(
              icon: Icons.auto_awesome_rounded,
              message: 'Stories made for you will appear here.',
            ),
          )
        else
          SizedBox(
            height: 270,
            child: PageView.builder(
              key: const ValueKey('personalized-story-carousel'),
              controller: _controller,
              padEnds: false,
              itemCount: items.length,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(
                  right: index == items.length - 1 ? 0 : 12,
                ),
                child: _CarouselStoryCard(story: items[index]),
              ),
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const ValueKey('view-all-personalized-stories'),
            onPressed: () => context.push(AppRoutes.libraryPersonalized),
            icon: const Icon(Icons.auto_stories_rounded),
            label: const Text('View all my stories'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF5B4CDD),
              side: const BorderSide(color: Color(0xFFC9C0F4)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _CarouselStoryCard extends StatelessWidget {
  const _CarouselStoryCard({required this.story});

  final Story story;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('personalized-carousel-${story.id}'),
        onTap: () => context.push(AppRoutes.storyPath(story.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: StoryImage(path: story.coverImagePath),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.category.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF7561E8),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    story.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF111626),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${story.pages.length} pages • ${story.readingTimeMinutes.clamp(1, 99)} min read',
                    style: const TextStyle(
                      color: Color(0xFF707487),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LibraryStoryListCard extends StatelessWidget {
  const LibraryStoryListCard({super.key, required this.story});

  final Story story;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('library-story-${story.id}'),
        onTap: () => context.push(AppRoutes.storyPath(story.id)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: StoryImage(
                  path: story.coverImagePath,
                  width: 84,
                  height: 104,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.category.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF7561E8),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      story.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF111626),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      story.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF707487),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9A8EB1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF111626),
        fontSize: 21,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.3,
      ),
    );
  }
}

class _LibraryMessage extends StatelessWidget {
  const _LibraryMessage({
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 38, color: const Color(0xFF9A8EB1)),
            const SizedBox(height: 10),
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
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
