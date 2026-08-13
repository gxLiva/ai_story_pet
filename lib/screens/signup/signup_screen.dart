import 'package:flutter/material.dart';

typedef CreateAccountCallback =
    void Function(String name, String email, String password);

class SignupScreen extends StatefulWidget {
  const SignupScreen({
    super.key,
    this.onBack,
    this.onCreateAccount,
    this.onLogIn,
  });

  final VoidCallback? onBack;
  final CreateAccountCallback? onCreateAccount;
  final VoidCallback? onLogIn;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const Color _background = Color(0xFFF8F2FF);
  static const Color _ink = Color(0xFF151A2D);
  static const Color _muted = Color(0xFF707487);
  static const Color _purple = Color(0xFF7A61E8);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _createAccount() {
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all three fields.')),
      );
      return;
    }

    widget.onCreateAccount?.call(name, email, password);
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
                          _SignupHeader(onBack: _goBack),
                          const SizedBox(height: 23),
                          const Text(
                            'Create your account',
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
                            'Start building gentle stories and practice\n'
                            'moments with Lumi.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _muted,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 66),
                          _SignupTextField(
                            controller: _nameController,
                            label: 'Name',
                            hintText: 'Your name',
                            icon: Icons.person_outline_rounded,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 26),
                          _SignupTextField(
                            controller: _emailController,
                            label: 'Email',
                            hintText: 'you@example.com',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                          ),
                          const SizedBox(height: 26),
                          _SignupTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hintText: 'Create a password',
                            icon: Icons.lock_outline_rounded,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.newPassword],
                            onSubmitted: (_) => _createAccount(),
                          ),
                          const SizedBox(height: 54),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _createAccount,
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
                              child: const Text('Create account'),
                            ),
                          ),
                          const SizedBox(height: 32),
                          TextButton(
                            onPressed: widget.onLogIn ?? () {},
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
                              'Already have an account? Log in',
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

class _SignupHeader extends StatelessWidget {
  const _SignupHeader({required this.onBack});

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
              elevation: 0,
              child: IconButton(
                onPressed: onBack,
                tooltip: 'Back',
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  size: 30,
                  color: _SignupScreenState._ink,
                ),
              ),
            ),
          ),
          const Text(
            'SIGN UP',
            style: TextStyle(
              color: _SignupScreenState._purple,
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

class _SignupTextField extends StatelessWidget {
  const _SignupTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    required this.textInputAction,
    required this.autofillHints,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String> autofillHints;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 59,
      padding: const EdgeInsets.symmetric(horizontal: 18),
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
        children: [
          Icon(icon, color: _SignupScreenState._muted, size: 25),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _SignupScreenState._muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  textCapitalization: textCapitalization,
                  obscureText: obscureText,
                  autofillHints: autofillHints,
                  onSubmitted: onSubmitted,
                  style: const TextStyle(
                    color: _SignupScreenState._ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                  decoration: InputDecoration.collapsed(
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      color: Color(0xFFA1A3B1),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
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
