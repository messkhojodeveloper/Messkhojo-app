import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/mess_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../data/models/mess_model.dart';
import '../../data/models/room_model.dart';
import '../../data/repositories/claim_repository.dart';
import '../../core/services/analytics_tracker.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/firebase_image.dart';
import '../../widgets/contact_owner_dialog.dart';
import '../../widgets/app_error_widget.dart';
import '../../widgets/app_empty_state_widget.dart';
import 'widgets/claim_mess_bottom_sheet.dart';

/// Helper to format food facility display, matching website MessDetails.jsx
String getFoodFacilityDisplay(MessModel mess) {
  if (mess.foodFacility != null && mess.foodFacility!.trim().isNotEmpty) {
    final ff = mess.foodFacility!.trim();
    final lff = ff.toLowerCase();
    if (lff.contains('student')) return 'Managed by Students';
    if (lff.contains('warden')) return 'Managed by Warden';
    if (lff.contains('canteen')) return 'Nearby Canteen';
    if (lff.contains('owner') || lff.contains('fssai') || lff.contains('rent')) return 'Managed by Owner';
    if (lff.contains('no food') || lff.contains('not available')) return 'Not Available';
    if (ff.length > 2) return ff;
  }
  if (mess.foodAvailability == 'No Food') return 'Not Available';
  if (mess.foodAvailability == 'Self Cook') return 'Managed by Students';
  if (mess.managedBy != null && mess.managedBy!.trim().isNotEmpty) {
    final val = mess.managedBy!.trim();
    if (val.toLowerCase() == 'nearby canteen') return 'Nearby Canteen';
    if (val.toLowerCase().startsWith('managed by')) return val;
    if (val.toLowerCase() == 'none' || val.toLowerCase() == 'no') return 'Not Available';
    return 'Managed by $val';
  }
  return 'Managed by Owner';
}

/// Helper to normalize occupancy numbers
String getCleanOccupancy(String? val) {
  if (val == null || val.trim().isEmpty) return '';
  final s = val.toLowerCase().trim();
  if (s == '1' || s == 'single' || s == '1 seater' || s.contains('single')) return '1';
  if (s == '2' || s == 'double' || s == '2 seater' || s.contains('double')) return '2';
  if (s == '3' || s == 'triple' || s == '3 seater' || s.contains('triple')) return '3';
  if (s == '4' || s == 'four' || s == '4 seater' || s.contains('four')) return '4';
  if (s == '5' || s == 'five' || s == '5 seater' || s.contains('five')) return '5';
  if (s == '6' || s == 'six' || s == '6 seater' || s.contains('six')) return '6';
  if (s == '8' || s == 'eight' || s == '8 seater' || s.contains('eight')) return '8';
  return val.replaceAll(RegExp(r'\s*(?:seater|sharing|room|beds?|seats?)\b', caseSensitive: false), '').trim();
}

class MessDetailsScreen extends ConsumerStatefulWidget {
  final String messId;
  const MessDetailsScreen({super.key, required this.messId});

  @override
  ConsumerState<MessDetailsScreen> createState() => _MessDetailsScreenState();
}

class _MessDetailsScreenState extends ConsumerState<MessDetailsScreen> {
  bool _showUserSourcedExpanded = false;

