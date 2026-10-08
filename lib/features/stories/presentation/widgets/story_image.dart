import 'package:flutter/material.dart';

class StoryImage extends StatelessWidget {
  const StoryImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;

  static const fallbackPath = 'assets/images/lumi_fox.png';

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(path);
    final isRemote =
        uri != null &&
        (uri.scheme.toLowerCase() == 'https' ||
            uri.scheme.toLowerCase() == 'http');
    if (!isRemote) {
      return Image.asset(path, width: width, height: height, fit: fit);
    }

    return Image.network(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          Image.asset(fallbackPath, width: width, height: height, fit: fit),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Stack(
          fit: StackFit.passthrough,
          alignment: Alignment.center,
          children: [
            Image.asset(fallbackPath, width: width, height: height, fit: fit),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        );
      },
    );
  }
}
