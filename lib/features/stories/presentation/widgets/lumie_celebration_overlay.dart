import 'dart:math';

import 'package:flutter/material.dart';

class LumieCelebration {
  const LumieCelebration({required this.imagePath, required this.message});

  final String imagePath;
  final String message;
}

LumieCelebration pickRandomCelebration(List<LumieCelebration> celebrations) {
  return celebrations[Random().nextInt(celebrations.length)];
}

Future<void> showLumieCelebrationOverlay({
  required BuildContext context,
  required LumieCelebration celebration,
  required String dismissLabel,
  required Key overlayKey,
  required Key imageKey,
  required Key messageKey,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.68),
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: curved, child: child),
      );
    },
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _LumieCelebrationOverlay(
        celebration: celebration,
        dismissLabel: dismissLabel,
        overlayKey: overlayKey,
        imageKey: imageKey,
        messageKey: messageKey,
        onDismiss: () => Navigator.of(dialogContext).pop(),
      );
    },
  );
}

class _LumieCelebrationOverlay extends StatelessWidget {
  const _LumieCelebrationOverlay({
    required this.celebration,
    required this.dismissLabel,
    required this.overlayKey,
    required this.imageKey,
    required this.messageKey,
    required this.onDismiss,
  });

  final LumieCelebration celebration;
  final String dismissLabel;
  final Key overlayKey;
  final Key imageKey;
  final Key messageKey;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Semantics(
        liveRegion: true,
        button: true,
        label: '${celebration.message} $dismissLabel.',
        child: InkWell(
          key: overlayKey,
          onTap: onDismiss,
          splashColor: Colors.white.withValues(alpha: 0.08),
          highlightColor: Colors.transparent,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      celebration.imagePath,
                      key: imageKey,
                      width: 310,
                      height: 310,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      celebration.message,
                      key: messageKey,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        shadows: [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      dismissLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
