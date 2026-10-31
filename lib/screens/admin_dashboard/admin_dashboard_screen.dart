import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../providers/auth_provider.dart';
import '../../providers/mess_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/booking_provider.dart';
import '../../data/models/user_model.dart';
import '../../data/models/mess_model.dart';
import '../../data/models/room_model.dart';
import '../../data/models/booking_model.dart';
import '../../core/theme/app_theme.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  // Booking remark controllers
  final Map<String, TextEditingController> _bookingRemarkControllers = {};
  final Map<String, bool> _bookingActionLoading = {};

  @override
  void dispose() {
    for (var controller in _bookingRemarkControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? Colors.red.shade600 : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out from Partner Dashboard?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          context.go('/partner-login');
        }
      } catch (e) {
        _showSnackBar('Logout failed: $e', isError: true);
      }
    }
  }

  Future<void> _handleUpdateBookingStatus(String bookingId, BookingStatus newStatus) async {
    setState(() => _bookingActionLoading[bookingId] = true);
    try {
      final remark = _bookingRemarkControllers[bookingId]?.text.trim() ?? '';
      await ref.read(bookingRepositoryProvider).updateBookingStatus(
            bookingId,
            newStatus,
            remark: remark.isNotEmpty ? remark : null,
          );
      _showSnackBar(
        newStatus == BookingStatus.confirmed
            ? '✅ Booking approved successfully!'
            : '❌ Booking rejected successfully!',
      );
    } catch (e) {
      _showSnackBar('Failed to update booking: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _bookingActionLoading[bookingId] = false);
      }
    }
  }

  Future<void> _confirmDeleteRoom(RoomModel room) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Room Type', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${room.occupancy} Seater"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(roomRepositoryProvider).deleteRoom(room.id);
        _showSnackBar('✅ Room type deleted successfully.');
      } catch (e) {
        _showSnackBar('Failed to delete room: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return _buildAccessDenied(
              title: 'Authentication Required',
              message: 'Please log in with your partner account to access this page.',
              buttonText: 'Partner Login',
              onPressed: () => context.go('/partner-login'),
            );
          }

          final hostMessAsync = ref.watch(hostMessProfileProvider(profile.id));

          return hostMessAsync.when(
            data: (messProfile) {
              final isPartner = profile.isPartnerOrAdmin || messProfile != null;

              if (!isPartner) {
                return _buildAccessDenied(
                  title: 'Access Denied',
                  message: 'This area is restricted to MessKhojo verified partners only.',
                  buttonText: 'Back to Home',
                  onPressed: () => context.go('/home'),
                );
              }

              return Column(
                children: [
                  // Top Navbar — exactly matching the website
                  _buildTopNavbar(messProfile),

                  // Main Content View
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1024),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Mess Profile Card
                              _buildMessProfileSection(profile.id, messProfile),

                              const SizedBox(height: 24),

                              // 2. Room Management Section
                              if (messProfile != null) ...[
                                _buildRoomManagementSection(messProfile),
                                const SizedBox(height: 28),

                                // 3. Booking Requests Section
                                _buildBookingRequestsSection(messProfile.id),
                              ],

                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading partner mess: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  // Top Navbar matching website exactly
  Widget _buildTopNavbar(MessModel? messProfile) {
    return Container(
      color: AppTheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Home Icon button
            InkWell(
              onTap: () => context.go('/home'),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(width: 12),

            // Page Title
            const Text(
              'Admin Dashboard',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),

            const Spacer(),

            // Mess Name (on wider screens)
            if (messProfile != null)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Text(
                    messProfile.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),

            // Logout Button
            InkWell(
              onTap: _handleLogout,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: const [
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFFF97316),
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.logout_rounded, color: Color(0xFFF97316), size: 19),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SECTION 1: Mess Profile Section
  Widget _buildMessProfileSection(String userId, MessModel? messProfile) {
    if (messProfile == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD1D5DB), style: BorderStyle.solid),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.business_rounded, color: AppTheme.primary, size: 36),
            ),
            const SizedBox(height: 14),
            const Text(
              'No Mess Profile Found',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Create your Mess Profile to list your mess and start managing room types.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Outfit', color: Color(0xFF6B7280), fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _openMessProfileModal(userId: userId, mess: null),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Create Mess Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    final hasYearly = messProfile.amenities['rentCycle'] == 'yearly' || messProfile.rentCycle == 'yearly';
    final minStay = (messProfile.amenities['minStayDuration'] as num?)?.toInt() ?? 1;
    final totalPhotos = (messProfile.posterUrl != null ? 1 : 0) + messProfile.galleryUrls.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mess Name & Primary Badges
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          messProfile.name,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF030712),
                            letterSpacing: -0.5,
                          ),
                        ),
                        _buildBadge(
                          label: messProfile.district.toUpperCase(),
                          bgColor: const Color(0xFFF3E8FF),
                          textColor: const Color(0xFF6B21A8),
                        ),
                        _buildBadge(
                          label: messProfile.messType,
                          bgColor: const Color(0xFFF3F4F6),
                          textColor: const Color(0xFF1F2937),
                        ),
                        if (hasYearly)
                          _buildBadge(
                            label: 'Yearly Billing',
                            bgColor: const Color(0xFFFEF3C7),
                            textColor: const Color(0xFF92400E),
                          ),
                        if (minStay > 1)
                          _buildBadge(
                            label: '${minStay}m min stay',
                            bgColor: const Color(0xFFDBEAFE),
                            textColor: const Color(0xFF1E40AF),
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Address
                    Text(
                      messProfile.address,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Contact
                    Row(
                      children: [
                        const Text('📞 ', style: TextStyle(fontSize: 15)),
                        Text(
                          messProfile.contact,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Secondary Highlight Pills
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (messProfile.operatingSince != null && messProfile.operatingSince!.isNotEmpty)
                          _buildPill(
                            label: '📅 Since ${messProfile.operatingSince}',
                            bgColor: const Color(0xFFFAF5FF),
                            borderColor: const Color(0xFFE9D5FF),
                            textColor: const Color(0xFF6B21A8),
                          ),
                        if (messProfile.noticePeriod != null && messProfile.noticePeriod!.isNotEmpty)
                          _buildPill(
                            label: '⏳ ${messProfile.noticePeriod} Notice',
                            bgColor: const Color(0xFFFFFBEB),
                            borderColor: const Color(0xFFFDE68A),
                            textColor: const Color(0xFF92400E),
                          ),
                        if (messProfile.foodAvailability != null && messProfile.foodAvailability!.isNotEmpty)
                          _buildPill(
                            label: '🍽️ ${messProfile.foodAvailability}',
                            bgColor: const Color(0xFFEEF2FF),
                            borderColor: const Color(0xFFC7D2FE),
                            textColor: const Color(0xFF3730A3),
                          ),
                        if (messProfile.latitude != null && messProfile.longitude != null)
                          _buildPill(
                            label: '✓ GPS Set',
                            bgColor: const Color(0xFFECFDF5),
                            borderColor: const Color(0xFFA7F3D0),
                            textColor: const Color(0xFF047857),
                          ),
                        if (messProfile.galleryUrls.isNotEmpty)
                          _buildPill(
                            label: '🖼️ ${messProfile.galleryUrls.length} gallery photos',
                            bgColor: const Color(0xFFF9FAFB),
                            borderColor: const Color(0xFFE5E7EB),
                            textColor: const Color(0xFF374151),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Edit Mess Profile Circular Action Button
              InkWell(
                onTap: () => _openMessProfileModal(userId: userId, mess: messProfile),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 20),
                ),
              ),
            ],
          ),

          // Published Photos & Gallery Preview
          if (totalPhotos > 0) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Color(0xFFF3F4F6), height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '📸 PUBLISHED PHOTOS & GALLERY ($totalPhotos)',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _openMessProfileModal(userId: userId, mess: messProfile),
                  child: const Text(
                    'Manage Photos',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 72,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (messProfile.posterUrl != null)
                    _buildGalleryThumbnail(messProfile.posterUrl!, isPoster: true),
                  ...messProfile.galleryUrls.map((url) => _buildGalleryThumbnail(url)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge({required String label, required Color bgColor, required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildPill({
    required String label,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildGalleryThumbnail(String url, {bool isPoster = false}) {
    return Container(
      width: 72,
      height: 72,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPoster ? AppTheme.primary : const Color(0xFFE5E7EB),
          width: isPoster ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 24, color: Colors.grey),
          ),
          if (isPoster)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: const Text(
                  'Poster',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // SECTION 2: Room Management Section
  Widget _buildRoomManagementSection(MessModel messProfile) {
    final roomsAsync = ref.watch(messRoomsProvider(messProfile.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Room Types',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF030712),
              ),
            ),
            InkWell(
              onTap: () => _openRoomModal(messProfile: messProfile, room: null),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0x334B2E83), blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        roomsAsync.when(
          data: (rooms) {
            if (rooms.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.bed_outlined, size: 40, color: Color(0xFF9CA3AF)),
                    const SizedBox(height: 8),
                    const Text(
                      'No room types added yet.',
                      style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap the "+" button above to add your first room configuration.',
                      style: TextStyle(fontFamily: 'Outfit', color: Color(0xFF6B7280), fontSize: 13),
                    ),
                  ],
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 650;
                final cardWidth = isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: rooms.map((room) {
                    return SizedBox(
                      width: cardWidth,
                      child: _buildRoomCard(messProfile, room),
                    );
                  }).toList(),
                );
              },
            );
          },
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
          error: (err, _) => Text('Error loading rooms: $err'),
        ),
      ],
    );
  }

  // Room Card matching RoomCard component from website
  Widget _buildRoomCard(MessModel messProfile, RoomModel room) {
    final occ = room.occupancy;
    final occName = ({
      '1': '1 Seater',
      '2': '2 Seater',
      '3': '3 Seater',
      '4': '4 Seater',
      '5': '5 Seater',
      '6': '6 Seater',
      '7': '7 Seater',
      'Single': '1 Seater',
      'Double': '2 Seater',
      'Triple': '3 Seater'
    })[occ] ?? '$occ Seater';

    final hasAc = room.amenities['ac'] == true;
    final hasBath = room.amenities['attachedBathroom'] == true;
    final isAvailable = room.availableCount > 0;
    final isYearly = messProfile.rentCycle == 'yearly' || room.rentCycle == 'yearly';

    final firstImage = room.imageUrls.isNotEmpty ? room.imageUrls.first : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Image Header
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (firstImage != null)
                  CachedNetworkImage(
                    imageUrl: firstImage,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFFF3F4F6),
                      child: const Icon(Icons.bed_rounded, size: 40, color: Color(0xFF9CA3AF)),
                    ),
                  )
                else
                  Container(
                    color: const Color(0xFFF3F4F6),
                    child: const Icon(Icons.bed_rounded, size: 40, color: Color(0xFF9CA3AF)),
                  ),

                // Top badges over image
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      occName,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAvailable ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAvailable ? '${room.availableCount} available' : 'Full',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Room Details Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price & Category
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹${room.price}',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                          ),
                        ),
                        Text(
                          isYearly ? ' /yr' : ' /mo',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    if (room.category != null && room.category!.trim().isNotEmpty)
                      _buildBadge(
                        label: room.category!.trim(),
                        bgColor: const Color(0xFFEFF6FF),
                        textColor: const Color(0xFF1D4ED8),
                      ),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  'Total: ${room.totalInventory} room${room.totalInventory > 1 ? 's' : ''}',
                  style: const TextStyle(fontFamily: 'Outfit', color: Color(0xFF4B5563), fontSize: 13),
                ),

                const SizedBox(height: 10),

                // Amenities Tags
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (hasAc)
                      _buildPill(
                        label: '❄️ AC',
                        bgColor: const Color(0xFFECFEFF),
                        borderColor: const Color(0xFFA5F3FC),
                        textColor: const Color(0xFF0E7490),
                      ),
                    if (hasBath)
                      _buildPill(
                        label: '🚿 Attached Bath',
                        bgColor: const Color(0xFFF0FDF4),
                        borderColor: const Color(0xFFBBF7D0),
                        textColor: const Color(0xFF15803D),
                      ),
                  ],
                ),

                if (room.otherInfo != null && room.otherInfo!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    room.otherInfo!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Outfit', color: Color(0xFF6B7280), fontSize: 12),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(color: Color(0xFFF3F4F6), height: 1),
                const SizedBox(height: 8),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _openRoomModal(messProfile: messProfile, room: room),
                      icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.primary),
                      label: const Text('Edit', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: () => _confirmDeleteRoom(room),
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                      label: const Text('Delete', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // SECTION 3: Booking Requests Section
  Widget _buildBookingRequestsSection(String messId) {
    final bookingsAsync = ref.watch(messBookingsProvider(messId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        bookingsAsync.maybeWhen(
          data: (bookings) {
            final pendingCount = bookings.where((b) => b.status == BookingStatus.pending || b.status == BookingStatus.contacted).length;
            return Row(
              children: [
                const Text(
                  'Booking Requests',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF030712),
                  ),
                ),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$pendingCount New',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
          orElse: () => const Text(
            'Booking Requests',
            style: TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF030712)),
          ),
        ),

        const SizedBox(height: 14),

        bookingsAsync.when(
          data: (bookings) {
            if (bookings.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Center(
                  child: Text(
                    'No booking requests yet.',
                    style: TextStyle(fontFamily: 'Outfit', color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                  ),
                ),
              );
            }

            return Column(
              children: bookings.map((booking) {
                if (!_bookingRemarkControllers.containsKey(booking.id)) {
                  _bookingRemarkControllers[booking.id] = TextEditingController(text: booking.remark ?? '');
                }

                final isPending = booking.status == BookingStatus.pending || booking.status == BookingStatus.contacted;
                final isLoading = _bookingActionLoading[booking.id] == true;

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: User Name & Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            booking.userName.isEmpty ? 'Student' : booking.userName,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF030712),
                            ),
                          ),
                          _buildBookingStatusBadge(booking.status),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // User Phone
                      Row(
                        children: [
                          const Text('📞 ', style: TextStyle(fontSize: 14)),
                          Text(
                            booking.userPhone,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Booking Summary Tags
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          Text(
                            '🛏️ ${booking.roomType} Seater',
                            style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                          ),
                          Text(
                            '💰 ₹${booking.price}${booking.rentCycle == 'yearly' ? '/yr' : '/mo'}',
                            style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                          ),
                          if (booking.createdAt != null)
                            Text(
                              '📅 ${DateFormat('dd/MM/yyyy').format(booking.createdAt!)}',
                              style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                            ),
                        ],
                      ),

                      // If pending: remark input + Approve/Reject action buttons
                      if (isPending) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _bookingRemarkControllers[booking.id],
                          decoration: InputDecoration(
                            hintText: 'Remark (optional)',
                            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                          ),
                          style: const TextStyle(fontFamily: 'Outfit', fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isLoading ? null : () => _handleUpdateBookingStatus(booking.id, BookingStatus.confirmed),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A34A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: isLoading
                                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Approve', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isLoading ? null : () => _handleUpdateBookingStatus(booking.id, BookingStatus.rejected),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFEF2F2),
                                  foregroundColor: const Color(0xFFB91C1C),
                                  side: const BorderSide(color: Color(0xFFFECACA)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Reject', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // If resolved with remark
                      if (!isPending && booking.remark != null && booking.remark!.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Text(
                            'Remark: ${booking.remark}',
                            style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Color(0xFF4B5563), fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
          error: (err, _) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 36),
                const SizedBox(height: 8),
                const Text(
                  'Unable to load booking requests',
                  style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937)),
                ),
                const SizedBox(height: 4),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(messBookingsProvider(messId)),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingStatusBadge(BookingStatus status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case BookingStatus.confirmed:
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF166534);
        label = 'CONFIRMED';
        break;
      case BookingStatus.rejected:
      case BookingStatus.cancelled:
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFF991B1B);
        label = 'REJECTED';
        break;
      case BookingStatus.pending:
      case BookingStatus.contacted:
      default:
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFF854D0E);
        label = 'PENDING';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: text,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Access Denied Placeholder
  Widget _buildAccessDenied({
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.gavel_rounded, size: 54, color: Colors.red.shade600),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Outfit', color: Color(0xFF6B7280), fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(buttonText, style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // MODAL 1: EDIT / CREATE MESS PROFILE
  // ==========================================
  void _openMessProfileModal({required String userId, MessModel? mess}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _MessProfileModalDialog(
        userId: userId,
        mess: mess,
        onSuccess: (msg) => _showSnackBar(msg),
      ),
    );
  }

  // ==========================================
  // MODAL 2: ADD / EDIT ROOM TYPE
  // ==========================================
  void _openRoomModal({required MessModel messProfile, RoomModel? room}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RoomModalDialog(
        messProfile: messProfile,
        room: room,
        onSuccess: (msg) => _showSnackBar(msg),
      ),
    );
  }
}

// -------------------------------------------------------------
// MESS PROFILE MODAL DIALOG (Matches MessProfileTab.jsx)
// -------------------------------------------------------------
class _MessProfileModalDialog extends ConsumerStatefulWidget {
  final String userId;
  final MessModel? mess;
  final Function(String) onSuccess;

  const _MessProfileModalDialog({
    required this.userId,
    required this.mess,
    required this.onSuccess,
  });

  @override
  ConsumerState<_MessProfileModalDialog> createState() => _MessProfileModalDialogState();
}

class _MessProfileModalDialogState extends ConsumerState<_MessProfileModalDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _contactController;
  late TextEditingController _descController;
  late TextEditingController _locationUrlController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _operatingSinceController;
  late TextEditingController _extraAppliancesController;
  late TextEditingController _foodFacilityController;
  late TextEditingController _securityController;
  late TextEditingController _posterUrlController;
  late TextEditingController _galleryUrlsController;

  String _messType = 'Boys';
  String _district = 'balasore';
  String _rentCycle = 'monthly';
  int _minStay = 1;
  String _foodAvailability = 'Food Available';
  String _noticePeriod = '1 Month';
  String _securityDeposit = 'No Deposit';
  String _electricityBill = 'Included in Rent';
  String _maintenanceFee = 'Included';
  String _cleaningCharges = 'Included in Rent';
  String _foodBill = 'Included in Rent';

  final Map<String, bool> _amenities = {
    'wifi': false,
    'food': false,
    'inverter': false,
    'cctv': false,
    'ac': false,
  };

  @override
  void initState() {
    super.initState();
    final m = widget.mess;
    _nameController = TextEditingController(text: m?.name ?? '');
    _addressController = TextEditingController(text: m?.address ?? '');
    _contactController = TextEditingController(text: m?.contact ?? '');
    _descController = TextEditingController(text: m?.description ?? '');
    _locationUrlController = TextEditingController(text: m?.locationUrl ?? '');
    _latController = TextEditingController(text: m?.latitude?.toString() ?? '');
    _lngController = TextEditingController(text: m?.longitude?.toString() ?? '');
    _operatingSinceController = TextEditingController(text: m?.operatingSince ?? '');
    _extraAppliancesController = TextEditingController(text: m?.extraAppliances ?? '');
    _foodFacilityController = TextEditingController(text: m?.foodFacility ?? '');
    _securityController = TextEditingController(text: m?.security ?? '');
    _posterUrlController = TextEditingController(text: m?.posterUrl ?? '');
    _galleryUrlsController = TextEditingController(text: m?.galleryUrls.join(', ') ?? '');

    if (m != null) {
      _messType = m.messType;
      _district = m.district;
      _rentCycle = m.amenities['rentCycle'] ?? m.rentCycle;
      _minStay = (m.amenities['minStayDuration'] as num?)?.toInt() ?? 1;
      _foodAvailability = m.foodAvailability ?? 'Food Available';
      _noticePeriod = m.noticePeriod ?? '1 Month';
      _securityDeposit = m.securityDeposit ?? 'No Deposit';
      _electricityBill = m.electricityBill ?? 'Included in Rent';
      _maintenanceFee = m.maintenanceFee ?? 'Included';
      _cleaningCharges = m.cleaningCharges ?? 'Included in Rent';
      _foodBill = m.foodBill ?? 'Included in Rent';

      _amenities.forEach((key, _) {
        _amenities[key] = m.amenities[key] == true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _descController.dispose();
    _locationUrlController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _operatingSinceController.dispose();
    _extraAppliancesController.dispose();
    _foodFacilityController.dispose();
    _securityController.dispose();
    _posterUrlController.dispose();
    _galleryUrlsController.dispose();
    super.dispose();
  }

  void _extractCoordsFromUrl() {
    final url = _locationUrlController.text.trim();
    if (url.isEmpty) return;

    final atPattern = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)');
    var match = atPattern.firstMatch(url);
    if (match != null) {
      _latController.text = match.group(1)!;
      _lngController.text = match.group(2)!;
      return;
    }

    final qPattern = RegExp(r'[?&]q=(-?\d+\.\d+),(-?\d+\.\d+)');
    match = qPattern.firstMatch(url);
    if (match != null) {
      _latController.text = match.group(1)!;
      _lngController.text = match.group(2)!;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final double? lat = double.tryParse(_latController.text.trim());
      final double? lng = double.tryParse(_lngController.text.trim());
      GeoPoint? location;
      if (lat != null && lng != null) {
        location = GeoPoint(lat, lng);
      }

      final gallery = _galleryUrlsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final data = {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'contact': _contactController.text.trim(),
        'description': _descController.text.trim(),
        'messType': _messType,
        'district': _district,
        'rentCycle': _rentCycle,
        'posterUrl': _posterUrlController.text.trim().isEmpty ? null : _posterUrlController.text.trim(),
        'galleryUrls': gallery,
        'location': location,
        'locationUrl': _locationUrlController.text.trim().isEmpty ? null : _locationUrlController.text.trim(),
        'operatingSince': _operatingSinceController.text.trim().isEmpty ? null : _operatingSinceController.text.trim(),
        'foodAvailability': _foodAvailability,
        'noticePeriod': _noticePeriod,
        'securityDeposit': _securityDeposit,
        'electricityBill': _electricityBill,
        'maintenanceFee': _maintenanceFee,
        'cleaningCharges': _cleaningCharges,
        'foodBill': _foodBill,
        'extraAppliances': _extraAppliancesController.text.trim(),
        'foodFacility': _foodFacilityController.text.trim(),
        'security': _securityController.text.trim(),
        'adminId': widget.userId,
        'amenities': {
          ..._amenities,
          'rentCycle': _rentCycle,
          'minStayDuration': _minStay,
        },
      };

      final messRepo = ref.read(messRepositoryProvider);
      if (widget.mess != null) {
        await messRepo.updateMess(widget.mess!.id, data);
        widget.onSuccess('✅ Mess Profile updated successfully!');
      } else {
        await messRepo.addMess(data);
        widget.onSuccess('✅ Mess Profile created successfully!');
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.mess != null ? 'Edit Mess Profile' : 'Create Mess Profile',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Modal Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Details
                      _buildFieldLabel('MESS NAME *'),
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration('e.g. Sri Balaji Boys Mess'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Mess Name is required' : null,
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('DISTRICT'),
                                DropdownButtonFormField<String>(
                                  value: _district,
                                  decoration: _inputDecoration(''),
                                  items: const [
                                    DropdownMenuItem(value: 'balasore', child: Text('Balasore')),
                                    DropdownMenuItem(value: 'bhadrak', child: Text('Bhadrak')),
                                    DropdownMenuItem(value: 'mayurbhanj', child: Text('Mayurbhanj')),
                                    DropdownMenuItem(value: 'jajpur', child: Text('Jajpur')),
                                  ],
                                  onChanged: (v) => setState(() => _district = v ?? 'balasore'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('MESS TYPE'),
                                DropdownButtonFormField<String>(
                                  value: _messType,
                                  decoration: _inputDecoration(''),
                                  items: const [
                                    DropdownMenuItem(value: 'Boys', child: Text('Boys Mess')),
                                    DropdownMenuItem(value: 'Girls', child: Text('Girls Mess')),
                                    DropdownMenuItem(value: 'Co-ed', child: Text('Co-ed Mess')),
                                  ],
                                  onChanged: (v) => setState(() => _messType = v ?? 'Boys'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      _buildFieldLabel('FULL ADDRESS *'),
                      TextFormField(
                        controller: _addressController,
                        decoration: _inputDecoration('Enter full locality, street, landmark address'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Address is required' : null,
                      ),
                      const SizedBox(height: 14),

                      _buildFieldLabel('CONTACT NUMBER *'),
                      TextFormField(
                        controller: _contactController,
                        decoration: _inputDecoration('Owner / Manager Phone Number'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Contact is required' : null,
                      ),
                      const SizedBox(height: 14),

                      _buildFieldLabel('DESCRIPTION / ABOUT MESS'),
                      TextFormField(
                        controller: _descController,
                        maxLines: 3,
                        decoration: _inputDecoration('Tell students about your mess environment, special facilities, meals...'),
                      ),
                      const SizedBox(height: 14),

                      // Google Maps Link
                      _buildFieldLabel('GOOGLE MAPS LOCATION URL'),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _locationUrlController,
                              decoration: _inputDecoration('Paste full Google Maps URL'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _extractCoordsFromUrl,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryLight,
                              foregroundColor: AppTheme.primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                            child: const Text('Parse GPS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latController,
                              decoration: _inputDecoration('Latitude (e.g. 21.493)'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _lngController,
                              decoration: _inputDecoration('Longitude (e.g. 86.932)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Food & Facilities
                      _buildSectionTitle('🍽️ Food & Facilities'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _foodAvailability,
                              decoration: _inputDecoration('Food Availability'),
                              items: const [
                                DropdownMenuItem(value: 'Food Available', child: Text('Food Available')),
                                DropdownMenuItem(value: 'Self Cook', child: Text('Self Cook')),
                                DropdownMenuItem(value: 'No Food', child: Text('No Food')),
                              ],
                              onChanged: (v) => setState(() => _foodAvailability = v ?? 'Food Available'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _rentCycle,
                              decoration: _inputDecoration('Billing Basis'),
                              items: const [
                                DropdownMenuItem(value: 'monthly', child: Text('Monthly Basis')),
                                DropdownMenuItem(value: 'yearly', child: Text('Yearly Basis')),
                              ],
                              onChanged: (v) => setState(() => _rentCycle = v ?? 'monthly'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: _amenities.keys.map((key) {
                          return FilterChip(
                            label: Text(key.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            selected: _amenities[key] ?? false,
                            onSelected: (val) => setState(() => _amenities[key] = val),
                            selectedColor: AppTheme.primaryLight,
                            checkmarkColor: AppTheme.primary,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // Photos
                      _buildSectionTitle('📸 Photos & Gallery'),
                      const SizedBox(height: 10),
                      _buildFieldLabel('POSTER IMAGE URL'),
                      TextFormField(
                        controller: _posterUrlController,
                        decoration: _inputDecoration('Main poster / front facade image URL'),
                      ),
                      const SizedBox(height: 12),

                      _buildFieldLabel('GALLERY IMAGE URLS (COMMA-SEPARATED)'),
                      TextFormField(
                        controller: _galleryUrlsController,
                        maxLines: 2,
                        decoration: _inputDecoration('https://photo1.jpg, https://photo2.jpg'),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // Modal Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _saving
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(widget.mess != null ? 'Update Profile' : 'Create Profile', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF374151),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppTheme.primary,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
    );
  }
}

// -------------------------------------------------------------
// ROOM MODAL DIALOG (Matches RoomManagementTab.jsx)
// -------------------------------------------------------------
class _RoomModalDialog extends ConsumerStatefulWidget {
  final MessModel messProfile;
  final RoomModel? room;
  final Function(String) onSuccess;

  const _RoomModalDialog({
    required this.messProfile,
    required this.room,
    required this.onSuccess,
  });

  @override
  ConsumerState<_RoomModalDialog> createState() => _RoomModalDialogState();
}

class _RoomModalDialogState extends ConsumerState<_RoomModalDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  String _occupancy = '2';
  late TextEditingController _categoryController;
  late TextEditingController _priceController;
  late TextEditingController _inventoryController;
  late TextEditingController _availableCountController;
  late TextEditingController _otherInfoController;
  late TextEditingController _imagesController;

  bool _ac = false;
  bool _attachedBathroom = false;

  @override
  void initState() {
    super.initState();
    final r = widget.room;
    _occupancy = r?.occupancy ?? '2';
    _categoryController = TextEditingController(text: r?.category ?? '');
    _priceController = TextEditingController(text: r != null ? r.price.toString() : '');
    _inventoryController = TextEditingController(text: r != null ? r.totalInventory.toString() : '1');
    _availableCountController = TextEditingController(text: r != null ? r.availableCount.toString() : '1');
    _otherInfoController = TextEditingController(text: r?.otherInfo ?? '');
    _imagesController = TextEditingController(text: r?.imageUrls.join(', ') ?? '');

    if (r != null) {
      _ac = r.amenities['ac'] == true;
      _attachedBathroom = r.amenities['attachedBathroom'] == true;
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _priceController.dispose();
    _inventoryController.dispose();
    _availableCountController.dispose();
    _otherInfoController.dispose();
    _imagesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final price = int.tryParse(_priceController.text.trim()) ?? 0;
      final inventory = int.tryParse(_inventoryController.text.trim()) ?? 1;
      final avail = int.tryParse(_availableCountController.text.trim()) ?? 0;

      final imgs = _imagesController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final data = {
        'messId': widget.messProfile.id,
        'messName': widget.messProfile.name,
        'district': widget.messProfile.district,
        'occupancy': _occupancy,
        'roomType': _occupancy,
        'category': _categoryController.text.trim(),
        'price': price,
        'rent': price,
        'totalInventory': inventory,
        'availableCount': avail,
        'available': avail > 0,
        'otherInfo': _otherInfoController.text.trim(),
        'imageUrls': imgs,
        'rentCycle': widget.messProfile.rentCycle,
        'amenities': {
          'ac': _ac,
          'attachedBathroom': _attachedBathroom,
        },
      };

      final roomRepo = ref.read(roomRepositoryProvider);
      if (widget.room != null) {
        await roomRepo.updateRoom(widget.room!.id, data);
        widget.onSuccess('✅ Room type updated successfully!');
      } else {
        await roomRepo.addRoom(data);
        widget.onSuccess('✅ Room type added successfully!');
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving room: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isYearly = widget.messProfile.rentCycle == 'yearly';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.room != null ? 'Edit Room Type' : 'Add New Room Type',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Modal Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('OCCUPANCY TYPE'),
                                DropdownButtonFormField<String>(
                                  value: _occupancy,
                                  decoration: _inputDecoration(''),
                                  items: const [
                                    DropdownMenuItem(value: '1', child: Text('1 Seater')),
                                    DropdownMenuItem(value: '2', child: Text('2 Seater')),
                                    DropdownMenuItem(value: '3', child: Text('3 Seater')),
                                    DropdownMenuItem(value: '4', child: Text('4 Seater')),
                                    DropdownMenuItem(value: '5', child: Text('5 Seater')),
                                    DropdownMenuItem(value: '6', child: Text('6 Seater')),
                                    DropdownMenuItem(value: '7', child: Text('7 Seater')),
                                  ],
                                  onChanged: (v) => setState(() => _occupancy = v ?? '2'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('CATEGORY (OPTIONAL)'),
                                TextFormField(
                                  controller: _categoryController,
                                  decoration: _inputDecoration('e.g. Deluxe, AC'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      _buildLabel('PRICE PER STUDENT (${isYearly ? '₹/year' : '₹/month'}) *'),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('Rent amount'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Price is required';
                          final val = int.tryParse(v.trim());
                          if (val == null || val <= 0) return 'Enter a valid price';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('TOTAL ROOMS OF THIS TYPE *'),
                                TextFormField(
                                  controller: _inventoryController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration('Total count'),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('AVAILABLE BEDS/SEATS *'),
                                TextFormField(
                                  controller: _availableCountController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration('Available count'),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('AMENITIES INCLUDED'),
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('❄️ AC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            selected: _ac,
                            onSelected: (val) => setState(() => _ac = val),
                            selectedColor: AppTheme.primaryLight,
                            checkmarkColor: AppTheme.primary,
                          ),
                          const SizedBox(width: 10),
                          FilterChip(
                            label: const Text('🚿 Attached Bathroom', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            selected: _attachedBathroom,
                            onSelected: (val) => setState(() => _attachedBathroom = val),
                            selectedColor: AppTheme.primaryLight,
                            checkmarkColor: AppTheme.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('OTHER DETAILS'),
                      TextFormField(
                        controller: _otherInfoController,
                        maxLines: 2,
                        decoration: _inputDecoration('Additional info about this room type...'),
                      ),
                      const SizedBox(height: 14),

                      _buildLabel('ROOM IMAGES (COMMA-SEPARATED URLS, MAX 5)'),
                      TextFormField(
                        controller: _imagesController,
                        maxLines: 2,
                        decoration: _inputDecoration('https://photo1.jpg, https://photo2.jpg'),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),

            // Modal Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.room != null ? const Color(0xFFF59E0B) : AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _saving
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(widget.room != null ? 'Update Room Type' : 'Add Room Type', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF374151),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
    );
  }
}
