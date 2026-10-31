import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../data/services/image_url_service.dart';

/// A widget that resolves a Firebase Storage path or direct URL to a displayable
/// [CachedNetworkImage], using [resolvedImageUrlProvider] for deduplicated,
/// Riverpod-cached URL resolution. Shows a shimmer skeleton while loading.
class FirebaseImage extends ConsumerWidget {
  final String? imagePath;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final double? width;
  final double? height;

  const FirebaseImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaultError = errorWidget ??
        Container(
          color: const Color(0xFFE5E7EB),
          width: width,
          height: height,
          child: const Center(
            child: Icon(Icons.image_not_supported, color: Colors.grey),
          ),
        );

    final shimmerPlaceholder = placeholder ??
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            color: Colors.white,
            width: width,
            height: height,
          ),
        );

    // Fast-path: direct HTTP/HTTPS URLs or already cached URLs render immediately
    final directUrl = ImageUrlService.getDirectOrCached(imagePath);
    if (directUrl != null) {
      return CachedNetworkImage(
        imageUrl: directUrl,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, url) => shimmerPlaceholder,
        errorWidget: (context, url, error) => defaultError,
      );
    }

    if (imagePath == null || imagePath!.isEmpty) {
      return defaultError;
    }

    final imageAsync = ref.watch(resolvedImageUrlProvider(imagePath));

    return imageAsync.when(
      loading: () => shimmerPlaceholder,
      data: (url) {
        if (url == null) return defaultError;
        return CachedNetworkImage(
          imageUrl: url,
          fit: fit,
          width: width,
          height: height,
          placeholder: (context, url) => shimmerPlaceholder,
          errorWidget: (context, url, error) => defaultError,
        );
      },
      error: (err, stack) => defaultError,
    );
  }
}
