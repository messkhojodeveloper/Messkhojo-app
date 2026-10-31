import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/mess_model.dart';
import '../../../data/services/image_url_service.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../providers/auth_provider.dart';

class HorizontalMessCard extends ConsumerStatefulWidget {
  final MessModel mess;

  const HorizontalMessCard({super.key, required this.mess});

  @override
  ConsumerState<HorizontalMessCard> createState() => _HorizontalMessCardState();
}

class _HorizontalMessCardState extends ConsumerState<HorizontalMessCard> {
  String? _imageUrl;
  bool _isLoadingImage = true;

  @override
  void initState() {
    super.initState();
    _resolveImageUrl();
  }

  @override
  void didUpdateWidget(covariant HorizontalMessCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mess.posterUrl != widget.mess.posterUrl) {
      _resolveImageUrl();
    }
  }

  Future<void> _resolveImageUrl() async {
    final posterUrl = widget.mess.posterUrl;
    if (posterUrl == null || posterUrl.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoadingImage = false;
        });
      }
      return;
    }
    try {
      final service = ref.read(imageUrlServiceProvider);
      final url = await service.resolveUrl(posterUrl);
      if (mounted) {
        setState(() {
          _imageUrl = url;
          _isLoadingImage = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingImage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mess = widget.mess;
    final wishlistedIds = ref.watch(wishlistedMessIdsProvider);
    final isWishlisted = wishlistedIds.contains(mess.id);
    final authState = ref.watch(authStateProvider);

    return GestureDetector(
      onTap: () => context.push('/mess/${mess.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 90,
                height: 90,
                child: _imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: _imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: const Color(0xFFF3F4F6)),
                        errorWidget: (context, url, error) => _buildPlaceholder(),
                      )
                    : (_isLoadingImage
                        ? Container(
                            color: const Color(0xFFF3F4F6),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _buildPlaceholder()),
              ),
            ),
            const SizedBox(width: 14),

            // Middle info details & price
            Expanded(
              child: SizedBox(
                height: 90,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mess Name
                    Text(
                      mess.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Outfit',
                        color: Color(0xFF1F2937),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Address
                    Text(
                      mess.address.isNotEmpty ? mess.address : 'Location not provided',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Outfit',
                        color: Color(0xFF6B7280),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),

                    // Price details bottom right aligned
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (mess.minPrice != null) ...[
                            Text(
                              mess.minPrice == mess.maxPrice
                                  ? '₹${mess.minPrice}'
                                  : '₹${mess.minPrice}–${mess.maxPrice}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Outfit',
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              mess.rentCycle == 'yearly' ? 'year' : 'month',
                              style: const TextStyle(
                                fontSize: 10,
                                fontFamily: 'Outfit',
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Right side heart wishlist icon
            GestureDetector(
              onTap: () async {
                if (authState.value == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please login to save messes to your wishlist.')),
                  );
                  return;
                }
                await ref.read(wishlistRepositoryProvider).toggleMessInWishlist(
                      authState.value!.uid,
                      mess.id,
                    );
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(
                  isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 20,
                  color: isWishlisted ? const Color(0xFF9B51E0) : const Color(0xFF9CA3AF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF3F0FF),
      child: const Center(
        child: Text('🏡', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