  @override
  Widget build(BuildContext context) {
    final messAsync = ref.watch(messDetailsProvider(widget.messId));
    final roomsAsync = ref.watch(messRoomsProvider(widget.messId));

    // Track mess view
    ref.listen<AsyncValue<MessModel?>>(messDetailsProvider(widget.messId), (prev, next) {
      final mess = next.value;
      if (mess != null && (prev == null || prev.value?.id != mess.id)) {
        AnalyticsTracker.instance.trackMessView(
          mess.id,
          mess.name,
          district: mess.district,
          gender: mess.messType,
          startingPrice: mess.minPrice?.toDouble(),
        );
      }
    });

    final mess = messAsync.value;
    final rooms = roomsAsync.value ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: messAsync.when(
        data: (mess) {
          if (mess == null) {
            return AppErrorWidget.notFound(
              title: 'Mess Listing Not Found',
              message: 'This mess property might have been removed or is temporarily unavailable.',
              showHomeButton: true,
            );
          }

          return CustomScrollView(
            slivers: [
              _buildHeroBanner(context, mess, rooms),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Community Sourced / Policy Card (if user-sourced)
                      if (mess.isUserSourced) ...[
                        _buildUserSourcedDisclaimer(mess),
                        const SizedBox(height: 24),
                      ],

                      // 2. Available Room Types Section
                      _buildAvailableRoomTypesHeader(rooms),
                      const SizedBox(height: 14),
                      if (rooms.isEmpty)
                        const AppEmptyStateWidget(
                          title: 'More details coming soon!',
                          message: 'We are collecting more information about this mess. Please contact the owner for current availability.',
                          icon: Icons.bed_outlined,
                          isCompact: true,
                        )
                      else
                        _buildRoomsList(rooms, mess),

                      const SizedBox(height: 32),

                      // 3. About & Overview Card
                      _buildAboutAndOverviewCard(mess),
                      const SizedBox(height: 24),

                      // 4. Living & Utility Services Card
                      _buildLivingAndUtilityServicesCard(mess, rooms),
                      const SizedBox(height: 24),

                      // 5. Fee Structure & Inclusions Card
                      _buildFeeStructureCard(mess),
                      const SizedBox(height: 24),

                      // 6. Photo Gallery Card (if any gallery photos)
                      if (mess.galleryUrls.isNotEmpty) ...[
                        _buildPhotoGalleryCard(mess),
                        const SizedBox(height: 24),
                      ],

                      // 7. Claim Listing Button
                      _buildClaimListingSection(mess),

                      // Spacing so content is never covered by floating action button
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => _buildShimmer(),
        error: (err, stack) => AppErrorWidget(
          title: 'Unable to Load Mess',
          message: 'Could not retrieve information for this mess. Please check your internet connection.',
          onRetry: () => ref.invalidate(messDetailsProvider(widget.messId)),
          showHomeButton: true,
        ),
      ),
      floatingActionButton: mess != null ? _buildContactOwnerFAB(mess, rooms) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ==========================================
  // 1. HERO BANNER WITH GRADIENT & OVERLAYS
  // ==========================================
  Widget _buildHeroBanner(BuildContext context, MessModel mess, List<RoomModel> rooms) {
    final bannerImage = mess.posterUrl ?? (mess.galleryUrls.isNotEmpty ? mess.galleryUrls.first : null);
    final wishlistedMessIds = ref.watch(wishlistedMessIdsProvider);
    final isWishlisted = wishlistedMessIds.contains(mess.id);

    // Amenities flags
    final hasFood = (mess.amenities['food'] == true) || (mess.foodFacility != null && mess.foodFacility != 'No Food') || rooms.any((r) => r.amenities['food'] == true);
    final hasWifi = (mess.amenities['wifi'] == true) || mess.facilities?.contains('Wifi') == true || rooms.any((r) => r.amenities['wifi'] == true);
    final hasInverter = (mess.amenities['inverter'] == true) || mess.facilities?.contains('InverterPower') == true || rooms.any((r) => r.amenities['inverter'] == true);

    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF300868),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image or Rich Gradient Fallback
            if (bannerImage != null && bannerImage.isNotEmpty)
              FirebaseImage(
                imagePath: bannerImage,
                fit: BoxFit.cover,
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF300868), Color(0xFF6B21A8), Color(0xFF4338CA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),

            // Darkening gradient overlay so white text is always crisp and readable
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x70000000),
                    Color(0x30000000),
                    Color(0xB0000000),
                    Color(0xE0000000),
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),

            // Top Glass Navigation Bar
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button (Glass pill)
                      InkWell(
                        onTap: () => context.pop(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'Back',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Right Action Buttons: Wishlist & Share
                      Row(
                        children: [
                          // Wishlist Heart Button
                          InkWell(
                            onTap: () async {
                              final auth = ref.read(authStateProvider);
                              final userId = auth.value?.uid;
                              if (userId == null) {
                                _showLoginPrompt(context, 'Save to Wishlist', 'Login to save messes to your personal wishlist.');
                                return;
                              }
                              await ref.read(wishlistRepositoryProvider).toggleMessInWishlist(userId, mess.id);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isWishlisted ? const Color(0xFFEF4444).withValues(alpha: 0.85) : Colors.black.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                              ),
                              child: Icon(
                                isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Share Button
                          InkWell(
                            onTap: () async {
                              final shareUrl = 'https://messkhojo.com/mess/${mess.id}';
                              final shareText = 'Check out ${mess.name} on MessKhojo!\n$shareUrl';

                              AnalyticsTracker.instance.trackShare(
                                'native',
                                messId: mess.id,
                                messName: mess.name,
                              );

                              try {
                                await SharePlus.instance.share(
                                  ShareParams(text: shareText),
                                );
                              } catch (_) {
                                await Clipboard.setData(ClipboardData(text: shareUrl));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                          SizedBox(width: 8),
                                          Text('Listing link copied to clipboard!'),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFF1F2937),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                              ),
                              child: const Icon(
                                Icons.share_rounded,
                                color: Colors.white,
                                size: 17,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Overlay: Title, Address, Badges & Locate button
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mess Name
                  Text(
                    mess.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.15,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Location Row + Locate Button
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Colors.white70, size: 15),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          mess.address.isNotEmpty ? mess.address : 'Address not available',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (mess.locationUrl != null && mess.locationUrl!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            AnalyticsTracker.instance.trackLocationUsage('map', district: mess.district);
                            launchUrl(Uri.parse(mess.locationUrl!), mode: LaunchMode.externalApplication);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.navigation_rounded, color: Colors.white, size: 13),
                                SizedBox(width: 4),
                                Text(
                                  'Locate',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Amenity & Property Badges
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      // Property Type Badge
                      _buildHeroGlassPill(
                        icon: Icons.business_center_rounded,
                        label: '${mess.messType} Mess',
                      ),
                      // Operating Since
                      if (mess.operatingSince != null && mess.operatingSince!.isNotEmpty)
                        _buildHeroGlassPill(
                          icon: Icons.calendar_today_rounded,
                          label: mess.operatingSince!.startsWith('Est.') ? mess.operatingSince! : 'Est. ${mess.operatingSince}',
                        ),
                      // Food Pill
                      if (hasFood)
                        _buildHeroGlassPill(
                          icon: Icons.restaurant_rounded,
                          label: mess.foodType != null && mess.foodType!.isNotEmpty ? 'Food (${mess.foodType})' : 'Food Available',
                        ),
                      // WiFi Pill
                      if (hasWifi)
                        _buildHeroGlassPill(
                          icon: Icons.wifi_rounded,
                          label: 'WiFi',
                        ),
                      // Power Backup Pill
                      if (hasInverter)
                        _buildHeroGlassPill(
                          icon: Icons.bolt_rounded,
                          label: 'Power Backup',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroGlassPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. USER SOURCED / COMMUNITY DISCLAIMER
  // ==========================================
  Widget _buildUserSourcedDisclaimer(MessModel mess) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shield_rounded, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Our Policy',
                      style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E3A8A)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'We strive for accuracy, but recommend visiting the premises before making any payments. MessKhojo is not responsible for any discrepancies.',
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Color(0xFF475569), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => setState(() => _showUserSourcedExpanded = !_showUserSourcedExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _showUserSourcedExpanded ? 'Show Less' : 'Read More',
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                    Icon(_showUserSourcedExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16, color: AppTheme.primary),
                  ],
                ),
              ),
            ),
          ),
          if (_showUserSourcedExpanded) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This listing was sourced by our community and has not been claimed by the property manager yet.',
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // 3. AVAILABLE ROOM TYPES SECTION
  // ==========================================
  Widget _buildAvailableRoomTypesHeader(List<RoomModel> rooms) {
    final count = rooms.map((r) => getCleanOccupancy(r.occupancy)).toSet().length;

    return Row(
      children: [
        const Text(
          'Available Room Types',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF030712),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count ${count == 1 ? 'Type' : 'Types'}',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomsList(List<RoomModel> rooms, MessModel mess) {
    final wishlistedRoomIds = ref.watch(wishlistedRoomIdsProvider);

    return Column(
      children: rooms.map((room) {
        final isWishlisted = wishlistedRoomIds.contains(room.id);
        final cleanOcc = getCleanOccupancy(room.occupancy);
        final title = cleanOcc.isNotEmpty ? '$cleanOcc Seater Room' : (room.roomType.isNotEmpty ? room.roomType : 'Standard Room');
        final isAvailable = room.availableCount > 0;
        final roomImg = room.imageUrls.isNotEmpty ? room.imageUrls.first : (room.images.isNotEmpty ? room.images.first : mess.posterUrl);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => context.push('/room/${room.id}'),
            borderRadius: BorderRadius.circular(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room Image Header
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: SizedBox(
                        height: 170,
                        width: double.infinity,
                        child: FirebaseImage(
                          imagePath: roomImg,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Gradient overlay
                    Container(
                      height: 170,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.35),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),

                    // Top Left: Availability Badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                          ],
                        ),
                        child: Text(
                          isAvailable ? '${room.availableCount} Available' : 'Sold Out',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Top Right: Room Wishlist Heart
                    Positioned(
                      top: 10,
                      right: 10,
                      child: InkWell(
                        onTap: () async {
                          final auth = ref.read(authStateProvider);
                          final userId = auth.value?.uid;
                          if (userId == null) {
                            _showLoginPrompt(context, 'Save to Wishlist', 'Login to save rooms to your wishlist.');
                            return;
                          }
                          await ref.read(wishlistRepositoryProvider).toggleRoomInWishlist(userId, room.id);
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isWishlisted ? Colors.red : Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),

                    // Bottom Overlay: Price Pill
                    Positioned(
                      bottom: 12,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          '₹${room.price}${room.rentCycle == 'yearly' ? '/yr' : '/mo'}',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Room Content Details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          if (room.category != null && room.category!.isNotEmpty && room.category != title)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                room.category!,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF166534),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Room Amenities Pills
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (room.amenities['ac'] == true)
                            _buildRoomAmenityTag(Icons.air_rounded, 'AC'),
                          if (room.amenities['attachedBathroom'] == true)
                            _buildRoomAmenityTag(Icons.water_drop_outlined, 'Attached Bath'),
                          if (room.amenities['wifi'] == true || mess.amenities['wifi'] == true)
                            _buildRoomAmenityTag(Icons.wifi_rounded, 'WiFi'),
                          if (room.amenities['food'] == true || mess.amenities['food'] == true)
                            _buildRoomAmenityTag(Icons.restaurant_rounded, 'Food Included'),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // View Details Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.push('/room/${room.id}'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: Color(0xFFDDD6FE)),
                            backgroundColor: const Color(0xFFF5F3FF),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'View Room Details',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRoomAmenityTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF4B5563)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. ABOUT & OVERVIEW CARD
  // ==========================================
  Widget _buildAboutAndOverviewCard(MessModel mess) {
    final foodDisplay = getFoodFacilityDisplay(mess);
    final notice = mess.noticePeriod ?? '1 Month';
    final operating = mess.operatingSince;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About & Overview',
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                    ),
                    Text(
                      'Property specifications, management, and occupancy rules',
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Description Paragraph
          if (mess.description.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: Text(
                mess.description,
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, color: Color(0xFF4B5563), height: 1.5),
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Metadata Grid Cards
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // Property Type
              _buildOverviewTile(
                label: 'Property Type',
                value: '${mess.messType} Mess',
                icon: Icons.business_center_rounded,
                iconColor: AppTheme.primary,
              ),

              // Food Facility
              if (foodDisplay != '-')
                _buildOverviewTile(
                  label: 'Food Facility',
                  value: foodDisplay,
                  icon: Icons.restaurant_rounded,
                  iconColor: const Color(0xFF059669),
                ),

              // Notice Period
              _buildOverviewTile(
                label: 'Notice Period',
                value: notice,
                icon: Icons.schedule_rounded,
                iconColor: const Color(0xFF4F46E5),
              ),

              // Established Year
              if (operating != null && operating.isNotEmpty)
                _buildOverviewTile(
                  label: 'Established',
                  value: operating.startsWith('Est.') ? operating : 'Est. $operating',
                  icon: Icons.calendar_today_rounded,
                  iconColor: const Color(0xFFD97706),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTile({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 15),
              const SizedBox(width: 6),
              Text(
                value,
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. LIVING & UTILITY SERVICES CARD
  // ==========================================
  Widget _buildLivingAndUtilityServicesCard(MessModel mess, List<RoomModel> rooms) {
    final foodDisplay = getFoodFacilityDisplay(mess);
    final hasWater = mess.waterFacility != null && mess.waterFacility!.isNotEmpty && mess.waterFacility != '-';
    final hasLaundry = mess.laundryFacility != null && mess.laundryFacility!.isNotEmpty && mess.laundryFacility != '-';
    final hasCleaning = (mess.cleaningService != null && mess.cleaningService!.isNotEmpty && mess.cleaningService != 'None') ||
        (mess.cleaningCharges != null && mess.cleaningCharges!.isNotEmpty && mess.cleaningCharges != '-');
    final hasWifi = (mess.amenities['wifi'] == true) || mess.facilities?.contains('Wifi') == true || rooms.any((r) => r.amenities['wifi'] == true);
    final hasPower = (mess.amenities['inverter'] == true) || mess.electricityBill != null || mess.facilities?.contains('InverterPower') == true;
    final hasCctv = mess.cctv == true || mess.facilities?.contains('CCTV') == true || (mess.security != null && mess.security!.isNotEmpty);
    final hasWarden = mess.wardenWatchman == true || mess.managedBy == 'Warden';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF059669), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Living & Utility Services',
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                    ),
                    Text(
                      'Key daily essentials and facilities provided on premises',
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Services Grid
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            childAspectRatio: 1.5,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // Food Service
              _buildServiceGridItem(
                title: 'Food Service',
                subtitle: foodDisplay,
                tagline: mess.foodType != null ? '${mess.foodType}' : 'Freshly Prepared',
                icon: Icons.restaurant_rounded,
                bgColor: const Color(0xFFFFF7ED),
                borderColor: const Color(0xFFFFEDD5),
                iconColor: const Color(0xFFEA580C),
              ),

              // Drinking Water
              _buildServiceGridItem(
                title: 'Drinking Water',
                subtitle: hasWater ? mess.waterFacility! : 'RO / Purified',
                tagline: 'Clean & Accessible',
                icon: Icons.water_drop_rounded,
                bgColor: const Color(0xFFEFF6FF),
                borderColor: const Color(0xFFDBEAFE),
                iconColor: const Color(0xFF2563EB),
              ),

              // Laundry
              _buildServiceGridItem(
                title: 'Laundry',
                subtitle: hasLaundry ? mess.laundryFacility! : 'Washing Area',
                tagline: 'Dedicated Space',
                icon: Icons.layers_rounded,
                bgColor: const Color(0xFFECFEFF),
                borderColor: const Color(0xFFCFFAFE),
                iconColor: const Color(0xFF0891B2),
              ),

              // Housekeeping
              _buildServiceGridItem(
                title: 'Housekeeping',
                subtitle: hasCleaning ? (mess.cleaningService ?? 'Regular Cleaning') : 'Premises Cleaned',
                tagline: 'Cleanliness Maintained',
                icon: Icons.check_circle_outline_rounded,
                bgColor: const Color(0xFFF0FDF4),
                borderColor: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF16A34A),
              ),

              // WiFi
              if (hasWifi)
                _buildServiceGridItem(
                  title: 'Internet / WiFi',
                  subtitle: 'High Speed WiFi',
                  tagline: 'Seamless Connectivity',
                  icon: Icons.wifi_rounded,
                  bgColor: const Color(0xFFEEF2FF),
                  borderColor: const Color(0xFFE0E7FF),
                  iconColor: const Color(0xFF4F46E5),
                ),

              // Power Backup
              if (hasPower)
                _buildServiceGridItem(
                  title: 'Power Backup',
                  subtitle: 'Inverter Backup',
                  tagline: 'Lighting & Fans',
                  icon: Icons.bolt_rounded,
                  bgColor: const Color(0xFFFEFCE8),
                  borderColor: const Color(0xFFFEF08A),
                  iconColor: const Color(0xFFCA8A04),
                ),

              // Security
              if (hasCctv)
                _buildServiceGridItem(
                  title: 'Security',
                  subtitle: 'CCTV / Secure Gate',
                  tagline: 'Resident Safety',
                  icon: Icons.videocam_rounded,
                  bgColor: const Color(0xFFFAF5FF),
                  borderColor: const Color(0xFFF3E8FF),
                  iconColor: const Color(0xFF9333EA),
                ),

              // Warden / Supervision
              if (hasWarden)
                _buildServiceGridItem(
                  title: 'Warden / Caretaker',
                  subtitle: 'Warden on Duty',
                  tagline: 'Discipline & Assistance',
                  icon: Icons.shield_rounded,
                  bgColor: const Color(0xFFFFF1F2),
                  borderColor: const Color(0xFFFFE4E6),
                  iconColor: const Color(0xFFE11D48),
                ),
            ],
          ),

          // Extra Spaces & Common Areas
          if (mess.extraSpace != null && mess.extraSpace!.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Divider(color: Color(0xFFF3F4F6)),
            const SizedBox(height: 8),
            const Text(
              'COMMON AREAS & EXTRA SPACES',
              style: TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 0.6),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: mess.extraSpace!.map((space) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 5),
                      Text(
                        space,
                        style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceGridItem({
    required String title,
    required String subtitle,
    required String tagline,
    required IconData icon,
    required Color bgColor,
    required Color borderColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 9, fontWeight: FontWeight.bold, color: iconColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
          Text(
            tagline,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: 'Outfit', fontSize: 10, color: const Color(0xFF4B5563).withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 6. FEE STRUCTURE & INCLUSIONS CARD
  // ==========================================
  Widget _buildFeeStructureCard(MessModel mess) {
    // Utility billing items
    final electricity = mess.electricityBill ?? 'Included in Rent';
    final isElecIncluded = electricity.toLowerCase().contains('included');

    final foodBill = mess.foodBill ?? 'Included in Rent';
    final isFoodIncluded = foodBill.toLowerCase().contains('included');

    final cleaning = mess.cleaningCharges ?? 'Included in Rent';
    final isCleanIncluded = cleaning.toLowerCase().contains('included') || cleaning.toLowerCase().contains('no');

    final maintenance = mess.maintenanceFee ?? 'Included';
    final isMaintIncluded = maintenance.toLowerCase().contains('included') || maintenance.toLowerCase().contains('no');

    // Deposits
    final deposit = mess.securityDeposit ?? mess.advanceDeposit ?? 'No Deposit';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description_outlined, color: Color(0xFF2563EB), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fee Structure & Inclusions',
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                    ),
                    Text(
                      'Transparent breakdown of rent, utility billing, and security deposits',
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          const Text(
            'MONTHLY INCLUSIONS & UTILITY BILLS',
            style: TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 0.6),
          ),
          const SizedBox(height: 10),

          // Electricity
          _buildFeeItem(
            icon: Icons.bolt_rounded,
            title: 'Electricity',
            subtitle: mess.electricityBillAmount != null && mess.electricityBillAmount!.isNotEmpty
                ? '$electricity (₹${mess.electricityBillAmount}/mo)'
                : electricity,
            badge: isElecIncluded ? '✓ Included' : '⚡ Extra / Units',
            isPositive: isElecIncluded,
          ),
          const SizedBox(height: 8),

          // Food Charges
          _buildFeeItem(
            icon: Icons.restaurant_rounded,
            title: 'Food Charges',
            subtitle: foodBill,
            badge: isFoodIncluded ? '✓ Included' : '🍽️ Extra',
            isPositive: isFoodIncluded,
          ),
          const SizedBox(height: 8),

          // Cleaning
          _buildFeeItem(
            icon: Icons.cleaning_services_rounded,
            title: 'Cleaning & Housekeeping',
            subtitle: cleaning,
            badge: isCleanIncluded ? '✓ No Extra' : '🧹 Extra',
            isPositive: isCleanIncluded,
          ),
          const SizedBox(height: 8),

          // Maintenance
          _buildFeeItem(
            icon: Icons.build_circle_rounded,
            title: 'Maintenance Charge',
            subtitle: maintenance,
            badge: isMaintIncluded ? '✓ Included' : '🛠️ Extra',
            isPositive: isMaintIncluded,
          ),

          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF3F4F6)),
          const SizedBox(height: 12),

          const Text(
            'DEPOSITS & MOVE-IN PAYMENTS',
            style: TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 0.6),
          ),
          const SizedBox(height: 10),

          // Security Deposit Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppTheme.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Security Deposit',
                        style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
                      ),
                      Text(
                        deposit,
                        style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, color: Color(0xFF4B5563)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Refundable',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPositive ? const Color(0xFFF0FDF4).withValues(alpha: 0.7) : const Color(0xFFFFFBEB).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPositive ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: isPositive ? const Color(0xFF16A34A) : const Color(0xFFD97706)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: isPositive ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isPositive ? const Color(0xFF15803D) : const Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 7. PHOTO GALLERY CARD
  // ==========================================
  Widget _buildPhotoGalleryCard(MessModel mess) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded, color: Color(0xFF4F46E5), size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Photo Gallery',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Grid of square images
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: mess.galleryUrls.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final url = mess.galleryUrls[index];
              return InkWell(
                onTap: () => _openFullScreenGallery(context, mess.galleryUrls, index),
                borderRadius: BorderRadius.circular(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FirebaseImage(
                    imagePath: url,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openFullScreenGallery(BuildContext context, List<String> images, int initialIndex) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Center(
                  child: FirebaseImage(
                    imagePath: images[index],
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ==========================================
  // 8. CLAIM LISTING SECTION
  // ==========================================
  Widget _buildClaimListingSection(MessModel mess) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: TextButton.icon(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (context) => ClaimMessBottomSheet(
                mess: mess,
                claimRepository: ClaimRepository(),
              ),
            );
          },
          icon: const Icon(Icons.verified_user_outlined, size: 16, color: Color(0xFF6B7280)),
          label: const Text(
            'Own this property? Claim this listing',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 9. FLOATING CONTACT BUTTON
  // ==========================================
  Widget _buildContactOwnerFAB(MessModel mess, List<RoomModel> rooms) {
    return FloatingActionButton.extended(
      heroTag: 'mess_contact_owner_fab_${mess.id}',
      onPressed: () {
        if (mess.contact.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact info not available')));
          return;
        }
        if (mess.hideContact) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Owner has hidden their contact info')));
          return;
        }
        ContactOwnerDialog.show(
          context,
          mess: mess,
          rooms: rooms,
        );
      },
      icon: const Icon(Icons.phone_rounded, color: Colors.white, size: 20),
      label: const Text(
        'Contact Owner',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
      backgroundColor: AppTheme.primary,
      elevation: 4,
      highlightElevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    );
  }

  void _showLoginPrompt(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFFFEE2E2), shape: BoxShape.circle),
              child: const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 20),
            ),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontFamily: 'Outfit', color: Color(0xFF4B5563))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe later', style: TextStyle(fontFamily: 'Outfit', color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Login / Sign Up', style: TextStyle(fontFamily: 'Outfit', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 280, color: Colors.white),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 28, width: 220, color: Colors.white, margin: const EdgeInsets.only(bottom: 10)),
                  Container(height: 16, width: 160, color: Colors.white, margin: const EdgeInsets.only(bottom: 24)),
                  Container(height: 180, width: double.infinity, color: Colors.white, margin: const EdgeInsets.only(bottom: 20)),
                  Container(height: 180, width: double.infinity, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
