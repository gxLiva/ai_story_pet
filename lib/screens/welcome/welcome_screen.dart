import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const Color _background = Color(0xFFF8F2FF);
  static const Color _ink = Color(0xFF161A2D);
  static const Color _muted = Color(0xFF6F7287);
  static const Color _purple = Color(0xFF7A61E8);

  void _openSignup(BuildContext context) {
    context.push('/signup');
  }

  void _openLogin(BuildContext context) {
    context.push('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        children: [
          const Positioned(
            top: 25,
            right: -55,
            child: _BackgroundCircle(size: 176, color: Color(0xFFE6D8FF)),
          ),
          const Positioned(
            top: 108,
            left: -76,
            child: _BackgroundCircle(size: 170, color: Color(0xFFE9DEFF)),
          ),
          const Positioned(
            right: -64,
            bottom: 104,
            child: _BackgroundCircle(size: 164, color: Color(0xFFFFE7AD)),
          ),
          const Positioned(
            left: -82,
            bottom: -12,
            child: _BackgroundCircle(size: 154, color: Color(0xFFD4F5E8)),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 34, 28, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 58,
                    ),
                    child: Column(
                      children: [
                        const _LumiPortrait(),
                        const SizedBox(height: 27),
                        Text(
                          'AI Story Pet',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: _ink,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                                letterSpacing: -0.4,
                              ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Gentle personalized stories that help\n'
                          'neurodiverse kids read, reflect, and practice\n'
                          'everyday social moments with Lumi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _muted,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.48,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _FeatureCard(
                                icon: Icons.menu_book_rounded,
                                iconColor: Color(0xFF7B5CE9),
                                iconBackground: Color(0xFFE4D7FF),
                                title: 'Story time',
                                description: 'Made for real\nmoments',
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _FeatureCard(
                                icon: Icons.favorite_rounded,
                                iconColor: Color(0xFFFF7C60),
                                iconBackground: Color(0xFFFFE0E6),
                                title: 'Feelings',
                                description: 'Name what\ncharacters feel',
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _FeatureCard(
                                icon: Icons.auto_awesome_rounded,
                                iconColor: Color(0xFF31B991),
                                iconBackground: Color(0xFFD8F5E9),
                                title: 'Practice',
                                description: 'Try kind choices',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 74),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => _openSignup(context),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: _purple,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              textStyle: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('Get started'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () => _openLogin(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _purple,
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFDDD2F3)),
                              shape: const StadiumBorder(),
                              textStyle: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('Log in'),
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Built for calm, supported reading practice.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

class _LumiPortrait extends StatelessWidget {
  const _LumiPortrait();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 208,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 176,
            height: 176,
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFDA6F),
            ),
            child: const ClipOval(
              child: Image(
                image: AssetImage('assets/images/lumi_fox.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 168,
            child: Container(
              width: 126,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D171A2D),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Text(
                'Hi, I’m Lumi',
                style: TextStyle(
                  color: WelcomeScreen._ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A171A2D),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 27),
          ),
          const SizedBox(height: 9),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: const TextStyle(
              color: WelcomeScreen._ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              color: WelcomeScreen._muted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.4,
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
