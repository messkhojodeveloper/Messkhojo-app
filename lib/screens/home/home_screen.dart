import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/districts_config.dart';
import '../../data/models/mess_model.dart';
import '../../data/models/user_model.dart';
import '../../providers/home_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hero_ad_provider.dart';
import 'components/compact_mess_card.dart';
import 'components/shimmer_loading.dart';
import 'components/hero_ads_carousel.dart';
import '../../widgets/feedback_bottom_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const int _previewCount = 6;

  @override
  Widget build(BuildContext context) {
    final messesAsync = ref.watch(messesStreamProvider);
    final messesByCity = ref.watch(messesByCityProvider);
    final loading = messesAsync.isLoading;
    final carouselEnabled = ref.watch(heroAdsCarouselEnabledProvider).asData?.value ?? false;
    final heroAds = ref.watch(homeHeroAdsProvider).asData?.value ?? [];

    final searchQuery = ref.watch(searchQueryProvider).trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      endDrawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(messesStreamProvider);
          ref.invalidate(roomsStreamProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildActionButtons(),
            ),
            // Active Search Filter Chip (if search is active from bottom bar)
            if (searchQuery.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_rounded, size: 14, color: AppTheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Search: "$searchQuery"',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => ref.read(searchQueryProvider.notifier).clear(),
                              child: const Icon(Icons.close_rounded, size: 16, color: AppTheme.primary),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => ref.read(searchQueryProvider.notifier).clear(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            color: AppTheme.textGray,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Hero Ads Carousel — only shown when carouselEnabled = true in Firestore
            if (carouselEnabled && heroAds.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: HeroAdsCarousel(ads: heroAds),
                ),
              ),
            if (loading)
              const SliverToBoxAdapter(child: _LoadingState())
            else
              SliverToBoxAdapter(
                child: _buildCitySections(messesByCity),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: const Text(
        'MessKhojo',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: 22,
          color: Color(0xFF1F2937),
          letterSpacing: -0.4,
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.favorite_border_rounded, color: Color(0xFF1F2937), size: 24),
          onPressed: () => context.push('/wishlist'),
          tooltip: 'Wishlist',
        ),
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF1F2937), size: 26),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            tooltip: 'Menu',
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDrawer() {
    final authState = ref.watch(authStateProvider);
    final isLoggedIn = authState.value != null;
    final userProfile = ref.watch(userProfileProvider).value;
    final isPartner = userProfile?.role == UserRole.admin;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        top: true,
        child: ListView(
          padding: const EdgeInsets.only(top: 16, bottom: 20),
          children: [
            ListTile(
              leading: const Icon(Icons.home_rounded, color: AppTheme.primary),
              title: const Text('Home', style: TextStyle(fontFamily: 'Outfit', color: Color(0xFF1F2937), fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                context.go('/home');
              },
            ),
            ListTile(
              leading: const Icon(Icons.bed_rounded, color: Color(0xFF4B5563)),
              title: const Text('Find Your Room', style: TextStyle(fontFamily: 'Outfit', color: Color(0xFF1F2937))),
              onTap: () {
                Navigator.pop(context);
                context.go('/find-your-room');
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_home_rounded, color: Color(0xFF4B5563)),
              title: const Text('Register Your Mess', style: TextStyle(fontFamily: 'Outfit', color: Color(0xFF1F2937))),
              onTap: () {
                Navigator.pop(context);
                context.push('/register-mess');
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite_rounded, color: Color(0xFF4B5563)),
              title: const Text('Wishlist', style: TextStyle(fontFamily: 'Outfit', color: Color(0xFF1F2937))),
              onTap: () {
                Navigator.pop(context);
                if (isLoggedIn) {
                  context.push('/wishlist');
                } else {
                  context.push('/login');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_rounded, color: Color(0xFF4B5563)),
              title: Text(isLoggedIn ? 'Profile' : 'Login / Sign Up', style: const TextStyle(fontFamily: 'Outfit', color: Color(0xFF1F2937))),
              onTap: () {
                Navigator.pop(context);
                context.push(isLoggedIn ? '/profile' : '/login');
              },
            ),
            const Divider(color: AppTheme.lightGray),
            // Partner Entry (Shows Partner Dashboard if logged in as partner, else Partner Login)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.business_center_rounded, color: AppTheme.primary, size: 20),
              ),
              title: Text(
                isPartner ? 'Partner Dashboard' : 'Partner Login',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                isPartner ? 'Manage your mess and rooms' : 'Mess owners sign in here',
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
              onTap: () {
                Navigator.pop(context);
                if (isPartner) {
                  context.push('/admin');
                } else {
                  context.push('/partner-login');
                }
              },
            ),
            const Divider(color: AppTheme.lightGray),
            ListTile(
              leading: const Icon(Icons.info_rounded, color: Color(0xFF4B5563)),
              title: const Text('About Us', style: TextStyle(fontFamily: 'Outfit', color: Color(0xFF1F2937))),
              onTap: () {
                Navigator.pop(context);
                context.push('/about');
              },
            ),
            ListTile(
              leading: const Icon(Icons.rate_review_rounded, color: AppTheme.primary),
              title: const Text(
                'Give Feedback',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Help us improve MessKhojo',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
              onTap: () {
                Navigator.pop(context);
                FeedbackBottomSheet.show(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_rounded, color: Color(0xFF4B5563)),
              title: const Text('Privacy Policy', style: TextStyle(fontFamily: 'Outfit', color: Color(0xFF1F2937))),
              onTap: () {
                Navigator.pop(context);
                context.push('/privacy');
              },
            ),
            ListTile(
              leading: const Icon(Icons.gavel_rounded, color: Color(0xFF4B5563)),
              title: const Text('Terms & Conditions', style: TextStyle(fontFamily: 'Outfit', color: Color(0xFF1F2937))),
              onTap: () {
                Navigator.pop(context);
                context.push('/terms');
              },
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              label: 'Find Your Room',
              subtitle: 'Convenient Rooms Available!',
              icon: Icons.bed_rounded,
              onTap: () => context.push('/find-your-room'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              label: 'Register Your Mess',
              subtitle: 'Enroll Today!',
              icon: Icons.add_home_rounded,
              onTap: () => context.push('/register-mess'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Outfit',
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'Outfit',
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitySections(Map<String, List<MessModel>> messesByCity) {
    // Apply search filter on top of grouped messes
    final query = ref.watch(searchQueryProvider).trim().toLowerCase();
    final filteredByCity = _applySearchFilter(messesByCity, query);

    // Build city list in priority order
    final cityOrder = DistrictsConfig.cityDisplayOrder;
    final orderedCities = <String>[];
    for (final cityId in cityOrder) {
      if (filteredByCity.containsKey(cityId) && filteredByCity[cityId]!.isNotEmpty) {
        orderedCities.add(cityId);
      }
    }
    // Add any extra cities not in the priority list
    for (final cityId in filteredByCity.keys) {
      if (!cityOrder.contains(cityId) && filteredByCity[cityId]!.isNotEmpty) {
        orderedCities.add(cityId);
      }
    }

    if (orderedCities.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final cityId in orderedCities) ...[
            _buildCitySection(cityId, filteredByCity[cityId]!),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Map<String, List<MessModel>> _applySearchFilter(
      Map<String, List<MessModel>> messesByCity, String query) {
    if (query.isEmpty) return messesByCity;

    // Check if query matches a district name exactly
    final matchedDistrictKey = DistrictsConfig.all.entries
        .where((e) => e.value.name.toLowerCase() == query)
        .map((e) => e.key)
        .firstOrNull;

    if (matchedDistrictKey != null) {
      final citiesInDistrict =
          DistrictsConfig.all[matchedDistrictKey]!.cities.map((c) => c.id).toSet();
      return Map.fromEntries(
        messesByCity.entries.where((e) => citiesInDistrict.contains(e.key)),
      );
    }

    final filtered = <String, List<MessModel>>{};
    for (final entry in messesByCity.entries) {
      final matching = entry.value.where((mess) {
        return mess.name.toLowerCase().contains(query) ||
            mess.address.toLowerCase().contains(query) ||
            mess.city.toLowerCase().contains(query);
      }).toList();
      if (matching.isNotEmpty) filtered[entry.key] = matching;
    }
    return filtered;
  }

  Widget _buildCitySection(String cityId, List<MessModel> messes) {
    final cityName = DistrictsConfig.getCityDisplayName(cityId);
    final districtId = DistrictsConfig.getDistrictForCity(cityId) ?? 'balasore';
    final preview = messes.take(_previewCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // City header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Popular mess in $cityName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Outfit',
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_rounded, size: 22, color: Color(0xFF1F2937)),
              onPressed: () => context.push('/city/$districtId/$cityId'),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Horizontally scrollable mess cards
        SizedBox(
          height: 178,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: preview.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 170,
                child: CompactMessCard(mess: preview[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F0FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.location_on_rounded, size: 32, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Messes Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: 'Outfit',
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We are launching in new areas soon.\nRegister your mess to get started!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Outfit',
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < 2; i++) ...[
            Container(
              height: 24,
              width: 180,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 14),
            const ShimmerRow(),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }
}
