import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../providers/story_providers.dart';

class StoryScreen extends ConsumerWidget {
  const StoryScreen({super.key, required this.storyId});

  final String storyId;

  static const _background = Color(0xFFF9F5FF);
  static const _purple = Color(0xFF7561E8);
  static const _ink = Color(0xFF171B2C);

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final story = ref.watch(storyProvider(storyId));
    if (story == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('We could not find that story.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _close(context),
                child: const Text('Return home'),
              ),
            ],
          ),
        ),
      );
    }

    final readingState = ref.watch(storyReadingProvider);
    final pageIndex = readingState.currentPageIndex.clamp(
      0,
      story.pages.length - 1,
    );
    final page = story.pages[pageIndex];
    final readingNotifier = ref.read(storyReadingProvider.notifier);
    final canGoNext = readingNotifier.canLeavePage(page);
    final isLastPage = pageIndex == story.pages.length - 1;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  _CircleButton(
                    tooltip: 'Exit story',
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => _close(context),
                  ),
                  Expanded(
                    child: Text(
                      story.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            _StoryProgressIndicator(
              currentPageIndex: pageIndex,
              pageCount: story.pages.length,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: AspectRatio(
                        aspectRatio: 1.15,
                        child: Image.asset(page.imagePath, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: _StoryPageText(
                        key: const ValueKey('story-page-text'),
                        text: page.text,
                        focusPhrase: page.feelingCheck?.focusPhrase,
                      ),
                    ),
                    if (page.feelingCheck != null) ...[
                      const SizedBox(height: 16),
                      _FeelingPrompt(
                        title: page.feelingCheck!.title,
                        focusPhrase: page.feelingCheck!.focusPhrase,
                        isCompleted: readingState.completedFeelingCheckIds
                            .contains(page.feelingCheck!.id),
                        onTap: () => context.push(
                          AppRoutes.feelingCheckPath(
                            story.id,
                            page.feelingCheck!.id,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PageNavigationButton(
                    key: const ValueKey('previous-page-button'),
                    tooltip: 'Previous page',
                    icon: Icons.arrow_back_rounded,
                    roundedEdge: _RoundedEdge.left,
                    onPressed: pageIndex == 0
                        ? null
                        : readingNotifier.previousPage,
                  ),
                  const SizedBox(width: 12),
                  _PageNavigationButton(
                    key: const ValueKey('next-page-button'),
                    tooltip: isLastPage ? 'Finish story' : 'Next page',
                    icon: Icons.arrow_forward_rounded,
                    roundedEdge: _RoundedEdge.right,
                    onPressed: canGoNext
                        ? () {
                            if (isLastPage) {
                              context.go(AppRoutes.home);
                            } else {
                              readingNotifier.nextPage(story);
                            }
                          }
                        : null,
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

class _StoryPageText extends StatelessWidget {
  const _StoryPageText({
    super.key,
    required this.text,
    required this.focusPhrase,
  });

  final String text;
  final String? focusPhrase;

  static const _style = TextStyle(
    color: StoryScreen._ink,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  @override
  Widget build(BuildContext context) {
    final phrase = focusPhrase;
    if (phrase == null || phrase.isEmpty) {
      return Text(text, style: _style);
    }

    final phraseStart = text.toLowerCase().indexOf(phrase.toLowerCase());
    if (phraseStart == -1) {
      return Text(text, style: _style);
    }

    final phraseEnd = phraseStart + phrase.length;
    return Text.rich(
      TextSpan(
        style: _style,
        children: [
          TextSpan(text: text.substring(0, phraseStart)),
          TextSpan(
            text: text.substring(phraseStart, phraseEnd),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFFFFD59A),
              decorationThickness: 5,
            ),
          ),
          TextSpan(text: text.substring(phraseEnd)),
        ],
      ),
    );
  }
}

class _StoryProgressIndicator extends StatelessWidget {
  const _StoryProgressIndicator({
    required this.currentPageIndex,
    required this.pageCount,
  });

  final int currentPageIndex;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < pageCount; index++) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: index == currentPageIndex ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: index == currentPageIndex
                  ? StoryScreen._purple
                  : const Color(0xFFD9D0FF),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          if (index < pageCount - 1) const SizedBox(width: 6),
        ],
        const SizedBox(width: 16),
        Text(
          '${currentPageIndex + 1} / $pageCount',
          key: const ValueKey('story-page-indicator'),
          style: const TextStyle(
            color: Color(0xFF9D96B0),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

enum _RoundedEdge { left, right }

class _PageNavigationButton extends StatelessWidget {
  const _PageNavigationButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.roundedEdge,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final _RoundedEdge roundedEdge;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    const outerRadius = Radius.circular(27);
    final borderRadius = roundedEdge == _RoundedEdge.left
        ? const BorderRadius.only(topLeft: outerRadius, bottomLeft: outerRadius)
        : const BorderRadius.only(
            topRight: outerRadius,
            bottomRight: outerRadius,
          );

    return SizedBox(
      width: 96,
      height: 54,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 30),
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? StoryScreen._purple.withValues(alpha: 0.38)
                : StoryScreen._purple,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? StoryScreen._purple.withValues(alpha: 0.12)
                : StoryScreen._purple.withValues(alpha: 0.30),
          ),
          overlayColor: WidgetStatePropertyAll(
            StoryScreen._purple.withValues(alpha: 0.10),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: borderRadius),
          ),
        ),
      ),
    );
  }
}

class _FeelingPrompt extends StatelessWidget {
  const _FeelingPrompt({
    required this.title,
    required this.focusPhrase,
    required this.isCompleted,
    required this.onTap,
  });

  final String title;
  final String focusPhrase;
  final bool isCompleted;
  final VoidCallback onTap;

  Widget _promptText() {
    const style = TextStyle(
      color: Colors.white,
      fontSize: 17,
      fontWeight: FontWeight.w800,
    );
    if (isCompleted) {
      return const Text('Feeling Check complete!', style: style);
    }

    final phraseStart = title.toLowerCase().indexOf(focusPhrase.toLowerCase());
    if (phraseStart == -1) {
      return Text('$title 🤔', style: style);
    }

    final phraseEnd = phraseStart + focusPhrase.length;
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: title.substring(0, phraseStart)),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(title.substring(phraseStart, phraseEnd), style: style),
            ),
          ),
          TextSpan(text: '${title.substring(phraseEnd)} 🤔'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 54,
          height: 54,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const CircleAvatar(
            backgroundImage: AssetImage('assets/images/lumi_fox.png'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Stack(
            children: [
              Positioned(
                top: 2,
                left: 42,
                child: Transform.rotate(
                  angle: 0.7853981634,
                  child: Container(
                    width: 18,
                    height: 18,
                    color: StoryScreen._purple,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Material(
                  color: StoryScreen._purple,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    key: const ValueKey('feeling-check-prompt'),
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 18,
                      ),
                      child: _promptText(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        color: StoryScreen._purple,
        icon: Icon(icon),
      ),
    );
  }
}
