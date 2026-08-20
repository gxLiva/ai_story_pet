import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _background = Color(0xFFF8F2FF);
  static const Color _ink = Color(0xFF151A2D);
  static const Color _muted = Color(0xFF707487);
  static const Color _purple = Color(0xFF7A61E8);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormFieldState<String>> _emailFieldKey =
      GlobalKey<FormFieldState<String>>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _logIn() {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    debugPrint('Login form submitted:');
    debugPrint('Email: $email');
    debugPrint('Password length: ${password.length} characters');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Form submitted. Check the debug console.')),
    );
  }

  void _forgotPassword() {
    FocusScope.of(context).unfocus();

    if (!(_emailFieldKey.currentState?.validate() ?? false)) {
      return;
    }

    final email = _emailController.text.trim();
    debugPrint('Password reset requested for: $email');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password reset request logged for testing.'),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Please enter your email.';
    }

    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailPattern.hasMatch(email)) {
      return 'Please enter a valid email address.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Please enter your password.';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _background,
      body: Stack(
        children: [
          const Positioned(
            top: 26,
            right: -60,
            child: _BackgroundCircle(size: 178, color: Color(0xFFE5D7FF)),
          ),
          const Positioned(
            top: 120,
            left: -76,
            child: _BackgroundCircle(size: 174, color: Color(0xFFE9DEFF)),
          ),
          const Positioned(
            right: -72,
            bottom: 93,
            child: _BackgroundCircle(size: 164, color: Color(0xFFFFE6AB)),
          ),
          const Positioned(
            left: -82,
            bottom: -19,
            child: _BackgroundCircle(size: 158, color: Color(0xFFD2F4E7)),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(27, 12, 27, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 36,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          _LoginHeader(onBack: _goBack),
                          const SizedBox(height: 23),
                          const Text(
                            'Welcome back',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _ink,
                              fontSize: 31,
                              fontWeight: FontWeight.w800,
                              height: 1.12,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Log in to continue reading and practicing with\n'
                            'Lumi.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _muted,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 91),
                          AutofillGroup(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _LoginTextField(
                                    key: _emailFieldKey,
                                    controller: _emailController,
                                    label: 'Email',
                                    hintText: 'you@example.com',
                                    icon: Icons.mail_outline_rounded,
                                    validator: _validateEmail,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.email],
                                  ),
                                  const SizedBox(height: 26),
                                  _LoginTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    hintText: 'Enter your password',
                                    icon: Icons.lock_outline_rounded,
                                    validator: _validatePassword,
                                    obscureText: true,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    onFieldSubmitted: (_) => _logIn(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _forgotPassword,
                              style: TextButton.styleFrom(
                                foregroundColor: _purple,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 6,
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          const SizedBox(height: 46),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _logIn,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                foregroundColor: Colors.white,
                                backgroundColor: _purple,
                                shape: const StadiumBorder(),
                                textStyle: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('Log in'),
                            ),
                          ),
                          const SizedBox(height: 38),
                          TextButton(
                            onPressed: () {
                              context.pushReplacement('/signup');
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: _purple,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text(
                              'New to StoryPet? Create account',
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(height: 42),
                          const Text(
                            'AI Story Pet',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              child: IconButton(
                onPressed: onBack,
                tooltip: 'Back',
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  size: 30,
                  color: _LoginScreenState._ink,
                ),
              ),
            ),
          ),
          const Text(
            'LOG IN',
            style: TextStyle(
              color: _LoginScreenState._purple,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginTextField extends StatelessWidget {
  const _LoginTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    required this.validator,
    required this.textInputAction,
    required this.autofillHints,
    this.keyboardType,
    this.obscureText = false,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final FormFieldValidator<String> validator;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String> autofillHints;
  final bool obscureText;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 59),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D38295C),
            blurRadius: 20,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: _LoginScreenState._muted, size: 25),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: controller,
              validator: validator,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              obscureText: obscureText,
              autofillHints: autofillHints,
              onFieldSubmitted: onFieldSubmitted,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              style: const TextStyle(
                color: _LoginScreenState._ink,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
              decoration: InputDecoration(
                labelText: label,
                hintText: hintText,
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                labelStyle: const TextStyle(
                  color: _LoginScreenState._muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                hintStyle: const TextStyle(
                  color: Color(0xFFA1A3B1),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                errorStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundCircle extends StatelessWidget {
  const _BackgroundCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
