import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProxiedCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ProxiedCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final proxiedUrl = ApiService.proxiedImageUrl(imageUrl);
    Widget image = CachedNetworkImage(
      imageUrl: proxiedUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => Container(
        color: Colors.grey[300],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (_, __, ___) => Container(
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}

ImageProvider proxiedNetworkImageProvider(String url) {
  return NetworkImage(ApiService.proxiedImageUrl(url));
}
