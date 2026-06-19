import 'package:carrocare_flutter/core/constants/app_urls.dart';
import 'package:flutter/material.dart';

class RemoteImageWithFallback extends StatelessWidget {
  const RemoteImageWithFallback({
    super.key,
    this.imageUrl,
    required this.fallbackAsset,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.color,
    this.colorBlendMode,
  });

  final String? imageUrl;
  final String fallbackAsset;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final Color? color;
  final BlendMode? colorBlendMode;

  Widget _assetImage() {
    return Image.asset(
      fallbackAsset,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      color: color,
      colorBlendMode: colorBlendMode,
      errorBuilder: (_, __, ___) => Icon(
        Icons.image_not_supported_outlined,
        size: (height ?? width ?? 48).clamp(24, 64),
        color: color ?? Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return _assetImage();
    }
    if (!AppUrls.isAppBackendUrl(url) && !url.startsWith('https://res.cloudinary.com/')) {
      return _assetImage();
    }
    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      color: color,
      colorBlendMode: colorBlendMode,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return _assetImage();
      },
      errorBuilder: (_, __, ___) => _assetImage(),
    );
  }
}

class RemoteSlide {
  const RemoteSlide({this.imageUrl, required this.fallbackAsset});

  final String? imageUrl;
  final String fallbackAsset;
}
