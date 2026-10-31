import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/room_provider.dart';
import '../../providers/mess_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../data/models/room_model.dart';
import '../../data/models/mess_model.dart';
import '../../widgets/firebase_image.dart';
import '../../widgets/contact_owner_dialog.dart';
import '../../widgets/app_error_widget.dart';
import '../../core/theme/app_theme.dart';
import '../mess_details/mess_details_screen.dart' show getFoodFacilityDisplay;

/// Helper to normalize occupancy numbers matching website
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

class RoomDetailsScreen extends ConsumerStatefulWidget {
  final String roomId;
  const RoomDetailsScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomDetailsScreen> createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends ConsumerState<RoomDetailsScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomDetailsProvider(widget.roomId));
    final wishlistedRoomIds = ref.watch(wishlistedRoomIdsProvider);
    final isWishlisted = wishlistedRoomIds.contains(widget.roomId);
    final room = roomAsync.value;
    final mess = room != null ? ref.watch(messDetailsProvider(room.messId)).value : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1F2937), size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Room Details',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isWishlisted ? const Color(0xFFEF4444) : const Color(0xFF6B7280),
              size: 22,
            ),
            onPressed: () async {
              final auth = ref.read(authStateProvider);
              if (auth.value == null) {
                _showLoginPrompt(context, 'Save to Wishlist', 'Login to save rooms to your personal wishlist.');
                return;
              }
              await ref.read(wishlistRepositoryProvider).toggleRoomInWishlist(auth.value!.uid, widget.roomId);
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.share_rounded,
              color: Color(0xFF6B7280),
              size: 20,
            ),
            onPressed: () async {
              final room = roomAsync.value;
              final shareUrl = 'https://messkhojo.com/room/${widget.roomId}';
              final roomName = room != null ? '${getCleanOccupancy(room.occupancy)} Seater Room' : 'Room';
              final shareText = 'Check out this $roomName on MessKhojo!\n$shareUrl';

              try {
                await SharePlus.instance.share(ShareParams(text: shareText));
              } catch (_) {
                await Clipboard.setData(ClipboardData(text: shareUrl));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Room link copied to clipboard!'),
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
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: roomAsync.when(
        data: (room) {
          if (room == null) {
            return AppErrorWidget.notFound(
              title: 'Room Not Found',
              message: 'This room specification is no longer available or was removed.',
              showHomeButton: true,
            );
          }

          final messAsync = ref.watch(messDetailsProvider(room.messId));
          final currentMess = messAsync.value;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Photo Gallery Card
                _buildImageGalleryCard(context, room, currentMess),
                const SizedBox(height: 16),

                // 2. Title & Price Card
                _buildTitleAndPriceCard(room, currentMess, isWishlisted),
                const SizedBox(height: 16),

                // 3. Amenities Card
                _buildAmenitiesCard(room, currentMess),
                const SizedBox(height: 16),

                // 4. Description & Comprehensive Policies Card
                _buildDescriptionAndPoliciesCard(room, currentMess),
                const SizedBox(height: 16),

                // 5. Parent Mess Quick Card
                if (currentMess != null) ...[
                  _buildParentMessCard(currentMess),
                  const SizedBox(height: 16),
                ],

                // Spacing so content is never covered by floating action button
                const SizedBox(height: 100),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, stack) => AppErrorWidget(
          title: 'Unable to Load Room Details',
          message: 'Could not fetch room information. Please check your network connection.',
          onRetry: () => ref.invalidate(roomDetailsProvider(widget.roomId)),
          showHomeButton: true,
        ),
      ),
      floatingActionButton: room != null ? _buildContactOwnerFAB(room, mess) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ==========================================
  // 1. PHOTO GALLERY CARD
  // ==========================================
  Widget _buildImageGalleryCard(BuildContext context, RoomModel room, MessModel? mess) {
    final images = <String>[];
    if (room.imageUrls.isNotEmpty) {
      images.addAll(room.imageUrls);
    } else if (room.images.isNotEmpty) {
      images.addAll(room.images);
    } else if (mess?.posterUrl != null && mess!.posterUrl!.isNotEmpty) {
      images.add(mess.posterUrl!);
    }

    if (images.isEmpty) {
      images.add('default-room.jpg');
    }

    return Container(
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
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 230,
              width: double.infinity,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (idx) => setState(() => _currentImageIndex = idx),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () => _openFullScreenGallery(context, images, index),
                        child: FirebaseImage(
                          imagePath: images[index],
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),

                  // Image count badge (if > 1)
                  if (images.length > 1)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1} / ${images.length}',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Thumbnail indicator row if multiple photos
          if (images.length > 1) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final isSelected = _currentImageIndex == idx;
                  return InkWell(
                    onTap: () {
                      _pageController.animateToPage(
                        idx,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : const Color(0xFFE5E7EB),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FirebaseImage(
                          imagePath: images[idx],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // 2. TITLE & PRICE CARD
  // ==========================================
  Widget _buildTitleAndPriceCard(RoomModel room, MessModel? mess, bool isWishlisted) {
    final cleanOcc = getCleanOccupancy(room.occupancy);
    final title = cleanOcc.isNotEmpty ? '$cleanOcc Seater' : (room.roomType.isNotEmpty ? room.roomType : 'Standard Room');
    final isAvailable = room.availableCount > 0;
    final category = room.category ?? 'Standard';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title, Category Badge, Wishlist Heart
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () async {
                  final auth = ref.read(authStateProvider);
                  if (auth.value == null) {
                    _showLoginPrompt(context, 'Save to Wishlist', 'Login to save rooms to your personal wishlist.');
                    return;
                  }
                  await ref.read(wishlistRepositoryProvider).toggleRoomInWishlist(auth.value!.uid, widget.roomId);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isWishlisted ? const Color(0xFFFEF2F2) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isWishlisted ? const Color(0xFFFECACA) : const Color(0xFFE5E7EB)),
                  ),
                  child: Icon(
                    isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isWishlisted ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          // Parent Mess Location Link
          if (mess != null) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => context.push('/mess/${mess.id}'),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      mess.name,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF3F4F6)),
          const SizedBox(height: 12),

          // Price & Beds Available Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MONTHLY RENT',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9CA3AF),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹${room.price}',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        room.rentCycle == 'yearly' ? '/yr' : '/mo',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Availability Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isAvailable ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isAvailable ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
                ),
                child: Text(
                  isAvailable ? '${room.availableCount} Beds Available' : 'Sold Out',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. AMENITIES CARD
  // ==========================================
  Widget _buildAmenitiesCard(RoomModel room, MessModel? mess) {
    final hasAc = room.amenities['ac'] == true;
    final hasAttachedBath = room.amenities['attachedBathroom'] == true;
    final hasWifi = room.amenities['wifi'] == true || mess?.amenities['wifi'] == true;
    final hasFood = room.amenities['food'] == true || mess?.amenities['food'] == true;

    final anyAmenity = hasAc || hasAttachedBath || hasWifi || hasFood;
    if (!anyAmenity) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Amenities',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),

          // Grid of Colored Cards (AC, Bath, Wifi, Food)
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            childAspectRatio: 1.5,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              if (hasAc)
                _buildAmenityGridTile(
                  icon: Icons.air_rounded,
                  label: 'AC',
                  bgColor: const Color(0xFFEFF6FF),
                  borderColor: const Color(0xFFDBEAFE),
                  iconColor: const Color(0xFF2563EB),
                ),
              if (hasAttachedBath)
                _buildAmenityGridTile(
                  icon: Icons.water_drop_rounded,
                  label: 'Bathroom',
                  bgColor: const Color(0xFFECFEFF),
                  borderColor: const Color(0xFFCFFAFE),
                  iconColor: const Color(0xFF0891B2),
                ),
              if (hasWifi)
                _buildAmenityGridTile(
                  icon: Icons.wifi_rounded,
                  label: 'Wi-Fi',
                  bgColor: const Color(0xFFEEF2FF),
                  borderColor: const Color(0xFFE0E7FF),
                  iconColor: const Color(0xFF4F46E5),
                ),
              if (hasFood)
                _buildAmenityGridTile(
                  icon: Icons.restaurant_rounded,
                  label: 'Food',
                  bgColor: const Color(0xFFFFF7ED),
                  borderColor: const Color(0xFFFFEDD5),
                  iconColor: const Color(0xFFEA580C),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityGridTile({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color borderColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. DESCRIPTION & POLICIES CARD
  // ==========================================
  Widget _buildDescriptionAndPoliciesCard(RoomModel room, MessModel? mess) {
    final description = room.otherInfo?.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            (description != null && description.isNotEmpty)
                ? description
                : 'Standard accommodation provided with comfortable living arrangement and essential daily amenities.',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              color: Color(0xFF4B5563),
              height: 1.5,
            ),
          ),

          if (mess != null) ...[
            const SizedBox(height: 18),
            const Divider(color: Color(0xFFF3F4F6)),
            const SizedBox(height: 14),

            // Mess Policies & Billing List
            const Text(
              'Mess Policies & Billing',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),

            _buildBulletPoint('Property Type', '${mess.messType} Mess'),
            _buildBulletPoint('Security Deposit', mess.securityDeposit ?? mess.advanceDeposit ?? 'No Deposit'),
            _buildBulletPoint('Notice Period', mess.noticePeriod ?? '1 Month'),
            _buildBulletPoint('Electricity', mess.electricityBill ?? 'Included in Rent'),
            _buildBulletPoint('Maintenance', mess.maintenanceFee ?? 'Included'),
            _buildBulletPoint('Cleaning', mess.cleaningCharges ?? 'Included in Rent'),

            const SizedBox(height: 18),
            const Divider(color: Color(0xFFF3F4F6)),
            const SizedBox(height: 14),

            // Living Services & Facilities List
            const Text(
              'Living Services & Facilities',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),

            if (mess.foodFacility != null && mess.foodFacility != 'No Food')
              _buildBulletPoint('Food Service', getFoodFacilityDisplay(mess)),
            if (mess.waterFacility != null && mess.waterFacility != '-')
              _buildBulletPoint('Water Supply', mess.waterFacility!),
            if (mess.laundryFacility != null && mess.laundryFacility != '-')
              _buildBulletPoint('Laundry', mess.laundryFacility!),
            if (mess.cleaningService != null && mess.cleaningService != 'None')
              _buildBulletPoint('Housekeeping', mess.cleaningService!),
            if (mess.cctv == true || mess.security != null)
              _buildBulletPoint('Security', 'CCTV & Secure Premises'),
          ],
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF374151),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. PARENT MESS CARD
  // ==========================================
  Widget _buildParentMessCard(MessModel mess) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/mess/${mess.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 64,
                height: 64,
                child: FirebaseImage(
                  imagePath: mess.posterUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ABOUT PROPERTY',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mess.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mess.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 6. FLOATING CONTACT BUTTON
  // ==========================================
  Widget _buildContactOwnerFAB(RoomModel room, MessModel? mess) {
    return FloatingActionButton.extended(
      heroTag: 'room_contact_owner_fab_${room.id}',
      onPressed: () {
        if (mess == null) return;
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
          rooms: [room],
          initialOccupancy: room.occupancy,
          roomId: room.id,
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
}
