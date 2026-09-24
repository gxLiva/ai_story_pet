import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/story.dart';
import '../../providers/story_providers.dart';
import '../widgets/lumie_celebration_overlay.dart';

class FeelingCheckScreen extends ConsumerStatefulWidget {
  const FeelingCheckScreen({
    super.key,
    required this.storyId,
    required this.checkId,
  });

  final String storyId;
  final String checkId;

  @override
  ConsumerState<FeelingCheckScreen> createState() => _FeelingCheckScreenState();
}

class _FeelingCheckScreenState extends ConsumerState<FeelingCheckScreen> {
  static const _purple = Color(0xFF7561E8);
  static const _celebrations = [
    LumieCelebration(
      imagePath: 'assets/images/lumie_celebrate_jump.png',
      message: 'You did it!',
    ),
    LumieCelebration(
      imagePath: 'assets/images/lumie_celebrate_proud.png',
      message: 'Wonderful thinking!',
    ),
    LumieCelebration(
      imagePath: 'assets/images/lumie_celebrate_detective.png',
      message: 'Great noticing!',
    ),
    LumieCelebration(
      imagePath: 'assets/images/lumie_celebrate_heart.png',
      message: 'You understood the feeling!',
    ),
  ];
  String? _feedback;

  Future<void> _showCelebration() async {
    await showLumieCelebrationOverlay(
      context: context,
      celebration: pickRandomCelebration(_celebrations),
      dismissLabel: 'click anywhere to resume reading',
      overlayKey: const ValueKey('feeling-check-success-overlay'),
      imageKey: const ValueKey('feeling-check-success-image'),
      messageKey: const ValueKey('feeling-check-success-message'),
    );

    if (mounted) context.pop();
  }

  FeelingCheck? _findCheck(Story story) {
    for (final page in story.pages) {
      if (page.feelingCheck?.id == widget.checkId) {
        return page.feelingCheck;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final story = ref.watch(storyProvider(widget.storyId));
    final check = story == null ? null : _findCheck(story);
    if (check == null) {
      return Scaffold(
        body: Center(
          child: TextButton(
            onPressed: context.pop,
            child: const Text('Return to story'),
          ),
        ),
      );
    }

    final readingState = ref.watch(storyReadingProvider);
    final notifier = ref.read(storyReadingProvider.notifier);
    final canSubmit = notifier.hasAnsweredEveryQuestion(check);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F3FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back to story',
          onPressed: context.pop,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Column(
          children: [
            Text(
              'FEELING CHECK',
              style: TextStyle(
                color: _purple,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'Answer both questions',
              style: TextStyle(
                color: Color(0xFF171B2C),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF8975ED),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage('assets/images/lumi_fox.png'),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        '${check.title} 🤔',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  check.quote,
                  style: const TextStyle(
                    color: Color(0xFF272B3A),
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              for (final question in check.questions) ...[
                const SizedBox(height: 26),
                Text(
                  question.prompt,
                  style: const TextStyle(
                    color: Color(0xFF34384A),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final option in question.options)
                      _AnswerOption(
                        key: ValueKey('answer-${question.id}-${option.id}'),
                        option: option,
                        isSelected:
                            readingState.selectedAnswers[question.id] ==
                            option.id,
                        onTap: () {
                          notifier.selectAnswer(question.id, option.id);
                          setState(() => _feedback = null);
                        },
                      ),
                  ],
                ),
              ],
              if (_feedback != null) ...[
                const SizedBox(height: 20),
                _LumieFeedbackBubble(
                  key: const ValueKey('feeling-check-feedback'),
                  message: _feedback!,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  key: const ValueKey('submit-feeling-check'),
                  onPressed: canSubmit
                      ? () async {
                          final isCorrect = notifier.submitFeelingCheck(check);
                          if (isCorrect) {
                            await _showCelebration();
                          } else {
                            setState(() {
                              _feedback =
                                  'Hmm, not quite—but that was a thoughtful try! '
                                  'Look at how Mia’s body feels, then give it another go. '
                                  'You’ve got this! 💜';
                            });
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFD5CDEF),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Text('Submit answers'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LumieFeedbackBubble extends StatelessWidget {
  const _LumieFeedbackBubble({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.94, end: 1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          alignment: Alignment.bottomLeft,
          child: Opacity(opacity: scale.clamp(0, 1), child: child),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 52,
              height: 52,
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
            const SizedBox(width: 12),
            Expanded(
              child: Stack(
                children: [
                  Positioned(
                    top: 2,
                    left: 36,
                    child: Transform.rotate(
                      angle: 0.7853981634,
                      child: Container(
                        width: 18,
                        height: 18,
                        color: _FeelingCheckScreenState._purple,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: _FeelingCheckScreenState._purple,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
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

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final FeelingOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFFE6DFFF) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minWidth: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? _FeelingCheckScreenState._purple
                  : const Color(0xFFE4DEEF),
              width: isSelected ? 3 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(option.emoji, style: const TextStyle(fontSize: 25)),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  option.label,
                  style: const TextStyle(
                    color: Color(0xFF34384A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
