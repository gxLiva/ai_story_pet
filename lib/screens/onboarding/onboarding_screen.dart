import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_router.dart';
import '../../providers/auth_providers.dart';
import '../../providers/user_profile_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _background = Color(0xFFF8F2FF);
  static const _ink = Color(0xFF18203A);
  static const _muted = Color(0xFF8A8EAD);
  static const _purple = Color(0xFF7561E8);
  static const _border = Color(0xFFE5E4F5);

  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _customGoalController = TextEditingController();
  final _otherHobbyController = TextEditingController();

  final Set<String> _readingGoals = {};
  final Set<String> _hobbies = {};
  final Set<String> _customReadingGoals = {};
  final Set<String> _customHobbies = {};
  String? _gender;
  String? _customGoalError;
  String? _customHobbyError;
  bool _showChoiceErrors = false;
  bool _isSubmitting = false;
  bool _isLeaving = false;
  String? _submissionError;

  static const _genderOptions = [
    'Male',
    'Female',
    'Others',
    'Would not like to share',
  ];

  @override
  void dispose() {
    _ageController.dispose();
    _customGoalController.dispose();
    _otherHobbyController.dispose();
    super.dispose();
  }

  String get _firstName {
    final displayName = ref.watch(currentUserProvider)?.displayName?.trim();
    if (displayName == null || displayName.isEmpty) {
      return 'Reader';
    }
    return displayName.split(RegExp(r'\s+')).first;
  }

  void _toggleChoice(Set<String> choices, String value) {
    setState(() {
      choices.contains(value) ? choices.remove(value) : choices.add(value);
      _showChoiceErrors = false;
    });
  }

  void _addCustomChoice({
    required TextEditingController controller,
    required Set<String> choices,
    required bool isGoal,
  }) {
    final value = controller.text.trim();
    if (value.isEmpty) return;

    if (choices.length >= 3) {
      setState(() {
        if (isGoal) {
          _customGoalError = 'You can add up to 3 custom reading goals.';
        } else {
          _customHobbyError = 'You can add up to 3 custom hobbies.';
        }
      });
      return;
    }

    final isDuplicate = choices.any(
      (choice) => choice.toLowerCase() == value.toLowerCase(),
    );
    setState(() {
      if (!isDuplicate) choices.add(value);
      controller.clear();
      _showChoiceErrors = false;
      if (isGoal) {
        _customGoalError = null;
      } else {
        _customHobbyError = null;
      }
    });
  }

  void _removeCustomChoice({
    required Set<String> choices,
    required String value,
    required bool isGoal,
  }) {
    setState(() {
      choices.remove(value);
      if (isGoal) {
        _customGoalError = null;
      } else {
        _customHobbyError = null;
      }
    });
  }

  String? _validateAge(String? value) {
    final age = int.tryParse(value?.trim() ?? '');
    if (age == null) return 'Please enter an age.';
    if (age < 3 || age > 18) return 'Please enter an age from 3 to 18.';
    return null;
  }

  Future<void> _confirmLeave() async {
    if (_isLeaving || _isSubmitting) return;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Leave onboarding?'),
          content: const Text(
            'Your account has been created, but these details have not been '
            'saved. You will be signed out.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );

    if (shouldLeave != true || !mounted) return;

    setState(() => _isLeaving = true);
    try {
      await ref.read(authRepositoryProvider).logOut();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLeaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We could not sign you out. Please try again.'),
        ),
      );
    }
  }

  Future<void> _continue() async {
    if (_isSubmitting) return;

    FocusScope.of(context).unfocus();
    final formIsValid = _formKey.currentState?.validate() ?? false;
    final hasReadingGoal =
        _readingGoals.isNotEmpty || _customReadingGoals.isNotEmpty;
    final hasHobby = _hobbies.isNotEmpty || _customHobbies.isNotEmpty;

    setState(() => _showChoiceErrors = !hasReadingGoal || !hasHobby);

    if (!formIsValid || !hasReadingGoal || !hasHobby) return;

    final user = ref.read(currentUserProvider);
    if (user == null || _gender == null) return;

    final profileRepository = ref.read(userProfileRepositoryProvider);
    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });

    try {
      await profileRepository.completeOnboarding(
        userId: user.uid,
        age: int.parse(_ageController.text.trim()),
        gender: _gender!,
        readingGoals: [..._readingGoals, ..._customReadingGoals],
        hobbies: [..._hobbies, ..._customHobbies],
      );

      if (mounted) context.go(AppRoutes.home);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submissionError = 'We could not save these details. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: _background,
        body: Stack(
          children: [
            const Positioned(
              top: 30,
              right: -92,
              child: _BackgroundCircle(size: 250, color: Color(0xFFEDE4FF)),
            ),
            const Positioned(
              top: 122,
              left: -102,
              child: _BackgroundCircle(size: 220, color: Color(0xFFE9DEFF)),
            ),
            const Positioned(
              right: -72,
              bottom: 95,
              child: _BackgroundCircle(size: 155, color: Color(0xFFFFE5B7)),
            ),
            const Positioned(
              left: -70,
              bottom: -35,
              child: _BackgroundCircle(size: 150, color: Color(0xFFD9F5E9)),
            ),
            SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BackButton(onPressed: _confirmLeave),
                      const SizedBox(height: 38),
                      Text(
                        'Tell Lumi\nabout $_firstName',
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 42,
                          fontWeight: FontWeight.w400,
                          height: 1.08,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'A few details help Lumi choose calmer\nstories and practice moments.',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _LumiMessage(name: _firstName),
                      const SizedBox(height: 18),
                      _FormCard(
                        ageController: _ageController,
                        gender: _gender,
                        genderOptions: _genderOptions,
                        onGenderChanged: (value) =>
                            setState(() => _gender = value),
                        validateAge: _validateAge,
                        readingGoals: _readingGoals,
                        onReadingGoalTap: (value) =>
                            _toggleChoice(_readingGoals, value),
                        customGoalController: _customGoalController,
                        customReadingGoals: _customReadingGoals,
                        customGoalError: _customGoalError,
                        onCustomGoalSubmitted: (_) => _addCustomChoice(
                          controller: _customGoalController,
                          choices: _customReadingGoals,
                          isGoal: true,
                        ),
                        onCustomGoalRemoved: (value) => _removeCustomChoice(
                          choices: _customReadingGoals,
                          value: value,
                          isGoal: true,
                        ),
                        hobbies: _hobbies,
                        onHobbyTap: (value) => _toggleChoice(_hobbies, value),
                        otherHobbyController: _otherHobbyController,
                        customHobbies: _customHobbies,
                        customHobbyError: _customHobbyError,
                        onCustomHobbySubmitted: (_) => _addCustomChoice(
                          controller: _otherHobbyController,
                          choices: _customHobbies,
                          isGoal: false,
                        ),
                        onCustomHobbyRemoved: (value) => _removeCustomChoice(
                          choices: _customHobbies,
                          value: value,
                          isGoal: false,
                        ),
                        showGoalError:
                            _showChoiceErrors &&
                            _readingGoals.isEmpty &&
                            _customGoalController.text.trim().isEmpty,
                        showHobbyError:
                            _showChoiceErrors &&
                            _hobbies.isEmpty &&
                            _otherHobbyController.text.trim().isEmpty,
                        name: _firstName,
                        onContinue: _continue,
                        isSubmitting: _isSubmitting,
                        submissionError: _submissionError,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LumiMessage extends StatelessWidget {
  const _LumiMessage({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8E6F5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12765DE8),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 78,
            height: 78,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E8),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFF2CC70), width: 3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: const Image(
                image: AssetImage('assets/images/lumi_fox.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi $name, I’ll remember this.',
                  style: const TextStyle(
                    color: _OnboardingScreenState._ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Grown-ups can update it anytime.',
                  style: TextStyle(
                    color: _OnboardingScreenState._muted,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.ageController,
    required this.gender,
    required this.genderOptions,
    required this.onGenderChanged,
    required this.validateAge,
    required this.readingGoals,
    required this.onReadingGoalTap,
    required this.customGoalController,
    required this.customReadingGoals,
    required this.customGoalError,
    required this.onCustomGoalSubmitted,
    required this.onCustomGoalRemoved,
    required this.hobbies,
    required this.onHobbyTap,
    required this.otherHobbyController,
    required this.customHobbies,
    required this.customHobbyError,
    required this.onCustomHobbySubmitted,
    required this.onCustomHobbyRemoved,
    required this.showGoalError,
    required this.showHobbyError,
    required this.name,
    required this.onContinue,
    required this.isSubmitting,
    required this.submissionError,
  });

  final TextEditingController ageController;
  final String? gender;
  final List<String> genderOptions;
  final ValueChanged<String?> onGenderChanged;
  final FormFieldValidator<String> validateAge;
  final Set<String> readingGoals;
  final ValueChanged<String> onReadingGoalTap;
  final TextEditingController customGoalController;
  final Set<String> customReadingGoals;
  final String? customGoalError;
  final ValueChanged<String> onCustomGoalSubmitted;
  final ValueChanged<String> onCustomGoalRemoved;
  final Set<String> hobbies;
  final ValueChanged<String> onHobbyTap;
  final TextEditingController otherHobbyController;
  final Set<String> customHobbies;
  final String? customHobbyError;
  final ValueChanged<String> onCustomHobbySubmitted;
  final ValueChanged<String> onCustomHobbyRemoved;
  final bool showGoalError;
  final bool showHobbyError;
  final String name;
  final VoidCallback onContinue;
  final bool isSubmitting;
  final String? submissionError;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE4E3F1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14765DE8),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel('Age'),
          const SizedBox(height: 9),
          TextFormField(
            controller: ageController,
            validator: validateAge,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              hintText: 'Age',
              prefixIcon: const _RoundIcon(
                icon: Icons.cake_rounded,
                color: Color(0xFFA56A00),
                background: Color(0xFFFFEDC5),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const _FieldLabel('Gender'),
          const SizedBox(height: 9),
          DropdownButtonFormField<String>(
            initialValue: gender,
            isExpanded: true,
            validator: (value) =>
                value == null ? 'Please select an option.' : null,
            decoration: _inputDecoration(
              hintText: 'Select an option',
              prefixIcon: const _RoundIcon(
                icon: Icons.person_rounded,
                color: _OnboardingScreenState._purple,
                background: Color(0xFFE9E2FF),
              ),
            ),
            borderRadius: BorderRadius.circular(18),
            items: genderOptions
                .map(
                  (option) =>
                      DropdownMenuItem(value: option, child: Text(option)),
                )
                .toList(),
            onChanged: onGenderChanged,
          ),
          const SizedBox(height: 24),
          const _FieldLabel('Reading goal'),
          const SizedBox(height: 11),
          _ChoiceGrid(
            choices: const [
              _Choice(
                'Read every day',
                Icons.calendar_month_rounded,
                Color(0xFF7C62E8),
                Color(0xFFE9E1FF),
              ),
              _Choice(
                'Practice feelings',
                Icons.favorite_rounded,
                Color(0xFF35B986),
                Color(0xFFDDF4E9),
              ),
              _Choice(
                'Make friends',
                Icons.group_rounded,
                Color(0xFF4C84E8),
                Color(0xFFE2ECFF),
              ),
              _Choice(
                'Try my own goal',
                Icons.edit_rounded,
                Color(0xFFFF8A3D),
                Color(0xFFFFE7D8),
              ),
            ],
            selected: readingGoals,
            onTap: onReadingGoalTap,
          ),
          const SizedBox(height: 12),
          if (customReadingGoals.isNotEmpty) ...[
            _CustomChoiceLabels(
              choices: customReadingGoals,
              onRemoved: onCustomGoalRemoved,
              color: const Color(0xFF7C62E8),
              background: const Color(0xFFE9E1FF),
              icon: Icons.edit_rounded,
            ),
            const SizedBox(height: 10),
          ],
          TextFormField(
            controller: customGoalController,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: onCustomGoalSubmitted,
            decoration: _inputDecoration(
              hintText: 'Write a goal and press Enter',
              prefixIcon: const Icon(
                Icons.edit_outlined,
                color: Color(0xFFA8ABC8),
              ),
            ),
          ),
          if (customGoalError != null) _ChoiceError(customGoalError!),
          if (showGoalError)
            const _ChoiceError('Choose or write a reading goal.'),
          const SizedBox(height: 24),
          const _FieldLabel('Hobbies'),
          const SizedBox(height: 11),
          _ChoiceGrid(
            choices: const [
              _Choice(
                'Writing',
                Icons.draw_rounded,
                Color(0xFF7C62E8),
                Color(0xFFE9E1FF),
              ),
              _Choice(
                'Exercise',
                Icons.directions_run_rounded,
                Color(0xFFFF765F),
                Color(0xFFFFE3DE),
              ),
              _Choice(
                'Hiking',
                Icons.landscape_rounded,
                Color(0xFF35A978),
                Color(0xFFDDF4E9),
              ),
              _Choice(
                'Movies',
                Icons.movie_rounded,
                Color(0xFF4C84E8),
                Color(0xFFE2ECFF),
              ),
            ],
            selected: hobbies,
            onTap: onHobbyTap,
          ),
          const SizedBox(height: 12),
          if (customHobbies.isNotEmpty) ...[
            _CustomChoiceLabels(
              choices: customHobbies,
              onRemoved: onCustomHobbyRemoved,
              color: const Color(0xFF35A978),
              background: const Color(0xFFDDF4E9),
              icon: Icons.star_rounded,
            ),
            const SizedBox(height: 10),
          ],
          TextFormField(
            controller: otherHobbyController,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: onCustomHobbySubmitted,
            decoration: _inputDecoration(
              hintText: 'Add a hobby and press Enter',
              prefixIcon: const Icon(
                Icons.add_rounded,
                color: Color(0xFFA8ABC8),
              ),
            ),
          ),
          if (customHobbyError != null) _ChoiceError(customHobbyError!),
          if (showHobbyError)
            const _ChoiceError('Choose or write at least one hobby.'),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF0E8FF), Color(0xFFF8E9FA)],
              ),
              borderRadius: BorderRadius.circular(21),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 23,
                  backgroundColor: Color(0xFF8B79ED),
                  child: Icon(
                    Icons.star_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Lumi will use these details to choose stories for $name.',
                    style: const TextStyle(
                      color: Color(0xFF555A79),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8468EF), Color(0xFF654EDB)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: ElevatedButton(
                onPressed: isSubmitting ? null : onContinue,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Continue'),
              ),
            ),
          ),
          if (submissionError != null) ...[
            const SizedBox(height: 12),
            Text(
              submissionError!,
              style: const TextStyle(
                color: Color(0xFFB3261E),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required Widget prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFFA8ABC8)),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(
          color: _OnboardingScreenState._border,
          width: 2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(
          color: _OnboardingScreenState._border,
          width: 2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(
          color: _OnboardingScreenState._purple,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: Color(0xFFB3261E)),
      ),
    );
  }
}

class _ChoiceGrid extends StatelessWidget {
  const _ChoiceGrid({
    required this.choices,
    required this.selected,
    required this.onTap,
  });
  final List<_Choice> choices;
  final Set<String> selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: choices.map((choice) {
            final isSelected = selected.contains(choice.label);
            return SizedBox(
              width: width,
              height: 64,
              child: InkWell(
                onTap: () => onTap(choice.label),
                borderRadius: BorderRadius.circular(22),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? choice.background.withValues(alpha: 0.7)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected
                          ? choice.color
                          : _OnboardingScreenState._border,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      _RoundIcon(
                        icon: choice.icon,
                        color: choice.color,
                        background: choice.background,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          choice.label,
                          style: const TextStyle(
                            color: Color(0xFF555A79),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _CustomChoiceLabels extends StatelessWidget {
  const _CustomChoiceLabels({
    required this.choices,
    required this.onRemoved,
    required this.color,
    required this.background,
    required this.icon,
  });

  final Set<String> choices;
  final ValueChanged<String> onRemoved;
  final Color color;
  final Color background;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: choices.map((choice) {
            return SizedBox(
              key: ValueKey('custom-choice-$choice'),
              width: width,
              height: 64,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: background.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: color, width: 2),
                ),
                child: Row(
                  children: [
                    _RoundIcon(
                      icon: icon,
                      color: color,
                      background: background,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        choice,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF555A79),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onRemoved(choice),
                      tooltip: 'Remove $choice',
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 30,
                        minHeight: 30,
                      ),
                      icon: Icon(Icons.close_rounded, color: color, size: 18),
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _Choice {
  const _Choice(this.label, this.icon, this.color, this.background);
  final String label;
  final IconData icon;
  final Color color;
  final Color background;
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.icon,
    required this.color,
    required this.background,
  });
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: background,
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF777C9D),
      fontSize: 17,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _ChoiceError extends StatelessWidget {
  const _ChoiceError(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 12, top: 7),
    child: Text(
      text,
      style: const TextStyle(color: Color(0xFFB3261E), fontSize: 12),
    ),
  );
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        tooltip: 'Back',
        padding: const EdgeInsets.all(14),
        icon: const Icon(
          Icons.chevron_left_rounded,
          color: _OnboardingScreenState._purple,
          size: 34,
        ),
      ),
    );
  }
}

class _BackgroundCircle extends StatelessWidget {
  const _BackgroundCircle({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
