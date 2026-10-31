import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../data/models/mess_model.dart';
import '../../../data/services/image_url_service.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../providers/auth_provider.dart';

/// A compact mess card matching the website's CityLanding page MessCard design.
///
/// Features:
/// - Clean, borderless layout with 4:3 aspect ratio poster image
/// - Smooth 24px rounded corners (rounded-3xl)
/// - Top-right translucent dark circular wishlist toggle
/// - Truncated extra-bold mess title in Outfit font
/// - Gray price range subtitle ("₹min-max / month")
class CompactMessCard extends ConsumerWidget {
  final MessModel mess;

  const CompactMessCard({super.key, required this.mess});

  Widget _buildImageStack(String imageUrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: imageUrl,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: const Color(0xFFF1F5F9),
          ),
          errorWidget: (context, url, error) => _buildPlaceholder(),
        ),
        // Gradient Overlay (subtle darkening at bottom like web)
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Color(0x35000000),
              ],
              stops: [0.6, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistedIds = ref.watch(wishlistedMessIdsProvider);
    final isWishlisted = wishlistedIds.contains(mess.id);
    final authState = ref.watch(authStateProvider);

    // Fast-path: Check if posterUrl is already a direct URL or in memory cache
    final directUrl = ImageUrlService.getDirectOrCached(mess.posterUrl);
    Widget imageContent;
    if (directUrl != null) {
      imageContent = _buildImageStack(directUrl);
    } else if (mess.posterUrl == null || mess.posterUrl!.isEmpty) {
      imageContent = _buildPlaceholder();
    } else {
      final imageAsync = ref.watch(resolvedImageUrlProvider(mess.posterUrl));
      imageContent = imageAsync.when(
        loading: () => Shimmer.fromColors(
          baseColor: const Color(0xFFE2E8F0),
          highlightColor: const Color(0xFFF8FAFC),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white,
          ),
        ),
        data: (url) => url != null ? _buildImageStack(url) : _buildPlaceholder(),
        error: (err, stack) => _buildPlaceholder(),
      );
    }

    // Format price according to website's format:
    // e.g. "₹3200-3600 / month" or "₹3000 / month"
    final minPrice = mess.minPrice;
    final maxPrice = mess.maxPrice;
    String priceText;
    if (minPrice != null && maxPrice != null && minPrice != maxPrice) {
      priceText = '₹$minPrice-$maxPrice';
    } else if (minPrice != null) {
      priceText = '₹$minPrice';
    } else if (maxPrice != null) {
      priceText = '₹$maxPrice';
    } else {
      priceText = '₹1500';
    }
    final cycle = mess.rentCycle == 'yearly' ? ' / year' : ' / month';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/mess/${mess.id}');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 4:3 Aspect Ratio Image with 24px border radius & wishlist button
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    color: const Color(0xFFF1F5F9), // Light gray background
                    child: imageContent,
                  ),
                ),

                // Wishlist Heart Button (Top-Right dark translucent circle)
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      if (authState.value == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Login to save to wishlist')),
                        );
                        return;
                      }
                      await ref.read(wishlistRepositoryProvider).toggleMessInWishlist(
                        authState.value!.uid,
                        mess.id,
                      );
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isWishlisted
                            ? const Color(0xFFEF4444)
                            : const Color(0x66000000), // bg-black/40 backdrop-blur
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Mess Name
          Text(
            mess.name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'Outfit',
              color: Color(0xFF030712), // text-gray-950
              height: 1.2,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 3),

          // Price range & cycle
          Text(
            '$priceText$cycle',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Outfit',
              color: Color(0xFF374151), // text-gray-700
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Text(
          '🏡',
          style: TextStyle(fontSize: 36),
        ),
      ),
    );
  }
}
