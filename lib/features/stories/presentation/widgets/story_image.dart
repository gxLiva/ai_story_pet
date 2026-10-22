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
      return Image.asset(
        path,
        key: ValueKey(path),
        width: width,
        height: height,
        fit: fit,
      );
    }

    return Image.network(
      path,
      key: ValueKey(path),
      width: width,
      height: height,
      fit: fit,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('[StoryImage] Failed to load $path: $error');
        return Image.asset(
          fallbackPath,
          width: width,
          height: height,
          fit: fit,
        );
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: width,
          height: height,
          child: const ColoredBox(
            color: Color(0xFFF0ECFA),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          ),
        );
      },
    );
  }
}
