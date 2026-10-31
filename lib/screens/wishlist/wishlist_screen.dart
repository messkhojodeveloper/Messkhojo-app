import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_providers.dart';
import '../../core/theme/app_theme.dart';
import '../home/components/mess_card.dart';
import '../../widgets/room_card.dart';

import '../../widgets/app_error_widget.dart';
import '../../widgets/app_empty_state_widget.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Wishlist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_rounded, size: 48, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Your Wishlist Awaits',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: AppTheme.textDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 36),
                    child: Text(
                      'Log in to save your favorite messes and rooms so you can revisit them anytime.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Outfit', color: AppTheme.textGray, fontSize: 14, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    child: const Text('Log In / Sign Up'),
                  ),
                ],
              ),
            );
          }

          return _buildTabsContent(context, ref, user.uid);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => AppErrorWidget(
          title: 'Authentication Error',
          message: 'Unable to verify login state. Please try again.',
          onRetry: () => ref.invalidate(authStateProvider),
        ),
      ),
    );
  }

  Widget _buildTabsContent(BuildContext context, WidgetRef ref, String uid) {
    final wishlistAsync = ref.watch(userWishlistProvider);
    final messesAsync = ref.watch(messesStreamProvider);
    final roomsAsync = ref.watch(roomsStreamProvider);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textGray,
              indicatorColor: AppTheme.primary,
              tabs: [
                Tab(icon: Icon(Icons.business), text: 'Messes'),
                Tab(icon: Icon(Icons.bed), text: 'Rooms'),
              ],
            ),
          ),
          Expanded(
            child: wishlistAsync.when(
              data: (wishlist) {
                if (wishlist == null) return const Center(child: CircularProgressIndicator());

                return TabBarView(
                  children: [
                    // MESSES TAB
                    messesAsync.when(
                      data: (messes) {
                        final wishlistedMesses = messes.where((m) => wishlist.messes.contains(m.id)).toList();
                        if (wishlistedMesses.isEmpty) {
                          return AppEmptyStateWidget(
                            title: 'No Messes Saved',
                            message: 'Explore messes in your area and tap the heart icon to save them here.',
                            icon: Icons.business_outlined,
                            actionLabel: 'Explore Messes',
                            onAction: () => context.go('/home'),
                          );
                        }
                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            mainAxisExtent: 280,
                          ),
                          itemCount: wishlistedMesses.length,
                          itemBuilder: (context, index) => MessCard(mess: wishlistedMesses[index], index: index),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => AppErrorWidget(
                        title: 'Error Loading Messes',
                        message: 'Could not fetch saved messes. Please check your connection.',
                        onRetry: () => ref.invalidate(messesStreamProvider),
                      ),
                    ),

                    // ROOMS TAB
                    roomsAsync.when(
                      data: (rooms) {
                        final wishlistedRooms = rooms.where((r) => wishlist.rooms.contains(r.id)).toList();
                        if (wishlistedRooms.isEmpty) {
                          return AppEmptyStateWidget(
                            title: 'No Rooms Saved',
                            message: 'Explore room listings in your area and tap the heart icon to save them here.',
                            icon: Icons.bed_outlined,
                            actionLabel: 'Explore Rooms',
                            onAction: () => context.go('/home'),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: wishlistedRooms.length,
                          itemBuilder: (context, index) => RoomCard(room: wishlistedRooms[index]),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => AppErrorWidget(
                        title: 'Error Loading Rooms',
                        message: 'Could not fetch saved rooms. Please check your connection.',
                        onRetry: () => ref.invalidate(roomsStreamProvider),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => AppErrorWidget(
                title: 'Error Loading Wishlist',
                message: 'Could not fetch your wishlist data.',
                onRetry: () => ref.invalidate(userWishlistProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
