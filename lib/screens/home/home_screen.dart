import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onStartStory});

  final VoidCallback? onStartStory;

  static const Color _background = Color(0xFFF9F5FF);
  static const Color _ink = Color(0xFF111626);
  static const Color _muted = Color(0xFF707487);
  static const Color _purple = Color(0xFF7561E8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 18, 28, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HomeHeader(),
              const SizedBox(height: 22),
              _LumiStoryCard(onStartStory: onStartStory),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Expanded(
                    child: _ProgressCard(
                      backgroundColor: Color(0xFFFFD37D),
                      emoji: '🔥',
                      label: 'DAYS',
                      value: '12',
                      valueColor: Color(0xFF3D2900),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _ProgressCard(
                      backgroundColor: Colors.white,
                      emoji: '💖',
                      label: 'FEELINGS',
                      value: '86%',
                      valueColor: _ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Keep reading 📖',
                style: TextStyle(
                  color: _ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 14),
              const _ReadingCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const _HomeNavigationBar(),
    );
  }
}

class _HomeHeader extends StatefulWidget {
  const _HomeHeader();

  @override
  State<_HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<_HomeHeader> {
  AuthService? _authService;
  bool _isLoggingOut = false;

  AuthService get _auth => _authService ??= AuthService();

  String get _userName {
    final user = _auth.currentUser;
    final displayName = user?.displayName?.trim();

    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = user?.email?.trim();
    if (email != null && email.isNotEmpty) {
      final emailName = email.split('@').first.trim();
      if (emailName.isNotEmpty) {
        return emailName;
      }
    }

    return 'Reader';
  }

  Future<void> _logOut() async {
    if (_isLoggingOut) {
      return;
    }

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _auth.logOut();

      if (!mounted) {
        return;
      }

      context.go('/');
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to log out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hi there,',
              style: TextStyle(
                color: HomeScreen._muted,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '$_userName 👋',
              style: const TextStyle(
                color: HomeScreen._ink,
                fontSize: 27,
                fontWeight: FontWeight.w800,
                height: 1.08,
              ),
            ),
          ],
        ),
        Material(
          color: const Color(0xFFF2E4FA),
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: _isLoggingOut ? null : _logOut,
            tooltip: 'Log out',
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: HomeScreen._purple,
                    ),
                  )
                : const Icon(
                    Icons.logout_rounded,
                    color: HomeScreen._purple,
                    size: 22,
                  ),
          ),
        ),
      ],
    );
  }
}

class _LumiStoryCard extends StatelessWidget {
  const _LumiStoryCard({this.onStartStory});

  final VoidCallback? onStartStory;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 258,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF917EFF), Color(0xFF5C50DA)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -58,
            right: -50,
            child: _DecorativeCircle(size: 170, color: Color(0x299E96EE)),
          ),
          const Positioned(
            left: -42,
            bottom: -74,
            child: _DecorativeCircle(size: 132, color: Color(0x409FD9B0)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9E9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: const Image(
                            image: AssetImage('assets/images/lumi_fox.png'),
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          ),
                        ),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: Container(
                            width: 19,
                            height: 19,
                            decoration: BoxDecoration(
                              color: const Color(0xFF59E8A8),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 13),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lumi 🦊',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Ready to play!',
                            style: TextStyle(
                              color: Color(0xFFF2EFFF),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 61,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: const Color(0x299999EE),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Want to read a story about\nmaking a new friend? 💛',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: onStartStory ?? () {},
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      foregroundColor: const Color(0xFF5B4CDD),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    icon: const Icon(Icons.menu_book_rounded, size: 22),
                    label: const Text('Start'),
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

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.backgroundColor,
    required this.emoji,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final Color backgroundColor;
  final String emoji;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.fromLTRB(17, 16, 15, 13),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: backgroundColor == Colors.white
            ? const [
                BoxShadow(
                  color: Color(0x0D48347A),
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 25)),
              const Spacer(),
              Text(
                label,
                style: TextStyle(
                  color: valueColor.withValues(alpha: 0.62),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 35,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D48347A),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 146,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const Image(
                  image: AssetImage('assets/images/mia_joins_game.png'),
                  fit: BoxFit.cover,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xB53A2D8E)],
                      stops: [0.48, 1],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 3,
                          backgroundColor: Color(0xFFFF826B),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'FRIENDS',
                          style: TextStyle(
                            color: Color(0xFF343746),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Positioned(
                  left: 13,
                  right: 13,
                  bottom: 12,
                  child: Text(
                    'Mia Joins the Game',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      '3 / 8 pages',
                      style: TextStyle(
                        color: HomeScreen._muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '38%',
                      style: TextStyle(
                        color: HomeScreen._purple,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  child: LinearProgressIndicator(
                    value: 0.38,
                    minHeight: 5,
                    backgroundColor: Color(0xFFE9E3F8),
                    valueColor: AlwaysStoppedAnimation(HomeScreen._purple),
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

class _HomeNavigationBar extends StatelessWidget {
  const _HomeNavigationBar();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (_) {},
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: HomeScreen._purple,
      unselectedItemColor: const Color(0xFFB6AACA),
      selectedFontSize: 11,
      unselectedFontSize: 11,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      iconSize: 27,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_rounded),
          label: 'Library',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.extension_rounded),
          label: 'Practice',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.show_chart_rounded),
          label: 'Growth',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.color});

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
